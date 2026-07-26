# EventView — 事件弹窗（横排卡片选择）
class_name EventView
extends Node2D

const CARD_W: float = 230.0
const CARD_H: float = 340.0
const CARD_GAP: float = 15.0
const CARD_PAD: float = 12.0

var event_manager: EventManager
var run_state: RunState
var on_close: Callable = Callable()
var _resolved: bool = false
var _result_text: String = ""
var _auto_trigger: bool = true
var _hovered_index: int = -1

func _ready() -> void:
	if _auto_trigger and event_manager != null:
		event_manager.trigger_random_event()

func setup(em: EventManager, rs: RunState, callback: Callable) -> void:
	event_manager = em
	run_state = rs
	on_close = callback

func setup_for_battle(em: EventManager, rs: RunState, callback: Callable) -> void:
	event_manager = em
	run_state = rs
	on_close = callback
	_auto_trigger = false

func _process(_delta: float) -> void:
	queue_redraw()

func _get_card_start_x(card_count: int) -> float:
	var total_w: float = CARD_W * card_count + CARD_GAP * (card_count - 1)
	return -total_w / 2.0

func _get_card_rect(index: int, card_count: int) -> Rect2:
	var start_x: float = _get_card_start_x(card_count)
	var x: float = start_x + index * (CARD_W + CARD_GAP)
	var y: float = -80.0
	return Rect2(x, y, CARD_W, CARD_H)

func _rarity_color(rarity: CardData.Rarity) -> Color:
	match rarity:
		CardData.Rarity.COMMON:
			return Color(0.65, 0.65, 0.65)
		CardData.Rarity.RARE:
			return Color(0.3, 0.5, 1.0)
		CardData.Rarity.EPIC:
			return Color(0.75, 0.35, 1.0)
		_:
			return Color(0.65, 0.65, 0.65)

func _rarity_name(rarity: CardData.Rarity) -> String:
	match rarity:
		CardData.Rarity.COMMON:
			return "普通"
		CardData.Rarity.RARE:
			return "稀有"
		CardData.Rarity.EPIC:
			return "史诗"
		_:
			return ""

func _draw() -> void:
	if event_manager == null or event_manager.current_event == null:
		return
	
	var vp_rect: Rect2 = TestHelper.get_viewport_world_rect()
	draw_rect(vp_rect, Color(0, 0, 0, 0.65), true)
	
	var event: EventData = event_manager.current_event
	var cards: Array[CardData] = event.card_options
	var card_count: int = cards.size()
	var font: Font = ThemeDB.fallback_font
	
	# 标题
	draw_string(font, Vector2(-400, -340), "❓ " + event.title, HORIZONTAL_ALIGNMENT_CENTER, -1, 64, Color(1.0, 0.8, 0.3))
	
	# 描述
	draw_string(font, Vector2(-480, -270), event.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.9, 0.9, 0.85))
	
	if _resolved:
		draw_string(font, Vector2(0, 130), _result_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color(0.5, 1.0, 0.5))
		draw_string(font, Vector2(0, 280), "点击或按任意键继续", HORIZONTAL_ALIGNMENT_CENTER, -1, 36, Color(0.5, 0.5, 0.5))
		return
	
	# 绘制卡片
	for i: int in card_count:
		var card: CardData = cards[i]
		var rect: Rect2 = _get_card_rect(i, card_count)
		var is_hovered: bool = (i == _hovered_index)
		var rcol: Color = _rarity_color(card.rarity)
		
		# 卡片背景
		var bg_color: Color = Color(0.1, 0.15, 0.22, 0.95)
		if is_hovered:
			bg_color = Color(0.18, 0.24, 0.32, 0.95)
		draw_rect(rect, bg_color, true)
		draw_rect(rect, rcol, false, 3.0)
		
		# 内边距区域
		var cx: float = rect.position.x + CARD_PAD
		var cy: float = rect.position.y + CARD_PAD
		var cw: float = rect.size.x - CARD_PAD * 2
		
		# --- 第一行：能量消耗 + 卡牌名 ---
		var cost_text: String = "⚡%d" % card.cost
		draw_string(font, Vector2(cx, cy), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.3, 0.8, 1.0))
		draw_string(font, Vector2(cx + 56, cy), card.card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		
		# --- 第二行：稀有度 + 类型 ---
		cy += 36
		var rarity_text: String = "[%s]" % _rarity_name(card.rarity)
		draw_string(font, Vector2(cx, cy), rarity_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, rcol)
		var type_text: String = "ATTACK" if card.type == CardData.CardType.ATTACK else ("EFFECT" if card.type == CardData.CardType.EFFECT else "UTILITY")
		draw_string(font, Vector2(cx + cw - 10, cy), type_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 22, Color(1.0, 0.6, 0.3))
		
		# --- 分隔线 ---
		cy += 30
		draw_line(Vector2(cx, cy), Vector2(cx + cw, cy), Color(0.3, 0.35, 0.45), 1.0)
		
		# --- 描述 ---
		cy += 12
		# 描述可能较长，需要限制宽度
		var desc_lines: Array[String] = _wrap_text(card.description, int(cw - 4), font, 22)
		for line in desc_lines:
			draw_string(font, Vector2(cx, cy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.8, 0.8, 0.75))
			cy += 24
		
		# --- 分隔线 ---
		cy += 6
		draw_line(Vector2(cx, cy), Vector2(cx + cw, cy), Color(0.3, 0.35, 0.45), 1.0)
		cy += 12
		
		# --- 属性 ---
		if card.effect_data.has("damage_bonus"):
			draw_string(font, Vector2(cx, cy), "伤害: +%d" % int(card.effect_data["damage_bonus"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.55, 0.3))
			cy += 24
		if card.effect_data.has("scatter_count"):
			draw_string(font, Vector2(cx, cy), "散射: %d" % int(card.effect_data["scatter_count"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.5, 0.8, 1.0))
			cy += 24
		if card.effect_data.has("radius_mult"):
			draw_string(font, Vector2(cx, cy), "半径: x%.1f" % float(card.effect_data["radius_mult"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.5, 1.0, 0.5))
			cy += 24
		if card.effect_data.has("spread_angle"):
			draw_string(font, Vector2(cx, cy), "散布: %.0f°" % float(card.effect_data["spread_angle"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.7, 0.4))
			cy += 24
		
		# 耐久
		var dur_text: String = "耐久: ∞" if card.durability < 0 else ("耐久: %d" % card.durability)
		draw_string(font, Vector2(cx, cy), dur_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.6, 0.6, 0.6))
		cy += 24
		
		# --- 升级预览（仅 upgrade_card 事件） ---
		if event.event_type == "upgrade_card":
			cy += 6
			draw_line(Vector2(cx, cy), Vector2(cx + cw, cy), Color(0.3, 0.45, 0.3), 1.0)
			cy += 10
		draw_string(font, Vector2(cx, cy), "── 升级预览 ──", HORIZONTAL_ALIGNMENT_CENTER, cw, 20, Color(0.5, 1.0, 0.5))
		cy += 26
		var preview: String = card.get_upgrade_preview()
		if preview != "" and preview != "无变化":
			draw_string(font, Vector2(cx, cy), preview, HORIZONTAL_ALIGNMENT_CENTER, cw, 22, Color(0.4, 1.0, 0.4))
			cy += 24
		
		# --- 底部操作提示 ---
		var hint_y: float = rect.position.y + CARD_H - 36
		if event.event_type == "upgrade_card":
			draw_string(font, Vector2(cx, hint_y), "[点击升级]", HORIZONTAL_ALIGNMENT_CENTER, cw, 24, Color(0.5, 1.0, 0.5))
		else:
			draw_string(font, Vector2(cx, hint_y), "[点击选择]", HORIZONTAL_ALIGNMENT_CENTER, cw, 24, Color(0.6, 0.7, 0.9))

## 简单文本换行（按字符宽度估算）
func _wrap_text(text: String, max_width: float, font: Font, font_size: int) -> Array[String]:
	var lines: Array[String] = []
	var current: String = ""
	for ch in text:
		var test: String = current + ch
		var size: Vector2 = font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if size.x > max_width and current.length() > 0:
			lines.append(current)
			current = ch
		else:
			current = test
	if current.length() > 0:
		lines.append(current)
	return lines

func _input(event: InputEvent) -> void:
	if _resolved:
		if event is InputEventKey and event.pressed:
			_close()
		if event is InputEventMouseButton and event.pressed:
			_close()
		return
	
	# 鼠标移动检测 hover
	if event is InputEventMouseMotion:
		_update_hover()
	
	if event is InputEventKey and event.pressed:
		var key: int = event.keycode
		if key >= KEY_1 and key <= KEY_9:
			var index: int = key - KEY_1
			if event_manager != null and event_manager.current_event != null:
				if index < event_manager.current_event.card_options.size():
					_choose(index)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event_manager == null or event_manager.current_event == null:
			return
		var mouse_pos: Vector2 = get_global_mouse_position()
		var card_count: int = event_manager.current_event.card_options.size()
		for i: int in card_count:
			var rect: Rect2 = _get_card_rect(i, card_count)
			if rect.has_point(mouse_pos):
				_choose(i)
				return

func _update_hover() -> void:
	if event_manager == null or event_manager.current_event == null:
		_hovered_index = -1
		return
	var mouse_pos: Vector2 = get_global_mouse_position()
	var card_count: int = event_manager.current_event.card_options.size()
	_hovered_index = -1
	for i: int in card_count:
		var rect: Rect2 = _get_card_rect(i, card_count)
		if rect.has_point(mouse_pos):
			_hovered_index = i
			return

func _choose(index: int) -> void:
	if _resolved:
		return
	var result: Dictionary = event_manager.resolve_card_choice(index)
	_resolved = true
	_result_text = result.get("message", "")

func _close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()
