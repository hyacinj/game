extends Node

var loading: bool = false

func load_scene(path: String) -> void:
	if loading: return
	loading = true
	EventBus.emit("scene:beforeLoad", path)
	get_tree().change_scene_to_file(path)
	loading = false
	EventBus.emit("scene:afterLoad", path)
