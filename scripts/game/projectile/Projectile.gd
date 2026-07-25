extends RigidBody2D
class_name Projectile

var damage: int = GameConfig.BASE_DAMAGE
var explosion_radius: float = GameConfig.EXPLOSION_RADIUS
var has_exploded: bool = false

func _ready() -> void:
	gravity_scale = 1.0; linear_damp = 0.1
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameConfig.PROJECTILE_RADIUS
	col.shape = circle; add_child(col)
	body_entered.connect(_on_hit)
	print("[Proj] Ready at: ", global_position)
	await get_tree().create_timer(10.0).timeout
	if not has_exploded: print("[Proj] Timeout — no collision!"); _explode()

func _draw() -> void:
	draw_circle(Vector2.ZERO, GameConfig.PROJECTILE_RADIUS, Color.BLACK)

func launch(velocity: Vector2) -> void:
	linear_velocity = velocity

func _on_hit(_body: Node) -> void:
	if has_exploded: return
	print("[Proj] Hit body: ", _body.name, " at ", global_position)
	_explode()

func _explode() -> void:
	has_exploded = true
	print("[Proj] Explode at: ", global_position)
	EventBus.emit("projectile:explode", {"pos": global_position, "radius": explosion_radius, "damage": damage})
	queue_free()
