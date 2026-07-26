# EventDB — 事件数据库
class_name EventDB
extends RefCounted

static var _initialized: bool = false
static var _events: Array[EventData] = []

static func init() -> void:
	if _initialized:
		return
	_initialized = true
	
	var events_array: Array = DataLoader.load_json_array("res://data/events.json", "events")
	for d in events_array:
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var event := _event_from_dict(d)
		if event.id != "":
			_events.append(event)
	
	print("[EventDB] Loaded %d events" % _events.size())

## 从字典构造 EventData
static func _event_from_dict(d: Dictionary) -> EventData:
	return EventData.new(
		d.get("id", ""),
		d.get("title", ""),
		d.get("description", ""),
		d.get("event_type", ""),
		d.get("card_count", 3)
	)

## 获取所有事件
static func get_all_events() -> Array[EventData]:
	init()
	return _events

## 获取可行事件（根据牌组状态过滤）
## 如果牌组没有可升级的 ATTACK 卡，则排除 upgrade_card 事件
static func get_feasible_events(deck: Array[CardData]) -> Array[EventData]:
	init()
	var has_upgradeable: bool = false
	for card in deck:
		if card.type == CardData.CardType.ATTACK and not card.upgraded:
			has_upgradeable = true
			break
	
	var feasible: Array[EventData] = []
	for event in _events:
		if event.event_type == "upgrade_card" and not has_upgradeable:
			continue
		feasible.append(event)
	
	# 如果所有事件都被过滤了，返回所有 add_card 事件
	if feasible.is_empty():
		for event in _events:
			if event.event_type == "add_card":
				feasible.append(event)
	
	return feasible

## 获取随机事件
static func get_random_event() -> EventData:
	init()
	if _events.is_empty():
		return EventData.new("fallback", "无事发生", "一切如常...", "add_card", 1)
	return _events[randi() % _events.size()]

func _self_test() -> void:
	init()
	TestHelper.assert_gt(_events.size(), 0, "EventDB has events loaded")
	
	var event := get_random_event()
	TestHelper.check(event != null, "EventDB returns event")
	TestHelper.check(event.event_type in ["add_card", "upgrade_card"], "EventDB event has valid type")
	TestHelper.check(event.card_count >= 1, "EventDB event has card_count")
	
	# 测试可行事件过滤
	var test_deck: Array[CardData] = [CardDB.get_by_id("cannonball")]
	var feasible := get_feasible_events(test_deck)
	TestHelper.assert_gt(feasible.size(), 0, "EventDB has feasible events for deck with attack card")
	
	print("[TEST] EventDB self-test complete")
