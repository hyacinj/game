extends Node2D
class_name BattleManager

# ---- Sub-systems ----
var turn_manager: TurnManager
var wind_system: WindSystem
var aim_line: AimLine
var projectile_launcher: ProjectileLauncher
var energy_system: EnergySystem
var card_manager: CardManager
var relic_manager: RelicManager
var run_state: RunState
var room_manager: RoomManager
var shop_manager: ShopManager
var event_manager: EventManager
var battle_hud: BattleHUD
## 待处理的卡牌效果
var _pending_card_effect: Dictionary = {}

# ---- Units ----
var player: Player
var enemies: Array[Enemy] = []
var battle_over: bool = false

## 可选：从 RoomData 传入的敌人配置（P2 房间系统使用）
var enemy_configs: Array[Dictionary] = []
## 可选：从外部传入的 RunState（游戏模式）
var run_state_override: RunState = null
## 可选：战斗结果回调
var battle_result_callback: Callable = Callable()
## 是否为游戏模式（非测试模式）
var _game_mode: bool = false

func _ready() -> void:
	# 游戏模式 vs 测试模式
	_game_mode = run_state_override != null
	
	_create_subsystems()
	_generate_terrain()
	_spawn_player()
	_spawn_enemies_from_config()
	_connect_events()
	_self_test()
	
	# 开始回合循环（测试和游戏模式都需要）
	turn_manager.start_battle()

func _create_subsystems() -> void:
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	wind_system = WindSystem.new()
	add_child(wind_system)
	
	aim_line = AimLine.new()
	aim_line.set_origin(Vector2(GameConfig.PLAYER_X, GameConfig.TERRAIN_Y_OFFSET - 40))
	aim_line.set_wind_system(wind_system)
	aim_line.set_fire_callback(_on_aim_fire)
	add_child(aim_line)
	
	projectile_launcher = ProjectileLauncher.new()
	projectile_launcher.setup(self, wind_system)
	add_child(projectile_launcher)
	
	energy_system = EnergySystem.new()
	add_child(energy_system)
	
	card_manager = CardManager.new()
	# 使用持久牌组（如果有）
	if _game_mode and run_state != null and run_state.deck.size() > 0:
		card_manager.initialize(run_state.deck)
		print("[Battle] Using persistent deck: %d cards" % run_state.deck.size())
	else:
		card_manager.initialize(CardDB.get_starting_deck())
	add_child(card_manager)
	
	relic_manager = RelicManager.new()
	add_child(relic_manager)
	
	# RunState (persistent across rooms)
	if run_state_override != null:
		run_state = run_state_override
	else:
		run_state = RunState.new()
	add_child(run_state)
	
	# RoomManager
	room_manager = RoomManager.new()
	room_manager.setup(run_state)
	add_child(room_manager)
	
	# ShopManager
	shop_manager = ShopManager.new()
	shop_manager.setup(run_state)
	add_child(shop_manager)
	
	# EventManager
	event_manager = EventManager.new()
	event_manager.setup(run_state)
	add_child(event_manager)
	
	# BattleHUD
	battle_hud = BattleHUD.new()
	battle_hud.setup(energy_system, card_manager, turn_manager, wind_system, player, enemies)
	add_child(battle_hud)

func _connect_events() -> void:
	EventBus.on("turn:player_begin", _on_player_turn_begin)
	EventBus.on("turn:enemy_begin", _on_enemy_turn_begin)
	EventBus.on("turn:tick_statuses", _on_tick_statuses)
	EventBus.on("unit:died", _on_unit_died)
	EventBus.on("projectile:explode", _on_vfx_explosion)
	EventBus.on("card:used", _on_card_used)
	EventBus.on("turn:end_requested", _on_end_turn_requested)

# ---- Turn Handlers ----
func _on_player_turn_begin(_data: Dictionary) -> void:
	wind_system.randomize_wind()
	aim_line.set_origin(player.global_position)
	aim_line.activate()

func _on_enemy_turn_begin(_data: Dictionary) -> void:
	aim_line.deactivate()
	# P2: Process all enemy AIs sequentially
	_process_enemy_turns()

func _process_enemy_turns() -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue
		if enemy.ai != null:
			await enemy.ai.take_turn()
		await get_tree().create_timer(0.3).timeout  # 间隔
	
	# All enemy actions complete
	EventBus.emit("turn:enemy_actions_complete", {})

func _on_aim_fire(angle_deg: float, power: float) -> void:
	aim_line.deactivate()
	_on_fire(angle_deg, power)

func _on_card_used(data: Dictionary) -> void:
	var card: CardData = data.get("card")
	if card:
		_pending_card_effect = card.effect_data.duplicate()
		print("[Battle] Card effect queued for next shot: %s" % card.effect_data)

func _on_end_turn_requested(_data: Dictionary) -> void:
	if battle_over:
		return
	aim_line.deactivate()
	_pending_card_effect.clear()
	turn_manager.end_player_turn()

func _on_fire(angle_deg: float, power: float) -> void:
	var effect: Dictionary = _pending_card_effect
	_pending_card_effect.clear()
	
	# 散射弹
	if effect.has("scatter_count"):
		var count: int = effect["scatter_count"]
		var spread: float = effect.get("spread_angle", 30.0)
		projectile_launcher.fire_scatter(player.global_position, angle_deg, power, count, spread)
	else:
		var proj: Projectile = projectile_launcher.fire_projectile(player.global_position, angle_deg, power)
		# 附加状态效果
		if effect.has("status"):
			proj.pending_status = effect
	
	# 重置
	projectile_launcher.base_damage = GameConfig.BASE_DAMAGE
	projectile_launcher.explosion_radius = GameConfig.EXPLOSION_RADIUS
	
	await get_tree().create_timer(2.5).timeout
	if not battle_over:
		turn_manager.end_player_turn()

func _on_tick_statuses(_data: Dictionary) -> void:
	player.tick_statuses()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.tick_statuses()

func _on_unit_died(unit: Unit) -> void:
	print("[Battle] Unit died: ", unit.name)
	# Spawn damage number
	_spawn_damage_number(unit.global_position, unit.max_hp)
	_check_battle_end()

func _on_vfx_explosion(data: Dictionary) -> void:
	var pos: Vector2 = data.get("pos", Vector2.ZERO)
	var radius: float = data.get("radius", 100.0)
	_spawn_explosion_effect(pos, radius)

# ---- VFX ----
func _spawn_explosion_effect(pos: Vector2, radius: float) -> void:
	var fx: ExplosionEffect = ExplosionEffect.new()
	fx.setup(pos, radius)
	add_child(fx)

func _spawn_damage_number(pos: Vector2, damage: int) -> void:
	var dn: DamageNumber = DamageNumber.new()
	dn.setup(pos + Vector2(0, -30), damage)
	add_child(dn)

func _check_battle_end() -> void:
	if battle_over:
		return
	if player.is_dead:
		battle_over = true
		turn_manager.end_battle("defeat")
		_sync_hp_to_runstate()
		if _game_mode and battle_result_callback.is_valid():
			battle_result_callback.call("defeat")
		return
	var all_dead: bool = true
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			all_dead = false
			break
	if all_dead:
		battle_over = true
		turn_manager.end_battle("victory")
		room_manager.complete_room()
		_sync_hp_to_runstate()
		if _game_mode and battle_result_callback.is_valid():
			battle_result_callback.call("victory")

func _sync_hp_to_runstate() -> void:
	if _game_mode and run_state != null and is_instance_valid(player):
		run_state.player_current_hp = player.current_hp
		# 同步牌组：战后剩余牌库 + 手牌 + 弃牌堆 = 当前牌组
		run_state.deck.clear()
		run_state.deck.append_array(card_manager.deck)
		run_state.deck.append_array(card_manager.hand)
		run_state.deck.append_array(card_manager.discard)
		print("[Battle] Synced HP=%d/%d Deck=%d cards to RunState" % [run_state.player_current_hp, run_state.player_max_hp, run_state.deck.size()])

# ---- Terrain ----
func _generate_terrain() -> void:
	var bs: int = GameConfig.BLOCK_SIZE
	var cols: int = GameConfig.TERRAIN_COLS
	var rows: int = GameConfig.TERRAIN_ROWS
	var sx: float = -(cols * bs) / 2.0 + bs / 2.0
	var sy: float = GameConfig.TERRAIN_Y_OFFSET
	for row in rows:
		for col in cols:
			var b: TerrainBlock = TerrainBlock.new()
			b.position = Vector2(sx + col * bs, sy + row * bs)
			add_child(b)

# ---- Units ----
func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector2(GameConfig.PLAYER_X, GameConfig.TERRAIN_Y_OFFSET - 40)
	# 使用 RunState 的持久 HP
	if _game_mode and run_state != null:
		player.max_hp = run_state.player_max_hp
		player.current_hp = run_state.player_current_hp
		player.unit_color = Color.GREEN
		print("[Battle] Player spawned with HP %d/%d" % [player.current_hp, player.max_hp])
	add_child(player)

func _spawn_enemies_from_config() -> void:
	# If enemy_configs is provided (P2 room system), use it
	if enemy_configs.size() > 0:
		for i: int in enemy_configs.size():
			var cfg: Dictionary = enemy_configs[i]
			_spawn_enemy_at(cfg, 400 + i * 150)
	else:
		# Default: 3 grunts with AI
		for i: int in 3:
			var cfg: Dictionary = EnemyDB.get_data("grunt")
			_spawn_enemy_at(cfg, 400 + i * 150)

func _spawn_enemy_at(cfg: Dictionary, x_pos: float) -> void:
	var e: Enemy = Enemy.new()
	e.setup_from_data(cfg)
	e.position = Vector2(x_pos, GameConfig.TERRAIN_Y_OFFSET - 33)
	add_child(e)
	e.attach_ai(player, projectile_launcher, wind_system, cfg)
	enemies.append(e)
	print("[Battle] Spawned enemy: %s at x=%.0f hp=%d" % [cfg.get("name", "?"), x_pos, e.max_hp])

# ---- Self-Test ----
func _self_test() -> void:
	TestHelper.check(turn_manager != null, "BattleManager has TurnManager")
	TestHelper.check(wind_system != null, "BattleManager has WindSystem")
	TestHelper.check(aim_line != null, "BattleManager has AimLine")
	TestHelper.check(projectile_launcher != null, "BattleManager has ProjectileLauncher")
	TestHelper.check(energy_system != null, "BattleManager has EnergySystem")
	TestHelper.check(card_manager != null, "BattleManager has CardManager")
	TestHelper.check(relic_manager != null, "BattleManager has RelicManager")
	TestHelper.check(run_state != null, "BattleManager has RunState")
	TestHelper.check(room_manager != null, "BattleManager has RoomManager")
	TestHelper.check(shop_manager != null, "BattleManager has ShopManager")
	TestHelper.check(event_manager != null, "BattleManager has EventManager")
	TestHelper.check(battle_hud != null, "BattleManager has BattleHUD")
	
	var count: int = 0
	for c in get_children():
		if c is TerrainBlock:
			count += 1
	TestHelper.assert_eq(count, GameConfig.TERRAIN_COLS * GameConfig.TERRAIN_ROWS, "Terrain block count")
	
	TestHelper.check(player != null, "Player exists")
	TestHelper.check(player.is_inside_tree(), "Player in tree")
	TestHelper.assert_range(player.position.x, -800, -700, "Player X position")
	TestHelper.assert_range(player.position.y, 150, 250, "Player Y position")
	
	TestHelper.assert_eq(enemies.size(), 3, "Enemy count")
	for i: int in enemies.size():
		TestHelper.check(enemies[i].is_inside_tree(), "Enemy %d in tree" % i)
		TestHelper.assert_range(enemies[i].position.x, 300, 900, "Enemy %d X" % i)
		TestHelper.check(enemies[i].ai != null, "Enemy %d has AI" % i)
	TestHelper.assert_eq(enemies[0].current_hp, GameConfig.ENEMY_HP, "Enemy0 full HP")
	
	TestHelper.assert_eq(turn_manager.current_phase, TurnManager.Phase.BATTLE_START, "TurnManager at BATTLE_START")
	
	await get_tree().create_timer(1.5).timeout
	_auto_test_fire()

func _auto_test_fire() -> void:
	if enemies.size() < 2 or not is_instance_valid(enemies[1]):
		TestHelper.check(false, "Auto-fire: enemy[1] not available")
		TestHelper.summary()
		return
	print("[TEST] Auto-fire: launching at enemy 1...")
	wind_system.wind_vector = Vector2.ZERO
	wind_system.strength = 0.0
	wind_system.direction = 0.0
	
	var target: Vector2 = enemies[1].global_position + Vector2(0, -400)
	var dir: Vector2 = target - player.global_position
	var angle: float = rad_to_deg(dir.angle())
	var power: float = clamp(dir.length() * 2.0, GameConfig.MIN_POWER, GameConfig.MAX_POWER)
	var rad: float = deg_to_rad(angle)
	var vel: Vector2 = Vector2(cos(rad) * power, sin(rad) * power)
	print("[TEST] Auto-fire: angle=%.1f power=%.1f vel=%s" % [angle, power, vel])
	
	var proj: Projectile = Projectile.new()
	proj.global_position = player.global_position
	proj.wind_system = wind_system
	add_child(proj)
	proj.launch(vel)
	
	EventBus.on("projectile:explode", _on_auto_test_explosion)

func _on_auto_test_explosion(_data: Dictionary) -> void:
	EventBus.off("projectile:explode", _on_auto_test_explosion)
	await get_tree().create_timer(0.5).timeout
	var any_damaged: bool = false
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.current_hp < GameConfig.ENEMY_HP:
			any_damaged = true
			print("[TEST] Enemy at x=%.0f took damage: hp=%d" % [enemy.position.x, enemy.current_hp])
			break
	TestHelper.check(any_damaged, "At least one enemy took damage from auto-fire")
	TestHelper.summary()
