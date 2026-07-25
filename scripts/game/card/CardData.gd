# CardData — 卡牌数据定义 (Resource)
class_name CardData
extends Resource

enum CardType { ATTACK, EFFECT, UTILITY }
enum Rarity { COMMON, RARE, EPIC }

@export var id: String = ""
@export var card_name: String = ""
@export var description: String = ""
@export var type: CardType = CardType.ATTACK
@export var cost: int = 1
@export var rarity: Rarity = Rarity.COMMON
@export var effect_data: Dictionary = {}  # {"scatter_count": 3, "damage_bonus": 5, "status": "burn", ...}
@export var icon_path: String = ""

func _init(p_id: String = "", p_name: String = "", p_desc: String = "", p_type: CardType = CardType.ATTACK, p_cost: int = 1, p_rarity: Rarity = Rarity.COMMON, p_effect: Dictionary = {}) -> void:
	id = p_id
	card_name = p_name
	description = p_desc
	type = p_type
	cost = p_cost
	rarity = p_rarity
	effect_data = p_effect
