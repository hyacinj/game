# ExplosionEffect — 爆炸粒子效果 (_draw 动画)
class_name ExplosionEffect
extends Node2D

var _elapsed: float = 0.0
var _duration: float = 0.5
var _max_radius: float = 50.0
var _color: Color = Color(1.0, 0.5, 0.0)

func _ready() -> void:
	_self_test()

func setup(pos: Vector2, radius: float = 100.0, color: Color = Color(1.0, 0.5, 0.0)) -> void:
	global_position = pos
	_max_radius = radius
	_color = color
	_duration = 0.5

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress: float = _elapsed / _duration
	var current_radius: float = _max_radius * progress
	var alpha: float = 1.0 - progress
	var c: Color = _color
	c.a = alpha * 0.6
	draw_circle(Vector2.ZERO, current_radius, c)
	# Outer ring
	c.a = alpha * 0.3
	draw_circle(Vector2.ZERO, current_radius * 1.3, c)

func _self_test() -> void:
	TestHelper.check(_duration > 0.0, "ExplosionEffect duration positive")
	TestHelper.check(_max_radius > 0.0, "ExplosionEffect max_radius positive")
	print("[TEST] ExplosionEffect self-test complete")
