# RoomData — 房间数据定义 (Resource)
class_name RoomData
extends Resource

enum RoomType { START, BATTLE, ELITE, SHOP, EVENT, BOSS, REST }

@export var id: String = ""
@export var room_type: RoomType = RoomType.BATTLE
@export var room_name: String = ""
@export var enemy_configs: Array[Dictionary] = []   # 敌人配置列表
@export var reward_gold: int = 0
@export var cleared: bool = false
@export var connections: Array[int] = []              # 连接到哪些房间索引

func _init(p_id: String = "", p_type: RoomType = RoomType.BATTLE, p_name: String = "", p_enemies: Array[Dictionary] = [], p_gold: int = 0, p_connections: Array[int] = []) -> void:
	id = p_id
	room_type = p_type
	room_name = p_name
	enemy_configs = p_enemies
	reward_gold = p_gold
	connections = p_connections

func get_type_name() -> String:
	match room_type:
		RoomType.START: return "起点"
		RoomType.BATTLE: return "战斗"
		RoomType.ELITE: return "精英"
		RoomType.SHOP: return "商店"
		RoomType.EVENT: return "事件"
		RoomType.BOSS: return "Boss"
		RoomType.REST: return "休息"
		_: return "未知"
