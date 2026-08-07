---
id: wiki-memory-layering
type: decision
tags: [wiki, memory, knowledge-base, documentation]
date: 2026-08-07
---

# 知识库分层：wiki 管「怎么用」，memory 管「为什么」

## 问题
`docs/` 是 11 个扁平 markdown，无导航、无组织、零交叉引用，且大量「为什么这么配」的决策知识散落在对话历史、auto-memory、CLAUDE.md 注释里，AI 和用户都难以按需检索。

## 决策
建立两层知识库 + 来源映射清单：
- **`wiki/`**：操作手册，回答「怎么用」，含故障排查。按 `architecture/`、`desktop/`、`productivity/`、`dev/`、`leisure/`、`networking/`、`security/`、`customization/` 分类子目录，每篇 frontmatter（title/category/tags/updated）+ TOC + 末尾 `## 相关链接` 双链 + 反链 memory 卡。
- **`memory/`**：决策记忆，回答「为什么」，AI 决策参考。`INDEX.md` + `cards/` 原子卡，三类：`decision`/`hardware`/`constraint`。
- **`wiki/_sources.yaml`**：来源映射清单（单真源）。每篇 wiki 文档声明派生自哪些 `.nix` + 关联哪些 memory 卡。doc-sync hook 与 wiki-maintainer skill 从此表实时计算反向映射（nix→docs）。

wiki 内容由三方合并：手写 wiki（怎么用）+ Qoder 生成的 content 树（结构/架构图）+ knowledge 知识库（模块级技术栈/编码规范/特殊命令）。决策/Why 不内联 wiki，改反链 memory 卡。

双链用 **markdown 相对链接**（`[x](desktop/hyprland.md)`）而非 Obsidian `[[ ]]`——纯 md 在编辑器/GitHub 可点击跳转，`[[ ]]` 只有 Obsidian 能渲染。memory 卡保留 `[[ ]]` 作为跨目录锚点。

## Why
- **分工边界**：wiki 存稳定操作手册（含故障排查），memory 存「从代码推不出来的 Why」。故障排查归 wiki 不迁 memory。
- **清单单真源**：避免 hook/skill 各维一份映射表，漂移后误拦或漏拦。
- **纯 Markdown**：零工具依赖，git 友好，符合 NixOS 声明式哲学，不引入 mdbook/mkdocs 构建链。
- **分类目录 + MOC**：README.md 做唯一导航（分类 MOC），子目录纯当容器，不建分类 _index 避免重复。
- **相关链接强制**：每篇必有 `## 相关链接`，形成可导航知识网络，杜绝孤岛文档。

## How to apply
- 新增 wiki 文档：按分类放子目录，frontmatter + TOC（>150 行）+ 相关链接 + 反链 memory 卡，注册到 `wiki/README.md` **和 `wiki/_sources.yaml`**
- 新增 memory 卡：用 `_template.md`，写完同步 `INDEX.md`
- 判定决策卡标准：配置的 Why 从 nix 代码 / commit message 推不出来 → 需要卡
- 改 nix → 读 `_sources.yaml` 反查受影响文档集 → 按三方合并规则更新正文 + 刷新 frontmatter `updated`

相关: [[docs-sync-automation]] | [[nix-search-before-manual]] | [[ai-tools-source]]
