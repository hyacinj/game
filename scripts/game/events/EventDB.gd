# EventDB — 事件数据库
class_name EventDB
extends RefCounted

static var _initialized: bool = false
static var _events: Array[EventData] = []

static func init() -> void:
	if _initialized:
		return
	_initialized = true
	
	_events.append(EventData.new(
		"mysterious_merchant",
		"神秘商人",
		"一个戴着兜帽的商人从阴影中出现，向你展示他的商品...",
		[
			{"text": "购买遗物 (100 金币)", "type": "buy_relic", "cost": 100},
			{"text": "偷走遗物 (50% 成功)", "type": "steal_relic", "success_rate": 0.5},
			{"text": "礼貌地离开", "type": "nothing"}
		]
	))
	_events.append(EventData.new(
		"healing_fountain",
		"治愈之泉",
		"你发现了一处闪着微光的泉水，散发着治愈的气息...",
		[
			{"text": "饮用泉水 (恢复 30% HP)", "type": "heal", "value": 30, "is_percent": true},
			{"text": "装满水瓶带走 (+50 金币)", "type": "gold", "value": 50},
			{"text": "无视泉水继续前进", "type": "nothing"}
		]
	))
	_events.append(EventData.new(
		"training_dummy",
		"训练假人",
		"路边有一个破旧的训练假人，旁边放着一本战斗手册...",
		[
			{"text": "研读手册 (随机获得一张牌)", "type": "random_card"},
			{"text": "拆解假人 (+30 金币)", "type": "gold", "value": 30},
			{"text": "继续赶路", "type": "nothing"}
		]
	))
	_events.append(EventData.new(
		"gambler",
		"赌徒的挑战",
		"一个赌徒拦住你：'来赌一把？押 50 金币，赢了翻倍！'",
		[
			{"text": "押注 (50% 赢 100 金币)", "type": "gamble", "cost": 50, "reward": 100, "success_rate": 0.5},
			{"text": "拒绝赌博", "type": "nothing"}
		]
	))
	_events.append(EventData.new(
		"cursed_altar",
		"被诅咒的祭坛",
		"古老的祭坛上刻着：'献上生命，换取力量'",
		[
			{"text": "献祭 20 HP → 获得稀有遗物", "type": "sacrifice_for_relic", "hp_cost": 20},
			{"text": "献祭 25 金币 → 恢复 15 HP", "type": "pay_for_heal", "cost": 25, "heal": 15},
			{"text": "远离这个不祥之地", "type": "nothing"}
		]
	))

static func get_random_event() -> EventData:
	init()
	return _events[randi() % _events.size()]
