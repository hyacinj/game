# 卡牌系统

> **最后更新**: 2026-07-25 | 参考: Cocos 版 `card/CardData.ts` `CardManager.ts` `Card.ts` `CardHandUI.ts` `CardRewardPanel.ts`

---

## 需求描述

### 卡牌数据结构 (CardData)
```
CardData {
  id: string            // 唯一 ID
  name: string          // 卡牌名
  description: string   // 效果描述
  type: CardType        // ATTACK / EFFECT / UTILITY
  cost: int             // 能量消耗
  rarity: Rarity        // COMMON / RARE / EPIC
  effect: CardEffect    // 效果配置
  icon: string          // 图标资源路径
}
```

### 卡牌类型

| 类型 | 说明 | Cocos 中存在 |
|------|------|------------|
| `ATTACK` | 攻击牌，影响炮弹发射 | ✅ |
| `EFFECT` | 效果牌，附加状态（灼烧/冰冻） | ✅ |
| `UTILITY` | 辅助牌（额外能量/抽牌/瞄准镜） | ✅ |

### 牌库管理 (CardManager)
- **牌库 (Deck)**: 所有拥有的卡牌，战后新增牌加入牌库
- **手牌 (Hand)**: 当前可用的卡牌，从牌库抽取
- **弃牌堆 (Discard)**: 使用过的牌，牌库空时洗入
- **抽牌**: 每回合开始时抽满手牌（如 5 张）
- **手牌上限**: 10 张，超出无法再抽
- **洗牌**: 牌库空时，弃牌堆洗入牌库

### 能量系统 (EnergySystem)
- 每回合恢复至最大能量（如 3 点）
- 使用卡牌消耗对应能量
- 能量不足时卡牌置灰不可用
- 部分卡牌/遗物可增加最大能量

### 手牌 UI (CardHandUI)
- 手牌横向排列在屏幕底部
- 可拖拽使用或点击选中
- 悬停时放大 + 显示详情
- 使用后飞入弃牌堆动画

### 战后选牌 (CardRewardPanel)
- 战斗胜利 → 弹出 3 选 1 面板
- 3 张随机牌（稀有度混合）
- 选中的牌加入牌库
- 未选的牌消失

---

## 当前进度

| 功能 | 状态 | Cocos 参考 |
|------|------|-----------|
| CardData 数据结构 | 📅 | `CardData.ts` |
| CardManager（牌库/手牌/弃牌） | 📅 | `CardManager.ts` |
| Card 组件 | 📅 | `Card.ts` |
| EnergySystem | 📅 | `EnergySystem.ts` |
| CardHandUI | 📅 | `CardHandUI.ts` |
| CardRewardPanel | 📅 | `CardRewardPanel.ts` |
| 卡牌效果实现 | 📅 | 散射弹优先 |

---

## 相关代码 (Cocos 参考)
- `assets/scripts/game/card/CardData.ts`
- `assets/scripts/game/card/CardManager.ts`
- `assets/scripts/game/card/Card.ts`
- `assets/scripts/game/card/CardHandUI.ts`
- `assets/scripts/game/card/CardRewardPanel.ts`
- `assets/scripts/game/battle/EnergySystem.ts`

## Godot 实现文件
- `scripts/game/card/`（待创建）
- `scripts/game/battle/EnergySystem.gd`（待创建）
