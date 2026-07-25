extends Node

var current_scene: Node = null

func load_scene(path: String) -> void:
	if current_scene:
		current_scene.queue_free()
	var s := load(path) as PackedScene
	if s:
		current_scene = s.instantiate()
		get_tree().root.add_child(current_scene)
		EventBus.emit("scene:afterLoad", path)
