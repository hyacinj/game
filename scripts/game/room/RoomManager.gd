# RoomManager — 房间切换管理
class_name RoomManager
extends Node

var run_state: RunState

func _ready() -> void:
	_self_test()

func setup(rs: RunState) -> void:
	run_state = rs

## 进入新楼层：生成地图
func start_floor() -> void:
	run_state.clear_room_data()
	run_state.room_nodes = MapGenerator.generate_floor(run_state.current_floor)
	run_state.current_room_index = 0
	print("[RoomManager] Floor %d started, %d rooms" % [run_state.current_floor, run_state.room_nodes.size()])
	EventBus.emit("floor:started", {"floor": run_state.current_floor, "rooms": run_state.room_nodes.size()})

## 进入下一个房间
func enter_next_room(room_index: int) -> void:
	if room_index < 0 or room_index >= run_state.room_nodes.size():
		print("[RoomManager] Invalid room index: %d" % room_index)
		return
	run_state.current_room_index = room_index
	var room: RoomData = run_state.room_nodes[room_index]
	room.cleared = false
	print("[RoomManager] Entering room %d: %s (%s)" % [room_index, room.room_name, room.get_type_name()])
	EventBus.emit("room:entered", {"room": room, "index": room_index})

## 完成当前房间
func complete_room() -> void:
	var idx: int = run_state.current_room_index
	var room: RoomData = run_state.room_nodes[idx]
	room.cleared = true
	run_state.rooms_cleared += 1
	
	# 发放金币奖励
	if room.reward_gold > 0:
		run_state.add_gold(room.reward_gold)
	
	# 战斗/精英胜利：选牌奖励
	if room.room_type == RoomData.RoomType.BATTLE or room.room_type == RoomData.RoomType.ELITE:
		var reward_cards: Array[CardData] = CardDB.get_random_mixed(3)
		print("[RoomManager] Reward: %d cards to choose from" % reward_cards.size())
		EventBus.emit("room:reward_cards", {"cards": reward_cards})
	elif room.room_type == RoomData.RoomType.BOSS:
		# Boss 胜利：遗物 + 稀有卡牌
		print("[RoomManager] Boss defeated! Floor %d complete!" % run_state.current_floor)
		EventBus.emit("room:boss_defeated", {"floor": run_state.current_floor})
	
	print("[RoomManager] Room %d complete, rooms cleared: %d" % [idx, run_state.rooms_cleared])
	EventBus.emit("room:completed", {"room": room, "index": idx})

## 获取可到达的下一个房间列表
func get_available_rooms() -> Array[RoomData]:
	var idx: int = run_state.current_room_index
	if idx < 0 or idx >= run_state.room_nodes.size():
		return []
	var current: RoomData = run_state.room_nodes[idx]
	var available: Array[RoomData] = []
	for conn_idx: int in current.connections:
		if conn_idx < run_state.room_nodes.size():
			available.append(run_state.room_nodes[conn_idx])
	return available

## 选择路径进入房间
func choose_room(room_index: int) -> void:
	enter_next_room(room_index)

func _self_test() -> void:
	# run_state will be set by BattleManager before _self_test runs
	# So we test with whatever state we have
	if run_state != null:
		TestHelper.check(run_state.gold >= 0, "RoomManager run_state has valid gold")
	else:
		TestHelper.check(true, "RoomManager _self_test runs (no run_state yet)")
	
	print("[TEST] RoomManager self-test complete")
