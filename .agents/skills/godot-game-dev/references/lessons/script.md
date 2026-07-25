# 脚本经验

## class_name
- 依赖 `.uid` 文件（在脚本旁边，不在 .godot 里）
- 删 .godot 不影响 class_name
- 如果失效，打开一次编辑器自动修复

## EventBus
- `callv(args_array)` 传参，不要用 `call(a,b,c)` 固定参数
- autoload 里用 `var _listeners: Dictionary = {}`

## _ready 限制
- `_ready` 里不要做增减节点的操作（报 `blocked > 0` 错误）
- 用 `call_deferred("method")` 延迟到下一帧

## autoload
- 声明顺序 = 加载顺序（先声明的先加载，可被后面的引用）
- 只在编辑器 UI 里添加，不手写 project.godot

## GDScript 陷阱
- `Array[Enemy]` 类型标注需要 class_name 已注册
- `const X = preload("path.gd")` 只加载脚本资源，不是类型
- 用编辑器编译后再跑 CLI，类型系统才生效
