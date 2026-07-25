# 渲染经验

> **适用版本**: Godot 4.4.x | **最后更新**: 2026-07-25

---

## 节点位置偏移 / 显示在屏幕外

**问题现象**: 地形或单位生成后在屏幕上看不到，或者位置偏了很远。

**复现条件**: 把节点放在 Y < 0 的区域。

**根因**: Godot 2D Y 轴向下（正 Y = 下方），摄像机默认位置 (0,0)，可视范围约 x: -960~960, y: -540~540。放负 Y 区域 = 屏幕上方外面。

**解决方案**: 地形和单位放在正 Y 区域（y = 200~500 是安全范围）。

**相关文件**: `scenes/start.tscn`, `scripts/game/terrain/TerrainBlock.gd`

**标签**: rendering, coordinate, camera

---

## Camera2D 不生效

**问题现象**: `cam.make_current()` 调用后画面没变化。

**根因**: Camera2D 必须先加入场景树（`add_child`）再调 `make_current()`，否则当前 Camera 未注册。

**解决方案**:
```gdscript
var cam = Camera2D.new()
add_child(cam)
cam.make_current()
```
另外设置 `anchor_mode = ANCHOR_MODE_DRAG_CENTER` 防止窗口拉伸时视口错位。

**相关文件**: `scripts/core/GameRoot.gd`

**标签**: rendering, camera

---

## 切场景后 Camera/UI 消失

**问题现象**: 切换场景后画面黑屏或 UI 丢失。

**根因**: 用了 `get_tree().change_scene_to_file()`——它会销毁整个场景树，包括 Camera 和 UI。

**解决方案**: 改用 `load(scene).instantiate()` → `add_child()`，保持 Camera 和持久节点存活。

**相关文件**: `scripts/managers/SceneManager.gd`

**标签**: rendering, scene, camera, architecture

---

## Canvas 子节点不渲染

**问题现象**: Label、Sprite 等已添加为 Canvas 子节点，但不可见。

**根因**: Canvas 子节点需要 `UITransform` 才能被渲染管线正确处理；Canvas 不连 Camera 时渲染也不可靠。

**解决方案**:
1. 确保 Canvas 在 Camera2D 的渲染链中
2. 手动为子节点添加 `UITransform` 组件（如果缺失）

**相关文件**: `scripts/core/GameRoot.gd`

**标签**: rendering, canvas, ui

---

## 背景色设置

**问题现象**: 默认灰白色背景不好看。

**解决方案**: 在启动脚本中设：
```gdscript
RenderingServer.set_default_clear_color(Color(0.06, 0.1, 0.18))
```

**相关文件**: `scripts/core/GameRoot.gd`

**标签**: rendering, background
