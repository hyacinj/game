# EventData -- 事件数据定义
class_name EventData
extends RefCounted

var id: String = ""
var title: String = ""
var description: String = ""
var event_type: String = ""  # "add_card" 或 "upgrade_card"
var card_count: int = 3
var card_options: Array[CardData] = []  # 运行时动态填充的卡片选项

func _init(p_id: String = "", p_title: String = "", p_desc: String = "", p_type: String = "", p_count: int = 3) -> void:
	id = p_id
	title = p_title
	description = p_desc
	event_type = p_type
	card_count = p_count
