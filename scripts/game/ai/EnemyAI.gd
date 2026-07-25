# EnemyAI — 敌人回合行为控制
class_name EnemyAI
extends Node

enum State { IDLE, AIMING, FIRING, DONE }

var enemy_unit: Unit = null
var target_player: Player = null
var projectile_launcher: ProjectileLauncher = null
var wind_system: WindSystem = null

var state: State = State.IDLE
var enemy_data: Dictionary = {}
var difficulty: float = 1.0
var base_damage: int = 25
var explosion_radius: float = 100.0
var _intent_label: Node2D = null

func setup(unit: Unit, player: Player, launcher: ProjectileLauncher, wind: WindSystem, data: Dictionary) -> void:
	enemy_unit = unit
	target_player = player
	projectile_launcher = launcher
	wind_system = wind
	enemy_data = data
	difficulty = data.get("difficulty", 1.0)
	base_damage = data.get("damage", 25)
	explosion_radius = data.get("explosion_radius", 100.0)
	# 创建意图标签
	_intent_label = IntentLabel.new()
	enemy_unit.add_child(_intent_label)

## 执行敌人回合：瞄准 → 发射 → 等待落地
func take_turn() -> void:
	if not is_instance_valid(enemy_unit) or enemy_unit.is_dead:
		state = State.DONE
		return
	
	state = State.AIMING
	if _intent_label:
		_intent_label.show_text("攻击!")
	
	# 计算基础瞄准方向
	var dir: Vector2 = target_player.global_position - enemy_unit.global_position
	var dist: float = dir.length()
	var base_angle: float = rad_to_deg(dir.angle())
	var base_power: float = clamp(dist * 2.0, GameConfig.MIN_POWER, GameConfig.MAX_POWER)
	
	# 加入随机误差（难度越低误差越大）
	var angle_error: float = randf_range(-20.0, 20.0) / difficulty
	var power_error: float = randf_range(-150.0, 150.0) / difficulty
	var aim_angle: float = base_angle + angle_error
	var aim_power: float = clamp(base_power + power_error, GameConfig.MIN_POWER, GameConfig.MAX_POWER)
	
	# 发射（稍微抬高以补偿重力）
	var adjusted_angle: float = aim_angle - 8.0  # 略微抬升
	
	state = State.FIRING
	print("[EnemyAI] %s fires: angle=%.1f power=%.1f" % [enemy_data.get("name", "enemy"), adjusted_angle, aim_power])
	
	# 临时覆盖 launcher 的伤害属性
	var saved_damage: int = projectile_launcher.base_damage
	var saved_radius: float = projectile_launcher.explosion_radius
	projectile_launcher.base_damage = base_damage
	projectile_launcher.explosion_radius = explosion_radius
	
	projectile_launcher.fire_projectile(enemy_unit.global_position, adjusted_angle, aim_power)
	
	# 恢复
	projectile_launcher.base_damage = saved_damage
	projectile_launcher.explosion_radius = saved_radius
	
	await get_tree().create_timer(1.5).timeout
	state = State.DONE
	if _intent_label:
		_intent_label.hide_text()

func get_intent() -> String:
	return "攻击"
