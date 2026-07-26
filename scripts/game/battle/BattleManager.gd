# BattleManager — 战斗管理器（攻城模式）
# 管理浮岛炮台、防御工事、回合循环和胜负判定
extends Node2D
class_name BattleManager

# ---- Sub-systems ----
var turn_manager: TurnManager
var aim_line: AimLine
var projectile_launcher: ProjectileLauncher
var energy_system: EnergySystem
var card_manager: CardManager
var relic_manager: RelicManager
var run_state: RunState
var event_manager: EventManager
var defense_manager: DefenseManager
var auto_scroller: AutoScroller
var battle_hud: BattleHUD

# ---- Floating Island ----
var floating_island: FloatingIsland

# ---- State ----
var _pending_card_effect: Dictionary = {}
var _card_selected: bool = false
var battle_over: bool = false
var _active_projectiles: int = 0  # 场上飞行中的炮弹数

## 可选：从外部传入的 RunState（持久状态）
var run_state_override: RunState = null
## 战斗结果回调
var battle_result_callback: Callable = Callable()
## 是否为游戏模式（非测试模式）
var _game_mode: bool = false

func _enter_tree() -> void:
	print("[LIFECYCLE] + BattleManager: game_mode=%s" % str(_game_mode))

func _exit_tree() -> void:
	print("[LIFECYCLE] - BattleManager: battle_over=%s" % str(battle_over))
	EventBus.off("turn:player_begin", _on_player_turn_begin)
	EventBus.off("projectile:explode", _on_vfx_explosion)
	EventBus.off("card:used", _on_card_used)
	EventBus.off("turn:end_requested", _on_end_turn_requested)
	EventBus.off("turn:ended", _on_turn_ended)

func _ready() -> void:
	_game_mode = run_state_override != null
	_create_subsystems()
	_create_floating_island()
	_generate_defense_wall()
	_connect_events()
	
	# 初始化 HUD（所有系统已就绪）
	_update_hud()
	
	_self_test()
	
	turn_manager.start_battle()

func _create_subsystems() -> void:
	turn_manager = TurnManager.new()
	add_child(turn_manager)

	# RunState (persistent across battles)
	if run_state_override != null:
		run_state = run_state_override
	else:
		run_state = RunState.new()
	add_child(run_state)
	
	# RelicManager（必须在 EnergySystem 之前创建，因为能量可能受遗物加成）
	relic_manager = RelicManager.new()
	if _game_mode and run_state != null:
		for relic in run_state.relics:
			relic_manager.add_relic(relic)
	add_child(relic_manager)
	
	energy_system = EnergySystem.new()
	# 遗物能量加成
	if _game_mode:
		var bonus := relic_manager.get_energy_bonus()
		if bonus > 0:
			energy_system.increase_max(bonus)
			print("[Battle] Relic energy bonus: +%d" % bonus)
	add_child(energy_system)
	
	card_manager = CardManager.new()
	if _game_mode and run_state != null and run_state.deck.size() > 0:
		card_manager.initialize(run_state.deck)
		print("[Battle] Using persistent deck: %d cards" % run_state.deck.size())
	else:
		card_manager.initialize(CardDB.get_starting_deck())
	add_child(card_manager)
	
	event_manager = EventManager.new()
	event_manager.setup(run_state, card_manager)
	add_child(event_manager)
	
	defense_manager = DefenseManager.new()
	add_child(defense_manager)
	
	auto_scroller = AutoScroller.new()
	add_child(auto_scroller)
	
	# 瞄准线（稍后用浮岛位置设置原点）
	aim_line = AimLine.new()
	aim_line.set_fire_callback(_on_aim_fire)
	add_child(aim_line)
	
	projectile_launcher = ProjectileLauncher.new()
	projectile_launcher.setup(self)
	add_child(projectile_launcher)
	
	battle_hud = BattleHUD.new()
	var hud_layer := CanvasLayer.new()
	hud_layer.add_child(battle_hud)
	add_child(hud_layer)

func _create_floating_island() -> void:
	floating_island = FloatingIsland.new()
	add_child(floating_island)
	
	# 炮台发射原点 = 浮岛炮管顶端
	aim_line.set_origin(floating_island.get_cannon_position())
	
	# 设置自动平移器的引用
	auto_scroller.setup(
		floating_island,
		get_viewport().get_camera_2d(),
		defense_manager,
		_on_collision_lose,
		_on_cleared_win
	)
	
	print("[Battle] Floating island created at x=%.0f y=%.0f" % [floating_island.position.x, floating_island.position.y])

func _generate_defense_wall() -> void:
	defense_manager.generate(self)

func _connect_events() -> void:
	EventBus.on("turn:player_begin", _on_player_turn_begin)
	EventBus.on("projectile:explode", _on_vfx_explosion)
	EventBus.on("card:used", _on_card_used)
	EventBus.on("turn:end_requested", _on_end_turn_requested)
	EventBus.on("turn:ended", _on_turn_ended)

# ---- Turn Handlers ----

func _on_player_turn_begin(_data: Dictionary) -> void:
	print("[Battle] === Turn %d begin ===" % turn_manager.turn_number)
	aim_line.set_origin(floating_island.get_cannon_position())
	aim_line.activate()

	# 更新 HUD
	_update_hud()

	# 默认选中第一张卡牌
	if battle_hud:
		battle_hud.auto_select_first_card()
	
	# 检查事件触发
	if _game_mode and turn_manager.turn_number > 0 and turn_manager.turn_number % GameConfig.EVENT_INTERVAL == 0:
		aim_line.deactivate()
		event_manager.trigger_random_event()
		print("[Battle] Event triggered on turn %d" % turn_manager.turn_number)
		
		# 显示事件弹窗
		var event_view: EventView = EventView.new()
		event_view.setup_for_battle(
			event_manager,
			run_state,
			func():
				# 事件关闭后恢复战斗
				aim_line.set_origin(floating_island.get_cannon_position())
				aim_line.activate()
				_update_hud()
		)
		add_child(event_view)
		return  # 等待事件弹窗关闭后再继续

func _on_turn_ended(_data: Dictionary) -> void:
	"""回合结束 → 自动平移 + 胜负检测"""
	aim_line.deactivate()
	
	await auto_scroller.pan_step()
	
	if battle_over:
		return
	
	turn_manager.resume_next_turn()

func _on_aim_fire(angle_deg: float, power: float) -> void:
	if battle_over:
		return

	# 未选卡牌时，激活瞄准线让玩家自由瞄准（无卡牌效果加成）
	if not _card_selected:
		aim_line.activate()
		return

	_card_selected = false
	aim_line.deactivate()
	_on_fire(angle_deg, power)

func _on_card_used(data: Dictionary) -> void:
	var card: CardData = data.get("card")
	if card:
		_pending_card_effect = card.effect_data.duplicate()
		print("[Battle] Card effect queued: %s" % card.effect_data)

func _on_end_turn_requested(_data: Dictionary) -> void:
	if battle_over:
		return
	if _active_projectiles > 0:
		print("[Battle] Cannot end turn — %d projectiles still in flight" % _active_projectiles)
		return
	aim_line.deactivate()
	_pending_card_effect.clear()
	_card_selected = false
	turn_manager.end_player_turn()

func _on_fire(angle_deg: float, power: float) -> void:
	# Snapshot card effect and launcher params — each fire is independent
	var effect: Dictionary = _pending_card_effect.duplicate()
	var fire_damage: int = projectile_launcher.base_damage
	var fire_radius: float = projectile_launcher.explosion_radius

	# Apply relic bonuses to this fire's snapshot
	if _game_mode and relic_manager != null:
		fire_damage = int(fire_damage * relic_manager.get_damage_multiplier())
		fire_radius *= relic_manager.get_radius_multiplier()

	# Reset launcher to base (ready for next card selection, no cross-fire pollution)
	projectile_launcher.base_damage = GameConfig.BASE_DAMAGE
	projectile_launcher.explosion_radius = GameConfig.EXPLOSION_RADIUS

	# Consume energy
	energy_system.spend(1)

	# Clear selection and immediately re-select if energy remains (supports rapid fire)
	if battle_hud:
		battle_hud.clear_selection()
		if energy_system.current_energy > 0:
			battle_hud.auto_select_first_card()
			aim_line.set_origin(floating_island.get_cannon_position())
			aim_line.activate()

	var origin := floating_island.get_cannon_position()

	# Fire projectile with snapshotted params — track active count for turn-end gating
	if effect.has("scatter_count"):
		var count: int = effect["scatter_count"]
		var spread: float = effect.get("spread_angle", 30.0)
		var projs := projectile_launcher.fire_scatter(origin, angle_deg, power, count, spread, fire_damage, fire_radius)
		_active_projectiles += projs.size()
	else:
		var proj: Projectile = projectile_launcher.fire_projectile(origin, angle_deg, power, fire_damage, fire_radius)
		_active_projectiles += 1
		if effect.has("status"):
			proj.pending_status = effect

	# Wait for flight (does NOT block subsequent fires — player can fire again immediately)
	await get_tree().create_timer(2.5).timeout

	if battle_over:
		return

	# Energy depleted + all projectiles landed → auto-end turn
	if (energy_system.current_energy <= 0 or card_manager.hand.is_empty()) and _active_projectiles == 0:
		print("[Battle] Turn auto-ending (energy=%d, projectiles=%d)" % [energy_system.current_energy, _active_projectiles])
		turn_manager.end_player_turn()
		return

	# Check affordable cards
	var can_play := false
	for card in card_manager.hand:
		if energy_system.can_afford(card.cost):
			can_play = true
			break

	if can_play:
		aim_line.set_origin(floating_island.get_cannon_position())
		aim_line.activate()
		if battle_hud:
			battle_hud.auto_select_first_card()
	elif _active_projectiles == 0:
		# No energy and no projectiles → safe to end turn
		print("[Battle] No affordable cards, auto-ending turn")
		turn_manager.end_player_turn()
	# else: projectiles still flying — wait for them to land

	_update_hud()

func _on_vfx_explosion(data: Dictionary) -> void:
	var pos: Vector2 = data.get("pos", Vector2.ZERO)
	var radius: float = data.get("radius", 100.0)
	var damage: int = data.get("damage", 0)
	_spawn_explosion_effect(pos, radius)
	_damage_terrain(pos, radius, damage)

	# Track active projectiles — when all landed and energy=0, auto-end turn
	_active_projectiles = max(0, _active_projectiles - 1)
	if _active_projectiles == 0 and energy_system.current_energy <= 0 and not battle_over:
		if turn_manager.current_phase == TurnManager.Phase.PLAYER_ACTION:
			print("[Battle] All projectiles landed, auto-ending turn")
			turn_manager.end_player_turn()

# ---- VFX ----

func _spawn_explosion_effect(pos: Vector2, radius: float) -> void:
	var fx: ExplosionEffect = ExplosionEffect.new()
	fx.setup(pos, radius)
	add_child(fx)

## 对爆炸范围内的地形块造成伤害
func _damage_terrain(explosion_pos: Vector2, radius: float, damage: int) -> void:
	for child in get_children():
		if child is TerrainBlock and is_instance_valid(child):
			var dist := explosion_pos.distance_to(child.position)
			if dist <= radius:
				var actual: int = floori(damage * (1.0 - (dist / radius) * 0.3))
				var destroyed: bool = child.take_damage(actual)
				if destroyed:
					print("[Battle] Terrain destroyed at %s" % str(child.position))

# ---- Win/Lose ----

func _on_collision_lose() -> void:
	if battle_over:
		return
	battle_over = true
	turn_manager.end_battle("defeat")
	_sync_to_runstate()
	if _game_mode and battle_result_callback.is_valid():
		battle_result_callback.call("defeat")
	print("[Battle] DEFEAT — Floating island crashed into defenses!")

func _on_cleared_win() -> void:
	if battle_over:
		return
	battle_over = true
	turn_manager.end_battle("victory")
	_sync_to_runstate()
	if _game_mode and battle_result_callback.is_valid():
		battle_result_callback.call("victory")
	print("[Battle] VICTORY — All defenses cleared!")

func _sync_to_runstate() -> void:
	if _game_mode and run_state != null:
		run_state.deck.clear()
		run_state.deck.append_array(card_manager.deck)
		run_state.deck.append_array(card_manager.hand)
		run_state.deck.append_array(card_manager.discard)
		print("[Battle] Synced deck (%d cards) to RunState" % run_state.deck.size())

func _update_hud() -> void:
	if battle_hud:
		battle_hud.update_display(energy_system, card_manager, turn_manager, defense_manager, floating_island)

# ---- Self-Test ----

func _self_test() -> void:
	TestHelper.check(is_inside_tree(), "BattleManager in tree")
	
	TestHelper.check(turn_manager != null, "BattleManager has TurnManager")
	TestHelper.check(aim_line != null, "BattleManager has AimLine")
	TestHelper.check(projectile_launcher != null, "BattleManager has ProjectileLauncher")
	TestHelper.check(energy_system != null, "BattleManager has EnergySystem")
	TestHelper.check(card_manager != null, "BattleManager has CardManager")
	TestHelper.check(relic_manager != null, "BattleManager has RelicManager")
	TestHelper.check(run_state != null, "BattleManager has RunState")
	TestHelper.check(event_manager != null, "BattleManager has EventManager")
	TestHelper.check(defense_manager != null, "BattleManager has DefenseManager")
	TestHelper.check(auto_scroller != null, "BattleManager has AutoScroller")
	TestHelper.check(battle_hud != null, "BattleManager has BattleHUD")
	TestHelper.check(floating_island != null, "BattleManager has FloatingIsland")
	
	# 验证浮岛位置
	TestHelper.assert_range(floating_island.position.x, -800, -700, "Floating island X position")
	TestHelper.assert_range(floating_island.position.y, 200, 300, "Floating island Y position")
	
	# 验证防御墙已生成
	var block_count := 0
	for c in get_children():
		if c is TerrainBlock:
			block_count += 1
	TestHelper.check(block_count > 0, "Defense wall has blocks (count=%d)" % block_count)
	
	TestHelper.assert_eq(turn_manager.current_phase, TurnManager.Phase.BATTLE_START, "TurnManager at BATTLE_START")
	
	# 自动射击测试
	await get_tree().create_timer(1.0).timeout
	_auto_test_fire()

func _auto_test_fire() -> void:
	# 简化测试：直接在防御块上方创建炮弹，验证碰撞和地形伤害
	print("[TEST] Auto-fire: direct collision test...")

	# 找到第一个防御块位置，将炮弹直接放在其上方
	var target_block: TerrainBlock = null
	for c in get_children():
		if c is TerrainBlock and is_instance_valid(c):
			target_block = c
			break
	
	if target_block == null:
		print("[TEST] No defense blocks found for auto-fire test")
		TestHelper.check(false, "Auto-fire: defense blocks exist")
		TestHelper.summary()
		return
	
	# 将炮弹放在防御块正上方，使其直接落下碰撞
	var proj: Projectile = Projectile.new()
	proj.global_position = target_block.position + Vector2(0, -60)
	add_child(proj)
	TestHelper.track_lifecycle(proj, "AutoTestProjectile")
	TestHelper.check(proj.is_inside_tree(), "Auto-test projectile in tree")
	
	# 给予很轻微的下落速度
	proj.launch(Vector2(0, 50))
	
	EventBus.on("projectile:explode", _on_auto_test_explosion)

func _on_auto_test_explosion(_data: Dictionary) -> void:
	EventBus.off("projectile:explode", _on_auto_test_explosion)
	await get_tree().create_timer(0.5).timeout
	
	var vfx_count := 0
	for c in get_children():
		if c is ExplosionEffect:
			vfx_count += 1
			TestHelper.check(c.is_inside_tree(), "ExplosionEffect in tree after auto-fire")
			TestHelper.check(c._draw_count > 0, "ExplosionEffect _draw() called (count=%d)" % c._draw_count)
		if c is DamageNumber:
			vfx_count += 1
			TestHelper.check(c.is_inside_tree(), "DamageNumber in tree after auto-fire")
			TestHelper.check(c._draw_count > 0, "DamageNumber _draw() called (count=%d)" % c._draw_count)
	TestHelper.check(vfx_count > 0, "VFX nodes created after auto-fire (count=%d)" % vfx_count)
	
	# 检查是否有防御块受损
	var any_damaged := false
	for c in get_children():
		if c is TerrainBlock and is_instance_valid(c):
			if c.hp < c.max_hp:
				any_damaged = true
				print("[TEST] Terrain block at %s took damage: hp=%d/%d" % [c.position, c.hp, c.max_hp])
				break
	TestHelper.check(any_damaged, "At least one terrain block damaged by auto-fire")
	
	TestHelper.lifecycle_report()
	TestHelper.summary()
