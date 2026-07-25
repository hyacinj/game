extends Node2D
class_name BattleManager

var player: Player
var enemies: Array[Enemy] = []
var turn: int = 0
var battle_over: bool = false
var is_player_turn: bool = false
var is_aiming: bool = false
var aim_angle: float = 45.0
var aim_power: float = 500.0

func _ready() -> void:
	_generate_terrain()
	_spawn_player()
	_spawn_enemies(3)
	_self_test()
	_start_player_turn()
	# Auto-fire test after 1s
	await get_tree().create_timer(1.0).timeout
	_auto_test_fire()

func _self_test() -> void:
	# Terrain
	var count := 0
	for c in get_children():
		if c is TerrainBlock: count += 1
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

	# First enemy HP
	TestHelper.assert_eq(enemies[0].current_hp, GameConfig.ENEMY_HP, "Enemy0 full HP")

func _auto_test_fire() -> void:
	print("[TEST] Auto-fire: aiming far above enemy 1...")
	# Aim much higher to compensate for gravity
	var target := enemies[1].global_position + Vector2(0, -400)
	_on_click(target)
	# Wait for projectile to explode, then check
	EventBus.on("projectile:explode", _on_test_explosion)

func _on_test_explosion(_data: Dictionary) -> void:
	await get_tree().create_timer(0.5).timeout
	TestHelper.assert_lt(enemies[1].current_hp, GameConfig.ENEMY_HP, "Enemy took damage from auto-fire")
	TestHelper.summary()

func _input(event: InputEvent) -> void:
	if not is_player_turn or not is_aiming: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(get_global_mouse_position())

func _on_click(pos: Vector2) -> void:
	var dir := pos - player.global_position
	aim_angle = rad_to_deg(dir.angle())
	aim_power = clamp(dir.length() * 2, GameConfig.MIN_POWER, GameConfig.MAX_POWER)
	_fire()

func _fire() -> void:
	is_aiming = false; is_player_turn = false
	var proj := Projectile.new()
	proj.global_position = player.global_position
	add_child(proj)
	print("[Battle] Projectile spawned at: ", proj.global_position)
	var rad := deg_to_rad(aim_angle)
	var vel := Vector2(cos(rad) * aim_power, sin(rad) * aim_power)
	print("[Battle] Launch vel: ", vel, " angle: ", aim_angle)
	proj.launch(vel)
	await get_tree().create_timer(2.0).timeout
	if not battle_over:
		_start_player_turn()

func _start_player_turn() -> void:
	turn += 1; is_player_turn = true; is_aiming = true

func _generate_terrain() -> void:
	var bs := GameConfig.BLOCK_SIZE
	var cols := GameConfig.TERRAIN_COLS
	var rows := GameConfig.TERRAIN_ROWS
	var sx := -(cols * bs) / 2.0 + bs / 2.0
	var sy := GameConfig.TERRAIN_Y_OFFSET
	for row in rows:
		for col in cols:
			var b := TerrainBlock.new()
			b.position = Vector2(sx + col * bs, sy + row * bs)
			add_child(b)

func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector2(GameConfig.PLAYER_X, GameConfig.TERRAIN_Y_OFFSET - 40)
	add_child(player)

func _spawn_enemies(count: int) -> void:
	for i in count:
		var e := Enemy.new()
		e.position = Vector2(400 + i * 150, GameConfig.TERRAIN_Y_OFFSET - 33)
		add_child(e); enemies.append(e)
