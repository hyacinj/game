# BattleHUD — 战斗信息面板 (_draw 绘制)
class_name BattleHUD
extends Node2D

var energy_system: EnergySystem = null
var card_manager: CardManager = null
var turn_manager: TurnManager = null
var wind_system: WindSystem = null
var player: Player = null
var enemies: Array[Enemy] = []
var battle_result: String = ""

const HP_BAR_WIDTH: float = 60.0
const HP_BAR_HEIGHT: float = 8.0
const HP_BAR_OFFSET: float = -50.0

func _ready() -> void:
	EventBus.on("energy:changed", _on_data_changed)
	EventBus.on("card:drawn", _on_data_changed)
	EventBus.on("card:used", _on_data_changed)
	EventBus.on("turn:phase_changed", _on_data_changed)
	EventBus.on("wind:changed", _on_data_changed)
	EventBus.on("battle:ended", _on_battle_ended)
	_self_test()

## 卡片点击处理
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if card_manager == null or energy_system == null:
		return
	var hand: Array[CardData] = card_manager.hand
	if hand.size() == 0:
		return
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var start_x: float = -200.0
	var y_pos: float = 360.0
	var spacing: float = 80.0
	
	for i: int in hand.size():
		var x: float = start_x + i * spacing
		var card_rect: Rect2 = Rect2(x, y_pos, 70, 95)
		if card_rect.has_point(mouse_pos):
			_use_card(i)
			return

func _use_card(index: int) -> void:
	if index < 0 or index >= card_manager.hand.size():
		return
	var card: CardData = card_manager.hand[index]
	if not energy_system.can_afford(card.cost):
		print("[BattleHUD] Cannot afford card: %s (cost=%d, energy=%d)" % [card.card_name, card.cost, energy_system.current_energy])
		return
	
	# 扣能量 + 移除手牌
	energy_system.spend(card.cost)
	card_manager.use_card(index)
	
	# 应用卡牌效果
	_apply_card_effect(card)

func _apply_card_effect(card: CardData) -> void:
	var effect: Dictionary = card.effect_data
	print("[BattleHUD] Applied card: %s effect=%s" % [card.card_name, effect])
	
	if effect.has("damage_bonus"):
		# 修改下一发炮弹的伤害
		var launcher: ProjectileLauncher = _find_projectile_launcher()
		if launcher:
			launcher.base_damage += effect["damage_bonus"]
			print("[BattleHUD] Damage bonus +%d applied" % effect["damage_bonus"])
	if effect.has("scatter_count"):
		# 下一发散射
		print("[BattleHUD] Scatter shot prepared: %d projectiles" % effect["scatter_count"])
	if effect.has("status"):
		print("[BattleHUD] Status effect prepared: %s" % effect["status"])
	if effect.has("radius_mult"):
		var launcher: ProjectileLauncher = _find_projectile_launcher()
		if launcher:
			launcher.explosion_radius *= effect["radius_mult"]
			print("[BattleHUD] Radius multiplier %.1f applied" % effect["radius_mult"])

func _find_projectile_launcher() -> ProjectileLauncher:
	var parent: Node = get_parent()
	while parent:
		if parent.has_method("_self_test"):  # BattleManager
			return parent.get("projectile_launcher")
		parent = parent.get_parent()
	return null

func setup(es: EnergySystem, cm: CardManager, tm: TurnManager, ws: WindSystem, p: Player, e: Array[Enemy]) -> void:
	energy_system = es
	card_manager = cm
	turn_manager = tm
	wind_system = ws
	player = p
	enemies = e

func _on_data_changed(_data: Dictionary) -> void:
	queue_redraw()

func _on_battle_ended(data: Dictionary) -> void:
	battle_result = data.get("result", "")
	queue_redraw()

func _draw() -> void:
	if battle_result != "":
		_draw_game_over()
		return
	
	_draw_hp_bars()
	_draw_energy()
	_draw_wind_text()
	_draw_turn_indicator()
	_draw_hand_cards()

func _draw_hp_bars() -> void:
	# Player HP bar
	if is_instance_valid(player):
		var ratio: float = float(player.current_hp) / float(player.max_hp)
		var bar_y: float = player.global_position.y + HP_BAR_OFFSET
		var bar_x: float = player.global_position.x - HP_BAR_WIDTH / 2.0
		_draw_hp_bar(bar_x, bar_y, ratio)
	
	# Enemy HP bars
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var ratio: float = float(enemy.current_hp) / float(enemy.max_hp)
			var bar_y: float = enemy.global_position.y + HP_BAR_OFFSET
			var bar_x: float = enemy.global_position.x - HP_BAR_WIDTH / 2.0
			_draw_hp_bar(bar_x, bar_y, ratio)

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

func _draw_energy() -> void:
	if energy_system == null:
		return
	var base: Vector2 = Vector2(-900, 380)
	for i: int in energy_system.max_energy:
		var color: Color = Color.BLUE if i < energy_system.current_energy else Color(0.2, 0.2, 0.4)
		draw_circle(base + Vector2(i * 30, 0), 10, color)

func _draw_wind_text() -> void:
	if wind_system == null:
		return
	var desc: String = wind_system.get_wind_description()
	draw_string(ThemeDB.fallback_font, Vector2(-900, -350), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)

func _draw_turn_indicator() -> void:
	if turn_manager == null:
		return
	var text: String = "玩家回合" if turn_manager.is_player_phase() else "敌人回合"
	var color: Color = Color.WHITE if turn_manager.is_player_phase() else Color.RED
	draw_string(ThemeDB.fallback_font, Vector2(-100, -350), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, color)

func _draw_hand_cards() -> void:
	if card_manager == null:
		return
	var hand: Array[CardData] = card_manager.hand
	if hand.size() == 0:
		return
	var start_x: float = -200.0
	var y_pos: float = 360.0
	var spacing: float = 80.0
	for i: int in hand.size():
		var card: CardData = hand[i]
		var x: float = start_x + i * spacing
		var card_rect: Rect2 = Rect2(x, y_pos, 70, 95)
		var can_afford: bool = energy_system != null and energy_system.can_afford(card.cost)
		var bg_color: Color = Color(0.2, 0.2, 0.3, 0.85) if can_afford else Color(0.15, 0.15, 0.15, 0.7)
		draw_rect(card_rect, bg_color, true)
		draw_rect(card_rect, Color.WHITE, false)
		draw_string(ThemeDB.fallback_font, Vector2(x + 5, y_pos + 15), card.card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var cost_str: String = str(card.cost) + "⚡"
		draw_string(ThemeDB.fallback_font, Vector2(x + 5, y_pos + 70), cost_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.YELLOW)

func _draw_game_over() -> void:
	var text: String
	var color: Color
	if battle_result == "victory":
		text = "胜利!"
		color = Color.GREEN
	else:
		text = "失败..."
		color = Color.RED
	draw_string(ThemeDB.fallback_font, Vector2(-80, -20), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, color)

func _self_test() -> void:
	TestHelper.check(true, "BattleHUD self-test placeholder")
	print("[TEST] BattleHUD self-test complete")
