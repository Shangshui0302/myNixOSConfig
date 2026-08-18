---
id: variant-option-integrity
type: decision
tags: [architecture, variant, specialisation, hyprland, gnome, fcitx5]
date: 2026-08-13
---

# 双变体差异用 option 内聚（方案 C）

## 问题

main（Hyprland）与 GNOME 变体通过 `inheritParentConfig=false` 完全隔离后，出现两类模块：
- **纯共享**（两 DE 都要，如字体、网络、dev 工具）——该进共享 base
- **有细微差异**（大部分共享、小部分不同，如 fcitx5：核心两 DE 都要，主题 addons + classicui 只有 Hyprland 要）——怎么组织？物理拆两份会碎片化，硬塞进共享又带错变体的包。

## 决策

三分类架构（方案 C）：
1. 纯共享 → `host/base/`、`home/base.nix`
2. 纯变体专属（Hyprland compositor/foot/Noctalia，GNOME Shell 扩展）→ 物理隔离在 `host/de/`、`specialisation/gnome/`
3. **有细微差异的模块 → 一个文件 + `lib.optionals (!gnome)` / `lib.mkIf (!gnome)` 内聚差异**

范例（`host/base/desktop.nix` 的 fcitx5）：
```nix
let gnome = config.services.desktopManager.gnome.enable; in
fcitx5.addons = [ 核心4个 ] ++ lib.optionals (!gnome) [ fcitx5-gtk 主题4个 ];
fcitx5.settings.addons.classicui.globalSection = lib.mkIf (!gnome) { ... };
```

## Why

- **包体隔离不受影响**：`mkIf false`/`optionals` 空列表的东西 nix 根本不构建，gnome 变体闭包不含 Hyprland 专属 addons——和物理拆分效果完全一样，但模块内聚（一个文件看全）
- **避免碎片化**：拆目录会让"有差异的模块"散落 base + 两个变体多处，改一处忘一处
- **加模块心智负担低**：新模块先判断是纯共享/纯专属/有差异，差异的照 fcitx5 模板写 `lib.optionals (!gnome)` 即可

## How to apply

- 当前判据 `gnome = config.services.desktopManager.gnome.enable` 是**二元假设**（非 gnome 即 Hyprland）。加第三个变体时须泛化为显式 variant 标识（specialArgs 注入字符串），否则新变体 `gnome=false` 会错误拿到 Hyprland 专属包
- 新"有差异模块"：共享部分放 attrset 主体，差异部分 `++ lib.optionals (!gnome) [...]` 或 `lib.mkIf (!gnome)` 包裹
- 别把纯专属的东西塞进 base（那会污染另一个变体闭包）

相关: [[gnome-specialisation]] | [[wiki/desktop/fcitx5.md]] | [[wiki/desktop/darkmode.md]]
