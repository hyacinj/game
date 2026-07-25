extends Node2D
class_name GameRoot

func _ready() -> void:
	print("[GameRoot] Init...")
	_ensure_camera()
	_self_test()
	call_deferred("_start_game")

func _ensure_camera() -> void:
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(cam)
	cam.make_current()
	RenderingServer.set_default_clear_color(Color(0.06, 0.1, 0.18))

func _self_test() -> void:
	TestHelper.check(has_node("MainCamera") or get_child_count() > 0, "GameRoot has children")
	TestHelper.check(is_inside_tree(), "GameRoot in scene tree")

func _start_game() -> void:
	var battle_scene := load("res://scenes/battle.tscn") as PackedScene
	TestHelper.check(battle_scene != null, "battle.tscn loaded")
	if battle_scene:
		var battle := battle_scene.instantiate()
		add_child(battle)
		TestHelper.check(battle.has_method("_self_test"), "BattleManager has _self_test")
	EventBus.emit("game:ready")
