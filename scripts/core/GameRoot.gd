extends Node2D
class_name GameRoot

## 测试模式：跳过标题，直接进入战斗自检
var _test_mode: bool = false

func _ready() -> void:
	print("[GameRoot] Init...")
	# 检测 headless 测试模式
	_test_mode = DisplayServer.get_name() == "headless"
	_ensure_camera()
	_self_test()
	call_deferred("_show_title")

func _ensure_camera() -> void:
	var cam: Camera2D = Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	# 居中显示战场：地形从 x=-960 到 x=+960，y=250 是地面
	cam.position = Vector2(0, 0)
	cam.zoom = Vector2(0.85, 0.85)
	add_child(cam)
	cam.make_current()
	RenderingServer.set_default_clear_color(Color(0.06, 0.1, 0.18))

func _self_test() -> void:
	TestHelper.check(get_child_count() > 0, "GameRoot has children")
	TestHelper.check(is_inside_tree(), "GameRoot in scene tree")

## 显示标题画面
func _show_title() -> void:
	if _test_mode:
		# 测试模式：跳过标题，直接进入战斗
		_start_test_battle()
		return
	print("[GameRoot] Showing title screen...")
	var title_label: TitleScreen = TitleScreen.new()
	title_label.start_game_callback = _on_start_game
	add_child(title_label)
	EventBus.emit("game:ready")

## 测试模式：直接加载战斗（兼容旧测试流程）
func _start_test_battle() -> void:
	var battle_scene: PackedScene = load("res://scenes/battle.tscn") as PackedScene
	TestHelper.check(battle_scene != null, "battle.tscn loaded")
	if battle_scene:
		var battle: BattleManager = battle_scene.instantiate()
		add_child(battle)
		TestHelper.check(battle.has_method("_self_test"), "BattleManager has _self_test")
	EventBus.emit("game:ready")

## 开始游戏：生成地图，进入房间选择
func _on_start_game() -> void:
	print("[GameRoot] Starting new game...")
	# 初始化 RunState
	var rs: RunState = RunState.new()
	rs.current_floor = 1
	# 生成第一层地图
	var rooms: Array[RoomData] = MapGenerator.generate_floor(1)
	rs.room_nodes = rooms
	rs.current_room_index = 0
	
	# 进入地图选择画面
	_show_map_view(rs)

## 显示地图选择
func _show_map_view(rs: RunState) -> void:
	# 清理之前的子节点（除了 Camera 和 autoloads）
	_clear_game_children()
	
	var map_view: MapView = MapView.new()
	map_view.setup(rs)
	map_view.room_selected_callback = func(room: RoomData):
		_enter_room(rs, room)
	add_child(map_view)

## 进入房间（战斗/商店/事件等）
func _enter_room(rs: RunState, room: RoomData) -> void:
	_clear_game_children()
	
	match room.room_type:
		RoomData.RoomType.BATTLE, RoomData.RoomType.ELITE, RoomData.RoomType.BOSS:
			_start_battle(rs, room)
		RoomData.RoomType.SHOP:
			_enter_shop(rs, room)
		RoomData.RoomType.EVENT:
			_enter_event(rs, room)
		RoomData.RoomType.REST:
			_enter_rest(rs, room)
		_:
			_start_battle(rs, room)

## 进入战斗
func _start_battle(rs: RunState, room: RoomData) -> void:
	print("[GameRoot] Entering battle: %s" % room.get_type_name())
	var battle_scene: PackedScene = load("res://scenes/battle.tscn") as PackedScene
	if battle_scene:
		var battle: BattleManager = battle_scene.instantiate()
		# 注入房间配置
		battle.enemy_configs = room.enemy_configs
		battle.run_state_override = rs
		battle.battle_result_callback = func(result: String):
			_on_battle_result(rs, room, result)
		add_child(battle)

func _enter_shop(rs: RunState, room: RoomData) -> void:
	print("[GameRoot] Entering shop...")
	var sm: ShopManager = ShopManager.new()
	sm.setup(rs)
	var view: ShopView = ShopView.new()
	view.setup(sm, rs, func(): _continue_after_room(rs, room))
	add_child(view)

func _enter_event(rs: RunState, room: RoomData) -> void:
	print("[GameRoot] Entering event...")
	var em: EventManager = EventManager.new()
	em.setup(rs)
	var view: EventView = EventView.new()
	view.setup(em, rs, func(): _continue_after_room(rs, room))
	add_child(view)

func _enter_rest(rs: RunState, room: RoomData) -> void:
	print("[GameRoot] Resting...")
	var view: RestView = RestView.new()
	view.setup(rs, func(): _continue_after_room(rs, room))
	add_child(view)

## 战斗结果处理
func _on_battle_result(rs: RunState, room: RoomData, result: String) -> void:
	if result == "victory":
		print("[GameRoot] Victory in %s!" % room.get_type_name())
		rs.add_gold(room.reward_gold)
		_continue_after_room(rs, room)
	else:
		print("[GameRoot] Defeat... Game Over")
		_show_game_over()

## 房间完成后：显示地图，选择下一房间
func _continue_after_room(rs: RunState, room: RoomData) -> void:
	room.cleared = true
	rs.rooms_cleared += 1
	# Boss 战后进入下一层
	if room.room_type == RoomData.RoomType.BOSS:
		rs.current_floor += 1
		var new_rooms: Array[RoomData] = MapGenerator.generate_floor(rs.current_floor)
		rs.room_nodes = new_rooms
		rs.current_room_index = 0
	_show_map_view(rs)

func _show_game_over() -> void:
	_clear_game_children()
	var go_label: GameOverLabel = GameOverLabel.new()
	add_child(go_label)

func _clear_game_children() -> void:
	# 遍历子节点，删掉非相机节点
	for child in get_children():
		if not child is Camera2D:
			child.queue_free()
