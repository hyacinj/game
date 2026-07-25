# MapView — 肉鸽地图显示（_draw 绘制）
class_name MapView
extends Node2D

var run_state: RunState
var room_selected_callback: Callable = Callable()
var _hovered_room: int = -1

func _ready() -> void:
	print("[MapView] Showing floor %d map..." % run_state.current_floor)

func setup(rs: RunState) -> void:
	run_state = rs

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if run_state == null:
		return
	
	# 标题
	draw_string(ThemeDB.fallback_font, Vector2(-200, -350), "第 %d 层 — 选择房间" % run_state.current_floor, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(-200, -320), "金币: %d | HP: %d/%d" % [run_state.gold, run_state.player_current_hp, run_state.player_max_hp], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.YELLOW)
	
	var rooms: Array[RoomData] = run_state.room_nodes
	if rooms.size() == 0:
		return
	
	# 按层分组显示
	var layer_y_positions: Dictionary = _compute_layer_positions(rooms)
	
	for i: int in rooms.size():
		var room: RoomData = rooms[i]
		var layer: int = _get_room_layer(i, rooms)
		var y_pos: float = layer_y_positions.get(layer, 0.0)
		var layer_rooms: Array = _get_layer_rooms(layer, rooms)
		var layer_idx: int = layer_rooms.find(i)
		var layer_count: int = layer_rooms.size()
		var x_spacing: float = 160.0
		var start_x: float = -(layer_count - 1) * x_spacing / 2.0
		var x_pos: float = start_x + layer_idx * x_spacing
		
		_draw_room_node(Vector2(x_pos, y_pos), room, i)

func _compute_layer_positions(rooms: Array[RoomData]) -> Dictionary:
	var layers: Dictionary = {}
	var y_start: float = -250.0
	var y_step: float = 130.0
	# Find max layer
	var max_layer: int = 0
	for i: int in rooms.size():
		var layer: int = _get_room_layer(i, rooms)
		max_layer = max(max_layer, layer)
	for l: int in range(0, max_layer + 1):
		layers[l] = y_start + l * y_step
	return layers

func _get_room_layer(index: int, rooms: Array[RoomData]) -> int:
	if index == 0:
		return 0
	# Rough: each room after start is in a layer based on connection depth
	var layer: int = 1
	var current: int = 0
	while current < index:
		if rooms[current].connections.has(index):
			return layer
		current += 1
	return 1 + (index % 3)  # fallback

func _get_layer_rooms(layer: int, rooms: Array[RoomData]) -> Array:
	var result: Array = []
	for i: int in rooms.size():
		if _get_room_layer(i, rooms) == layer:
			result.append(i)
	return result

func _draw_room_node(pos: Vector2, room: RoomData, index: int) -> void:
	var size: Vector2 = Vector2(100, 60)
	var rect: Rect2 = Rect2(pos - size / 2.0, size)
	
	# 颜色
	var bg_color: Color
	match room.room_type:
		RoomData.RoomType.START: bg_color = Color(0.2, 0.6, 0.2)
		RoomData.RoomType.BATTLE: bg_color = Color(0.6, 0.3, 0.2)
		RoomData.RoomType.ELITE: bg_color = Color(0.7, 0.4, 0.1)
		RoomData.RoomType.SHOP: bg_color = Color(0.2, 0.4, 0.6)
		RoomData.RoomType.EVENT: bg_color = Color(0.5, 0.2, 0.5)
		RoomData.RoomType.BOSS: bg_color = Color(0.8, 0.1, 0.1)
		RoomData.RoomType.REST: bg_color = Color(0.2, 0.5, 0.4)
	
	if room.cleared:
		bg_color = bg_color.darkened(0.4)
	
	draw_rect(rect, bg_color, true)
	draw_rect(rect, Color.WHITE, false)
	
	var icon: String = _room_icon(room.room_type)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-40, -16), icon + " " + room.room_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-40, 4), room.get_type_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.8, 0.8))
	
	if room.cleared:
		draw_string(ThemeDB.fallback_font, pos + Vector2(20, -16), "✓", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.GREEN)

func _room_icon(type: int) -> String:
	match type:
		RoomData.RoomType.START: return "🏁"
		RoomData.RoomType.BATTLE: return "⚔️"
		RoomData.RoomType.ELITE: return "💀"
		RoomData.RoomType.SHOP: return "🛒"
		RoomData.RoomType.EVENT: return "❓"
		RoomData.RoomType.BOSS: return "👑"
		RoomData.RoomType.REST: return "🏕️"
		_: return "?"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = get_global_mouse_position()
		_check_click(pos)
	if event is InputEventKey and event.pressed:
		# 数字键选择房间
		var key: int = event.keycode
		if key >= KEY_1 and key <= KEY_9:
			var idx: int = key - KEY_1
			_select_room(idx)

func _check_click(mouse_pos: Vector2) -> void:
	var rooms: Array[RoomData] = run_state.room_nodes
	var layer_y_positions: Dictionary = _compute_layer_positions(rooms)
	for i: int in rooms.size():
		if rooms[i].cleared:
			continue
		var layer: int = _get_room_layer(i, rooms)
		var y_pos: float = layer_y_positions.get(layer, 0.0)
		var layer_rooms: Array = _get_layer_rooms(layer, rooms)
		var layer_idx: int = layer_rooms.find(i)
		var layer_count: int = max(layer_rooms.size(), 1)
		var x_spacing: float = 160.0
		var start_x: float = -(layer_count - 1) * x_spacing / 2.0
		var x_pos: float = start_x + layer_idx * x_spacing
		var size: Vector2 = Vector2(100, 60)
		var rect: Rect2 = Rect2(Vector2(x_pos, y_pos) - size / 2.0, size)
		if rect.has_point(mouse_pos):
			_select_room(i)
			return

func _select_room(index: int) -> void:
	if index < 0 or index >= run_state.room_nodes.size():
		return
	var room: RoomData = run_state.room_nodes[index]
	if room.cleared:
		return
	run_state.current_room_index = index
	print("[MapView] Selected room %d: %s" % [index, room.room_name])
	if room_selected_callback.is_valid():
		room_selected_callback.call(room)
	queue_free()
