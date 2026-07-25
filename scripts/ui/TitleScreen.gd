# TitleScreen — 标题画面（_draw 绘制）
class_name TitleScreen
extends Node2D

var start_game_callback: Callable = Callable()
var _pulse: float = 0.0
var _auto_start_timer: float = 0.0
var _test_mode: bool = false

func _ready() -> void:
	print("[TitleScreen] Showing...")
	_test_mode = DisplayServer.get_name() == "headless"

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()
	# 测试模式：0.5 秒后自动开始
	if _test_mode:
		_auto_start_timer += delta
		if _auto_start_timer > 0.5 and start_game_callback.is_valid():
			start_game_callback.call()
			queue_free()

func _draw() -> void:
	# 标题
	draw_string(ThemeDB.fallback_font, Vector2(-200, -80), "抛物线炮兵", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.GREEN)
	draw_string(ThemeDB.fallback_font, Vector2(-200, -30), "Roguelike Card Artillery", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.5, 0.8, 0.5))
	
	# 闪烁提示
	var alpha: float = 0.5 + 0.5 * sin(_pulse * 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-200, 100), "点击任意位置开始游戏", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 1, 1, alpha))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if start_game_callback.is_valid():
			start_game_callback.call()
			queue_free()
	if event is InputEventKey and event.pressed:
		if start_game_callback.is_valid():
			start_game_callback.call()
			queue_free()
