# EnemyDB — 敌人类型数据库
class_name EnemyDB
extends RefCounted

enum EnemyType { GRUNT, TANK, SNIPER, BOSS }

static var _initialized: bool = false
static var _data: Dictionary = {}

static func init() -> void:
	if _initialized:
		return
	_initialized = true
	
	_data["grunt"] = {
		"type": EnemyType.GRUNT,
		"name": "小兵",
		"hp": 60,
		"damage": 25,
		"color": Color.RED,
		"radius": 28.0,
		"difficulty": 0.8,    # 低精度
		"gold_reward": 20,
		"explosion_radius": 100.0
	}
	_data["tank"] = {
		"type": EnemyType.TANK,
		"name": "重装兵",
		"hp": 120,
		"damage": 35,
		"color": Color(0.8, 0.2, 0.0),  # 暗橙
		"radius": 38.0,
		"difficulty": 0.5,    # 低精度但伤害高
		"gold_reward": 35,
		"explosion_radius": 130.0
	}
	_data["sniper"] = {
		"type": EnemyType.SNIPER,
		"name": "狙击手",
		"hp": 40,
		"damage": 20,
		"color": Color(0.6, 0.0, 0.6),  # 紫色
		"radius": 22.0,
		"difficulty": 1.5,    # 高精度
		"gold_reward": 30,
		"explosion_radius": 80.0
	}
	_data["boss"] = {
		"type": EnemyType.BOSS,
		"name": "Boss",
		"hp": 250,
		"damage": 40,
		"color": Color(0.9, 0.1, 0.1),  # 深红
		"radius": 45.0,
		"difficulty": 1.3,
		"gold_reward": 100,
		"explosion_radius": 150.0
	}

static func get_data(enemy_type: String) -> Dictionary:
	init()
	if _data.has(enemy_type):
		return _data[enemy_type].duplicate()
	return _data["grunt"].duplicate()

static func get_all_types() -> Array[String]:
	init()
	return ["grunt", "tank", "sniper", "boss"]

static func get_random_normal() -> String:
	init()
	var roll: float = randf()
	if roll < 0.5:
		return "grunt"
	elif roll < 0.8:
		return "tank"
	else:
		return "sniper"
