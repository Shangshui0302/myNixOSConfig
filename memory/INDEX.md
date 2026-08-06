# Memory 索引 — AI 决策记忆

遇到「为什么这么配」「历史决策」「硬件特性」问题时，先查本索引。卡片是原子化 markdown，放 `cards/`。新建卡片用 `_template.md`。

## 决策 decision

- [claude-code 版本策略: latest 跟随 nixpkgs](cards/claude-code-version-strategy.md) — 默认最新，可 pin 具体版本
- [portal-gtk dangling symlink 导致 fcitx5 浅色皮肤](cards/portal-gtk-dangling-symlink.md) — D-Bus 无法激活 portal-gtk 的根因修复
- [知识库分层: wiki 管怎么用, memory 管为什么](cards/wiki-memory-layering.md) — 纯 Markdown wiki + 决策卡架构
- [文档同步自动化: hook 门禁 + session-wrapup](cards/docs-sync-automation.md) — commit 硬门禁 + 会话收尾沉淀
- [mihomo TUN: gvisor + mtu 1500](cards/mihomo-tun-stack.md) — nix 下载慢的根因修复，吞吐 47 倍
- [AI 工具优先 llm-agents.nix](cards/ai-tools-source.md) — 第三方打包源，需安全审查
- [flake 全用 unstable](cards/flake-unstable-strategy.md) — 出问题再修，不 pin stable

## 硬件 hardware

- （暂无卡片）

## 约束 constraint

- [查包强制多路径搜索](cards/nix-search-before-manual.md) — 禁止一次查不到就手搓 Nix module
