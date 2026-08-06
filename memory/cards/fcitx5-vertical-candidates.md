---
id: fcitx5-vertical-candidates
type: decision
tags: [fcitx5, ime, candidate, nix]
date: 2026-08-06
---

# fcitx5 垂直候选窗：键名含空格 + 值必须大写 True

## 问题
fcitx5 候选窗想要垂直排列，但配置选项名带空格（`Vertical Candidate List`），在 nix 里写 attr 时踩坑，且布尔值大小写敏感。

## 决策
`host/desktop.nix` 里 `i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection` 配置：

```nix
fcitx5.settings.addons.classicui.globalSection = {
  Theme = "mellow-wechat";
  DarkTheme = "mellow-wechat-dark";
  UseDarkTheme = "True";
  # 键名含空格，必须用引号包裹；值必须大写 True/False
  "Vertical Candidate List" = "True";
};
```

## Why
- **键名含空格**：classicui 配置项的官方名是 `Vertical Candidate List`（带空格），不是 camelCase。nix 里含空格的 attr 必须加引号 `"Vertical Candidate List"`，否则语法错误
- **值必须大写 `True`**：fcitx5 只识别大写 `True`/`False`，小写 `true`/`false`（某些配置工具会写）不被识别，配置静默失效。NixOS 有相关 issue（#295398）
- 与深色联动同处一个 `globalSection`：`UseDarkTheme=True` 时 fcitx5 通过 portal 检测深浅色切 `Theme`/`DarkTheme`

## How to apply
- 改 classicui 配置时，含空格的键名加引号，布尔值用大写 `True`/`False`
- 配置写入 `/etc/xdg/fcitx5/conf/classicui.conf`（NixOS 系统级），rebuild 后生效，需重启 fcitx5
- 引擎逻辑可能覆盖候选窗方向（个别输入法引擎仍可强制横向）

相关: [[portal-gtk-dangling-symlink]]
