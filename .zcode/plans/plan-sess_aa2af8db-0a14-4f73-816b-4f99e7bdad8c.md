# P1 开发计划：战斗丰富化 + 卡牌框架 + 遗物系统

## 总览
P1 阶段目标：在 P0 核心（抛物线+地形+单位）基础上，添加 6 大系统。按依赖关系分 4 步实施。

---

## Step 1: 战斗精炼 — TurnManager + WindSystem + AimLine + ProjectileLauncher

### 1a. TurnManager (`scripts/game/battle/TurnManager.gd`)
**核心职责**: 管理回合阶段切换，替代 BattleManager 中简单的布尔标志

```
状态机: BATTLE_START → PLAYER_TURN(draw→energy→action) → ENEMY_TURN → NEXT → loop
```

- `enum Phase { BATTLE_START, PLAYER_DRAW, PLAYER_ACTION, PLAYER_END, ENEMY_TURN, BATTLE_OVER }`
- 信号通过 EventBus 发出: `turn:phase_changed`, `turn:player_begin`, `turn:enemy_begin`, `turn:ended`
- 与 CardManager/EnergySystem 通过 EventBus 联动（抽牌、回能）
- `_self_test()`: 验证状态流转正确

### 1b. WindSystem (`scripts/game/wind/WindSystem.gd`)
**核心职责**: 每回合随机风向/强度，影响炮弹水平加速度

- `direction: Vector2` (归一化，水平分量)
- `strength: float` (0~1)
- `randomize()` → 每回合开始随机生成
- `get_wind_force() → Vector2` → 供 Projectile 和 AimLine 使用
- 简单 UI: `_draw()` 在屏幕上方画风向箭头
- `_self_test()`: 验证随机范围、方向合法性

### 1c. AimLine (`scripts/game/projectile/AimLine.gd`)
**核心职责**: 鼠标拖拽时显示抛物线预览（虚线轨迹）

- Node2D，挂在 BattleManager 下
- 拖拽计算: 起点=玩家位置，角度=鼠标方向反向，力度=拖拽距离×系数
- `_draw()` 用 `draw_dashed_line` 绘制抛物线预测点
- 预测算法: 逐帧模拟 `pos += vel * dt; vel.y += gravity * dt; vel.x += wind.x * dt`
- 显示 N 个点（如 60 帧预览）
- 松开鼠标触发发射
- `_self_test()`: 验证预览点数、角度计算

### 1d. ProjectileLauncher (`scripts/game/projectile/ProjectileLauncher.gd`)
**核心职责**: 创建并发射炮弹，支持散射

- 从 BattleManager 的 `_fire()` 逻辑迁移
- `fire_projectile(origin, velocity)` → 创建 Projectile 实例
- `fire_scatter(origin, base_vel, count, spread_angle)` → 一次发射 N 颗
- 从对象池获取（简单数组复用，后续可优化）
- `_self_test()`: 验证单发、散射数量正确

### BattleManager 重构
- 移除内联的 `_fire()`、`is_aiming`、`aim_angle` 等
- 改为组合: 持有 TurnManager + WindSystem + AimLine + ProjectileLauncher
- `_input()` 委托给 AimLine 处理拖拽

---

## Step 2: 卡牌框架 — CardData + EnergySystem + CardManager

### 2a. CardData (`scripts/game/card/CardData.gd`)
**核心职责**: 卡牌数据定义（Resource 子类）

```gdscript
class_name CardData extends Resource

enum CardType { ATTACK, EFFECT, UTILITY }
enum Rarity { COMMON, RARE, EPIC }

@export var id: String
@export var card_name: String
@export var description: String
@export var type: CardType
@export var cost: int
@export var rarity: Rarity
@export var effect_data: Dictionary  # {"scatter_count": 3, "damage_bonus": 5, ...}
@export var icon_path: String
```

- 预定义初始牌组（如 5 张基础牌）
- `CardDB` 辅助类: 提供 `all_cards()` 和 `get_random(rarity)`
- `_self_test()`: 验证数据完整性

### 2b. EnergySystem (`scripts/game/battle/EnergySystem.gd`)
**核心职责**: 能量资源管理

- `current_energy: int`, `max_energy: int = 3`
- `restore()` → 回满
- `can_afford(cost) → bool`
- `spend(cost) → bool` → 成功返回 true
- 事件: `energy:changed(current, max)`
- `_self_test()`: 验证花费、恢复、边界

### 2c. CardManager (`scripts/game/card/CardManager.gd`)
**核心职责**: 牌库/手牌/弃牌堆管理（纯逻辑，无 UI）

- `deck: Array[CardData]`, `hand: Array[CardData]`, `discard: Array[CardData]`
- **常量**: `MAX_HAND_SIZE = 10`, `DRAW_PER_TURN = 5`
- `initialize(starting_deck)` → 洗牌
- `draw(n)` → 从牌库抽到手牌（牌库空时洗入弃牌堆）
- `use_card(index)` → 手牌→弃牌，触发效果
- `add_card(card)` → 加入牌库（战后奖励）
- `shuffle_discard_into_deck()`
- 事件: `card:drawn`, `card:used`, `deck:shuffled`
- `_self_test()`: 验证抽牌、洗牌、手牌上限、牌库循环

---

## Step 3: 战斗增强 — 散射弹 + 状态效果

### 3a. Projectile 增强
- 读取 WindSystem 风力（每帧 `_integrate_forces` 中叠加）
- 支持散射: 从 ProjectileLauncher 以不同角度发射多颗

### 3b. 状态效果系统 (`scripts/game/unit/StatusEffect.gd`)
**核心职责**: 单位状态效果（灼烧、冰冻）

```gdscript
class_name StatusEffect extends RefCounted
enum Type { BURN, FREEZE }

var type: Type
var duration: int      # 剩余回合
var damage_per_turn: int   # 灼烧
var slow_ratio: float      # 冰冻减速比例
```

- Unit 增加 `status_effects: Array[StatusEffect]`
- `apply_status(effect)` / `remove_status(type)`
- `tick_statuses()` → 回合结束结算（灼烧扣血、冰冻减回合）
- `_self_test()`: 灼烧 DOT、冰冻衰减

### 3c. 卡牌效果实现
- 散射牌: 调用 ProjectileLauncher.fire_scatter()
- 灼烧牌: 对爆炸范围内敌人施加 Burn
- 冰冻牌: 对爆炸范围内敌人施加 Freeze
- 伤害加成牌: 临时提升炮弹伤害

---

## Step 4: 遗物系统 — RelicData + RelicManager

### 4a. RelicData (`scripts/game/relic/RelicData.gd`)
- Resource 子类，类似 CardData
- 效果类型: `STAT_BONUS`, `ENERGY_BONUS`, `DRAW_BONUS`, `DAMAGE_BONUS` 等
- `effect_data: Dictionary` → `{"stat": "max_hp", "value": 20, "is_percent": true}`

### 4b. RelicManager (`scripts/game/relic/RelicManager.gd`)
- `relics: Array[RelicData]`
- `add_relic(relic)` / `has_relic(id)`
- `get_stat_multiplier(stat) → float` → 计算所有遗物叠加
- 事件响应: `battle:started` → 触发 `onBattleStart`、`turn:player_begin` → 触发 `onTurnStart`
- `_self_test()`: 验证叠加、事件触发

---

## 实施顺序
| 顺序 | 内容 | 预估 |
|------|------|------|
| 1 | Step 1: TurnManager + WindSystem + AimLine + Launcher | 核心战斗打磨 |
| 2 | Step 2: CardData + EnergySystem + CardManager | 卡牌逻辑 |
| 3 | Step 3: 散射弹 + 状态效果 | 战斗丰富化 |
| 4 | Step 4: RelicData + RelicManager | 遗物框架 |

## 注意事项
- 每步完成后编译 + 测试，确保自检通过
- P1 卡牌/遗物暂不做 UI（UI 是 P3），纯逻辑节点
- 风力/瞄准线先做核心计算，视觉打磨放 P3
- 敌人 AI 留到 P2
- 先修复 `config/project.toml` 中过期路径