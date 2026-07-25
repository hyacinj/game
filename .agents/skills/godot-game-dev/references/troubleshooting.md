# 故障排查指南

> 按症状查找 → 按方案修复。解决后，将新问题追加到 `references/lessons/` 对应文件。

---

## 🔴 编译期错误

### `class_name` 失效 / 类型找不到
**症状**: `Parser Error: Could not find type "ClassName"`  
**根因**: `.uid` 文件与脚本不同步  
**修复**:
1. 用编辑器打开一次项目（自动重建 uid 映射）
2. 或用 CLI: `godot --headless --path . --editor`（触发重新扫描）

### `blocked > 0` 错误
**症状**: `Can't change this state while flushing queries`  
**根因**: 在 `_ready` 里增减子节点  
**修复**: 用 `call_deferred("_add_children")` 延迟到下一帧执行

### autoload 未加载
**症状**: `Invalid get index 'xxx' (on base: 'null instance')`  
**根因**: autoload 声明顺序或未在编辑器中添加  
**修复**: 
1. 编辑器 → Project Settings → Autoload → 确认脚本已添加且 Enable 勾选
2. 检查声明顺序：被依赖的 autoload 必须在依赖者之前

---

## 🟡 运行时错误

### 碰撞信号不触发
**症状**: `body_entered` 从不发射  
**根因**: 碰撞对象不是物理体（RigidBody2D/StaticBody2D/CharacterBody2D）  
**修复**: 
- 物理碰撞 → 用 `body_entered`
- 非物理体（Node2D）→ 用事件系统 + 距离检测
- 高速物体 → 设 `continuous_cd = true`

### 炮弹穿透地形
**症状**: 炮弹穿过 StaticBody2D 不触发碰撞  
**根因**: 高速物体在一帧内穿过碰撞体  
**修复**: 在 RigidBody2D 上设 `continuous_cd = true`

### 场景切换后节点丢失
**症状**: 切场景后 Camera/UI 消失  
**根因**: 用了 `change_scene_to_file`（会销毁当前树）  
**修复**: 改用 `load(scene).instantiate()` → `add_child()`

### Canvas 子节点不渲染
**症状**: Label/Sprite 加了但看不见  
**根因**: Canvas 没有连 Camera，或子节点缺少 UITransform  
**修复**: 确保 Canvas 在 Camera2D 的渲染链中，或手动加 `UITransform`

---

## 🟢 测试相关

### 测试不运行
**症状**: `[TEST]` 日志没出现  
**根因**: 入口场景的 `_ready` 没有调用 `_self_test()`  
**修复**: 在 GameRoot 或 start.tscn 的根节点中显式调用各模块 `_self_test()`

### 测试结果不稳定
**症状**: 有时 PASS 有时 FAIL  
**可能原因**:
- 依赖 `await` 的时序不确定 → 用信号回调替代
- 物理模拟帧率不同 → 用固定 `delta` 或 `Engine.time_scale`
- 测试之间有状态残留 → 每个测试前重置状态

### Godot 命令找不到
**症状**: `godot: command not found`  
**修复**: 用 `config/project.toml` 中配置的完整路径，不依赖 PATH

---

## 📋 排查流程

```
遇到问题
  ↓
1. 看错误日志 → 确定症状类型
2. 查本文对应章节 → 有则按方案修复
3. 无匹配项 → 查 references/lessons/ 对应文件
4. 仍未解决 → 分析根因 → 修复 → 按 _template.md 格式写入 lessons/
5. 更新 _index.md（如果新增文件）
6. 如果是通用经验 → 同步更新本文的排查表
```

> ⚠️ 步骤 4-6 即 **知识回流协议**，详见 `SKILL.md §🔄 知识回流协议（自更新）`。
