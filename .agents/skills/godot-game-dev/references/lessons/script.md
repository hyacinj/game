# 脚本经验

> **适用版本**: Godot 4.4.x | **最后更新**: 2026-07-25

---

## class_name 类型找不到

**问题现象**: `Parser Error: Could not find type "ClassName"`。

**复现条件**: 刚创建 `.gd` 文件并加了 `class_name`，或者移动/重命名了脚本文件。

**根因**: class_name 依赖脚本旁边的 `.uid` 文件（不在 .godot 里）。uid 与脚本路径绑定，路径变了 uid 就对不上。

**解决方案**:
1. 用编辑器打开一次项目（自动重建 uid 映射）
2. 或 CLI: `godot --headless --path . --editor`（触发重新扫描）
3. 不要删除 `.uid` 文件，不要删除 `.godot/`

**相关文件**: 所有带 `class_name` 的 `.gd` 文件

**标签**: script, class_name, build

---

## _ready 里增减节点报错

**问题现象**: `Can't change this state while flushing queries`（又名 `blocked > 0`）。

**复现条件**: 在 `_ready()` 中调用 `add_child()` 或 `remove_child()`。

**根因**: `_ready` 执行时场景树正在构建中（flushing），不允许结构变更。

**解决方案**: 用 `call_deferred("_add_children")` 将操作延迟到下一帧执行。

**相关文件**: 所有重写了 `_ready` 的脚本

**标签**: script, _ready, deferred

---

## EventBus 参数传递失败

**问题现象**: EventBus 发射事件后，监听方收到的参数为空或不正确。

**复现条件**: 用了 `signal.emit(arg1, arg2, arg3)` 固定参数方式。

**根因**: EventBus 是通用事件系统，不同事件的参数个数不同，固定参数无法适配。

**解决方案**: 用 `callv(args_array)` 动态传参：
```gdscript
func emit(event: String, args: Array = []) -> void:
    if _listeners.has(event):
        for listener in _listeners[event]:
            listener.callv(args)
```

**相关文件**: `scripts/core/EventBus.gd`

**标签**: script, eventbus, signal, autoload

---

## autoload 访问为 null

**问题现象**: `EventBus.some_method()` 报 `Invalid get index on null instance`。

**复现条件**: autoload 脚本在 Project Settings 中声明但顺序不对。

**根因**: autoload 声明顺序 = 加载顺序。如果 B 依赖 A，但 B 在 A 之前声明，B 的 `_ready` 里访问 A 会是 null。

**解决方案**:
1. 只在编辑器 UI（Project Settings → Autoload）中管理 autoload
2. 被依赖的 autoload 必须排在依赖者之前
3. 不手写 `project.godot`

**相关文件**: `project.godot`（编辑器管理）

**标签**: script, autoload, project-settings

---

## 类型标注 `Array[Enemy]` 失效

**问题现象**: GDScript 类型检查不生效，`Array[Enemy]` 等价于 `Array`。

**复现条件**: Enemy 的 `class_name` 尚未被引擎注册。

**根因**: 类型系统需要编辑器编译后建立 class_name → 类型的映射。CLI 编译后类型系统才完全可用。

**解决方案**: 先用编辑器或 `--editor` 参数编译一次，再用 CLI 测试。

**标签**: script, typing, class_name, build

---

## const preload 不等于类型导入

**问题现象**: `const Bullet = preload("res://bullet.gd")` 之后 `var b: Bullet` 报类型未知。

**根因**: `preload("path.gd")` 加载的是 GDScript 资源对象，不是类型名。class_name 注册的类型才可用于类型标注。

**解决方案**:
- 类型标注 → 用 `class_name`（如 `var b: BulletClass`）
- 实例化 → 用 `preload("path").instantiate()`

**标签**: script, preload, typing
