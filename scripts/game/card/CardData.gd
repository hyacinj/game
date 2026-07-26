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
@export var durability: int = -1  # 耐久：-1=无限∞, 0=损坏, >0=剩余使用次数
@export var upgraded: bool = false

func _init(p_id: String = "", p_name: String = "", p_desc: String = "", p_type: CardType = CardType.ATTACK, p_cost: int = 1, p_rarity: Rarity = Rarity.COMMON, p_effect: Dictionary = {}, p_durability: int = -1) -> void:
	id = p_id
	card_name = p_name
	description = p_desc
	type = p_type
	cost = p_cost
	rarity = p_rarity
	effect_data = p_effect
	durability = p_durability

## 对卡片进行升级
func apply_upgrade() -> void:
	upgraded = true
	# 首选增强已有属性
	if effect_data.has("damage_bonus"):
		effect_data["damage_bonus"] = int(effect_data["damage_bonus"]) + 5
	elif effect_data.has("scatter_count"):
		effect_data["scatter_count"] = int(effect_data["scatter_count"]) + 1
	elif effect_data.has("radius_mult"):
		effect_data["radius_mult"] = float(effect_data["radius_mult"]) + 0.2
	elif durability > 0:
		durability += 2
	else:
		# 无特殊属性的卡牌，添加伤害加成
		effect_data["damage_bonus"] = 5

## 获取升级预览文本
func get_upgrade_preview() -> String:
	var previews: Array[String] = []
	
	if effect_data.has("damage_bonus"):
		var cur: int = int(effect_data["damage_bonus"])
		previews.append("伤害 +%d → +%d" % [cur, cur + 5])
	elif not effect_data.has("scatter_count") and not effect_data.has("radius_mult") and durability <= 0:
		previews.append("伤害 0 → +5")
	
	if effect_data.has("scatter_count"):
		var cur: int = int(effect_data["scatter_count"])
		previews.append("散射 %d → %d" % [cur, cur + 1])
	
	if effect_data.has("radius_mult"):
		var cur: float = float(effect_data["radius_mult"])
		previews.append("半径 x%.1f → x%.1f" % [cur, cur + 0.2])
	
	if durability > 0:
		previews.append("耐久 %d → %d" % [durability, durability + 2])
	
	if previews.is_empty():
		return "无变化"
	return ", ".join(previews)
