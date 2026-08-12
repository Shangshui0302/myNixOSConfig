# Memory 索引 — AI 决策记忆

遇到「为什么这么配」「历史决策」「硬件特性」问题时，先查本索引。卡片是原子化 markdown，放 `cards/`。新建卡片用 `_template.md`。

## 决策 decision

- [claude-code 版本策略: latest 跟随 nixpkgs](cards/claude-code-version-strategy.md) — 默认最新，可 pin 具体版本
- [fcitx5 垂直候选窗: 键名含空格 + 值大写 True](cards/fcitx5-vertical-candidates.md) — classicui 配置坑
- [portal-gtk dangling symlink 导致 fcitx5 浅色皮肤](cards/portal-gtk-dangling-symlink.md) — D-Bus 无法激活 portal-gtk 的根因修复
- [知识库分层: wiki 管怎么用, memory 管为什么](cards/wiki-memory-layering.md) — 纯 Markdown wiki + 决策卡架构
- [文档同步自动化: hook 门禁 + session-wrapup](cards/docs-sync-automation.md) — commit 硬门禁 + 会话收尾沉淀
- [mihomo TUN: gvisor + mtu 1500](cards/mihomo-tun-stack.md) — nix 下载慢的根因修复，吞吐 47 倍
- [sops 解密密钥: SSH host key + useSystemdActivation](cards/sops-ssh-host-key.md) — initrd 时序修复，免独立 age key
- [AI 工具优先 llm-agents.nix](cards/ai-tools-source.md) — 第三方打包源，需安全审查
- [Qoder IDE 用国际版](cards/qoder-ide-source.md) — download.qoder.com，非 qoder.com.cn 国内版
- [flake 全用 unstable](cards/flake-unstable-strategy.md) — 出问题再修，不 pin stable
- [AMD 核显留在 nixpkgs 默认内核](cards/amd-kernel-stay-lts.md) — 不上 linuxPackages_latest，避 RDNA 硬挂起回归
- [GNOME 用 specialisation 变体](cards/gnome-specialisation.md) — 保留 kmscon 主流程，GDM 隔离
- [TTY 下 DE 切换: kmscon/uwsm 会话管理](cards/uwsm-kmscon-session-handoff.md) — graphical-session.target 残留 + fcitx5 autostart 机制
- [Flatpak 声明式管理: nix-flatpak home-manager 模块](cards/nix-flatpak-declarative-flatpak.md) — services.flatpak.packages/overrides

## 硬件 hardware

- [Hyprland 0.56 blur 在 AMD 780M 上失效](cards/hyprland-056-blur-amd.md) — new_optimizations 关闭恢复模糊
- [机械革命无界14X AMD 背光曲线溢出](cards/mechrevo-amd-backlight-curve.md) — dcdebugmask=0x40000 禁用 custom brightness curve
- [niri/cosmic 局部雪花点闪烁](cards/mechrevo-psr-snow-artifacts.md) — PSR/Panel Replay 固件 bug，dcdebugmask 未解决

## 约束 constraint

- [查包强制多路径搜索](cards/nix-search-before-manual.md) — 禁止一次查不到就手搓 Nix module
