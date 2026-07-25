# GDScript 编码规范

> 适用于 `scripts/` 下所有 `.gd` 文件。Agent 写代码时遵守，Code Review 时检查。

---

## 命名

### 文件
- 使用 PascalCase：`BattleManager.gd`、`TerrainBlock.gd`
- autoload 脚本名与 class_name 一致
- 测试用脚本前缀 `test_`：`test_combat.gd`

### 类名 (class_name)
- PascalCase，与文件名一致
- 不用 Godot 内置类名（`Node`、`Sprite`、`Label` 等）

### 变量
- `snake_case`：`move_speed`、`current_hp`
- 私有变量前缀 `_`：`_cache = {}`
- 常量 `CONST_CASE`：`MAX_PLAYERS = 4`
- 导出变量 `@export var` 用 snake_case

### 函数
- `snake_case`：`take_damage()`、`calculate_trajectory()`
- 私有函数前缀 `_`：`_on_body_entered()`
- 信号回调统一 `_on_<signal>`：`_on_projectile_explode()`
- 布尔返回函数前缀 `is_` / `has_` / `can_`

### 信号
- `snake_case`，描述发生了什么
- 好的：`projectile:explode`、`unit:died`、`turn:changed`
- 避免：`explodeSignal`、`on_explode`

---

## 文件组织

```gdscript
# 1. class_name / extends
class_name BattleManager
extends Node2D

# 2. 信号
signal turn_changed(turn: int)
signal battle_ended(result: String)

# 3. 常量
const MAX_UNITS := 10
const GRAVITY := 980.0

# 4. 导出变量
@export var debug_mode := false
@export var max_rounds := 20

# 5. 公共变量
var current_turn := 0
var units: Array[Unit] = []

# 6. 私有变量
var _listeners: Dictionary = {}
var _cache := {}

# 7. _ready / _init
func _ready() -> void:
    pass

# 8. 公共方法（按调用顺序排列）
func start_battle() -> void:
    pass

# 9. 私有方法
func _next_turn() -> void:
    pass

# 10. 信号回调
func _on_unit_died(unit: Unit) -> void:
    pass
```

---

## 类型标注

- 所有函数参数和返回值必须标注类型
- 数组标注元素类型：`Array[Unit]` 而非 `Array`
- 可空引用标注：`var unit: Unit = null`（Godot 4 允许）

---

## 最佳实践

1. **不用 `change_scene_to_file`** — 用 `load().instantiate()` + `add_child()`
2. **`_ready` 里不增减节点** — 用 `call_deferred("method")`
3. **事件驱动优先** — 跨节点通信用 EventBus，不直接引用
4. **自检可插拔** — 每个模块写 `_self_test()`，测试时由 TestHelper 调用
5. **autoload 只在编辑器 UI 添加** — 不手写 project.godot
6. **preload 常量放文件顶部** — `const BulletScene = preload("res://...")`

---

## 禁止事项

- ❌ 硬编码数值（用 `GameConfig` 或 `@export var`）
- ❌ `await` 在 `_ready` 中依赖子节点已就绪
- ❌ 直接用 `$NodePath` 跨 scene 引用（用信号或 %unique_name）
- ❌ 手写 `project.godot`
- ❌ 删除 `.godot/` 或 `*.uid` 文件
