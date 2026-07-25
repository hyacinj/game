# MapGenerator — 肉鸽地图生成器
class_name MapGenerator
extends RefCounted

## 每层房间数范围
const MIN_ROOMS_PER_LAYER: int = 3
const MAX_ROOMS_PER_LAYER: int = 4
## 楼层数
const LAYER_COUNT: int = 3

## 生成完整楼层地图
static func generate_floor(floor_number: int) -> Array[RoomData]:
	var rooms: Array[RoomData] = []
	
	# 第0层：起点
	rooms.append(RoomData.new("start", RoomData.RoomType.START, "起点", [], 0, [1]))
	
	var room_counter: int = 1
	for layer: int in range(1, LAYER_COUNT + 1):
		var rooms_in_layer: int = randi_range(MIN_ROOMS_PER_LAYER, MAX_ROOMS_PER_LAYER)
		var layer_start: int = room_counter
		
		for _j: int in rooms_in_layer:
			var room: RoomData
			if layer == LAYER_COUNT:
				# 最后一层固定 Boss
				room = _create_boss_room(floor_number)
			else:
				room = _create_random_room(floor_number)
			room.id = "room_%d_%d" % [layer, room_counter - layer_start]
			rooms.append(room)
			room_counter += 1
		
			# 连接：保证每个房间可达下一层
			# For now, just set connections as consecutive indices
		for i: int in range(layer_start, room_counter):
			rooms[i].connections.clear()
			# Connect to next layer or mark as endpoint
			if layer < LAYER_COUNT:
				var next_start: int = room_counter
				# Will be updated after generating next layer
				rooms[i].connections.append(next_start)  # placeholder
	
	# Set proper connections (simplified: each room connects to all rooms in next layer)
	# Re-index: for each non-terminal room, connect to all rooms in next layer
	var layer_boundaries: Array[int] = [0, 1]  # room indices where each layer starts
	room_counter = 1
	for layer: int in range(1, LAYER_COUNT + 1):
		var rooms_in_layer: int = randi_range(MIN_ROOMS_PER_LAYER, MAX_ROOMS_PER_LAYER)
		layer_boundaries.append(room_counter)
		room_counter += rooms_in_layer
	# Fix connections properly
	for i: int in rooms.size():
		if rooms[i].room_type == RoomData.RoomType.BOSS or rooms[i].room_type == RoomData.RoomType.START:
			continue
		# Find next layer
		var next_layer_idx: int = -1
		for l: int in range(1, layer_boundaries.size()):
			if i >= layer_boundaries[l] and (l + 1 >= layer_boundaries.size() or i < layer_boundaries[l + 1]):
				next_layer_idx = l + 1
				break
		if next_layer_idx > 0 and next_layer_idx < layer_boundaries.size():
			var start_idx: int = layer_boundaries[next_layer_idx]
			var end_idx: int = rooms.size() if next_layer_idx + 1 >= layer_boundaries.size() else layer_boundaries[next_layer_idx + 1]
			rooms[i].connections.clear()
			for j: int in range(start_idx, end_idx):
				rooms[i].connections.append(j)
	
	print("[MapGenerator] Generated floor %d: %d rooms" % [floor_number, rooms.size()])
	return rooms

static func _create_random_room(floor: int) -> RoomData:
	var roll: float = randf()
	var room_type: int
	if roll < 0.55:
		room_type = RoomData.RoomType.BATTLE
	elif roll < 0.75:
		room_type = RoomData.RoomType.ELITE
	elif roll < 0.85:
		room_type = RoomData.RoomType.SHOP
	elif roll < 0.95:
		room_type = RoomData.RoomType.EVENT
	else:
		room_type = RoomData.RoomType.REST
	
	var enemy_count: int = randi_range(2, 4)
	if room_type == RoomData.RoomType.ELITE:
		enemy_count = randi_range(2, 3)
	
	var enemies: Array[Dictionary] = []
	for _i: int in enemy_count:
		var enemy_type: String = EnemyDB.get_random_normal()
		if room_type == RoomData.RoomType.ELITE:
			# Elite rooms have tougher enemies
			if randf() < 0.4:
				enemy_type = "tank"
		var data: Dictionary = EnemyDB.get_data(enemy_type)
		data["type_name"] = enemy_type
		enemies.append(data)
	
	var gold_reward: int = 20 + floor * 10
	if room_type == RoomData.RoomType.ELITE:
		gold_reward += 25
	
	var name_str: String = "战斗" if room_type == RoomData.RoomType.BATTLE else "精英"
	return RoomData.new("", room_type, name_str, enemies, gold_reward, [])

static func _create_boss_room(floor: int) -> RoomData:
	var boss_data: Dictionary = EnemyDB.get_data("boss")
	boss_data["type_name"] = "boss"
	return RoomData.new("boss", RoomData.RoomType.BOSS, "Boss战", [boss_data], 80 + floor * 20, [])
