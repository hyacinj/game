extends Unit
class_name Enemy

var enemy_type: String = "grunt"
var ai: EnemyAI = null

func _ready() -> void:
	faction = Faction.ENEMY
	# Defaults (overridden by setup_from_data)
	max_hp = GameConfig.ENEMY_HP
	unit_color = Color.RED
	unit_radius = 28.0
	super._ready()

## 从 EnemyDB 数据配置敌人属性
func setup_from_data(data: Dictionary) -> void:
	enemy_type = str(data.get("type_name", data.get("type", "grunt")))
	max_hp = data.get("hp", GameConfig.ENEMY_HP)
	current_hp = max_hp
	unit_color = data.get("color", Color.RED)
	unit_radius = data.get("radius", 28.0)
	queue_redraw()

## 挂载 AI 组件
func attach_ai(player_target: Player, launcher: ProjectileLauncher, wind: WindSystem, data: Dictionary) -> void:
	ai = EnemyAI.new()
	ai.setup(self, player_target, launcher, wind, data)
	add_child(ai)
