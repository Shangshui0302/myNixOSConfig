---
id: gsettings-override-schema-packages
type: decision
tags: [gnome, gsettings, override, extraGSettingsOverridePackages, schema, extensions]
date: 2026-08-13
---

# GSettings override 生效条件：extraGSettingsOverridePackages + 扩展 schema 链接

## 问题

`services.desktopManager.gnome.extraGSettingsOverrides` 里配了 Console/nautilus/扩展的设置，但 `gsettings get` 返回默认值（或报"没有这个架构"）——override 段明明写在文件里却不生效。

## 决策

NixOS 官方文档（gnome.md）明确：**override 某包 schema 必须把该包加进 `extraGSettingsOverridePackages`**，否则 gschema 编译时丢弃未知段。

两层坑：
1. **普通包**（Console/nautilus 等标准 `share/gsettings-schemas/` 路径）：加 `pkgs.gnome-console`、`pkgs.nautilus` 到 `extraGSettingsOverridePackages` 即可
2. **GNOME Shell 扩展**（dash-to-dock/blur-my-shell/user-themes）：schema 在 `share/gnome-shell/extensions/<uuid>/schemas/`（**非标准路径**），直接加会让 `nixos-gsettings-overrides` 构建 `cp` 失败。需先用 `withStandardSchemas` 把 schema 链接到标准 gsettings-schemas 路径再添加

```nix
# specialisation/gnome/host.nix
withStandardSchemas = ext: ext.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    mkdir -p $out/share/gsettings-schemas/${ext.name}/glib-2.0/schemas
    cp -r $out/share/gnome-shell/extensions/*/schemas/*.gschema.xml \
      $out/share/gsettings-schemas/${ext.name}/glib-2.0/schemas/ 2>/dev/null || true
  '';
});
extraGSettingsOverridePackages = [ pkgs.gnome-console pkgs.nautilus
  (withStandardSchemas pkgs.gnomeExtensions.dash-to-dock)
  (withStandardSchemas pkgs.gnomeExtensions.blur-my-shell)
  (withStandardSchemas pkgs.gnomeExtensions.user-themes) ];
```

## Why

- `nixos-gsettings-overrides` 把 override 编译进 gschemas.compiled，只含它目录里的 schema；扩展 schema 非标准路径不在内 → override 段被编译丢弃（`gsettings` 报"没有这个架构"）
- `org.gnome.desktop.*` / `org.gnome.shell` 的 schema 由该包默认携带，所以那些段一直生效，易造成"部分生效"的假象

## How to apply

- 在 `extraGSettingsOverrides` 里加新段时，先确认该 schema 的包在不在 `extraGSettingsOverridePackages`
- 扩展设置走 override 必须 `withStandardSchemas`
- 验证：`NIX_GSETTINGS_OVERRIDES_DIR=<当前系统 override 路径> gsettings get <schema> <key>`（注意用当前系统路径，`ls -dt` 可能选到构建临时包）

相关: [[gnome-specialisation]] | [[wiki/desktop/gnome.md]]
