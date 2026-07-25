# 战斗系统

## 回合流程
```
PlayerTurn → 点击开火 → ProjectileFlying → 爆炸 → EnemyTurn → PlayerTurn
```
- 一回合可多次开火（能量系统待实现）
- 敌人行动目前为空（待实现 AI）

## 炮弹物理
- RigidBody2D 受重力影响
- 速度 = (cos(angle) * power, sin(angle) * power)
- 角度：从玩家指向点击位置

## 伤害计算
- 爆炸半径 100，中心满伤害，边缘衰减 30%
- damage_final = damage * (1 - dist/radius * 0.3)

## 地形
- 288 块 (48×6)，每块 40×40 像素
- 有 HP，受损后颜色变暗，HP≤0 后消除
- 待实现：地形破坏后的碎片效果
