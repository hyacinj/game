# CardDB — 卡牌数据库，管理所有卡牌定义和初始牌组
class_name CardDB
extends RefCounted

## 所有可用卡牌
static var _all_cards: Array[CardData] = []
static var _initialized: bool = false

## 初始化卡牌数据库（从 JSON 加载）
static func init() -> void:
	if _initialized:
		return
	_initialized = true
	
	var cards_array: Array = DataLoader.load_json_array("res://data/cards.json", "cards")
	for d in cards_array:
		var card := _card_from_dict(d)
		if card.id != "":
			_all_cards.append(card)
	
	print("[CardDB] Loaded %d cards" % _all_cards.size())

## 将字符串转换为 CardType 枚举
static func _parse_card_type(s: String) -> CardData.CardType:
	match s:
		"ATTACK":  return CardData.CardType.ATTACK
		"EFFECT":  return CardData.CardType.EFFECT
		"UTILITY": return CardData.CardType.UTILITY
		_:         return CardData.CardType.ATTACK

## 将字符串转换为 Rarity 枚举
static func _parse_rarity(s: String) -> CardData.Rarity:
	match s:
		"COMMON": return CardData.Rarity.COMMON
		"RARE":   return CardData.Rarity.RARE
		"EPIC":   return CardData.Rarity.EPIC
		_:        return CardData.Rarity.COMMON

## 从字典构造 CardData
static func _card_from_dict(d: Dictionary) -> CardData:
	if typeof(d) != TYPE_DICTIONARY:
		return CardData.new("invalid", "无效", "数据错误")
	
	var type: CardData.CardType = _parse_card_type(d.get("type", "ATTACK"))
	var rarity: CardData.Rarity = _parse_rarity(d.get("rarity", "COMMON"))
	
	return CardData.new(
		d.get("id", ""),
		d.get("name", ""),
		d.get("description", ""),
		type,
		d.get("cost", 1),
		rarity,
		d.get("effect_data", {}),
		d.get("durability", -1)
	)

## 获取初始牌组
static func get_starting_deck() -> Array[CardData]:
	init()
	var deck: Array[CardData] = []
	# 1 张普通炮弹（无限耐久）
	deck.append(get_by_id("cannonball"))
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

## 获取随机 ATTACK 类型卡牌（用于事件奖励）
static func get_random_attack_cards(count: int = 3) -> Array[CardData]:
	init()
	var attack_pool: Array[CardData] = []
	for card in _all_cards:
		if card.type == CardData.CardType.ATTACK:
			attack_pool.append(card)
	
	var result: Array[CardData] = []
	for _i in count:
		if attack_pool.is_empty():
			break
		var idx: int = randi() % attack_pool.size()
		result.append(attack_pool[idx].duplicate())
	return result

## 获取优先稀有的 ATTACK 卡牌（稀有 > 普通，首次事件专用）
static func get_rare_attack_cards(count: int = 4) -> Array[CardData]:
	init()
	var rare_pool: Array[CardData] = []
	var common_pool: Array[CardData] = []
	for card in _all_cards:
		if card.type != CardData.CardType.ATTACK:
			continue
		if card.rarity >= CardData.Rarity.RARE:
			rare_pool.append(card)
		else:
			common_pool.append(card)
	
	# 优先稀有，不够再用普通填充
	var result: Array[CardData] = []
	for card in rare_pool:
		if result.size() >= count:
			break
		result.append(card.duplicate())
	for card in common_pool:
		if result.size() >= count:
			break
		result.append(card.duplicate())
	return result

func _self_test() -> void:
	init()
	TestHelper.assert_gt(_all_cards.size(), 0, "CardDB has cards loaded")
	
	# 验证关键卡牌存在
	var strike := get_by_id("strike")
	TestHelper.check(strike.id == "strike", "CardDB strike exists")
	TestHelper.check(strike.card_name == "打击", "CardDB strike name correct")
	
	var burn := get_by_id("burning_shell")
	TestHelper.check(burn.id == "burning_shell", "CardDB burning_shell exists")
	
	# 初始牌组
	var deck := get_starting_deck()
	TestHelper.assert_eq(deck.size(), 1, "CardDB starting deck size=1")
	
	# 随机生成
	var cards := get_random_mixed(3)
	TestHelper.assert_eq(cards.size(), 3, "CardDB random_mixed returns 3")
	
	print("[TEST] CardDB self-test complete")
