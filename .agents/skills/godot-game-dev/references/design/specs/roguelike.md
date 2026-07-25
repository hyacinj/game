# 肉鸽地图 + 商店

> **最后更新**: 2026-07-25 | 参考: Cocos 版 `room/RoomData.ts` `room/MapView.ts` `room/ShopPanel.ts`

---

## 需求描述

### 房间类型 (RoomData)
```
RoomData {
  id: string
  type: RoomType        // BATTLE / SHOP / EVENT / BOSS / REST / START
  position: Vector2     // 地图上的位置
  connections: string[] // 连接到的房间 ID
  cleared: bool         // 是否已完成
  reward: Reward        // 完成奖励
}
```

| 房间类型 | 说明 |
|---------|------|
| `BATTLE` | 普通战斗，胜利后选牌 |
| `ELITE` | 精英战斗，敌人更强 + 遗物掉落 |
| `SHOP` | 商店，金币购买卡牌/遗物 |
| `EVENT` | 随机事件，选择获得/失去 |
| `BOSS` | Boss 战，通关节点 |
| `REST` | 休息点，恢复 HP |
| `START` | 起始房间 |

### 地图生成 (MapView)
- 多层结构（如 3 层，每层 3-4 个房间）
- 每层随机生成房间类型
- 房间之间随机连线（保证可达）
- 玩家选择路径，只能前进不能后退
- 当前层完成后解锁下一层
- Boss 在最后一层

### 商店 (ShopPanel)
- 商品列表：3 张随机牌 + 2 个随机遗物
- 金币购买
- 可刷新（有限次数或花费金币）
- 8 折/免费刷新等遗物效果影响商店

### 事件房间
- 随机事件文本 + 2-3 个选项
- 选项可能导致：获得/失去 HP、获得卡牌/遗物、获得/失去金币
- 高风险高回报

---

## 当前进度

| 功能 | 状态 | Cocos 参考 |
|------|------|-----------|
| RoomData 数据结构 | 📅 | `RoomData.ts` |
| MapView 地图生成+UI | 📅 | `MapView.ts` |
| ShopPanel 商店 | 📅 | `ShopPanel.ts` |
| 事件系统 | 📅 | |
| 路径选择逻辑 | 📅 | |
| Boss 战 | 📅 | P3 |

---

## 相关代码 (Cocos 参考)
- `assets/scripts/game/room/RoomData.ts`
- `assets/scripts/game/room/MapView.ts`
- `assets/scripts/game/room/ShopPanel.ts`

## Godot 实现文件
- `scripts/game/room/`（待创建）
