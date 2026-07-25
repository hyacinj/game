# 物理经验

## 碰撞检测
- `RigidBody2D.body_entered` 只能检测**物理体**（RigidBody2D / StaticBody2D / CharacterBody2D）
- Node2D **不是物理体**，碰撞信号不会触发
- 对非物理体（Unit），用事件系统 + 距离检测

## 炮弹飞行
- 高速物体可能穿透碰撞体 → 设 `continuous_cd = true`
- 重力在 `ProjectSettings` 中默认 (0, 980)，正 Y 向下
- 测试时爆炸半径要足够大（敌人间距 150，半径需 100+）

## 地形碰撞
- StaticBody2D + RectangleShape2D
- 碰撞形状中心 == 节点位置

## 爆炸伤害
- 用 EventBus 事件驱动：`projectile:explode` → Unit 监听 → 距离检测
- 不可靠 `await timer` 等物理事件，用信号回调
