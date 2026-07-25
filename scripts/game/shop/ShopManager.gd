# ShopManager — 商店逻辑（纯数据，UI 留 P3）
class_name ShopManager
extends Node

const CARD_PRICES: Dictionary = {
	"COMMON": 50,
	"RARE": 100,
	"EPIC": 150
}
const RELIC_PRICES: Dictionary = {
	"COMMON": 80,
	"RARE": 150,
	"EPIC": 250,
	"LEGENDARY": 400
}
const REFRESH_COST: int = 30

var run_state: RunState
var cards_for_sale: Array[CardData] = []
var relics_for_sale: Array[RelicData] = []

func _ready() -> void:
	_self_test()

func setup(rs: RunState) -> void:
	run_state = rs

## 生成商店商品
func generate_shop() -> void:
	cards_for_sale.clear()
	relics_for_sale.clear()
	
	# 3 张随机卡牌
	cards_for_sale = CardDB.get_random_mixed(3)
	# 2 个随机遗物
	for _i: int in 2:
		relics_for_sale.append(_create_random_relic())
	
	EventBus.emit("shop:generated", {"cards": cards_for_sale, "relics": relics_for_sale})
	print("[ShopManager] Shop generated: %d cards, %d relics" % [cards_for_sale.size(), relics_for_sale.size()])

## 购买卡牌
func buy_card(index: int) -> bool:
	if index < 0 or index >= cards_for_sale.size():
		return false
	var card: CardData = cards_for_sale[index]
	var price: int = get_card_price(card)
	if not run_state.spend_gold(price):
		print("[ShopManager] Cannot afford card: %s (%d gold needed)" % [card.card_name, price])
		return false
	run_state.add_card_to_deck(card)
	cards_for_sale.remove_at(index)
	EventBus.emit("shop:item_bought", {"item": card, "type": "card"})
	print("[ShopManager] Bought card: %s for %d gold" % [card.card_name, price])
	return true

## 购买遗物
func buy_relic(index: int) -> bool:
	if index < 0 or index >= relics_for_sale.size():
		return false
	var relic: RelicData = relics_for_sale[index]
	var price: int = get_relic_price(relic)
	if not run_state.spend_gold(price):
		print("[ShopManager] Cannot afford relic: %s (%d gold needed)" % [relic.relic_name, price])
		return false
	run_state.add_relic(relic)
	relics_for_sale.remove_at(index)
	EventBus.emit("shop:item_bought", {"item": relic, "type": "relic"})
	print("[ShopManager] Bought relic: %s for %d gold" % [relic.relic_name, price])
	return true

## 刷新商店
func refresh_shop() -> bool:
	if not run_state.spend_gold(REFRESH_COST):
		return false
	generate_shop()
	print("[ShopManager] Shop refreshed for %d gold" % REFRESH_COST)
	return true

func get_card_price(card: CardData) -> int:
	match card.rarity:
		CardData.Rarity.COMMON: return CARD_PRICES["COMMON"]
		CardData.Rarity.RARE: return CARD_PRICES["RARE"]
		CardData.Rarity.EPIC: return CARD_PRICES["EPIC"]
		_: return CARD_PRICES["COMMON"]

func get_relic_price(relic: RelicData) -> int:
	match relic.rarity:
		RelicData.Rarity.COMMON: return RELIC_PRICES["COMMON"]
		RelicData.Rarity.RARE: return RELIC_PRICES["RARE"]
		RelicData.Rarity.EPIC: return RELIC_PRICES["EPIC"]
		RelicData.Rarity.LEGENDARY: return RELIC_PRICES["LEGENDARY"]
		_: return RELIC_PRICES["COMMON"]

func _create_random_relic() -> RelicData:
	var roll: float = randf()
	var rarity: int
	if roll < 0.5:
		rarity = RelicData.Rarity.COMMON
	elif roll < 0.8:
		rarity = RelicData.Rarity.RARE
	elif roll < 0.95:
		rarity = RelicData.Rarity.EPIC
	else:
		rarity = RelicData.Rarity.LEGENDARY
	
	var relics_list: Array[Dictionary] = [
		{"id": "hp_up", "name": "生命提升", "desc": "最大 HP +20%", "type": RelicData.EffectType.STAT_BONUS, "data": {"stat": "max_hp", "value": 20, "is_percent": true}},
		{"id": "dmg_up", "name": "伤害提升", "desc": "伤害 +15%", "type": RelicData.EffectType.DAMAGE_BONUS, "data": {"value": 15, "is_percent": true}},
		{"id": "energy_up", "name": "能量之源", "desc": "+1 最大能量", "type": RelicData.EffectType.ENERGY_BONUS, "data": {"energy": 1}},
		{"id": "radius_up", "name": "爆破专家", "desc": "爆炸范围 +30%", "type": RelicData.EffectType.RADIUS_BONUS, "data": {"value": 30, "is_percent": true}},
	]
	var chosen: Dictionary = relics_list[randi() % relics_list.size()]
	return RelicData.new(chosen["id"], chosen["name"], chosen["desc"], rarity, chosen["type"], chosen["data"])

func _self_test() -> void:
	# Create a temporary RunState for testing
	var temp_rs: RunState = RunState.new()
	temp_rs.gold = 200
	setup(temp_rs)
	
	generate_shop()
	TestHelper.assert_eq(cards_for_sale.size(), 3, "ShopManager has 3 cards")
	TestHelper.assert_eq(relics_for_sale.size(), 2, "ShopManager has 2 relics")
	
	# Buy a card
	var card: CardData = cards_for_sale[0]
	var price: int = get_card_price(card)
	if temp_rs.gold >= price:
		TestHelper.check(buy_card(0), "ShopManager buy_card success")
		TestHelper.assert_eq(cards_for_sale.size(), 2, "ShopManager card removed after purchase")
	
	print("[TEST] ShopManager self-test complete")
