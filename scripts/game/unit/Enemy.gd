extends Unit
class_name Enemy

func _ready() -> void:
	faction = Faction.ENEMY; max_hp = GameConfig.ENEMY_HP
	unit_color = Color.RED; unit_radius = 28.0
	super._ready()
