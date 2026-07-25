---
name: godot-game-dev
description: >
  Godot 4 游戏开发的标准化工作流。当用户提到 Godot、GDScript、.tscn 场景、
  game development、游戏开发、或对 D:\Projects\新建游戏项目 进行操作时触发。
  覆盖：文件规则、编译测试、自检系统、窗口管理。
  禁止手写 project.godot，禁止删除 .godot 目录。
---

## 项目路径
`D:\Projects\新建游戏项目`

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

## 开发流程

```
1. 写/改 .gd 脚本
2. 写/改 .tscn 场景
3. 添加自检: TestHelper.check/assert_eq/assert_range
4. 编译: godot --headless --path . --editor   (5秒)
5. 测试: godot --headless --path . res://scenes/start.tscn
6. 看日志 [TEST] PASS/FAIL → 修 → 回到 4
7. git commit
```

## 窗口规则
- **编译/测试**：`--headless` 无窗口
- **人工看画面**：`--editor` 开 GUI（用户手动操作）

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

## 查资料
遇到具体问题时读对应 reference：
- 渲染问题 → `references/lessons/rendering.md`
- 物理问题 → `references/lessons/physics.md`
- 脚本问题 → `references/lessons/script.md`
- 架构疑问 → `references/architecture/`
- 策划需求 → `references/design/`
