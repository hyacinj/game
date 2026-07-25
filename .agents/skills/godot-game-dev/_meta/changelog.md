# Changelog

格式遵循 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [SemVer](https://semver.org/)。

---

## [1.0.1] — 2026-07-25

### Changed
- **gdscript-style.md**: 新增 `:=` 类型推断禁令，列出会返回 Variant 的内置函数，补充安全/不安全场景
- **gdscript-style.md**: 禁止事项新增：`:=` Variant 推断、Tab/空格混用、`global_position` 在 `add_child` 前设置
- **testing.md**: 新增 "异步测试：事件驱动 vs await timer" 章节，强调 EventBus 回调优于时间猜测
- **troubleshooting.md**: 新增两种编译错误：`:=` Variant 推断 和 缩进 Indent 错误
- **SKILL.md**: 开发流程新增步骤 4（新脚本→运行 editor 生成 UID），补充缩进错误处理建议

### Lessons
- **script.md**: 追加 `:=` 类型推断、缩进混用 两条经验
- **physics.md**: 追加 `global_position` 时序、风力持续力、`linear_damp` 弹道偏差 三条经验

---

## [1.0.0] — 2026-07-25

### Added
- 初始化自维护体系：`_meta/`、`config/`、`conventions/`
- 知识回流协议：Agent 遇到新问题 → 解决后 → 写入 lessons → 更新 _index
- Lesson 标准模板 `_template.md`
- 故障排查指南 `troubleshooting.md`
- GDScript 编码规范 `gdscript-style.md`
- 测试规范 `testing.md`
- Healthcheck 自检脚本和清单
- 项目配置文件 `config/project.toml`

---

## [Unreleased] — 初始版本（改造前）

### 已有内容（迁移自旧版）
- SKILL.md 核心工作流
- references/architecture/overview.md — 项目架构
- references/architecture/file-classification.md — 文件分类规则
- references/design/roadmap.md — 开发路线图
- references/design/combat.md — 战斗系统
- references/lessons/physics.md — 物理踩坑
- references/lessons/rendering.md — 渲染踩坑
- references/lessons/script.md — 脚本踩坑
- scripts/test.ps1 — 编译测试脚本
