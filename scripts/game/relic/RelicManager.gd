# RelicManager — 遗物管理（全局被动效果）
class_name RelicManager
extends Node

var relics: Array[RelicData] = []
var _test_mode: bool = false

func _ready() -> void:
	EventBus.on("battle:started", _on_battle_started)
	EventBus.on("turn:player_begin", _on_player_turn)
	_self_test()

## 添加遗物
func add_relic(relic: RelicData) -> void:
	# Check stack limit
	var count: int = 0
	for r in relics:
		if r.id == relic.id:
			count += 1
	if count >= relic.max_stack:
		print("[RelicManager] Max stack reached for %s (%d/%d)" % [relic.relic_name, count, relic.max_stack])
		return
	relics.append(relic.duplicate())
	EventBus.emit("relic:added", {"relic": relic})
	print("[RelicManager] Added relic: %s (total: %d)" % [relic.relic_name, relics.size()])

## 是否拥有某遗物
func has_relic(relic_id: String) -> bool:
	for r in relics:
		if r.id == relic_id:
			return true
	return false

## 获取遗物数量
func get_relic_count(relic_id: String) -> int:
	var count: int = 0
	for r in relics:
		if r.id == relic_id:
			count += 1
	return count

## 获取属性加成倍率（考虑所有遗物叠加）
func get_stat_multiplier(stat: String) -> float:
	var multiplier: float = 1.0
	for r in relics:
		if r.effect_type == RelicData.EffectType.STAT_BONUS:
			var data: Dictionary = r.effect_data
			if data.get("stat", "") == stat:
				var value: float = float(data.get("value", 0))
				if data.get("is_percent", false):
					multiplier += value / 100.0
				else:
					multiplier += value / 100.0  # Treat as % for simplicity
	return multiplier

## 获取整数加成
func get_stat_bonus(stat: String) -> int:
	var bonus: int = 0
	for r in relics:
		if r.effect_type == RelicData.EffectType.STAT_BONUS:
			var data: Dictionary = r.effect_data
			if data.get("stat", "") == stat and not data.get("is_percent", false):
				bonus += int(data.get("value", 0))
	return bonus

## 获取伤害加成倍率
func get_damage_multiplier() -> float:
	var mult: float = 1.0
	for r in relics:
		if r.effect_type == RelicData.EffectType.DAMAGE_BONUS:
			var data: Dictionary = r.effect_data
			var value: float = float(data.get("value", 0))
			if data.get("is_percent", false):
				mult += value / 100.0
			else:
				mult += value / 100.0
	return mult

## 获取爆炸范围加成倍率
func get_radius_multiplier() -> float:
	var mult: float = 1.0
	for r in relics:
		if r.effect_type == RelicData.EffectType.RADIUS_BONUS:
			var data: Dictionary = r.effect_data
			var value: float = float(data.get("value", 0))
			mult += value / 100.0
	return mult

## 获取额外能量
func get_energy_bonus() -> int:
	var bonus: int = 0
	for r in relics:
		if r.effect_type == RelicData.EffectType.ENERGY_BONUS:
			bonus += int(r.effect_data.get("energy", 0))
	return bonus

## 免疫某状态
func is_immune_to(status: String) -> bool:
	for r in relics:
		if r.effect_type == RelicData.EffectType.STATUS_IMMUNE:
			if r.effect_data.get("status", "") == status:
				return true
	return false

# ---- Event Handlers ----
func _on_battle_started(_data: Dictionary) -> void:
	print("[RelicManager] Battle started, relics: %d" % relics.size())

func _on_player_turn(_data: Dictionary) -> void:
	# Trigger on-turn-start effects (like extra energy)
	pass

# ---- Self-Test ----
func _self_test() -> void:
	_test_mode = true
	
	# Create test relics
	var hp_relic: RelicData = RelicData.new("hp_up", "生命提升", "最大 HP +20%", RelicData.Rarity.COMMON, RelicData.EffectType.STAT_BONUS, {"stat": "max_hp", "value": 20, "is_percent": true})
	var damage_relic: RelicData = RelicData.new("dmg_up", "伤害提升", "伤害 +15%", RelicData.Rarity.RARE, RelicData.EffectType.DAMAGE_BONUS, {"value": 15, "is_percent": true})
	var energy_relic: RelicData = RelicData.new("energy_up", "能量之源", "每回额外+1能量", RelicData.Rarity.EPIC, RelicData.EffectType.ENERGY_BONUS, {"energy": 1})
	
	# Test add
	add_relic(hp_relic)
	TestHelper.assert_eq(relics.size(), 1, "RelicManager has 1 relic")
	TestHelper.check(has_relic("hp_up"), "RelicManager has hp_up relic")
	
	add_relic(damage_relic)
	TestHelper.assert_eq(relics.size(), 2, "RelicManager has 2 relics")
	
	# Test stacking (hp_relic max_stack=1, should not add duplicate)
	add_relic(hp_relic)
	TestHelper.assert_eq(get_relic_count("hp_up"), 1, "RelicManager non-stackable relic count=1")
	
	# Test stat queries
	var hp_mult: float = get_stat_multiplier("max_hp")
	TestHelper.assert_range(hp_mult, 1.19, 1.21, "RelicManager hp multiplier ~1.2")
	
	var dmg_mult: float = get_damage_multiplier()
	TestHelper.assert_range(dmg_mult, 1.14, 1.16, "RelicManager damage multiplier ~1.15")
	
	var energy_bonus: int = get_energy_bonus()
	TestHelper.assert_eq(energy_bonus, 0, "RelicManager energy bonus = 0 (no energy relic yet)")
	
	# Add energy relic
	add_relic(energy_relic)
	energy_bonus = get_energy_bonus()
	TestHelper.assert_eq(energy_bonus, 1, "RelicManager energy bonus = 1 after adding energy relic")
	
	# Test immune
	TestHelper.check(not is_immune_to("burn"), "RelicManager not immune to burn by default")
	
	var immune_relic: RelicData = RelicData.new("immunity", "防火服", "免疫灼烧", RelicData.Rarity.RARE, RelicData.EffectType.STATUS_IMMUNE, {"status": "burn"})
	add_relic(immune_relic)
	TestHelper.check(is_immune_to("burn"), "RelicManager immune to burn after relic")
	
	# Clean up
	relics.clear()
	
	print("[TEST] RelicManager self-test complete")
