# RestView — 休息画面
class_name RestView
extends Node2D

var run_state: RunState
var on_close: Callable = Callable()
var _heal_amount: int = 0

func _ready() -> void:
	_heal_amount = int(run_state.player_max_hp * 0.3)
	run_state.heal_player(_heal_amount)

func setup(rs: RunState, callback: Callable) -> void:
	run_state = rs
	on_close = callback

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-80, -80), "🏕️ 休息点", HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color(0.3, 0.8, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(-120, -20), "恢复了 %d HP" % _heal_amount, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.GREEN)
	draw_string(ThemeDB.fallback_font, Vector2(-120, 20), "当前 HP: %d/%d" % [run_state.player_current_hp, run_state.player_max_hp], HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(0, 100), "按任意键继续", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.5))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_close()
	if event is InputEventMouseButton and event.pressed:
		_close()

func _close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()
