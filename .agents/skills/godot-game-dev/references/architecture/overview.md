# 项目架构

## 目录结构
```
scripts/
├── core/              # 框架（不动）
│   ├── EventBus.gd    # 事件总线 (autoload)
│   ├── GameRoot.gd    # 启动根节点
│   └── TestHelper.gd  # 自检工具 (autoload)
├── managers/          # 全局管理器 (autoload)
│   ├── SceneManager.gd
│   ├── AudioManager.gd
│   └── SaveManager.gd
└── game/              # 游戏逻辑（频繁改动）
    ├── battle/        # BattleManager.gd
    ├── unit/          # Unit/Player/Enemy
    ├── projectile/    # Projectile
    ├── terrain/       # TerrainBlock
    └── config/        # GameConfig

scenes/
├── start.tscn         # 入口场景 (GameRoot + Camera)
└── battle.tscn        # 战场 (BattleManager)
```

## 信号流
```
_ready → 生成地形 → 生成单位 → 开始回合
  ↓
点击 → 计算角度力度 → 创建炮弹 → 发射
  ↓
炮弹碰撞 → 爆炸事件 → Unit 监听 → 距离检测 → 扣血
  ↓
单位死亡 → 检查胜负 → 下一回合
```

## 场景加载
GameRoot (持久) → add_child(battle.tscn) → BattleManager 接管
**不用 change_scene_to_file**
