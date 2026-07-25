# 战斗系统

> **最后更新**: 2026-07-25 | 参考: Cocos 版 `battle/BattleManager.ts` `TurnManager.ts` `projectile/AimLine.ts` `projectile/ProjectileLauncher.ts` `wind/WindSystem.ts`

---

## 需求描述

### 回合流程 (TurnManager)
```
回合开始 → 抽牌 → 恢复能量 → 玩家操作阶段 → 结束回合 → 敌回合 → 下一回合
```

- **玩家操作阶段**: 可使用卡牌 + 发射炮弹（多次，直至能量不足或主动结束）
- **敌回合**: 敌人 AI 行动（待实现）
- **回合结束触发**: 状态效果结算（灼烧 DOT、冰冻衰减）

### 瞄准系统 (AimLine)
- 鼠标按下拖拽 → 显示瞄准虚线（抛物线预览）
- 力度 = 拖拽距离 × 系数
- 角度 = 玩家 → 鼠标方向的反向
- 松开鼠标 → 发射炮弹
- 虚线受风力影响实时更新

### 发射器 (ProjectileLauncher)
- 负责创建炮弹实例
- 支持散射（一次发射 N 颗，角度偏移）
- 支持分裂（空中分裂为多颗）
- 从对象池获取炮弹（PoolManager）

### 炮弹 (Projectile)
- RigidBody2D，受重力和风力影响
- 碰撞检测 `continuous_cd = true`
- 爆炸：半径伤害 + 地形破坏
- 生命周期：飞行 → 碰撞/超时 → 爆炸 → 回收

### 风力系统 (WindSystem)
- 每回合随机生成风向（左/右）和强度
- 影响炮弹飞行轨迹（水平加速度）
- UI 显示当前风向和强度
- 部分卡牌可操控风力

---

## 当前进度

| 功能 | 状态 | 备注 |
|------|------|------|
| 基础炮弹飞行 | ✅ | RigidBody2D + 重力 |
| 爆炸伤害 | ✅ | 距离衰减 |
| 回合切换 | ✅ | PlayerTurn ↔ EnemyTurn |
| 瞄准线预览 | ❌ | Cocos: `AimLine.ts` |
| 拖拽力度控制 | ❌ | Cocos: `ProjectileLauncher.ts` |
| 风力系统 | ❌ | Cocos: `WindSystem.ts` |
| TurnManager | ❌ | Cocos: `TurnManager.ts` |
| 散射弹 | 📅 | |
| 分裂弹 | 📅 | |

---

## 相关代码 (Cocos 参考)
- `assets/scripts/game/battle/BattleManager.ts`
- `assets/scripts/game/battle/TurnManager.ts`
- `assets/scripts/game/projectile/ProjectileLauncher.ts`
- `assets/scripts/game/projectile/AimLine.ts`
- `assets/scripts/game/wind/WindSystem.ts`

## Godot 实现文件
- `scripts/game/battle/BattleManager.gd`（更新）
- `scripts/game/battle/TurnManager.gd`（待创建）
- `scripts/game/projectile/ProjectileLauncher.gd`（待创建）
- `scripts/game/projectile/AimLine.gd`（待创建）
- `scripts/game/wind/WindSystem.gd`（待创建）
