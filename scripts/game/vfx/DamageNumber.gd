# DamageNumber — 浮动伤害数字
class_name DamageNumber
extends Node2D

var _elapsed: float = 0.0
var _duration: float = 1.0
var _damage_text: String = ""
var _color: Color = Color.RED

func _ready() -> void:
	_self_test()

func setup(pos: Vector2, damage: int, color: Color = Color.RED) -> void:
	global_position = pos
	_damage_text = str(damage)
	_color = color

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	# Float upward
	position.y -= 40.0 * delta
	queue_redraw()

func _draw() -> void:
	var alpha: float = 1.0 - (_elapsed / _duration)
	var c: Color = _color
	c.a = alpha
	draw_string(ThemeDB.fallback_font, Vector2(-15, 0), _damage_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, c)

func _self_test() -> void:
	TestHelper.check(_duration > 0.0, "DamageNumber duration positive")
	print("[TEST] DamageNumber self-test complete")
