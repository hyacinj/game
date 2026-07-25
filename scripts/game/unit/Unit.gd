extends Node2D
class_name Unit

enum Faction { PLAYER, ENEMY }
var max_hp: int = 100
var current_hp: int = 100
var faction: int = Faction.PLAYER
var unit_color: Color = Color.WHITE
var unit_radius: float = 30.0
var is_dead: bool = false

# P1: Status effects
var status_effects: Array[StatusEffect] = []

func _ready() -> void:
	current_hp = max_hp
	EventBus.on("projectile:explode", _on_explosion)
	_self_test()

func _self_test() -> void:
	# Test status effects
	TestHelper.assert_eq(status_effects.size(), 0, "Unit starts with no status effects")
	
	# Apply burn
	var burn: StatusEffect = StatusEffect.burn(3, 5)
	apply_status(burn)
	TestHelper.assert_eq(status_effects.size(), 1, "Unit has 1 status after burn applied")
	TestHelper.check(has_status(StatusEffect.Type.BURN), "Unit has burn status")
	
	# Apply freeze
	var freeze: StatusEffect = StatusEffect.freeze(2)
	apply_status(freeze)
	TestHelper.assert_eq(status_effects.size(), 2, "Unit has 2 statuses")
	TestHelper.check(has_status(StatusEffect.Type.FREEZE), "Unit has freeze status")
	
	# Stack same type (should refresh, not duplicate)
	apply_status(StatusEffect.burn(5, 10))
	TestHelper.assert_eq(status_effects.size(), 2, "Unit still has 2 statuses after refreshing burn")
	
	# Tick burn
	var hp_before: int = current_hp
	tick_statuses()
	TestHelper.assert_eq(current_hp, hp_before - 10, "Unit took burn damage on tick (wait hp=%d, got=%d)" % [hp_before - 10, current_hp])
	
	# Remove status
	remove_status(StatusEffect.Type.BURN)
	TestHelper.assert_eq(status_effects.size(), 1, "Unit has 1 status after removing burn")
	TestHelper.check(not has_status(StatusEffect.Type.BURN), "Unit no longer has burn")
	
	# Clean up
	status_effects.clear()
	current_hp = max_hp
	print("[TEST] Unit status self-test complete")

func _draw() -> void:
	draw_circle(Vector2.ZERO, unit_radius, unit_color)
	draw_arc(Vector2.ZERO, unit_radius, 0, TAU, 32, Color.BLACK, 2.0)

func take_damage(amount: int) -> bool:
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		is_dead = true
		EventBus.emit("unit:died", self)
		queue_free()
		return true
	queue_redraw()
	return false

func apply_status(effect: StatusEffect) -> void:
	# Stack or refresh existing status of same type
	for se in status_effects:
		if se.type == effect.type:
			se.duration = max(se.duration, effect.duration)
			se.damage_per_turn = max(se.damage_per_turn, effect.damage_per_turn)
			se.slow_ratio = max(se.slow_ratio, effect.slow_ratio)
			return
	status_effects.append(effect)

func has_status(type: int) -> bool:
	for se in status_effects:
		if se.type == type:
			return true
	return false

func remove_status(type: int) -> void:
	status_effects = status_effects.filter(func(se): return se.type != type)

func tick_statuses() -> void:
	if is_dead:
		return
	var expired: Array[StatusEffect] = []
	for se in status_effects:
		if se.type == StatusEffect.Type.BURN:
			take_damage(se.damage_per_turn)
			print("[Unit] Burn tick: %d damage" % se.damage_per_turn)
		se.duration -= 1
		if se.duration <= 0:
			expired.append(se)
	for se in expired:
		status_effects.erase(se)
		print("[Unit] Status expired: %d" % se.type)

func _on_explosion(data: Dictionary) -> void:
	if is_dead:
		return
	var pos: Vector2 = data.get("pos", Vector2.ZERO)
	var r: float = data.get("radius", 0.0)
	var dmg: int = data.get("damage", 0)
	var dist := global_position.distance_to(pos)
	print("[Unit] Explosion at ", pos, " dist=", dist, " r=", r, " myPos=", global_position)
	if dist <= r:
		var actual := floori(dmg * (1.0 - (dist / r) * 0.3))
		print("[Unit] Take damage: ", actual)
		take_damage(actual)
