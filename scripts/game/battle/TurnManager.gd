# TurnManager — 回合状态机
# 管理 BATTLE_START → PLAYER_TURN → ENEMY_TURN 的完整流程
class_name TurnManager
extends Node

enum Phase {
	BATTLE_START,
	PLAYER_DRAW,
	PLAYER_ACTION,
	PLAYER_END,
	ENEMY_TURN,
	BATTLE_OVER
}

var current_phase: Phase = Phase.BATTLE_START
var turn_number: int = 0
var _test_mode: bool = false

func _ready() -> void:
	EventBus.on("turn:enemy_actions_complete", _on_enemy_actions_complete)
	_self_test()

func start_battle() -> void:
	turn_number = 0
	_set_phase(Phase.BATTLE_START)
	_begin_player_turn()

func _begin_player_turn() -> void:
	turn_number += 1
	EventBus.emit("turn:player_begin", {"turn": turn_number})
	_set_phase(Phase.PLAYER_DRAW)
	EventBus.emit("turn:draw_phase")
	EventBus.emit("turn:energy_restore")
	_set_phase(Phase.PLAYER_ACTION)

func end_player_turn() -> void:
	if current_phase != Phase.PLAYER_ACTION:
		return
	_set_phase(Phase.PLAYER_END)
	EventBus.emit("turn:player_end", {"turn": turn_number})
	_begin_enemy_turn()

func _begin_enemy_turn() -> void:
	_set_phase(Phase.ENEMY_TURN)
	EventBus.emit("turn:enemy_begin", {"turn": turn_number})

func _on_enemy_actions_complete(_data: Dictionary) -> void:
	if current_phase != Phase.ENEMY_TURN:
		return
	_end_enemy_turn()

func _end_enemy_turn() -> void:
	EventBus.emit("turn:enemy_end", {"turn": turn_number})
	EventBus.emit("turn:ended", {"turn": turn_number})
	EventBus.emit("turn:tick_statuses")
	_begin_player_turn()

func end_battle(result: String) -> void:
	_set_phase(Phase.BATTLE_OVER)
	EventBus.emit("battle:ended", {"result": result})

func is_player_phase() -> bool:
	return current_phase == Phase.PLAYER_ACTION

func is_battle_over() -> bool:
	return current_phase == Phase.BATTLE_OVER

func _set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	EventBus.emit("turn:phase_changed", {"phase": current_phase, "turn": turn_number})

func _self_test() -> void:
	_test_mode = true
	TestHelper.assert_eq(current_phase, Phase.BATTLE_START, "TurnManager initial phase is BATTLE_START")
	TestHelper.assert_eq(turn_number, 0, "TurnManager initial turn is 0")
	TestHelper.check(not is_battle_over(), "TurnManager not battle over at start")
	print("[TEST] TurnManager self-test complete")
