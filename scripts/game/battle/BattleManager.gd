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

# ---- Units ----
var player: Player
var enemies: Array[Enemy] = []
var battle_over: bool = false

func _ready() -> void:
	_create_subsystems()
	_generate_terrain()
	_spawn_player()
	_spawn_enemies(3)
	_connect_events()
	_self_test()
	# Start battle
	turn_manager.start_battle()

func _create_subsystems() -> void:
	# TurnManager
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	# WindSystem
	wind_system = WindSystem.new()
	add_child(wind_system)
	
	# AimLine
	aim_line = AimLine.new()
	aim_line.set_origin(Vector2(GameConfig.PLAYER_X, GameConfig.TERRAIN_Y_OFFSET - 40))
	aim_line.set_wind_system(wind_system)
	aim_line.set_fire_callback(_on_aim_fire)
	add_child(aim_line)
	
	# ProjectileLauncher
	projectile_launcher = ProjectileLauncher.new()
	projectile_launcher.setup(self, wind_system)
	add_child(projectile_launcher)
	
	# EnergySystem
	energy_system = EnergySystem.new()
	add_child(energy_system)
	
	# CardManager
	card_manager = CardManager.new()
	card_manager.initialize(CardDB.get_starting_deck())
	add_child(card_manager)
	
	# RelicManager
	relic_manager = RelicManager.new()
	add_child(relic_manager)

func _connect_events() -> void:
	EventBus.on("turn:player_begin", _on_player_turn_begin)
	EventBus.on("turn:enemy_begin", _on_enemy_turn_begin)
	EventBus.on("turn:tick_statuses", _on_tick_statuses)
	EventBus.on("unit:died", _on_unit_died)

func _on_player_turn_begin(_data: Dictionary) -> void:
	# Randomize wind each turn
	wind_system.randomize_wind()
	# Activate aiming
	aim_line.set_origin(player.global_position)
	aim_line.activate()

func _on_enemy_turn_begin(_data: Dictionary) -> void:
	aim_line.deactivate()
	# P2: Enemy AI goes here

func _on_aim_fire(angle_deg: float, power: float) -> void:
	aim_line.deactivate()
	_on_fire(angle_deg, power)

func _on_fire(angle_deg: float, power: float) -> void:
	projectile_launcher.fire_projectile(player.global_position, angle_deg, power)
	# Wait for projectile to land, then end turn
	await get_tree().create_timer(2.5).timeout
	if not battle_over:
		turn_manager.end_player_turn()

func _on_tick_statuses(_data: Dictionary) -> void:
	# Tick status effects on all units
	player.tick_statuses()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.tick_statuses()

func _on_unit_died(unit: Unit) -> void:
	print("[Battle] Unit died: ", unit.name)
	_check_battle_end()

func _check_battle_end() -> void:
	if battle_over:
		return
	# Check player dead
	if player.is_dead:
		battle_over = true
		turn_manager.end_battle("defeat")
		return
	# Check all enemies dead
	var all_dead: bool = true
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			all_dead = false
			break
	if all_dead:
		battle_over = true
		turn_manager.end_battle("victory")

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
	add_child(player)

func _spawn_enemies(count: int) -> void:
	for i in count:
		var e: Enemy = Enemy.new()
		e.position = Vector2(400 + i * 150, GameConfig.TERRAIN_Y_OFFSET - 33)
		add_child(e)
		enemies.append(e)

# ---- Self-Test ----
func _self_test() -> void:
	# Sub-systems exist
	TestHelper.check(turn_manager != null, "BattleManager has TurnManager")
	TestHelper.check(wind_system != null, "BattleManager has WindSystem")
	TestHelper.check(aim_line != null, "BattleManager has AimLine")
	TestHelper.check(projectile_launcher != null, "BattleManager has ProjectileLauncher")
	TestHelper.check(energy_system != null, "BattleManager has EnergySystem")
	TestHelper.check(card_manager != null, "BattleManager has CardManager")
	TestHelper.check(relic_manager != null, "BattleManager has RelicManager")
	
	# Terrain
	var count: int = 0
	for c in get_children():
		if c is TerrainBlock:
			count += 1
	TestHelper.assert_eq(count, GameConfig.TERRAIN_COLS * GameConfig.TERRAIN_ROWS, "Terrain block count")
	
	# Player
	TestHelper.check(player != null, "Player exists")
	TestHelper.check(player.is_inside_tree(), "Player in tree")
	TestHelper.assert_range(player.position.x, -800, -700, "Player X position")
	TestHelper.assert_range(player.position.y, 150, 250, "Player Y position")
	
	# Enemies
	TestHelper.assert_eq(enemies.size(), 3, "Enemy count")
	for i in enemies.size():
		TestHelper.check(enemies[i].is_inside_tree(), "Enemy %d in tree" % i)
		TestHelper.assert_range(enemies[i].position.x, 300, 900, "Enemy %d X" % i)
	TestHelper.assert_eq(enemies[0].current_hp, GameConfig.ENEMY_HP, "Enemy0 full HP")
	
	# TurnManager initial state
	TestHelper.assert_eq(turn_manager.current_phase, TurnManager.Phase.BATTLE_START, "TurnManager at BATTLE_START")
	
	# Auto-fire test (deferred, after battle starts)
	await get_tree().create_timer(1.5).timeout
	_auto_test_fire()

func _auto_test_fire() -> void:
	if enemies.size() < 2 or not is_instance_valid(enemies[1]):
		TestHelper.check(false, "Auto-fire: enemy[1] not available")
		TestHelper.summary()
		return
	print("[TEST] Auto-fire: launching at enemy 1...")
	# Zero out wind for deterministic test fire
	wind_system.wind_vector = Vector2.ZERO
	wind_system.strength = 0.0
	wind_system.direction = 0.0
	
	# Use exact same logic as original working code
	var target: Vector2 = enemies[1].global_position + Vector2(0, -400)
	var dir: Vector2 = target - player.global_position
	var angle: float = rad_to_deg(dir.angle())
	var power: float = clamp(dir.length() * 2.0, GameConfig.MIN_POWER, GameConfig.MAX_POWER)
	var rad: float = deg_to_rad(angle)
	var vel: Vector2 = Vector2(cos(rad) * power, sin(rad) * power)
	print("[TEST] Auto-fire: angle=%.1f power=%.1f vel=%s" % [angle, power, vel])
	
	# Create projectile directly
	var proj: Projectile = Projectile.new()
	proj.global_position = player.global_position
	proj.wind_system = wind_system
	add_child(proj)
	proj.launch(vel)
	
	# Listen for explosion event (original approach)
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
	TestHelper.summary()
