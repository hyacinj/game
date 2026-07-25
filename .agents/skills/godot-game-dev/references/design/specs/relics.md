# 遗物系统

> **最后更新**: 2026-07-25 | 参考: Cocos 版 `relic/RelicData.ts` `RelicManager.ts`

---

## 需求描述

### 遗物定义 (RelicData)
```
RelicData {
  id: string
  name: string          // 遗物名
  description: string   // 效果描述
  rarity: Rarity        // COMMON / RARE / EPIC / LEGENDARY
  effect: RelicEffect   // 被动效果
  icon: string
  maxStack: int         // 可叠加层数（默认 1）
}
```

### 遗物效果类型
| 类型 | 示例 |
|------|------|
| 属性加成 | 最大 HP +20%、伤害 +10% |
| 能量相关 | 每回合额外 +1 能量、首回合能量翻倍 |
| 抽牌相关 | 每回合多抽 1 张、起始手牌 +1 |
| 炮弹相关 | 爆炸半径 +20%、炮弹速度 +15% |
| 状态相关 | 灼烧伤害 +50%、免疫冰冻 |
| 商店相关 | 商店 8 折、刷新免费 |
| 特殊规则 | 敌人 HP 减半、开局随机获得一张稀有牌 |

### 遗物管理 (RelicManager)
- 全局单例，持有当前所有遗物列表
- 获得遗物 → 添加并立即生效
- 遗物可叠加（maxStack > 1）
- 战斗开始时触发 `onBattleStart` 效果
- 回合开始时触发 `onTurnStart` 效果
- 被动加成在计算时实时读取

### 获取途径
- 战斗胜利奖励（随机掉落）
- 商店购买（金币）
- 事件房间
- Boss 掉落（固定稀有遗物）

---

## 当前进度

| 功能 | 状态 | Cocos 参考 |
|------|------|-----------|
| RelicData 数据结构 | 📅 | `RelicData.ts` |
| RelicManager | 📅 | `RelicManager.ts` |
| 遗物效果实现 | 📅 | |
| 遗物 UI 展示 | 📅 | P3 |
| 获取途径 | 📅 | 依赖商店/事件系统 |

---

## 相关代码 (Cocos 参考)
- `assets/scripts/game/relic/RelicData.ts`
- `assets/scripts/game/relic/RelicManager.ts`

## Godot 实现文件
- `scripts/game/relic/RelicData.gd`（待创建）
- `scripts/game/relic/RelicManager.gd`（待创建）
