# EventManager — 随机事件处理（纯逻辑，UI 留 P3）
class_name EventManager
extends Node

var run_state: RunState
var current_event: EventData = null

func _ready() -> void:
	_self_test()

func setup(rs: RunState) -> void:
	run_state = rs

## 触发随机事件
func trigger_random_event() -> void:
	current_event = EventDB.get_random_event()
	print("[EventManager] Event triggered: %s" % current_event.title)
	EventBus.emit("event:triggered", {"event": current_event})

## 处理玩家选择
func resolve_choice(option_index: int) -> Dictionary:
	if current_event == null:
		return {"result": "error", "message": "No active event"}
	if option_index < 0 or option_index >= current_event.options.size():
		return {"result": "error", "message": "Invalid option"}
	
	var opt: Dictionary = current_event.options[option_index]
	var result: Dictionary = {"result": "success", "event": current_event.title, "choice": opt["text"]}
	var opt_type: String = opt.get("type", "nothing")
	
	match opt_type:
		"nothing":
			result["message"] = "你选择什么都不做。"
			print("[EventManager] Player chose nothing")
		
		"gold":
			var amount: int = opt.get("value", 0)
			run_state.add_gold(amount)
			result["message"] = "获得了 %d 金币！" % amount
		
		"heal":
			var value: int = opt.get("value", 0)
			if opt.get("is_percent", false):
				value = int(run_state.player_max_hp * value / 100.0)
			run_state.heal_player(value)
			result["message"] = "恢复了 %d 点生命！" % value
		
		"random_card":
			var card: CardData = CardDB.get_random()
			run_state.add_card_to_deck(card)
			result["message"] = "获得了卡牌：%s！" % card.card_name
		
		"buy_relic":
			var cost: int = opt.get("cost", 0)
			if run_state.spend_gold(cost):
				var relic: RelicData = _create_random_relic()
				run_state.add_relic(relic)
				result["message"] = "花费 %d 金币，获得了遗物：%s！" % [cost, relic.relic_name]
			else:
				result["result"] = "fail"
				result["message"] = "金币不足！"
		
		"steal_relic":
			var rate: float = opt.get("success_rate", 0.5)
			if randf() < rate:
				var relic: RelicData = _create_random_relic()
				run_state.add_relic(relic)
				result["message"] = "偷窃成功！获得了遗物：%s！" % relic.relic_name
			else:
				var penalty: int = 20
				run_state.spend_gold(min(penalty, run_state.gold))
				result["result"] = "fail"
				result["message"] = "偷窃失败！损失了 20 金币..."
		
		"gamble":
			var cost: int = opt.get("cost", 0)
			var reward: int = opt.get("reward", 0)
			var rate: float = opt.get("success_rate", 0.5)
			if not run_state.spend_gold(cost):
				result["result"] = "fail"
				result["message"] = "金币不足，无法下注！"
			elif randf() < rate:
				run_state.add_gold(reward)
				result["message"] = "赢了！获得 %d 金币！" % reward
			else:
				result["message"] = "输了...失去了 %d 金币。" % cost
		
		"sacrifice_for_relic":
			var hp_cost: int = opt.get("hp_cost", 0)
			run_state.take_damage(hp_cost)
			var relic: RelicData = _create_random_relic()
			run_state.add_relic(relic)
			result["message"] = "献祭了 %d HP，获得了遗物：%s！" % [hp_cost, relic.relic_name]
		
		"pay_for_heal":
			var cost: int = opt.get("cost", 0)
			var heal: int = opt.get("heal", 0)
			if run_state.spend_gold(cost):
				run_state.heal_player(heal)
				result["message"] = "花费 %d 金币，恢复了 %d HP！" % [cost, heal]
			else:
				result["result"] = "fail"
				result["message"] = "金币不足！"
	
	EventBus.emit("event:resolved", result)
	current_event = null
	return result

func _create_random_relic() -> RelicData:
	var relics_list: Array[Dictionary] = [
		{"id": "hp_up", "name": "生命提升", "desc": "最大 HP +20%", "type": RelicData.EffectType.STAT_BONUS, "data": {"stat": "max_hp", "value": 20, "is_percent": true}},
		{"id": "dmg_up", "name": "伤害提升", "desc": "伤害 +15%", "type": RelicData.EffectType.DAMAGE_BONUS, "data": {"value": 15, "is_percent": true}},
	]
	var chosen: Dictionary = relics_list[randi() % relics_list.size()]
	return RelicData.new(chosen["id"], chosen["name"], chosen["desc"], RelicData.Rarity.COMMON, chosen["type"], chosen["data"])

func _self_test() -> void:
	var temp_rs: RunState = RunState.new()
	temp_rs.gold = 200
	setup(temp_rs)
	
	# Trigger event
	trigger_random_event()
	TestHelper.check(current_event != null, "EventManager has current event")
	TestHelper.check(current_event.options.size() >= 1, "EventManager event has options")
	
	# Resolve first option
	if current_event.options.size() > 0:
		var result: Dictionary = resolve_choice(0)
		TestHelper.check(result.get("result", "") != "error", "EventManager resolve_choice works")
	
	print("[TEST] EventManager self-test complete")
