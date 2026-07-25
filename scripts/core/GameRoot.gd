extends Node2D
class_name GameRoot

func _ready() -> void:
	print("[GameRoot] Init...")
	_ensure_camera()
	call_deferred("_start_game")

func _ensure_camera() -> void:
	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()
	# Set background dark blue
	RenderingServer.set_default_clear_color(Color(0.06, 0.1, 0.18))
	print("[GameRoot] Camera ready.")

func _start_game() -> void:
	print("[GameRoot] Loading battle...")
	var battle_scene := load("res://scenes/battle.tscn") as PackedScene
	if battle_scene:
		var battle := battle_scene.instantiate()
		add_child(battle)
		print("[GameRoot] Battle scene loaded as child.")
	EventBus.emit("game:ready")
