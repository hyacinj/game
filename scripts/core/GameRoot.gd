extends Node2D
class_name GameRoot

func _ready() -> void:
	print("[GameRoot] Init...")
	_ensure_camera()
	# Defer scene load to after _ready completes
	call_deferred("_start_game")

func _ensure_camera() -> void:
	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()
	print("[GameRoot] Camera ready.")

func _start_game() -> void:
	print("[GameRoot] Loading battle...")
	SceneManager.load_scene("res://scenes/battle.tscn")
	EventBus.emit("game:ready")
