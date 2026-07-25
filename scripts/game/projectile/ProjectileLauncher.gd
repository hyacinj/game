# ProjectileLauncher — 炮弹发射器
# 负责创建炮弹实例，支持单发和散射
class_name ProjectileLauncher
extends Node

## 对象池（简单数组复用）
var _pool: Array[Projectile] = []
var _active: Array[Projectile] = []

## 引用
var wind_system: WindSystem = null
var battle_root: Node2D = null

## 发射配置
var base_damage: int = GameConfig.BASE_DAMAGE
var explosion_radius: float = GameConfig.EXPLOSION_RADIUS

func _ready() -> void:
	_self_test()

func setup(root: Node2D, ws: WindSystem) -> void:
	battle_root = root
	wind_system = ws

## 单发炮弹
func fire_projectile(origin: Vector2, angle_deg: float, power: float) -> Projectile:
	var rad: float = deg_to_rad(angle_deg)
	var vel: Vector2 = Vector2(cos(rad) * power, sin(rad) * power)
	return _create_and_launch(origin, vel)

## 散射弹：同时发射 N 颗，角度均匀分布在 spread_angle 范围内
func fire_scatter(origin: Vector2, angle_deg: float, power: float, count: int, spread_angle: float) -> Array[Projectile]:
	var projectiles: Array[Projectile] = []
	if count <= 1:
		projectiles.append(fire_projectile(origin, angle_deg, power))
		return projectiles
	
	var half_spread: float = spread_angle / 2.0
	var step: float = spread_angle / float(count - 1) if count > 1 else 0.0
	for i in range(count):
		var offset_angle: float = -half_spread + step * i
		var rad: float = deg_to_rad(angle_deg + offset_angle)
		var vel: Vector2 = Vector2(cos(rad) * power, sin(rad) * power)
		projectiles.append(_create_and_launch(origin, vel))
	return projectiles

## 创建炮弹实例并发射
func _create_and_launch(origin: Vector2, velocity: Vector2) -> Projectile:
	var proj: Projectile = _get_from_pool()
	proj.damage = base_damage
	proj.explosion_radius = explosion_radius
	proj.wind_system = wind_system
	battle_root.add_child(proj)
	proj.global_position = origin
	proj.launch(velocity)
	print("[Launcher] Fired projectile at %s vel=%s" % [origin, velocity])
	return proj

## 从对象池获取
func _get_from_pool() -> Projectile:
	if _pool.size() > 0:
		var proj: Projectile = _pool.pop_back()
		proj.has_exploded = false
		return proj
	return Projectile.new()

## 回收炮弹到对象池
func recycle(proj: Projectile) -> void:
	if proj in _active:
		_active.erase(proj)
	proj.get_parent().remove_child(proj)
	_pool.append(proj)

func get_active_count() -> int:
	return _active.size()

func _self_test() -> void:
	TestHelper.check(base_damage > 0, "ProjectileLauncher base_damage positive")
	TestHelper.check(explosion_radius > 0, "ProjectileLauncher explosion_radius positive")
	# Verify pool starts empty
	TestHelper.assert_eq(_pool.size(), 0, "ProjectileLauncher pool starts empty")
	TestHelper.assert_eq(_active.size(), 0, "ProjectileLauncher active starts empty")
	print("[TEST] ProjectileLauncher self-test complete")
