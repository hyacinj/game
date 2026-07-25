---
name: godot-game-dev
version: "1.0.0"
description: >
  Godot 4 游戏开发的标准化工作流。当用户提到 Godot、GDScript、.tscn 场景、
  game development、游戏开发、或对当前项目进行操作时触发。
  覆盖：文件规则、编译测试、自检系统、窗口管理、
  知识回流（自更新）、健康自检（自维护）、目录扩展（可拓展）。
  禁止手写 project.godot，禁止删除 .godot 目录。
---

## ⚡ 上下文预算

> 本 skill 共 19 个文件 / ~1100 行。Agent 按需加载，不全量预读。

| 时机 | 必读（预加载） | 按需读取 |
|------|---------------|---------|
| **触发 skill 时** | `SKILL.md`（本文件） | — |
| **写 GDScript 时** | — | `conventions/gdscript-style.md` |
| **写测试时** | — | `conventions/testing.md` |
| **编译/运行前** | `config/project.toml` | — |
| **遇到报错时** | — | `references/troubleshooting.md` → `lessons/<category>.md` |
| **不了解结构时** | — | `references/_index.md` → 按需跳转 |
| **完成功能后** | 知识回流协议（本文 §🔄） | `references/lessons/_template.md` |
| **会话结束时** | 自维护协议（本文 §🔍） | `_meta/healthcheck.md` |

**原则**: 先查索引（`_index.md`），再点对点读具体文件。不要一口气吞掉所有 reference。

---

## 项目信息

> 具体路径从 `config/project.toml` 读取，不硬编码。
> Godot 版本: 4.4.1-mono | Skill 版本: 1.0.0

---

## 文件规则

### 🔴 绝不手写
- `project.godot` — 编辑器会覆盖
- `.godot/` — 引擎缓存，删了 class_name 全挂
- `*.uid` — 脚本 UID 映射

### 🟢 Agent 自主
- `scripts/**/*.gd` — 所有游戏逻辑
- `scenes/**/*.tscn` — 场景文件（纯文本，可手写）

### 🟡 编辑器操作（极其罕见）
- 新增 autoload → Project Settings → Autoload 面板
- 详细分类见 `references/architecture/file-classification.md`

---

## 开发流程

```
1. 写/改 .gd 脚本（遵守 conventions/gdscript-style.md）
2. 写/改 .tscn 场景
3. 添加自检: TestHelper.check/assert_eq/assert_range（遵守 conventions/testing.md）
4. 编译: godot --headless --path . --editor   (5秒)
5. 测试: godot --headless --path . res://scenes/start.tscn
6. 看日志 [TEST] PASS/FAIL → 修 → 回到 4
7. git commit
```

---

## 窗口规则
- **编译/测试**：`--headless` 无窗口
- **人工看画面**：`--editor` 开 GUI（用户手动操作）

---

## 场景模板
```gdscript
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/xxx.gd" id="1_xxx"]
[node name="Root" type="Node2D"]
script = ExtResource("1_xxx")
```

## 自检模板
```gdscript
func _self_test() -> void:
    TestHelper.check(condition, "description")
    TestHelper.assert_eq(actual, expected, "description")
    TestHelper.assert_range(value, lo, hi, "description")
```

---

## 🔄 知识回流协议（自更新）

> 这是 skill 的**核心自更新机制**。Agent 在开发中遇到问题并解决后，必须执行回流。

### 触发条件
以下任一情况发生时，Agent 必须将知识写回 skill：
- 遇到一个**新类型错误**并找到解决方案
- 发现一个**代码模式**可以复用到其他模块
- 踩到一个**Godot 坑**（API 行为与预期不符）
- 完成一个 `design/roadmap.md` 中的待办项
- 发现 conventions 中的规范需要补充

### 回流流程
```
1. 确定知识类别（物理/渲染/脚本/架构/设计/流程）
2. 打开 references/lessons/_template.md 作为格式参考
3. 将新经验追加到 references/lessons/<category>.md 末尾
   （如果是全新领域，新建文件但保留 _template.md 格式）
4. 更新 references/_index.md 的索引条目
5. 如果是重要经验，更新 references/troubleshooting.md 的排查表
6. 更新 design/roadmap.md（如果涉及功能完成）
7. 更新 _meta/changelog.md（如果 skill 本身结构有变化）
```

### 不回流的情况
- 语法错误/拼写错误（一次性修复，无需记录）
- 已在现有 lessons 中覆盖的重复问题
- Godot 官方文档已充分说明的标准 API 用法

---

## 🔍 自维护协议

### 会话启动时（轻量）
Agent 应快速检查：
1. `config/project.toml` 中的 Godot 路径是否存在
2. 上次测试结果（如果可用）
3. roadmap 是否有超过 7 天未更新的进行中任务

### 开发周期结束时（必须）
Agent 执行完整健康检查，参考 `_meta/healthcheck.md`：
1. 文件完整性检查
2. 引用有效性检查
3. 知识时效性检查
4. 配置有效性检查

### 发现问题时
- 可自动修复的 → 修 + 记录到 changelog
- 需用户决策的 → 提示用户 + 给出建议

---

## 📐 可拓展规则

### 目录扩展
Agent 可在以下条件下创建新目录：

| 位置 | 允许创建 | 条件 |
|------|---------|------|
| `references/design/` | `design.md` | 游戏总策划 |
| `references/design/specs/` | 新 `.md` 文件 | 每个系统一个文件（需求+进度） |
| `references/lessons/` | 新 `.md` 文件 | 遵循 `_template.md` 格式 |
| `references/architecture/` | 新 `.md` 文件 | 补充架构文档 |
| `conventions/` | 新 `.md` 文件 | 新增规范类别 |
| `scripts/` | 新脚本 | 辅助开发流程 |

### 禁止创建
- 不在 skill 目录下创建 `.gd` 游戏逻辑文件（应在项目 `scripts/` 下）
- 不创建与现有文件重复的 reference

### 移植到其他项目
1. 复制整个 skill 目录到新项目的 `.agents/skills/`
2. 修改 `config/project.toml` 中的路径
3. 清空 `references/lessons/` 中项目特定的经验（可选）
4. 保留 `conventions/` 和 `_meta/`（通用）

---

## 查资料

> 按照优先级从高到低查找：

1. **出错了？** → `references/troubleshooting.md`
2. **不确定怎么写？** → `conventions/gdscript-style.md`
3. **想知道怎么测？** → `conventions/testing.md`
4. **踩坑了？** → `references/lessons/<category>.md`
5. **想了解这游戏是什么？** → `references/design/design.md`（总策划）
6. **想了解某个系统？** → `references/design/specs/<系统名>.md`（需求+进度，共 7 个系统）
7. **想了解代码结构？** → `references/architecture/overview.md`
8. **想知道什么能改？** → `references/architecture/file-classification.md`
9. **找文件索引？** → `references/_index.md`
10. **查版本/变更？** → `_meta/changelog.md`
11. **执行健康检查？** → `_meta/healthcheck.md`
