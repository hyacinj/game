# 测试规范

> 测试是自维护系统的核心——自检通过 = 代码健康。

---

## TestHelper API

```gdscript
# 布尔断言：condition 为 true 即 PASS
TestHelper.check(something_worked, "玩家受到伤害")

# 相等断言：actual == expected
TestHelper.assert_eq(unit.hp, 80, "扣血后 HP 应为 80")

# 范围断言：lo <= value <= hi
TestHelper.assert_range(damage, 20, 30, "伤害应在 20~30 之间")
```

---

## 自检函数规范

每个游戏逻辑模块必须实现：

```gdscript
func _self_test() -> void:
    # 1. 准备测试数据
    # 2. 执行被测逻辑
    # 3. 调用 TestHelper.check/assert_eq/assert_range
    # 4. 清理副作用（如果有）
    pass
```

### 命名和位置
- 函数名必须为 `_self_test()`
- 放在类的公共方法区（或最后）
- 测试代码不应影响正常运行——用 `if not _test_mode: return` 守卫

---

## 测试运行流程

```
godot --headless --path <项目> <入口场景>
```

- 入口场景加载 → 调用各模块 `_self_test()` → TestHelper 统计 → 输出 `[TEST] SUMMARY: X/Y PASS`
- Agent 解析日志，PASS 数不对就修代码

---

## 测试覆盖要求

| 模块类型 | 最小覆盖 |
|---------|---------|
| Manager（管理器） | 核心流程 + 边界条件 |
| Unit（单位） | 伤害/死亡/状态切换 |
| Projectile（炮弹） | 飞行/碰撞/爆炸 |
| Terrain（地形） | 生成/破坏/消除 |
| Config（配置） | 数值范围校验 |

---

## 测试编写原则

1. **隔离** — 每个测试不依赖其他测试的执行结果
2. **可重复** — 相同输入永远产生相同输出
3. **自文档化** — 描述字符串写清楚 "什么情况下，期望什么"
4. **不污染** — 测试后清理创建的节点/资源

### 好的测试
```gdscript
TestHelper.assert_eq(unit.hp, 80, "满血100时受到20伤害后HP应为80")
```

### 不好的测试
```gdscript
TestHelper.check(ok, "works")           # 描述不清
TestHelper.assert_eq(x, y, "test 1")    # 序号无意义
```

---

## CI 集成

```powershell
# scripts/test.ps1 — 一键编译+测试
# 从 config/project.toml 自动读取所有参数
powershell -ExecutionPolicy Bypass -File scripts/test.ps1

# 跳过编译（仅测试）
powershell -ExecutionPolicy Bypass -File scripts/test.ps1 -SkipCompile

# 额外过滤关键词
powershell -ExecutionPolicy Bypass -File scripts/test.ps1 -Filter "damage|explosion"
```
