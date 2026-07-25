# IntentLabel — 敌人意图显示（头顶文字）
class_name IntentLabel
extends Node2D

var _text: String = ""
var _visible: bool = false
var _elapsed: float = 0.0

func show_text(text: String) -> void:
	_text = text
	_visible = true
	_elapsed = 0.0

func hide_text() -> void:
	_visible = false
	queue_redraw()

func _process(delta: float) -> void:
	if _visible:
		_elapsed += delta
		queue_redraw()

func _draw() -> void:
	if not _visible:
		return
	var alpha: float = 1.0
	var bounce: float = sin(_elapsed * 4.0) * 5.0
	draw_string(ThemeDB.fallback_font, Vector2(-20, -50 + bounce), _text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1.0, 0.3, 0.3, alpha))
