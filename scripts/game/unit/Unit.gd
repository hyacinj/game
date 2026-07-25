extends Node2D
class_name Unit

enum Faction { PLAYER, ENEMY }
var max_hp: int = 100
var current_hp: int = 100
var faction: int = Faction.PLAYER
var unit_color: Color = Color.WHITE
var unit_radius: float = 30.0
var is_dead: bool = false

func _ready() -> void:
	current_hp = max_hp
	EventBus.on("projectile:explode", _on_explosion)

func _draw() -> void:
	draw_circle(Vector2.ZERO, unit_radius, unit_color)
	draw_arc(Vector2.ZERO, unit_radius, 0, TAU, 32, Color.BLACK, 2.0)

func take_damage(amount: int) -> bool:
	current_hp -= amount
	if current_hp <= 0: current_hp = 0; is_dead = true; EventBus.emit("unit:died", self); queue_free(); return true
	queue_redraw(); return false

func _on_explosion(data: Dictionary) -> void:
	if is_dead: return
	var pos: Vector2 = data.get("pos", Vector2.ZERO)
	var r: float = data.get("radius", 0.0)
	var dmg: int = data.get("damage", 0)
	var dist := global_position.distance_to(pos)
	if dist <= r: take_damage(floori(dmg * (1.0 - (dist / r) * 0.3)))
