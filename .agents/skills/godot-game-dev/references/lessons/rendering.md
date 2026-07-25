# 渲染经验

## 坐标系
- **Godot 2D Y 轴向下**（正 Y = 下方）
- 摄像机默认位置 (0,0)，可视范围约 x: -960~960, y: -540~540
- 地形和单位放正 Y 区域（y=200~500）

## Camera2D
- `add_child(cam)` 之后才能 `cam.make_current()`
- `anchor_mode = ANCHOR_MODE_DRAG_CENTER` 防止窗口拉伸时视口错位
- 切场景不要用 `change_scene_to_file`（会销毁 Camera）
- 改用 `load(scene).instantiate()` → `add_child()`

## Canvas / UI
- Label、Graphics、Sprite 等 2D 组件**必须挂在 Canvas 节点下**
- Canvas 子节点需要 UITransform 才能正常渲染
- Canvas 不连 Camera 时渲染不可靠

## 背景色
```gdscript
RenderingServer.set_default_clear_color(Color(0.06, 0.1, 0.18))
```
