# AimLine — 瞄准抛物线预览
# 鼠标拖拽时显示虚线轨迹，松开时发射
class_name AimLine
extends Node2D

## 抛物线模拟参数
const SIM_STEPS: int = 60          # 预览点数
const SIM_DT: float = 0.05         # 模拟步长（秒）
const GRAVITY: float = 600.0       # 重力加速度
const POWER_MULTIPLIER: float = 3.0 # 拖拽距离 → 力度系数
const MIN_POWER: float = 200.0
const MAX_POWER: float = 800.0
const DOT_COLOR := Color(1.0, 1.0, 1.0, 0.6)  # 白色半透明
const DOT_RADIUS: float = 3.0

## 状态
var is_aiming: bool = false
var is_active: bool = false          # 是否可以瞄准
var aim_origin: Vector2 = Vector2.ZERO  # 玩家位置
var aim_angle: float = 45.0
var aim_power: float = 500.0
var wind_system: WindSystem = null

## 发射回调
var _on_fire_callback: Callable = Callable()

func _ready() -> void:
	_self_test()

func _process(_delta: float) -> void:
	if is_aiming and is_active:
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_aim()
			else:
				if is_aiming:
					_end_aim()
	if event is InputEventMouseMotion and is_aiming:
		_update_aim(get_global_mouse_position())

func activate() -> void:
	is_active = true

func deactivate() -> void:
	is_active = false
	is_aiming = false
	queue_redraw()

func set_origin(pos: Vector2) -> void:
	aim_origin = pos

func set_wind_system(ws: WindSystem) -> void:
	wind_system = ws

func set_fire_callback(cb: Callable) -> void:
	_on_fire_callback = cb

func get_aim_angle() -> float:
	return aim_angle

func get_aim_power() -> float:
	return aim_power

func _start_aim() -> void:
	is_aiming = true

func _end_aim() -> void:
	is_aiming = false
	queue_redraw()
	# 计算发射方向和力度
	var mouse_pos := get_global_mouse_position()
	var dir := mouse_pos - aim_origin
	aim_angle = rad_to_deg(dir.angle())
	aim_power = clamp(dir.length() * POWER_MULTIPLIER, MIN_POWER, MAX_POWER)
	if _on_fire_callback.is_valid():
		_on_fire_callback.call(aim_angle, aim_power)

func _update_aim(mouse_pos: Vector2) -> void:
	var dir := mouse_pos - aim_origin
	aim_angle = rad_to_deg(dir.angle())
	aim_power = clamp(dir.length() * POWER_MULTIPLIER, MIN_POWER, MAX_POWER)

func _draw() -> void:
	if not is_aiming or not is_active:
		return
	# 计算发射速度
	var rad := deg_to_rad(aim_angle)
	var vel := Vector2(cos(rad) * aim_power, sin(rad) * aim_power)
	var pos := aim_origin
	var points: Array[Vector2] = [pos]
	
	for _i in range(SIM_STEPS):
		vel.y += GRAVITY * SIM_DT
		# 叠加风力
		if wind_system:
			vel += wind_system.get_wind_force() * SIM_DT
		pos += vel * SIM_DT
		points.append(pos)
		
		# 碰地或飞出屏幕则停
		if pos.y > 600 or abs(pos.x) > 1200:
			break
	
	# 绘制虚线轨迹
	for i in range(points.size() - 1):
		if i % 2 == 0:  # 虚线效果：隔点画
			draw_line(points[i], points[i + 1], DOT_COLOR, 1.5)
	
	# 绘制落点标记
	if points.size() > 1:
		var last: Vector2 = points[points.size() - 1]
		draw_circle(last, DOT_RADIUS * 2, Color.RED)

func _self_test() -> void:
	TestHelper.check(SIM_STEPS > 0, "AimLine SIM_STEPS positive")
	TestHelper.assert_range(POWER_MULTIPLIER, 1.0, 10.0, "AimLine power multiplier reasonable")
	TestHelper.assert_range(SIM_DT, 0.01, 0.2, "AimLine dt reasonable")
	# Verify angle calculation
	aim_origin = Vector2(0, 0)
	_update_aim(Vector2(100, -50))
	TestHelper.assert_range(aim_angle, -90, 90, "AimLine angle in range")
	TestHelper.assert_range(aim_power, MIN_POWER, MAX_POWER, "AimLine power in range")
	print("[TEST] AimLine self-test complete")
