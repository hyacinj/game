# BattleHUD — 战斗信息面板 (_draw 绘制 + 自检验证)
class_name BattleHUD
extends Node2D

var energy_system: EnergySystem = null
var card_manager: CardManager = null
var turn_manager: TurnManager = null
var wind_system: WindSystem = null
var player: Player = null
var enemies: Array[Enemy] = []
var battle_result: String = ""

## ---- 自检追踪字段 ----
var _draw_count: int = 0
var _hp_bars_drawn: int = 0
var _cards_drawn: int = 0
var _energy_dots: int = 0
var _last_card_positions: Array[Rect2] = []
var _last_wind_text: String = ""
var _last_turn_text: String = ""
var _font_ok: bool = false
var _pending_effect_text: String = ""
var _show_help: bool = true

const HP_BAR_WIDTH: float = 60.0
const HP_BAR_HEIGHT: float = 8.0
const HP_BAR_OFFSET: float = -50.0

func _ready() -> void:
	EventBus.on("energy:changed", _on_data_changed)
	EventBus.on("card:drawn", _on_data_changed)
	EventBus.on("card:used", _on_data_changed)
	EventBus.on("turn:phase_changed", _on_phase_changed)
	EventBus.on("wind:changed", _on_data_changed)
	EventBus.on("battle:ended", _on_battle_ended)
	EventBus.on("card:used", _on_card_used_hud)
	# 验证字体可用性
	_font_ok = ThemeDB.fallback_font != null
	if not _font_ok:
		print("[BattleHUD] WARNING: ThemeDB.fallback_font is null, text won't render!")
	_self_test()

func setup(es: EnergySystem, cm: CardManager, tm: TurnManager, ws: WindSystem, p: Player, e: Array[Enemy]) -> void:
	energy_system = es
	card_manager = cm
	turn_manager = tm
	wind_system = ws
	player = p
	enemies = e

func _on_data_changed(_data: Dictionary) -> void:
	queue_redraw()

func _on_phase_changed(data: Dictionary) -> void:
	# 清除待处理效果
	var phase = data.get("phase", -1)
	if phase == TurnManager.Phase.PLAYER_DRAW:
		_pending_effect_text = ""
	queue_redraw()

func _on_battle_ended(data: Dictionary) -> void:
	battle_result = data.get("result", "")
	queue_redraw()

func _on_card_used_hud(data: Dictionary) -> void:
	var card: CardData = data.get("card")
	if card:
		_pending_effect_text = card.card_name + ": " + card.description
		_show_help = false
		queue_redraw()

func _draw() -> void:
	_draw_count += 1
	_hp_bars_drawn = 0
	_cards_drawn = 0
	_energy_dots = 0
	_last_card_positions.clear()
	
	if battle_result != "":
		_draw_game_over()
		return
	
	_draw_player_hp_big()
	_draw_hp_bars()
	_draw_energy()
	_draw_pending_effect()
	_draw_help()
	_draw_wind_text()
	_draw_turn_indicator()
	_draw_hand_cards()

# ---- Player HP Big ----
func _draw_player_hp_big() -> void:
	if not is_instance_valid(player) or not _font_ok:
		return
	var hp_text: String = "❤️ %d/%d" % [player.current_hp, player.max_hp]
	var hp_ratio: float = float(player.current_hp) / float(max(player.max_hp, 1))
	var color: Color
	if hp_ratio > 0.6:
		color = Color.GREEN
	elif hp_ratio > 0.3:
		color = Color.YELLOW
	else:
		color = Color.RED
	draw_string(ThemeDB.fallback_font, Vector2(-900, -380), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
	
	# 牌组信息
	if card_manager != null:
		var deck_info: String = "🂠 牌库:%d 弃牌:%d" % [card_manager.deck.size(), card_manager.discard.size()]
		draw_string(ThemeDB.fallback_font, Vector2(-900, -355), deck_info, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.6))

func _draw_pending_effect() -> void:
	if _pending_effect_text == "" or not _font_ok:
		return
	draw_string(ThemeDB.fallback_font, Vector2(-200, -280), "⚡ " + _pending_effect_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1.0, 0.8, 0.2))

func _draw_help() -> void:
	if not _show_help or not _font_ok:
		return
	draw_string(ThemeDB.fallback_font, Vector2(-200, 120), "🖱️ 拖拽瞄准 & 松开发射 | 点击卡牌使用 | E 结束回合", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.4, 0.5, 0.6))

# ---- HP Bars ----
func _draw_hp_bars() -> void:
	if is_instance_valid(player):
		var ratio: float = float(player.current_hp) / float(max(player.max_hp, 1))
		var bar_y: float = player.global_position.y + HP_BAR_OFFSET
		var bar_x: float = player.global_position.x - HP_BAR_WIDTH / 2.0
		_draw_hp_bar(bar_x, bar_y, ratio)
		_hp_bars_drawn += 1
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var ratio: float = float(enemy.current_hp) / float(max(enemy.max_hp, 1))
			var bar_y: float = enemy.global_position.y + HP_BAR_OFFSET
			var bar_x: float = enemy.global_position.x - HP_BAR_WIDTH / 2.0
			_draw_hp_bar(bar_x, bar_y, ratio)
			_hp_bars_drawn += 1

func _draw_hp_bar(x: float, y: float, ratio: float) -> void:
	var bg: Rect2 = Rect2(x, y, HP_BAR_WIDTH, HP_BAR_HEIGHT)
	draw_rect(bg, Color(0.3, 0.3, 0.3), true)
	
	var fill_color: Color
	if ratio > 0.6:
		fill_color = Color.GREEN
	elif ratio > 0.3:
		fill_color = Color.YELLOW
	else:
		fill_color = Color.RED
	
	var fill: Rect2 = Rect2(x, y, HP_BAR_WIDTH * ratio, HP_BAR_HEIGHT)
	draw_rect(fill, fill_color, true)
	draw_rect(bg, Color.WHITE, false)

# ---- Energy ----
func _draw_energy() -> void:
	if energy_system == null:
		return
	var base: Vector2 = Vector2(-900, -300)
	for i: int in energy_system.max_energy:
		var color: Color = Color.BLUE if i < energy_system.current_energy else Color(0.2, 0.2, 0.4)
		draw_circle(base + Vector2(i * 30, 0), 10, color)
		_energy_dots += 1

# ---- Wind ----
func _draw_wind_text() -> void:
	if wind_system == null:
		return
	_last_wind_text = wind_system.get_wind_description()
	if _font_ok:
		draw_string(ThemeDB.fallback_font, Vector2(-900, -350), _last_wind_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)

# ---- Turn ----
func _draw_turn_indicator() -> void:
	if turn_manager == null:
		return
	_last_turn_text = "玩家回合" if turn_manager.is_player_phase() else "敌人回合"
	var color: Color = Color.WHITE if turn_manager.is_player_phase() else Color.RED
	if _font_ok:
		draw_string(ThemeDB.fallback_font, Vector2(-100, -350), _last_turn_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, color)
	
	if turn_manager.is_player_phase() and _font_ok:
		draw_string(ThemeDB.fallback_font, Vector2(600, 390), "[E] 结束回合", HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, Color(0.6, 0.6, 0.6))

# ---- Hand Cards ----
func _draw_hand_cards() -> void:
	if card_manager == null:
		return
	var hand: Array[CardData] = card_manager.hand
	if hand.size() == 0:
		if _font_ok:
			draw_string(ThemeDB.fallback_font, Vector2(-40, 280), "手牌为空", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.3, 0.3, 0.4))
		return
	
	# 大卡片：120x170，放在屏幕下方
	var card_w: float = 120.0
	var card_h: float = 170.0
	var spacing: float = 140.0 if hand.size() <= 5 else (110.0 if hand.size() <= 7 else 90.0)
	var total_w: float = hand.size() * spacing - (spacing - card_w)
	var start_x: float = -total_w / 2.0 + card_w / 2.0
	var y_pos: float = 200.0
	
	for i: int in hand.size():
		var card: CardData = hand[i]
		var x: float = start_x + i * spacing - card_w / 2.0
		var card_rect: Rect2 = Rect2(x, y_pos, card_w, card_h)
		_last_card_positions.append(card_rect)
		_cards_drawn += 1
		
		var can_afford: bool = energy_system != null and energy_system.can_afford(card.cost)
		
		# 底色：买得起亮，买不起暗
		var bg: Color = Color(0.1, 0.15, 0.25, 0.95) if can_afford else Color(0.08, 0.08, 0.08, 0.85)
		draw_rect(card_rect, bg, true)
		
		# 类型颜色边框
		var border: Color
		match card.type:
			CardData.CardType.ATTACK: border = Color(0.9, 0.3, 0.2)     # 红色
			CardData.CardType.EFFECT: border = Color(0.3, 0.6, 0.9)     # 蓝色
			CardData.CardType.UTILITY: border = Color(0.3, 0.8, 0.4)    # 绿色
		border.a = 0.9 if can_afford else 0.4
		draw_rect(card_rect, border, false, 3.0)
		
		# 费用圆圈
		var cost_circle: Vector2 = Vector2(x + card_w - 16, y_pos + 16)
		draw_circle(cost_circle, 14, Color.YELLOW if can_afford else Color(0.3, 0.3, 0.1))
		
		if _font_ok:
			# 卡名
			draw_string(ThemeDB.fallback_font, Vector2(x + 8, y_pos + 28), card.card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
			# 描述
			draw_string(ThemeDB.fallback_font, Vector2(x + 6, y_pos + 58), card.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.8, 0.7))
			# 费用数字
			draw_string(ThemeDB.fallback_font, Vector2(cost_circle.x - 6, cost_circle.y - 6), str(card.cost), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.BLACK)
			# 稀有度标签
			var rarity_str: String
			var rarity_color: Color
			match card.rarity:
				CardData.Rarity.COMMON: rarity_str = "普通"; rarity_color = Color(0.7, 0.7, 0.7)
				CardData.Rarity.RARE: rarity_str = "稀有"; rarity_color = Color(0.3, 0.5, 1.0)
				CardData.Rarity.EPIC: rarity_str = "史诗"; rarity_color = Color(1.0, 0.6, 0.2)
			draw_string(ThemeDB.fallback_font, Vector2(x + 6, y_pos + card_h - 20), rarity_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, rarity_color)

func _draw_game_over() -> void:
	if not _font_ok:
		return
	var text: String
	var color: Color
	if battle_result == "victory":
		text = "胜利!"
		color = Color.GREEN
	else:
		text = "失败..."
		color = Color.RED
	draw_string(ThemeDB.fallback_font, Vector2(-80, -20), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, color)

# ---- Card Click ----
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		EventBus.emit("turn:end_requested", {})
		return
	
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if card_manager == null or energy_system == null:
		return
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	for i: int in _last_card_positions.size():
		if _last_card_positions[i].has_point(mouse_pos):
			_use_card(i)
			return

func _use_card(index: int) -> void:
	if index < 0 or index >= card_manager.hand.size():
		return
	var card: CardData = card_manager.hand[index]
	if not energy_system.can_afford(card.cost):
		print("[BattleHUD] Cannot afford: %s" % card.card_name)
		return
	
	energy_system.spend(card.cost)
	card_manager.use_card(index)
	_apply_card_effect(card)

func _apply_card_effect(card: CardData) -> void:
	var effect: Dictionary = card.effect_data
	print("[BattleHUD] Applied card: %s effect=%s" % [card.card_name, effect])
	
	if effect.has("damage_bonus"):
		var launcher: ProjectileLauncher = _find_projectile_launcher()
		if launcher:
			launcher.base_damage += effect["damage_bonus"]
	if effect.has("radius_mult"):
		var launcher: ProjectileLauncher = _find_projectile_launcher()
		if launcher:
			launcher.explosion_radius *= effect["radius_mult"]

func _find_projectile_launcher() -> ProjectileLauncher:
	var parent: Node = get_parent()
	while parent:
		if parent.has_method("_self_test"):
			return parent.get("projectile_launcher")
		parent = parent.get_parent()
	return null

# ---- Self-Test: 验证 UI 状态（不检查像素，检查数据+绘制计数）----
func _self_test() -> void:
	# 1. 字体可用性
	TestHelper.check(_font_ok, "BattleHUD font available (ThemeDB.fallback_font)")
	
	# 2. 数据源绑定（可能尚未 setup，检查 null 是正常的）
	# energy_system 等在 setup() 之后可用，setup() 在 add_child 之前调用
	# 但 player/enemies 在 BattleManager 中后于 _create_subsystems 创建
	# 所以延迟验证
	
	# 3. 延迟验证（等所有节点就绪）
	call_deferred("_self_test_post_draw")

func _self_test_post_draw() -> void:
	# 数据源绑定验证
	TestHelper.check(energy_system != null, "BattleHUD.energy_system bound")
	TestHelper.check(card_manager != null, "BattleHUD.card_manager bound")
	TestHelper.check(turn_manager != null, "BattleHUD.turn_manager bound")
	TestHelper.check(wind_system != null, "BattleHUD.wind_system bound")
	TestHelper.check(player != null, "BattleHUD.player bound")
	TestHelper.check(enemies.size() > 0, "BattleHUD.enemies bound (%d enemies)" % enemies.size())
	
	# 强制触发一次 _draw
	queue_redraw()
	await get_tree().process_frame
	
	TestHelper.check(_draw_count > 0, "BattleHUD _draw() called (count=%d)" % _draw_count)
	
	var expected_bars: int = 1
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			expected_bars += 1
	TestHelper.assert_eq(_hp_bars_drawn, expected_bars, "BattleHUD HP bars (%d expected)" % expected_bars)
	
	TestHelper.check(_energy_dots > 0, "BattleHUD energy dots (%d)" % _energy_dots)
	
	if card_manager != null:
		TestHelper.assert_eq(_cards_drawn, card_manager.hand.size(), "BattleHUD cards match hand (%d)" % card_manager.hand.size())
		for rect in _last_card_positions:
			TestHelper.assert_range(rect.position.x, -1200, 1200, "Card X in viewport")
			TestHelper.assert_range(rect.position.y, -600, 600, "Card Y in viewport")
	
	TestHelper.check(_last_turn_text != "", "BattleHUD turn text (%s)" % _last_turn_text)
	TestHelper.check(_last_wind_text != "", "BattleHUD wind text (%s)" % _last_wind_text)
	
	print("[TEST] BattleHUD self-test complete")
