# RelicData — 遗物数据定义 (Resource)
class_name RelicData
extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum EffectType {
	STAT_BONUS,        # 属性加成: {"stat": "max_hp", "value": 20, "is_percent": false}
	ENERGY_BONUS,      # 能量加成: {"energy": 1}
	DRAW_BONUS,        # 抽牌加成: {"cards": 1}
	DAMAGE_BONUS,      # 伤害加成: {"value": 10, "is_percent": true}
	RADIUS_BONUS,      # 爆炸范围: {"value": 20, "is_percent": true}
	STATUS_IMMUNE,     # 免疫某种状态: {"status": "burn"} 
	SHOP_DISCOUNT,     # 商店折扣: {"discount": 0.2}
	SPECIAL,           # 特殊效果: {"id": "enemy_hp_halved"}
}

@export var id: String = ""
@export var relic_name: String = ""
@export var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var effect_type: EffectType = EffectType.STAT_BONUS
@export var effect_data: Dictionary = {}
@export var max_stack: int = 1
@export var icon_path: String = ""

func _init(p_id: String = "", p_name: String = "", p_desc: String = "", p_rarity: Rarity = Rarity.COMMON, p_type: EffectType = EffectType.STAT_BONUS, p_data: Dictionary = {}, p_max_stack: int = 1) -> void:
	id = p_id
	relic_name = p_name
	description = p_desc
	rarity = p_rarity
	effect_type = p_type
	effect_data = p_data
	max_stack = p_max_stack
