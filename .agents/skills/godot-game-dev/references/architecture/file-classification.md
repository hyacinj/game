# 文件分类

## 🔴 禁止修改
- `project.godot` — 编辑器属性，autoload 通过 UI 添加
- `*.uid` — 引擎生成
- `.godot/` — 引擎缓存
- `*.import` — 导入配置

## 🟢 可修改
- `scripts/**/*.gd` — 游戏代码
- `scenes/**/*.tscn` — 场景文件
- `assets/**/*` — 资源文件

## 🟡 特殊操作
- 新增 autoload：编辑器 Project Settings → Autoload → 添加脚本 → 勾选 Enable
- 新增场景：手写 .tscn（模板见 SKILL.md）
