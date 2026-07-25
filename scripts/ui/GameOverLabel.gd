# GameOverLabel — 游戏结束画面
class_name GameOverLabel
extends Node2D

var _elapsed: float = 0.0

func _ready() -> void:
	print("[GameOver] Showing...")

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-150, -40), "游戏结束", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.RED)
	draw_string(ThemeDB.fallback_font, Vector2(-150, 20), "点击任意位置重新开始", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.5, 0.5, 0.5, 0.8))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_restart()
	if event is InputEventKey and event.pressed:
		_restart()

func _restart() -> void:
	get_tree().reload_current_scene()
