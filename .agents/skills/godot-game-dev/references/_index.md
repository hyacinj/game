# 知识库索引

> **自动维护规则**: Agent 新增/删除 reference 文件后，必须同步更新此索引。
> 最后更新: 2026-07-25 | Skill 版本: 1.0.0

---

## 目录结构

```
references/
├── _index.md                 ← 本文件（Agent 自维护）
├── troubleshooting.md        ← 故障排查指南
├── architecture/             ← 项目架构
│   ├── overview.md           ← 目录结构 + 信号流 + 场景加载
│   └── file-classification.md ← 文件修改权限（🔴🟢🟡）
├── design/                   ← 游戏策划
│   ├── design.md             ← 总策划（一页讲清全貌）
│   └── specs/                ← 系统拆解（需求 + 当前进度）
│       ├── combat.md         ← 战斗系统（瞄准/回合/风力）
│       ├── terrain.md        ← 地形系统
│       ├── units.md          ← 单位系统
│       ├── cards.md          ← 卡牌+能量系统
│       ├── relics.md         ← 遗物系统
│       ├── roguelike.md      ← 肉鸽地图+商店
│       └── ui.md             ← UI 框架
└── lessons/                  ← 经验教训（Agent 开发中沉淀）
    ├── _template.md          ← 新 lesson 的标准模板
    ├── physics.md            ← 物理相关经验（碰撞/飞行/爆炸）
    ├── rendering.md          ← 渲染相关经验（坐标/Camera/Canvas）
    └── script.md             ← 脚本相关经验（class_name/EventBus/autoload）
```

---

## 按主题查找

### 🎮 想了解这游戏是什么？
→ `design/design.md`（总策划，第一站）

### 🏗 想了解项目结构？
→ `architecture/overview.md`

### 🎯 想知道能改什么、不能改什么？
→ `architecture/file-classification.md`

### ⚔️ 想了解某个系统的需求和进度？
→ `design/specs/combat.md` / `terrain.md` / `units.md` / `cards.md`

### 🐛 出错了不知道怎么修？
→ `troubleshooting.md`（先查这里，再查 lessons）

### 💡 踩了新坑想写下来？
→ 按 `lessons/_template.md` 格式 → 写入对应 lesson 文件 → 更新本索引

---

## 索引维护规则

Agent 必须遵守：
1. **新增文件**: 在本文件的 "目录结构" 章节添加条目，并视情况在 "按主题查找" 添加引导
2. **删除文件**: 从两处同时移除
3. **新增目录**: 在 "目录结构" 中添加，在 "按主题查找" 中添加引导
4. **每次修改后**: 更新顶部的 "最后更新" 日期和 Skill 版本

---

## 按标签检索

> 标签来自各 lesson 文件中的"标签"字段。同一标签的经验集中对比阅读。

| 标签 | 相关文件 |
|------|---------|
| `physics` | `lessons/physics.md` |
| `collision` | `lessons/physics.md` |
| `signal` | `lessons/physics.md`, `lessons/script.md` |
| `projectile` | `lessons/physics.md` |
| `explosion` | `lessons/physics.md` |
| `damage` | `lessons/physics.md` |
| `eventbus` | `lessons/physics.md`, `lessons/script.md` |
| `async` | `lessons/physics.md` |
| `gravity` | `lessons/physics.md` |
| `coordinate` | `lessons/physics.md`, `lessons/rendering.md` |
| `rendering` | `lessons/rendering.md` |
| `camera` | `lessons/rendering.md` |
| `scene` | `lessons/rendering.md` |
| `canvas` | `lessons/rendering.md` |
| `ui` | `lessons/rendering.md` |
| `background` | `lessons/rendering.md` |
| `script` | `lessons/script.md` |
| `class_name` | `lessons/script.md` |
| `build` | `lessons/script.md` |
| `_ready` | `lessons/script.md` |
| `deferred` | `lessons/script.md` |
| `autoload` | `lessons/script.md` |
| `project-settings` | `lessons/script.md` |
| `typing` | `lessons/script.md` |
| `preload` | `lessons/script.md` |

> Agent 新增 lesson 时，同步更新本表。
