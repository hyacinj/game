extends StaticBody2D
class_name TerrainBlock

var hp: int = GameConfig.BLOCK_HP
var max_hp: int = GameConfig.BLOCK_HP

func _ready() -> void:
	max_hp = hp
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(GameConfig.BLOCK_SIZE, GameConfig.BLOCK_SIZE)
	col.shape = rect; add_child(col); queue_redraw()

func _draw() -> void:
	var ratio := float(hp) / float(max_hp)
	var half := GameConfig.BLOCK_SIZE / 2.0
	var c := Color(0.3 + ratio * 0.4, 0.2 + ratio * 0.3, 0.1 + ratio * 0.2)
	draw_rect(Rect2(-half, -half, GameConfig.BLOCK_SIZE, GameConfig.BLOCK_SIZE), c)
	draw_rect(Rect2(-half, -half, GameConfig.BLOCK_SIZE, GameConfig.BLOCK_SIZE), Color.WHITE, false, 1.0)

func take_damage(amount: int) -> bool:
	hp -= amount
	if hp <= 0: queue_free(); return true
	queue_redraw(); return false
