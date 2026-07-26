# CardManager — 牌库/手牌/弃牌堆管理（纯逻辑，无 UI）
class_name CardManager
extends Node

var max_hand_size: int = GameConfig.MAX_HAND_SIZE
var draw_per_turn: int = GameConfig.DRAW_PER_TURN

var deck: Array[CardData] = []       # 牌库
var hand: Array[CardData] = []       # 手牌
var discard: Array[CardData] = []    # 弃牌堆

func _ready() -> void:
	# 监听抽牌阶段事件
	EventBus.on("turn:draw_phase", _on_draw_phase)
	_self_test()

## 初始化手牌（直接入手，不经过牌库）
func initialize(starting_hand: Array[CardData]) -> void:
	hand = starting_hand.duplicate()
	deck.clear()
	discard.clear()
	print("[CardManager] Initialized hand with %d cards" % hand.size())

## 洗牌
func shuffle_deck() -> void:
	deck.shuffle()
	EventBus.emit("deck:shuffled", {"deck_size": deck.size()})

## 洗入弃牌堆
func shuffle_discard_into_deck() -> void:
	deck.append_array(discard)
	discard.clear()
	shuffle_deck()
	print("[CardManager] Discard shuffled into deck, now %d cards" % deck.size())

## 抽牌
func draw(count: int = 1) -> Array[CardData]:
	var drawn: Array[CardData] = []
	for _i in range(count):
		if hand.size() >= max_hand_size:
			print("[CardManager] Hand full, cannot draw more")
			break
		if deck.is_empty():
			if discard.is_empty():
				print("[CardManager] No cards left to draw")
				break
			shuffle_discard_into_deck()
		var card: CardData = deck.pop_back()
		hand.append(card)
		drawn.append(card)
	if drawn.size() > 0:
		EventBus.emit("card:drawn", {"cards": drawn, "count": drawn.size()})
		print("[CardManager] Drew %d cards, hand=%d, deck=%d" % [drawn.size(), hand.size(), deck.size()])
	return drawn

## 使用手牌（不消耗——无限耐久）
func use_card(index: int) -> CardData:
	if index < 0 or index >= hand.size():
		return null
	var card: CardData = hand[index]
	# 无限耐久：不从手牌移除，不放入弃牌堆
	print("[CardManager] Fired card: %s (hand=%d)" % [card.card_name, hand.size()])
	return card

## 战后获得新牌
func add_card(card: CardData) -> void:
	deck.append(card.duplicate())
	print("[CardManager] Added card: %s, deck=%d" % [card.card_name, deck.size()])

## 添加多张牌
func add_cards(cards: Array[CardData]) -> void:
	for card in cards:
		add_card(card)

func get_hand_size() -> int:
	return hand.size()

func get_deck_size() -> int:
	return deck.size()

func get_discard_size() -> int:
	return discard.size()

func _on_draw_phase(_data: Dictionary = {}) -> void:
	draw(draw_per_turn)

func _self_test() -> void:
	# Initialize with starting cards (1 card directly in hand)
	var starter: Array[CardData] = CardDB.get_starting_deck()
	initialize(starter)
	TestHelper.assert_eq(hand.size(), 1, "CardManager hand has 1 card")
	TestHelper.assert_eq(deck.size(), 0, "CardManager deck empty")
	TestHelper.assert_eq(discard.size(), 0, "CardManager discard empty")
	
	# Use card — should NOT remove from hand (infinite durability)
	var used: CardData = use_card(0)
	TestHelper.check(used != null, "CardManager use_card returns card")
	TestHelper.assert_eq(hand.size(), 1, "CardManager hand still has 1 after use (infinite)")
	TestHelper.assert_eq(discard.size(), 0, "CardManager discard still empty")
	
	print("[TEST] CardManager self-test complete")
