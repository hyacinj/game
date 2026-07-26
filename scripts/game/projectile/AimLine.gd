# AimLine — 瞄准抛物线预览
# 鼠标拖拽时显示虚线轨迹，松开时发射
class_name AimLine
extends Node2D

## 抛物线模拟参数
const SIM_STEPS: int = 120         # 更多预览点（匹配物理帧率）
const SIM_DT: float = 0.016667     # 匹配 60fps 物理步长
const POWER_MULTIPLIER: float = 3.0
const MIN_POWER: float = 200.0
const MAX_POWER: float = 1200.0
const DAMP: float = 0.1            # 匹配 Projectile.linear_damp
const DOT_COLOR := Color(1.0, 1.0, 0.3, 0.8)  # 亮黄色半透明

## 状态
var is_aiming: bool = false
var is_active: bool = false          # 是否可以瞄准
var aim_origin: Vector2 = Vector2.ZERO  # 玩家位置（世界坐标）
var aim_angle: float = 45.0
var aim_power: float = 500.0

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

## 模拟 RigidBody2D 物理轨迹，使预览与实际弹道一致
func _simulate_trajectory(start_vel: Vector2, origin: Vector2) -> Array[Vector2]:
	# 模拟 RigidBody2D 物理轨迹（重力 + 线性阻尼）
	# 等效重力 = 默认重力(980) × gravity_scale(GameConfig.GRAVITY/980) = GameConfig.GRAVITY
	var vel := start_vel
	var pos := origin
	var points: Array[Vector2] = [to_local(pos)]
	var effective_gravity: float = GameConfig.GRAVITY

	for _i in range(SIM_STEPS):
		# 1. 重力（使用与 Projectile 一致的等效重力）
		vel.y += effective_gravity * SIM_DT
		# 2. 线性阻尼（与 RigidBody2D 的 linear_damp 行为一致）
		vel /= (1.0 + DAMP * SIM_DT)
		# 3. 位置积分
		pos += vel * SIM_DT
		points.append(to_local(pos))
		
		# 超出屏幕范围提前终止
		if pos.y > 600 or abs(pos.x) > 1200:
			break

	return points

func _draw() -> void:
	if not is_aiming or not is_active:
		return
	
	# 计算发射速度（与 ProjectileLauncher 完全一致）
	var rad := deg_to_rad(aim_angle)
	var vel := Vector2(cos(rad) * aim_power, sin(rad) * aim_power)
	
	# 模拟物理轨迹
	var points: Array[Vector2] = _simulate_trajectory(vel, aim_origin)
	
	if points.size() < 2:
		return
	
	# 绘制轨迹（实线，更粗）
	for i in range(points.size() - 1):
		var alpha: float = 0.3 + 0.5 * float(i) / float(points.size())
		var c: Color = DOT_COLOR
		c.a = alpha
		draw_line(points[i], points[i + 1], c, 3.0)
	
	# 绘制落点 + 爆炸范围预览
	var last: Vector2 = points[points.size() - 1]
	draw_circle(last, 8, Color.RED)
	draw_circle(last, GameConfig.EXPLOSION_RADIUS, Color(1.0, 0.3, 0.1, 0.2))
	
	# ---- 力度可视化 ----
	_draw_power_bar(points[0])

## 在玩家左侧绘制力度条，展示当前蓄力程度
func _draw_power_bar(origin_local: Vector2) -> void:
	const BAR_WIDTH: float = 10.0
	const BAR_HEIGHT: float = 80.0
	const BAR_OFFSET_X: float = -45.0   # 玩家左侧
	const BAR_OFFSET_Y: float = -40.0   # 垂直居中偏移
	
	var bar_x := origin_local.x + BAR_OFFSET_X
	var bar_y := origin_local.y + BAR_OFFSET_Y
	
	# 力度比例 0~1
	var ratio := clampf((aim_power - MIN_POWER) / (MAX_POWER - MIN_POWER), 0.0, 1.0)
	var fill_h := BAR_HEIGHT * ratio
	var fill_y := bar_y + BAR_HEIGHT - fill_h
	
	# 根据力度选择颜色：绿(低)→黄(中)→红(高)
	var fill_color: Color
	if ratio < 0.5:
		fill_color = Color.GREEN.lerp(Color.YELLOW, ratio * 2.0)
	else:
		fill_color = Color.YELLOW.lerp(Color.RED, (ratio - 0.5) * 2.0)
	
	# 背景框（半透明深色）
	draw_rect(Rect2(bar_x, bar_y, BAR_WIDTH, BAR_HEIGHT), Color(0.1, 0.1, 0.1, 0.6))
	# 填充条
	draw_rect(Rect2(bar_x, fill_y, BAR_WIDTH, fill_h), fill_color)
	# 边框
	draw_rect(Rect2(bar_x, bar_y, BAR_WIDTH, BAR_HEIGHT), Color.WHITE, false, 1.0)
	draw_rect(Rect2(bar_x, fill_y, BAR_WIDTH, fill_h), Color.WHITE, false, 1.0)
	
	# 力度数值文字
	var label := "%d" % int(aim_power)
	var font := ThemeDB.fallback_font
	if font == null:
		return  # 无字体时不渲染力度数值，避免 draw_string 静默失败
	var font_size := 14
	var label_color := Color.WHITE
	label_color.a = 0.9
	draw_string(font, Vector2(bar_x + BAR_WIDTH + 6, bar_y + BAR_HEIGHT - 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)

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
