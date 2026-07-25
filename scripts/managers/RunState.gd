# RunState — 跨战斗持久状态（roolike 跑团状态）
class_name RunState
extends Node

## 当前楼层
var current_floor: int = 1
## 金币
var gold: int = 100
## 玩家持久 HP
var player_max_hp: int = 100
var player_current_hp: int = 100
## 整局牌组
var deck: Array[CardData] = []
## 整局遗物
var relics: Array[RelicData] = []
## 当前楼层房间列表
var room_nodes: Array[RoomData] = []
## 当前房间索引
var current_room_index: int = 0
## 已访问房间数
var rooms_cleared: int = 0

func _ready() -> void:
	_init_starting_deck()
	_self_test()

func _init_starting_deck() -> void:
	deck = CardDB.get_starting_deck()
	player_max_hp = GameConfig.PLAYER_HP
	player_current_hp = player_max_hp

func add_gold(amount: int) -> void:
	gold += amount
	print("[RunState] +%d gold, total: %d" % [amount, gold])

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	print("[RunState] -%d gold, total: %d" % [amount, gold])
	return true

func heal_player(amount: int) -> void:
	player_current_hp = min(player_current_hp + amount, player_max_hp)
	print("[RunState] Healed %d HP, now %d/%d" % [amount, player_current_hp, player_max_hp])

func take_damage(amount: int) -> void:
	player_current_hp = max(player_current_hp - amount, 0)
	print("[RunState] Took %d damage, HP now %d/%d" % [amount, player_current_hp, player_max_hp])

func add_card_to_deck(card: CardData) -> void:
	deck.append(card.duplicate())
	print("[RunState] Added card: %s, deck=%d" % [card.card_name, deck.size()])

func add_relic(relic: RelicData) -> void:
	relics.append(relic.duplicate())
	print("[RunState] Added relic: %s, total=%d" % [relic.relic_name, relics.size()])

func is_player_alive() -> bool:
	return player_current_hp > 0

func clear_room_data() -> void:
	room_nodes.clear()
	current_room_index = 0
	rooms_cleared = 0

func _self_test() -> void:
	TestHelper.assert_eq(gold, 100, "RunState initial gold=100")
	TestHelper.assert_eq(player_max_hp, 100, "RunState initial max_hp=100")
	TestHelper.assert_eq(player_current_hp, 100, "RunState initial hp=100")
	TestHelper.check(is_player_alive(), "RunState player alive")
	
	add_gold(50)
	TestHelper.assert_eq(gold, 150, "RunState add_gold")
	TestHelper.check(spend_gold(30), "RunState spend_gold success")
	TestHelper.assert_eq(gold, 120, "RunState after spend gold=120")
	TestHelper.check(not spend_gold(999), "RunState spend_gold fail when insufficient")
	
	heal_player(10)
	TestHelper.assert_eq(player_current_hp, 100, "RunState heal caps at max")
	take_damage(30)
	TestHelper.assert_eq(player_current_hp, 70, "RunState take_damage")
	heal_player(10)
	TestHelper.assert_eq(player_current_hp, 80, "RunState heal partial")
	
	# Reset
	gold = 100
	player_current_hp = player_max_hp
	clear_room_data()
	TestHelper.assert_eq(room_nodes.size(), 0, "RunState room nodes cleared")
	
	print("[TEST] RunState self-test complete")
