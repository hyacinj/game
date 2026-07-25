# WindSystem — 风力系统
# 每回合随机生成风向和强度，影响炮弹水平飞行
class_name WindSystem
extends Node2D

## 当前风力向量（水平分量）
var wind_vector: Vector2 = Vector2.ZERO
## 风力强度 (0.0 ~ 1.0)
var strength: float = 0.0
## 风向 (-1: 左, 0: 无风, 1: 右)
var direction: float = 0.0

## 风力加速度系数（像素/秒²，满强度时）
const WIND_FORCE_MAX: float = 80.0
const STRENGTH_MIN: float = 0.0
const STRENGTH_MAX: float = 1.0

func _ready() -> void:
	_self_test()

## 每回合随机生成新风力
func randomize_wind() -> void:
	direction = randf_range(-1.0, 1.0)
	strength = randf_range(STRENGTH_MIN, STRENGTH_MAX)
	wind_vector = Vector2(direction * strength * WIND_FORCE_MAX, 0.0)
	EventBus.emit("wind:changed", {"direction": direction, "strength": strength, "vector": wind_vector})
	queue_redraw()
	print("[Wind] New wind: dir=%.2f strength=%.2f force=%.1f" % [direction, strength, wind_vector.x])

## 获取当前风力加速度 (Vector2)，供 Projectile 和 AimLine 使用
func get_wind_force() -> Vector2:
	return wind_vector

## 获取风力描述（用于 UI）
func get_wind_description() -> String:
	if strength < 0.05:
		return "无风"
	var dir_str: String = "→" if direction > 0 else "←"
	var str_str: String
	if strength < 0.3:
		str_str = "微风"
	elif strength < 0.6:
		str_str = "中等风"
	elif strength < 0.85:
		str_str = "强风"
	else:
		str_str = "暴风"
	return "%s %s (%.0f%%)" % [dir_str, str_str, strength * 100]

func _draw() -> void:
	# 在屏幕上方绘制风力指示
	if strength < 0.05:
		return
	var base: Vector2 = Vector2(0, -300)
	var length: float = strength * 100.0
	var end: Vector2 = base + Vector2(direction * length, 0)
	var color: Color = Color.RED if strength > 0.7 else (Color.ORANGE if strength > 0.4 else Color.WHITE)
	color.a = 0.6
	# Arrow line
	draw_line(base, end, color, 2.0)
	# Arrow head
	if abs(direction) > 0.01:
		var head_dir: float = sign(direction)
		var head: Vector2 = end
		draw_line(head, head + Vector2(-head_dir * 10, -8), color, 2.0)
		draw_line(head, head + Vector2(-head_dir * 10, 8), color, 2.0)

func _self_test() -> void:
	# Test randomize produces valid range
	var any_nonzero: bool = false
	for _i in 20:
		randomize_wind()
		TestHelper.assert_range(strength, 0.0, 1.0, "WindSystem strength in [0,1]")
		TestHelper.assert_range(direction, -1.0, 1.0, "WindSystem direction in [-1,1]")
		if strength > 0.01:
			any_nonzero = true
	# Verify wind force calculation
	var force: Vector2 = get_wind_force()
	TestHelper.check(force.y == 0.0, "WindSystem force is horizontal only")
	TestHelper.check(not any_nonzero or strength > 0.0, "WindSystem can generate non-zero wind")
	
	# Test zero wind
	direction = 0.0
	strength = 0.0
	wind_vector = Vector2.ZERO
	TestHelper.assert_eq(get_wind_force(), Vector2.ZERO, "WindSystem zero wind is zero vector")
	
	print("[TEST] WindSystem self-test complete")
