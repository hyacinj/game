# CardRewardView — 战后选牌（3选1）
class_name CardRewardView
extends Node2D

var reward_cards: Array[CardData] = []
var run_state: RunState
var on_close: Callable = Callable()

func _ready() -> void:
	reward_cards = CardDB.get_random_mixed(3)

func setup(rs: RunState, callback: Callable) -> void:
	run_state = rs
	on_close = callback

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-120, -280), "🎁 选择一张卡牌", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.YELLOW)
	
	for i: int in reward_cards.size():
		var card: CardData = reward_cards[i]
		var x: float = -220.0 + i * 190.0
		var y: float = -240.0
		var rect: Rect2 = Rect2(x, y, 160, 220)
		
		var bg_color: Color
		match card.rarity:
			CardData.Rarity.COMMON: bg_color = Color(0.2, 0.2, 0.3, 0.9)
			CardData.Rarity.RARE: bg_color = Color(0.2, 0.15, 0.35, 0.9)
			CardData.Rarity.EPIC: bg_color = Color(0.3, 0.15, 0.2, 0.9)
		
		draw_rect(rect, bg_color, true)
		draw_rect(rect, Color.WHITE, false)
		
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 20), card.card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		
		var type_str: String = "攻击" if card.type == CardData.CardType.ATTACK else ("效果" if card.type == CardData.CardType.EFFECT else "辅助")
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 50), "%s | 费用: %d" % [type_str, card.cost], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 75), card.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.8, 0.6))
		
		var rarity_str: String = "普通" if card.rarity == CardData.Rarity.COMMON else ("稀有" if card.rarity == CardData.Rarity.RARE else "史诗")
		draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 160), rarity_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key: int = event.keycode
		if key >= KEY_1 and key <= KEY_3:
			var idx: int = key - KEY_1
			if idx < reward_cards.size():
				_select(idx)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_global_mouse_position()
		for i: int in reward_cards.size():
			var x: float = -220.0 + i * 190.0
			var rect: Rect2 = Rect2(x, -240.0, 160, 220)
			if rect.has_point(mouse_pos):
				_select(i)
				return

func _select(index: int) -> void:
	if index < 0 or index >= reward_cards.size():
		return
	var card: CardData = reward_cards[index]
	run_state.add_card_to_deck(card)
	print("[CardReward] Selected: %s" % card.card_name)
	if on_close.is_valid():
		on_close.call()
	queue_free()
