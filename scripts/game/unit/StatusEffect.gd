# StatusEffect — 单位状态效果（灼烧、冰冻等）
class_name StatusEffect
extends RefCounted

enum Type { BURN, FREEZE }

var type: Type = Type.BURN
var duration: int = 0       # 剩余回合数
var damage_per_turn: int = 0   # 灼烧每回合伤害
var slow_ratio: float = 0.0    # 冰冻减速比例 (0~1)

func _init(t: Type, dur: int, dpt: int = 0, slow: float = 0.0) -> void:
	type = t
	duration = dur
	damage_per_turn = dpt
	slow_ratio = slow

## Factory: 创建灼烧效果
static func burn(duration: int = GameConfig.STATUS_DEFAULT_DURATION, dmg: int = GameConfig.BURN_DAMAGE_PER_TURN) -> StatusEffect:
	return StatusEffect.new(Type.BURN, duration, dmg, 0.0)

## Factory: 创建冰冻效果
static func freeze(duration: int = GameConfig.STATUS_DEFAULT_DURATION, slow: float = GameConfig.FREEZE_SLOW_RATIO) -> StatusEffect:
	return StatusEffect.new(Type.FREEZE, duration, 0, slow)
