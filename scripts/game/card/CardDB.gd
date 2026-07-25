# CardDB — 卡牌数据库，管理所有卡牌定义和初始牌组
class_name CardDB
extends RefCounted

## 所有可用卡牌
static var _all_cards: Array[CardData] = []
static var _initialized: bool = false

## 初始化卡牌数据库
static func init() -> void:
	if _initialized:
		return
	_initialized = true
	
	# ---- 基础攻击牌 ----
	_all_cards.append(CardData.new("strike", "打击", "造成基础伤害", CardData.CardType.ATTACK, 1, CardData.Rarity.COMMON, {"damage_bonus": 5}))
	_all_cards.append(CardData.new("heavy_strike", "重击", "造成额外伤害", CardData.CardType.ATTACK, 2, CardData.Rarity.COMMON, {"damage_bonus": 15}))
	_all_cards.append(CardData.new("scatter_shot", "散射弹", "同时发射 3 颗炮弹", CardData.CardType.ATTACK, 2, CardData.Rarity.RARE, {"scatter_count": 3, "spread_angle": 30.0}))
	_all_cards.append(CardData.new("sniper_shot", "精准射击", "缩小爆炸范围但大幅增加伤害", CardData.CardType.ATTACK, 2, CardData.Rarity.RARE, {"damage_bonus": 20, "radius_mult": 0.5}))
	
	# ---- 效果牌 ----
	_all_cards.append(CardData.new("burning_shell", "燃烧弹", "爆炸附加灼烧效果", CardData.CardType.EFFECT, 1, CardData.Rarity.COMMON, {"status": "burn", "status_duration": 3}))
	_all_cards.append(CardData.new("freeze_bomb", "冰冻炸弹", "爆炸附加冰冻效果", CardData.CardType.EFFECT, 2, CardData.Rarity.COMMON, {"status": "freeze", "status_duration": 2}))
	
	# ---- 辅助牌 ----
	_all_cards.append(CardData.new("extra_energy", "能量补充", "获得 1 点额外能量", CardData.CardType.UTILITY, 0, CardData.Rarity.COMMON, {"energy_gain": 1}))
	_all_cards.append(CardData.new("wind_control", "风向操控", "下回合无风", CardData.CardType.UTILITY, 1, CardData.Rarity.RARE, {"wind_control": true}))
	_all_cards.append(CardData.new("rapid_fire", "快速装填", "本回合可再发射一次", CardData.CardType.UTILITY, 1, CardData.Rarity.RARE, {"extra_shot": true}))
	_all_cards.append(CardData.new("big_explosion", "大爆炸", "爆炸范围翻倍", CardData.CardType.UTILITY, 2, CardData.Rarity.EPIC, {"radius_mult": 2.0}))

## 获取初始牌组（新手牌组）
static func get_starting_deck() -> Array[CardData]:
	init()
	var deck: Array[CardData] = []
	# 4 张打击 + 2 张燃烧弹
	for _i in 4:
		deck.append(get_by_id("strike"))
	for _i in 2:
		deck.append(get_by_id("burning_shell"))
	return deck

## 按 ID 查找卡牌
static func get_by_id(card_id: String) -> CardData:
	init()
	for card in _all_cards:
		if card.id == card_id:
			return card.duplicate()
	return CardData.new("unknown", "未知卡牌", "未知的卡牌")

## 随机获取一张卡牌（可选稀有度过滤）
static func get_random(rarity: CardData.Rarity = CardData.Rarity.COMMON) -> CardData:
	init()
	var pool: Array[CardData] = []
	for card in _all_cards:
		if rarity == CardData.Rarity.COMMON or card.rarity == rarity:
			pool.append(card)
	if pool.is_empty():
		pool = _all_cards
	return pool[randi() % pool.size()].duplicate()

## 获取随机卡牌（稀有度混合）
static func get_random_mixed(count: int = 3) -> Array[CardData]:
	init()
	var result: Array[CardData] = []
	for _i in count:
		var roll: float = randf()
		var r: CardData.Rarity
		if roll < 0.6:
			r = CardData.Rarity.COMMON
		elif roll < 0.85:
			r = CardData.Rarity.RARE
		else:
			r = CardData.Rarity.EPIC
		result.append(get_random(r))
	return result
