# SaveManager — 存档管理 (autoload)
extends Node

const SAVE_KEY: String = "run_state"

func save_run_state(rs: RunState) -> bool:
	var data: Dictionary = {
		"gold": rs.gold,
		"player_max_hp": rs.player_max_hp,
		"player_current_hp": rs.player_current_hp,
		"current_floor": rs.current_floor,
		"current_room_index": rs.current_room_index,
		"rooms_cleared": rs.rooms_cleared,
		"deck_ids": _serialize_deck(rs.deck),
		"relic_data": _serialize_relics(rs.relics)
	}
	var json_str: String = JSON.stringify(data)
	var file: FileAccess = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file == null:
		print("[SaveManager] Failed to open save file for writing")
		return false
	file.store_string(json_str)
	file.close()
	print("[SaveManager] Game saved: floor=%d gold=%d hp=%d" % [rs.current_floor, rs.gold, rs.player_current_hp])
	return true

func load_run_state() -> Dictionary:
	if not has_save():
		return {}
	var file: FileAccess = FileAccess.open("user://save_game.json", FileAccess.READ)
	if file == null:
		return {}
	var json_str: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var err: int = json.parse(json_str)
	if err != OK:
		print("[SaveManager] Failed to parse save file")
		return {}
	var data = json.get_data()
	if data == null:
		return {}
	print("[SaveManager] Save loaded: floor=%d gold=%d" % [data.get("current_floor", 0), data.get("gold", 0)])
	return data

func has_save() -> bool:
	return FileAccess.file_exists("user://save_game.json")

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute("user://save_game.json")
		print("[SaveManager] Save deleted")

func apply_to_run_state(rs: RunState, data: Dictionary) -> void:
	if data.is_empty():
		return
	rs.gold = data.get("gold", 100)
	rs.player_max_hp = data.get("player_max_hp", 100)
	rs.player_current_hp = data.get("player_current_hp", 100)
	rs.current_floor = data.get("current_floor", 1)
	rs.current_room_index = data.get("current_room_index", 0)
	rs.rooms_cleared = data.get("rooms_cleared", 0)
	# Restore deck from IDs
	var deck_ids: Array = data.get("deck_ids", [])
	if deck_ids.size() > 0:
		rs.deck.clear()
		for card_id in deck_ids:
			rs.deck.append(CardDB.get_by_id(str(card_id)))

func _serialize_deck(deck: Array[CardData]) -> Array:
	var ids: Array = []
	for card in deck:
		ids.append(card.id)
	return ids

func _serialize_relics(relics: Array[RelicData]) -> Array:
	var data: Array = []
	for relic in relics:
		data.append({"id": relic.id, "rarity": relic.rarity})
	return data

func _self_test() -> void:
	# Create temp RunState and save/load
	var rs: RunState = RunState.new()
	rs.gold = 150
	rs.player_current_hp = 80
	rs.current_floor = 2
	
	var saved: bool = save_run_state(rs)
	TestHelper.check(saved, "SaveManager save_run_state success")
	TestHelper.check(has_save(), "SaveManager has_save after save")
	
	var data: Dictionary = load_run_state()
	TestHelper.check(not data.is_empty(), "SaveManager load_run_state returns data")
	TestHelper.assert_eq(data.get("gold", 0), 150, "SaveManager loaded gold=150")
	TestHelper.assert_eq(data.get("player_current_hp", 0), 80, "SaveManager loaded hp=80")
	
	# Apply to a new RunState
	var rs2: RunState = RunState.new()
	apply_to_run_state(rs2, data)
	TestHelper.assert_eq(rs2.gold, 150, "SaveManager apply_to_run_state gold")
	TestHelper.assert_eq(rs2.player_current_hp, 80, "SaveManager apply_to_run_state hp")
	
	# Clean up
	delete_save()
	TestHelper.check(not has_save(), "SaveManager save deleted")
	
	print("[TEST] SaveManager self-test complete")
