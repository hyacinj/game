# Skill 健康自检清单

Agent 应在以下时机执行自检：
- 每次会话开始时（可选轻量检查）
- 完成一个开发周期后（必须完整检查）
- 用户明确要求时

---

## 🔍 检查项

### 1. 文件完整性
- [ ] `SKILL.md` 存在且可读
- [ ] `_meta/version.txt` 版本号格式正确（X.Y.Z）
- [ ] `_meta/changelog.md` 记录与版本号一致
- [ ] `config/project.toml` 配置项完整
- [ ] `references/_index.md` 索引与实际文件一致

### 2. 引用有效性
- [ ] `SKILL.md` 中所有内部链接指向存在的文件
- [ ] `references/_index.md` 中所有链接指向存在的文件
- [ ] `references/lessons/` 中引用的 Godot API 未在 4.x 中废弃
- [ ] `references/architecture/` 中描述的目录结构与实际项目一致

### 3. 知识时效性
- [ ] `references/lessons/` 每条经验标注了验证版本
- [ ] `references/design/roadmap.md` 完成项有日期
- [ ] 没有过时的、与当前 Godot 版本冲突的建议

### 4. 可拓展性
- [ ] 新增 lesson 遵循 `_template.md` 格式
- [ ] 新增 reference 目录在 `_index.md` 中有记录
- [ ] `conventions/` 下的规范在项目中实际被遵守

### 5. 配置有效性
- [ ] `config/project.toml` 中 `godot.exe` 路径存在
- [ ] `config/project.toml` 中 `project.path` 路径存在
- [ ] `config/project.toml` 中 `project.entry_scene` 文件存在

---

## 🔧 自动修复

如果检查失败，Agent 应：
1. **文件缺失** → 根据模板重建
2. **引用断裂** → 更新 `_index.md` 或修正链接
3. **版本过期** → 在经验条目前追加 `⚠️ 待验证: Godot X.X`
4. **配置无效** → 提示用户更新 `config/project.toml`
