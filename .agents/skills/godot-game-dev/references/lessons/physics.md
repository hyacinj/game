# 物理经验

> **适用版本**: Godot 4.4.x | **最后更新**: 2026-07-25

---

## 碰撞信号不触发

**问题现象**: `body_entered` 信号从不发射，炮弹穿过目标无反应。

**复现条件**: 碰撞检测的目标节点是 `Node2D`（非物理体）。

**根因**: `RigidBody2D.body_entered` 只能检测**物理体**（RigidBody2D / StaticBody2D / CharacterBody2D）。Node2D 不是物理体，碰撞信号不会触发。

**解决方案**: 对非物理体（如 Unit），用 EventBus 事件 + 手动距离检测替代物理碰撞信号。

**相关文件**: `scripts/game/unit/Unit.gd`, `scripts/core/EventBus.gd`

**标签**: physics, collision, signal

---

## 炮弹穿透碰撞体

**问题现象**: 高速飞行的炮弹穿过 StaticBody2D 地形，不触发碰撞。

**复现条件**: 炮弹速度很快（如 >1000 px/s），地形块较小（40×40 像素）。

**根因**: 高速物体在一帧内的位移超过了碰撞体的厚度，物理引擎来不及检测。

**解决方案**: 在 RigidBody2D 上设置 `continuous_cd = true`（连续碰撞检测）。

**相关文件**: `scripts/game/projectile/Projectile.gd`

**标签**: physics, projectile, collision

---

## 爆炸伤害检测不到敌人

**问题现象**: 炮弹爆炸后，距离检测返回空，敌人不掉血。

**复现条件**: 爆炸半径设置过小（如 <50），敌人间距 150。

**根因**: 测试时爆炸半径必须大于敌人间距，否则距离检测无法覆盖。

**解决方案**: 确保爆炸半径 ≥ 150（覆盖相邻敌人）。伤害公式：`damage * (1 - dist/radius * 0.3)`，边缘衰减 30%。

**相关文件**: `scripts/game/battle/BattleManager.gd`, `scripts/game/unit/Unit.gd`

**标签**: physics, damage, explosion

---

## 爆炸时序不可靠

**问题现象**: 用 `await timer` 等爆炸效果结束，有时回调不触发。

**根因**: `await` 依赖帧时序，在 headless 测试模式下帧率不稳定。

**解决方案**: 用信号回调替代 `await`——发射 `projectile:explode` 事件，所有 Unit 通过 EventBus 监听并同步处理。

**相关文件**: `scripts/core/EventBus.gd`, `scripts/game/projectile/Projectile.gd`

**标签**: physics, signal, async, eventbus

---

## 重力方向

**问题现象**: 炮弹向上飞或重力方向反了。

**根因**: Godot 2D 中 Y 轴向下（正 Y = 下方），重力默认 (0, 980) —— 正 Y = 向下，符合直觉。但如果手动设了负值或忘记了坐标系，方向就会反。

**解决方案**: 保持 `ProjectSettings` 中重力默认值 `(0, 980)`，速度计算时 Y 分量为负表示向上：`velocity = (cos(angle) * power, -sin(angle) * power)`。

**相关文件**: `scripts/game/projectile/Projectile.gd`

**标签**: physics, gravity, coordinate
