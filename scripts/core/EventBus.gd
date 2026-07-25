extends Node

var _listeners: Dictionary = {}

func on(event: String, callback: Callable) -> void:
	if not _listeners.has(event): _listeners[event] = []
	_listeners[event].append(callback)

func emit(event: String, arg1 = null, arg2 = null, arg3 = null) -> void:
	if not _listeners.has(event): return
	var args: Array = []
	if arg1 != null: args.append(arg1)
	if arg2 != null: args.append(arg2)
	if arg3 != null: args.append(arg3)
	for cb in _listeners[event]:
		cb.callv(args)

func off(event: String, callback: Callable) -> void:
	if _listeners.has(event): _listeners[event].erase(callback)

func clear() -> void: _listeners.clear()
