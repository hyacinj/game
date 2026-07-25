# UI 框架

> **最后更新**: 2026-07-25 | 参考: Cocos 版 `ui/UIBase.ts` `ui/UILayer.ts` `managers/UIManager.ts`

---

## 需求描述

### UI 层级 (UILayer)
```
BACKGROUND   ← 背景层（地图、场景）
GAME         ← 游戏层（单位、炮弹、地形）
HUD          ← HUD 层（HP 条、能量、手牌、风力指示）
POPUP        ← 弹窗层（选牌、商店、事件）
TOP          ← 顶层（加载、提示、确认框）
```

### UI 基类 (UIBase)
```
UIBase {
  show(): void        // 显示（带动画）
  hide(): void        // 隐藏（带动画）
  update(): void      // 刷新数据
  layer: UILayer      // 所属层级
}
```

### UI 管理器 (UIManager)
- 管理所有 UI 面板的显示/隐藏
- 层级控制：高层级遮盖低层级交互
- 弹窗栈：弹出新窗口时旧窗口不可交互
- UI 预制体加载和缓存

### 具体 UI 面板

| 面板 | 层级 | 说明 |
|------|------|------|
| HUD | HUD | HP 条、能量球、当前手牌、风力箭头 |
| CardHandUI | HUD | 手牌展示（横向排列） |
| CardRewardPanel | POPUP | 战后 3 选 1 |
| ShopPanel | POPUP | 商店 |
| EventPanel | POPUP | 随机事件 |
| MapView | BACKGROUND | 肉鸽地图 |
| BattleUI | GAME | 瞄准线、炮弹轨迹（非 UI 节点，但逻辑相关） |
| GameOverPanel | TOP | 游戏结束 |
| PausePanel | TOP | 暂停菜单 |

### HUD 布局
```
┌────────────────────────────┐
│  💨 风力 ← 3             │  ← 风力指示
│                            │
│  ❤️❤️❤️❤️❤️              │  ← HP 条
│                            │
│         [游戏画面]          │
│                            │
│  ⚡⚡⚡                    │  ← 能量球
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐   │  ← 手牌
│  │牌│ │牌│ │牌│ │牌│   │
│  └──┘ └──┘ └──┘ └──┘   │
│         [结束回合]         │  ← 按钮
└────────────────────────────┘
```

---

## 当前进度

| 功能 | 状态 | 备注 |
|------|------|------|
| UIManager | 📅 | Cocos: `UIManager.ts` |
| UIBase | 📅 | Cocos: `UIBase.ts` |
| UILayer 层级控制 | 📅 | Cocos: `UILayer.ts` |
| HUD（HP/能量） | 📅 | P3 |
| CardHandUI | 📅 | P1 |
| CardRewardPanel | 📅 | P1 |
| ShopPanel | 📅 | P2 |

---

## 相关代码 (Cocos 参考)
- `assets/scripts/ui/UIBase.ts`
- `assets/scripts/ui/UILayer.ts`
- `assets/scripts/core/managers/UIManager.ts`

## Godot 实现文件
- `scripts/ui/`（待创建）
- `scripts/core/managers/UIManager.gd`（待创建）
