# EventData — 事件数据定义
class_name EventData
extends RefCounted

var id: String = ""
var title: String = ""
var description: String = ""
var options: Array[Dictionary] = []  # [{text, effect_type, effect_value, risk}]

func _init(p_id: String, p_title: String, p_desc: String, p_options: Array[Dictionary]) -> void:
	id = p_id
	title = p_title
	description = p_desc
	options = p_options
