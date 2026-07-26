# EventManager — 随机事件处理
class_name EventManager
extends Node

var run_state: RunState
var card_manager: CardManager = null
var current_event: EventData = null
var _first_event_done: bool = false

func _ready() -> void:
	_self_test()

func setup(rs: RunState, cm: CardManager = null) -> void:
	run_state = rs
	card_manager = cm

## 触发随机事件（动态填充 card_options）
func trigger_random_event() -> void:
	if not _first_event_done:
		# 首次事件固定：4 张稀有炮弹任选其一
		_first_event_done = true
		current_event = EventData.new("first_reward", "军械补给", "你发现了一个废弃的军械库，选择一枚稀有炮弹带走！", "add_card", 4)
		current_event.card_options = CardDB.get_rare_attack_cards(4)
	else:
		var feasible := EventDB.get_feasible_events(run_state.deck)
		if feasible.is_empty():
			current_event = EventDB.get_random_event()
		else:
			current_event = feasible[randi() % feasible.size()]
		_populate_card_options()
	
	print("[EventManager] Event triggered: %s (type=%s, cards=%d)" % [current_event.title, current_event.event_type, current_event.card_options.size()])
	EventBus.emit("event:triggered", {"event": current_event})

## 根据事件类型填充卡片选项
func _populate_card_options() -> void:
	match current_event.event_type:
		"add_card":
			current_event.card_options = CardDB.get_random_attack_cards(current_event.card_count)
		"upgrade_card":
			current_event.card_options = _get_upgradeable_cards(current_event.card_count)

## 从牌组中获取可升级的 ATTACK 卡片
func _get_upgradeable_cards(count: int) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in run_state.deck:
		if card.type == CardData.CardType.ATTACK and not card.upgraded:
			pool.append(card)
	
	# 去重（同一 ID 的卡片只保留一份用于展示）
	var seen_ids: Array[String] = []
	var unique: Array[CardData] = []
	for card in pool:
		if card.id not in seen_ids:
			seen_ids.append(card.id)
			unique.append(card)
	
	# 随机选 count 张
	var result: Array[CardData] = []
	while result.size() < count and not unique.is_empty():
		var idx: int = randi() % unique.size()
		result.append(unique[idx])
		unique.remove_at(idx)
	
	return result

## 处理玩家选择卡片
func resolve_card_choice(card_index: int) -> Dictionary:
	if current_event == null:
		return {"result": "error", "message": "No active event"}
	if card_index < 0 or card_index >= current_event.card_options.size():
		return {"result": "error", "message": "Invalid card index"}
	
	var card: CardData = current_event.card_options[card_index]
	var result: Dictionary = {"result": "success", "event": current_event.title}
	
	match current_event.event_type:
		"add_card":
			run_state.add_card_to_deck(card)
			if card_manager != null:
				card_manager.add_card(card)
			result["message"] = "获得了 %s！" % card.card_name
		
		"upgrade_card":
			card.apply_upgrade()
			result["message"] = "%s 已升级！" % card.card_name
	
	EventBus.emit("event:resolved", result)
	current_event = null
	return result

func _self_test() -> void:
	# 保存当前状态，测试后恢复（避免 _ready() 中的自检覆盖真实状态）
	var saved_rs := run_state
	var saved_cm := card_manager
	
	var temp_rs: RunState = RunState.new()
	temp_rs.deck = CardDB.get_starting_deck()
	setup(temp_rs)
	
	# Trigger event
	trigger_random_event()
	TestHelper.check(current_event != null, "EventManager has current event")
	TestHelper.check(current_event.card_options.size() >= 1, "EventManager has card options")
	
	# Resolve first card
	if current_event.card_options.size() > 0:
		var result: Dictionary = resolve_card_choice(0)
		TestHelper.check(result.get("result", "") != "error", "EventManager resolve_card_choice works")
	
	# Test upgrade event scenario
	temp_rs.deck = CardDB.get_starting_deck()
	# Force an upgrade event by temporarily setting event
	current_event = EventData.new("test_upgrade", "测试升级", "test", "upgrade_card", 1)
	current_event.card_options = [temp_rs.deck[0]]
	var up_result := resolve_card_choice(0)
	TestHelper.check(up_result["result"] == "success", "EventManager upgrade succeeds")
	TestHelper.check(temp_rs.deck[0].upgraded, "EventManager card marked upgraded")
	
	# 恢复原始状态
	run_state = saved_rs
	card_manager = saved_cm
	current_event = null
	
	print("[TEST] EventManager self-test complete")
