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
	print("[Battle] Init...")
	_generate_terrain()
	_spawn_player()
	_spawn_enemies(3)
	_start_player_turn()

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
	var rad := deg_to_rad(aim_angle)
	proj.launch(Vector2(cos(rad) * aim_power, sin(rad) * aim_power))
	print("[Battle] Fired!")
	await get_tree().create_timer(2.0).timeout
	if not battle_over: _start_player_turn()

func _start_player_turn() -> void:
	turn += 1; is_player_turn = true; is_aiming = true
	print("[Battle] Turn ", turn, " — click to fire!")

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
	print("  Terrain: ", cols * rows, " blocks")

func _spawn_player() -> void:
	player = Player.new()
	var y := GameConfig.TERRAIN_Y_OFFSET + GameConfig.TERRAIN_ROWS * GameConfig.BLOCK_SIZE + 35
	player.position = Vector2(GameConfig.PLAYER_X, y)
	add_child(player)
	print("  Player at: ", player.position)

func _spawn_enemies(count: int) -> void:
	for i in count:
		var e := Enemy.new()
		var y := GameConfig.TERRAIN_Y_OFFSET + GameConfig.TERRAIN_ROWS * GameConfig.BLOCK_SIZE + 28
		e.position = Vector2(400 + i * 150, y)
		add_child(e); enemies.append(e)
	print("  Enemies: ", count)
