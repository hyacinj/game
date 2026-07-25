# EnergySystem — 能量管理
# 每回合恢复能量，使用卡牌消耗能量
class_name EnergySystem
extends Node

var current_energy: int = GameConfig.STARTING_ENERGY
var max_energy: int = GameConfig.MAX_ENERGY

func _ready() -> void:
	EventBus.on("turn:energy_restore", _on_energy_restore)
	_self_test()

## 检查是否付得起
func can_afford(cost: int) -> bool:
	return current_energy >= cost

## 花费能量，成功返回 true
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	current_energy -= cost
	EventBus.emit("energy:changed", {"current": current_energy, "max": max_energy})
	return true

## 恢复至满
func restore() -> void:
	current_energy = max_energy
	EventBus.emit("energy:changed", {"current": current_energy, "max": max_energy})

## 增加最大能量（遗物/卡牌效果）
func increase_max(amount: int) -> void:
	max_energy += amount
	current_energy = max_energy
	EventBus.emit("energy:changed", {"current": current_energy, "max": max_energy})

## 临时获得能量
func gain(amount: int) -> void:
	current_energy = min(current_energy + amount, max_energy + 5)  # 允许临时超过上限
	EventBus.emit("energy:changed", {"current": current_energy, "max": max_energy})

func _on_energy_restore(_data: Dictionary) -> void:
	restore()
	print("[Energy] Restored to %d/%d" % [current_energy, max_energy])

func _self_test() -> void:
	# Initial state
	TestHelper.assert_eq(current_energy, GameConfig.STARTING_ENERGY, "EnergySystem initial energy")
	TestHelper.assert_eq(max_energy, GameConfig.MAX_ENERGY, "EnergySystem max energy")
	
	# Can afford
	TestHelper.check(can_afford(1), "EnergySystem can afford 1")
	TestHelper.check(can_afford(3), "EnergySystem can afford 3")
	TestHelper.check(not can_afford(4), "EnergySystem cannot afford 4")
	
	# Spend
	TestHelper.check(spend(2), "EnergySystem spend 2")
	TestHelper.assert_eq(current_energy, 1, "EnergySystem energy after spend (got=%d, want=1)" % current_energy)
	TestHelper.check(not spend(2), "EnergySystem cannot overspend")
	
	# Gain
	gain(2)
	TestHelper.assert_eq(current_energy, 3, "EnergySystem energy after gain")
	
	# Restore
	restore()
	TestHelper.assert_eq(current_energy, max_energy, "EnergySystem restore to max")
	
	# Increase max
	var old_max: int = max_energy
	increase_max(1)
	TestHelper.assert_eq(max_energy, old_max + 1, "EnergySystem max increased")
	TestHelper.assert_eq(current_energy, max_energy, "EnergySystem full after max increase")
	
	# Reset
	max_energy = GameConfig.MAX_ENERGY
	current_energy = max_energy
	
	print("[TEST] EnergySystem self-test complete")
