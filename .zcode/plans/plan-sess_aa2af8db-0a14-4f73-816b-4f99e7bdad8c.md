# P2 开发计划：肉鸽地图 + 敌人AI + 商店/事件 + Boss

## 总览
P2 在 P1 战斗核心之上，构建 roguelike 跑团循环。分 4 步实施，按影响力排序。

---

## Step 1: 敌人 AI — 让战斗有来有回

### 1a. EnemyAI (`scripts/game/ai/EnemyAI.gd`)
**核心职责**: 每个敌人挂一个 AI 组件，控制其回合行为

```gdscript
class_name EnemyAI extends Node
enum State { IDLE, AIMING, FIRING, DONE }

var enemy_unit: Unit
var target_player: Player
var aim_angle: float
var aim_power: float
var difficulty: float = 1.0  # 难度系数 (0.5~2.0, 影响精度)

func take_turn() -> void:
    # 简单策略: 瞄准玩家, 加入随机误差
    # 角度抖动 ±(15/difficulty)°, 力度抖动 ±(100/difficulty)
    # 调用 ProjectileLauncher.fire_projectile()

func get_intent() -> String:  # "攻击", "防御" 等
```

### 1b. TurnManager 改造
- `_begin_enemy_turn()`: 不再 auto-end，改为遍历所有存活的敌人
- 每个敌人依次调用 `enemy_ai.take_turn()`
- 所有敌人行动完毕后发 `turn:enemy_actions_complete` → `_end_enemy_turn()`

### 1c. Enemy 增强
- 增加 `enemy_type: String` ("grunt", "tank", "sniper", "boss")
- 从 `EnemyDB` 读取不同敌人的 HP/伤害/颜色
- 增加 `ai: EnemyAI` 子节点

### 1d. EnemyDB (`scripts/game/ai/EnemyDB.gd`)
- 定义敌人类型数据: grunt (HP 60), tank (HP 120, 低速), sniper (HP 40, 高精度)
- `get_enemy_data(type) → Dictionary`

### BattleManager 适配
- `_spawn_enemies()` 改为接受 `Array[Dictionary]` 敌人配置
- `_on_enemy_turn_begin()` 连接 AI 系统

---

## Step 2: RunState + 房间系统 — roguelike 框架

### 2a. RunState (`scripts/managers/RunState.gd` — autoload)
**核心职责**: 跨战斗的持久状态

```
var current_floor: int = 1
var gold: int = 0
var player_max_hp: int = 100     # 跨房间持久
var player_current_hp: int = 100
var deck: Array[CardData] = []   # 牌组在整局游戏中累积
var relics: Array[RelicData] = []
var room_nodes: Array[RoomData]  # 当前楼层所有房间
var current_room_index: int = 0
func add_gold(amount), spend_gold(amount) → bool
func heal_player(amount)
```

### 2b. RoomData (`scripts/game/room/RoomData.gd`)
- Resource 类, 房间数据结构
- type: BATTLE / ELITE / SHOP / EVENT / BOSS / REST / START
- `enemy_configs: Array[Dictionary]` (仅 BATTLE/ELITE/BOSS)
- `reward_gold: int`, `reward_cards: Array[CardData]`
- `connections: Array[int]` (连接到哪些房间索引)

### 2c. MapGenerator (`scripts/game/room/MapGenerator.gd`)
**核心职责**: 生成楼层地图

- 固定结构: 3-4 层, 每层 3-4 个房间
- 每层随机: 60% BATTLE, 15% ELITE, 15% SHOP/EVENT, 10% REST
- 最后一层固定 BOSS
- 保证房间之间可达 (每层至少一条路径)
- `generate_floor(floor_number) → Array[RoomData]`

### 2d. RoomManager (`scripts/game/room/RoomManager.gd`)
**核心职责**: 管理房间切换流程

- `enter_room(room_data)` → 根据类型进入战斗/商店/事件
- 战斗胜利后: 发奖励 (选牌/金币) → 显示地图 → 选择下一个房间
- 商店/事件: 切换到对应 UI（P3 做 UI，P2 用纯数据/简单文本）

### BattleManager 适配
- 从 RunState 读取敌人配置，而非硬编码
- 战斗结束时通知 RoomManager 而非直接结束

---

## Step 3: Boss 战 — 端点挑战

### 3a. Boss AI (`EnemyAI` 子类化或特殊模式)
- Boss 专属行为: 多阶段 (HP < 50% 切换), 强力攻击
- Boss 配置: HP 200+, 爆炸范围翻倍, 精准度提升
- 掉落: 固定稀有遗物 + 2 张稀有卡牌

### 3b. BossRoom
- Boss 房间在 MapGenerator 最后一层
- 进入 Boss 房间 → 特殊战斗 → 胜利 → 楼层通关

---

## Step 4: 商店 + 事件 — 经济与随机

### 4a. ShopData + ShopManager (`scripts/game/shop/`)
- ShopManager 生成商品: 3 张随机牌 + 2 个随机遗物
- 卡牌价格: COMMON 50g, RARE 100g, EPIC 150g
- 遗物价格: COMMON 80g, RARE 150g, EPIC 250g
- `buy_card(index)` / `buy_relic(index)` → 扣金币, 加入牌库/遗物
- `refresh_shop()` → 重新随机商品 (消耗 30g)
- 商店数据纯逻辑, UI 留到 P3

### 4b. EventData + EventManager (`scripts/game/events/`)
- EventDB: 5-8 个预定义事件
- 事件结构: 文本 + 2-3 个选项 → 每选项有后果
- 示例: "遇到神秘商人" → [买遗物(100g), 偷遗物(50% 成功), 离开]
- EventManager: 随机选事件 → 返回结果
- 纯数据+逻辑, UI 留 P3

---

## 实施顺序

| 顺序 | 内容 | 新增文件 | 说明 |
|------|------|---------|------|
| **1** | EnemyAI + EnemyDB | ai/EnemyAI.gd, ai/EnemyDB.gd | 战斗从单向变为双向 |
| **2** | RunState + RoomData + MapGenerator + RoomManager | room/ (4 files), managers/RunState.gd | roguelike 框架 |
| **3** | Boss AI + Boss 配置 | ai/ 扩展, Boss 配置 | 楼层终点 |
| **4** | ShopManager + EventManager | shop/ (2 files), events/ (2 files) | 经济+随机 |

## 注意事项
- P2 所有 UI (地图显示、商店面板、事件对话框) 留到 P3
- P2 做纯逻辑层, 通过 EventBus/日志输出结果
- 敌人 AI 简化为 "瞄准玩家 + 随机误差" 的抛物线射击
- 金色货币系统最简单: RunState 持有一个 int
- 每个 Step 完成后编译+测试, 确保 100% PASS 再推进
- 遵守 P1 建立的规范: 显式类型, 无 `:=` Variant 推断, Tab 缩进