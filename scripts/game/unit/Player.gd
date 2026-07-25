extends Unit
class_name Player

func _ready() -> void:
	faction = Faction.PLAYER; max_hp = GameConfig.PLAYER_HP
	unit_color = Color.GREEN; unit_radius = 35.0
	super._ready()
