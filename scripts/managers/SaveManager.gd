extends Node

func set_data(key: String, value) -> void:
	var f := FileAccess.open("user://sv_" + key + ".sav", FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(value)); f.close()

func get_data(key: String, default = null):
	var f := FileAccess.open("user://sv_" + key + ".sav", FileAccess.READ)
	if not f: return default
	var r := f.get_as_text(); f.close()
	var j := JSON.new()
	if j.parse(r) == OK: return j.data
	return default
