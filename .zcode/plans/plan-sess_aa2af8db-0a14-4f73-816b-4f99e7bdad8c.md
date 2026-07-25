# P3 开发计划：UI/HUD + 存档 + 音效 + 粒子

P3 把 P0-P2 的纯逻辑系统变成可见可玩的游戏。由于 headless 模式限制，优先做**可测试的数据驱动组件**。

---

## Step 1: HUD 面板 — 战斗信息可视化

### 1a. BattleHUD (`scripts/ui/BattleHUD.gd`)
基于 `_draw()` 的战斗信息面板，挂载到 BattleManager 子节点。

**显示内容**:
- **HP 条**: 玩家 + 敌人头顶血条 (绿色→黄色→红色渐变)
- **能量球**: 当前能量/最大能量 (蓝色圆点)
- **风力指示**: 已内置在 WindSystem._draw，HUD 读取文字描述
- **回合指示**: "玩家回合" / "敌人回合"
- **手牌显示**: 底部横排小方块，显示卡牌名+费用

**数据源**: 读取 EnergySystem、Unit、CardManager、WindSystem、TurnManager
**更新**: 通过 EventBus 监听 `energy:changed`、`card:drawn`、`card:used`、`turn:phase_changed`

### 1b. GameOverPanel (`scripts/ui/GameOverPanel.gd`)
监听 `battle:ended`，在 _draw 中显示 "胜利!" 或 "失败!"
纯文本居中显示

---

## Step 2: 存档系统 — RunState 持久化

### 2a. SaveManager 扩展
已有基础 key-value 文件存储。扩展为：
- `save_run_state(run_state)` → JSON 序列化 RunState 到文件
- `load_run_state()` → 从文件恢复 RunState
- `delete_save()` → 清除存档
- 序列化内容: gold, HP, floor, room_index, deck (card IDs), relics (relic IDs)
- `has_save()` → 检查存档是否存在

### 2b. BattleManager 集成
- 战斗开始时从 SaveManager 恢复 HP（如果 RunState 有存档数据）
- 房间完成时自动保存
- 游戏结束时可选择清除存档

---

## Step 3: 音效系统 — 事件驱动音效

### 3a. AudioManager 扩展
已有 `play_sfx(stream)` 基础。扩展为：
- `_ready` 中监听 EventBus 事件，自动播放对应音效
- 音频文件不存在时静默降级（不报错）
- 事件→音效映射:
  - `projectile:explode` → 爆炸音效
  - `card:used` → 卡牌音效
  - `unit:died` → 死亡音效
  - `turn:phase_changed` → 回合切换音效
  - `battle:ended` → 胜利/失败音效
  - `shop:item_bought` → 购买音效

### 3b. 音效资源
- 使用 Godot 内置 AudioStreamGenerator 生成简单音效（或加载 .wav）
- 如无资源文件，创建占位 AudioStreamPlayer 静默运行

---

## Step 4: 粒子效果 — 视觉反馈

### 4a. ExplosionEffect (`scripts/game/vfx/ExplosionEffect.gd`)
- Node2D，在爆炸位置播放粒子动画
- 用 `_draw()` 绘制扩散圆环（半径从小→大，透明度递减）
- 用 `_process` 驱动动画帧
- 爆炸事件触发时创建，动画结束后 queue_free

### 4b. DamageNumber (`scripts/game/vfx/DamageNumber.gd`)
- Node2D，在受伤单位上方显示伤害数字
- `_draw()` 绘制浮动上升的红色数字
- 1 秒后自动消失

### 4c. StatusIndicator (`scripts/game/unit/StatusIndicator.gd`)
- 挂载到 Unit 子节点
- 在 Unit 上方绘制状态图标: 🔥 灼烧, ❄️ 冰冻
- 随 Unit 移动

---

## 实施顺序

| 顺序 | 内容 | 文件 | 可测试性 |
|------|------|------|---------|
| **1** | BattleHUD | ui/BattleHUD.gd | 数据断言 |
| **2** | SaveManager 扩展 | managers/SaveManager.gd | 文件读写 |
| **3** | AudioManager 事件 | managers/AudioManager.gd | 事件绑定 |
| **4** | 粒子效果 | vfx/ (2-3 files) | 节点创建 |

## 注意事项
- P3 大量使用 `_draw()` 而非 Control 节点（headless 兼容，纯代码可测试）
- 音效在无音频文件时静默降级，不阻塞测试
- SaveManager 用 JSON 序列化，卡牌/遗物按 ID 存储
- BattleHUD 通过 EventBus 自动更新，无需手动调用
- 遵守 P1 规范：显式类型、Tab 缩进、无 `:=` Variant