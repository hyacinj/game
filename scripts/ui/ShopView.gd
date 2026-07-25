# ShopView — 商店面板（_draw 绘制 + 点击交互）
class_name ShopView
extends Node2D

var shop_manager: ShopManager
var run_state: RunState
var on_close: Callable = Callable()

func _ready() -> void:
	shop_manager.generate_shop()

func setup(sm: ShopManager, rs: RunState, callback: Callable) -> void:
	shop_manager = sm
	run_state = rs
	on_close = callback

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-120, -300), "🛒 商 店", HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color.YELLOW)
	draw_string(ThemeDB.fallback_font, Vector2(200, -300), "金币: %d" % run_state.gold, HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, Color.YELLOW)
	
	# 卡牌
	draw_string(ThemeDB.fallback_font, Vector2(-300, -260), "卡牌:", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	for i: int in shop_manager.cards_for_sale.size():
		var card: CardData = shop_manager.cards_for_sale[i]
		var x: float = -300.0 + i * 180.0
		var y: float = -240.0
		var rect: Rect2 = Rect2(x, y, 150, 100)
		var price: int = shop_manager.get_card_price(card)
		var affordable: bool = run_state.gold >= price
		draw_rect(rect, Color(0.15, 0.15, 0.25, 0.9), true)
		draw_rect(rect, Color.WHITE if affordable else Color(0.4, 0.4, 0.4), false)
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 20), card.card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 45), card.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 75), "%dg" % price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GREEN if affordable else Color.RED)
	
	# 遗物
	draw_string(ThemeDB.fallback_font, Vector2(-300, -120), "遗物:", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	for i: int in shop_manager.relics_for_sale.size():
		var relic: RelicData = shop_manager.relics_for_sale[i]
		var x: float = -300.0 + i * 200.0
		var y: float = -100.0
		var rect: Rect2 = Rect2(x, y, 170, 80)
		var price: int = shop_manager.get_relic_price(relic)
		var affordable: bool = run_state.gold >= price
		draw_rect(rect, Color(0.15, 0.15, 0.25, 0.9), true)
		draw_rect(rect, Color.WHITE if affordable else Color(0.4, 0.4, 0.4), false)
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 20), relic.relic_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 40), relic.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 60), "%dg" % price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GREEN if affordable else Color.RED)
	
	# 提示
	draw_string(ThemeDB.fallback_font, Vector2(0, 200), "点击物品购买 | 按空格离开", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.5))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_close()
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	# 检查卡牌点击
	for i: int in shop_manager.cards_for_sale.size():
		var x: float = -300.0 + i * 180.0
		var rect: Rect2 = Rect2(x, -240.0, 150, 100)
		if rect.has_point(mouse_pos):
			shop_manager.buy_card(i)
			return
	
	# 检查遗物点击
	for i: int in shop_manager.relics_for_sale.size():
		var x: float = -300.0 + i * 200.0
		var rect: Rect2 = Rect2(x, -100.0, 170, 80)
		if rect.has_point(mouse_pos):
			shop_manager.buy_relic(i)
			return

func _close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()
