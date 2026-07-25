# CardManager — 牌库/手牌/弃牌堆管理（纯逻辑，无 UI）
class_name CardManager
extends Node

const MAX_HAND_SIZE: int = GameConfig.MAX_HAND_SIZE
const DRAW_PER_TURN: int = GameConfig.DRAW_PER_TURN

var deck: Array[CardData] = []       # 牌库
var hand: Array[CardData] = []       # 手牌
var discard: Array[CardData] = []    # 弃牌堆

func _ready() -> void:
	EventBus.on("turn:draw_phase", _on_draw_phase)
	_self_test()

## 初始化牌组
func initialize(starting_deck: Array[CardData]) -> void:
	deck = starting_deck.duplicate()
	hand.clear()
	discard.clear()
	shuffle_deck()
	print("[CardManager] Initialized with %d cards" % deck.size())

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
		if hand.size() >= MAX_HAND_SIZE:
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

## 使用手牌
func use_card(index: int) -> CardData:
	if index < 0 or index >= hand.size():
		return null
	var card: CardData = hand[index]
	hand.remove_at(index)
	discard.append(card)
	EventBus.emit("card:used", {"card": card, "hand_size": hand.size()})
	print("[CardManager] Used card: %s, hand=%d, discard=%d" % [card.card_name, hand.size(), discard.size()])
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

func _on_draw_phase(_data: Dictionary) -> void:
	draw(DRAW_PER_TURN)

func _self_test() -> void:
	# Initialize with starting deck
	var starter: Array[CardData] = CardDB.get_starting_deck()
	initialize(starter)
	TestHelper.assert_eq(deck.size(), GameConfig.STARTING_DECK_SIZE, "CardManager starting deck size")
	TestHelper.assert_eq(hand.size(), 0, "CardManager hand starts empty")
	TestHelper.assert_eq(discard.size(), 0, "CardManager discard starts empty")
	
	# Draw cards
	var drawn: Array[CardData] = draw(DRAW_PER_TURN)
	TestHelper.assert_eq(drawn.size(), DRAW_PER_TURN, "CardManager drew 5 cards")
	TestHelper.assert_eq(hand.size(), DRAW_PER_TURN, "CardManager hand has 5 cards")
	TestHelper.assert_eq(deck.size(), GameConfig.STARTING_DECK_SIZE - DRAW_PER_TURN, "CardManager deck reduced")
	
	# Use a card
	var used: CardData = use_card(0)
	TestHelper.check(used != null, "CardManager used card returned")
	TestHelper.assert_eq(hand.size(), DRAW_PER_TURN - 1, "CardManager hand reduced after use")
	TestHelper.assert_eq(discard.size(), 1, "CardManager discard has 1 after use")
	
	# Draw more to empty deck + test shuffle
	draw(100)  # Try to draw all remaining
	var total_cards_after: int = hand.size() + deck.size() + discard.size()
	TestHelper.assert_eq(total_cards_after, GameConfig.STARTING_DECK_SIZE, "CardManager no cards lost")
	
	# Reset for clean state
	deck.clear()
	hand.clear()
	discard.clear()
	
	print("[TEST] CardManager self-test complete")
