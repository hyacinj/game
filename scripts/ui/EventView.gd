# EventView — 事件面板（_draw 绘制 + 点击选择）
class_name EventView
extends Node2D

var event_manager: EventManager
var run_state: RunState
var on_close: Callable = Callable()
var _resolved: bool = false
var _result_text: String = ""

func _ready() -> void:
	event_manager.trigger_random_event()

func setup(em: EventManager, rs: RunState, callback: Callable) -> void:
	event_manager = em
	run_state = rs
	on_close = callback

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if event_manager.current_event == null:
		return
	
	var event: EventData = event_manager.current_event
	
	draw_string(ThemeDB.fallback_font, Vector2(-200, -250), "❓ " + event.title, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1.0, 0.8, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(-300, -200), event.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	if _resolved:
		draw_string(ThemeDB.fallback_font, Vector2(0, 0), _result_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.5, 1.0, 0.5))
		draw_string(ThemeDB.fallback_font, Vector2(0, 150), "按任意键继续", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.5))
		return
	
	# 选项
	for i: int in event.options.size():
		var opt: Dictionary = event.options[i]
		var y: float = -100.0 + i * 60.0
		var rect: Rect2 = Rect2(-280, y, 560, 50)
		draw_rect(rect, Color(0.15, 0.2, 0.3, 0.8), true)
		draw_rect(rect, Color(0.4, 0.6, 0.8), false)
		draw_string(ThemeDB.fallback_font, Vector2(-260, y + 15), "%d. %s" % [i + 1, opt.get("text", "")], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _input(event: InputEvent) -> void:
	if _resolved:
		if event is InputEventKey and event.pressed:
			_close()
		if event is InputEventMouseButton and event.pressed:
			_close()
		return
	
	if event is InputEventKey and event.pressed:
		var key: int = event.keycode
		if key >= KEY_1 and key <= KEY_3:
			_choose(key - KEY_1)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_global_mouse_position()
		for i: int in event_manager.current_event.options.size():
			var y: float = -100.0 + i * 60.0
			var rect: Rect2 = Rect2(-280, y, 560, 50)
			if rect.has_point(mouse_pos):
				_choose(i)
				return

func _choose(index: int) -> void:
	if _resolved:
		return
	var result: Dictionary = event_manager.resolve_choice(index)
	_resolved = true
	_result_text = result.get("message", "")

func _close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()
