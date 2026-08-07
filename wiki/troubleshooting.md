---
title: 故障排除
category: 顶层
tags: [troubleshooting, faq, index, issues]
updated: 2026-08-07
---

# 故障排除

本页是故障排查总览，**不重复正文**：按分类列出常见问题，每条指向对应 wiki 文档的故障排查节，或指向已归档的问题记录 `issues/archived/`。先按分类定位，再进入具体文档。

## 目录

1. [桌面与显示](#桌面与显示)
2. [输入法](#输入法)
3. [网络与代理](#网络与代理)
4. [认证与权限](#认证与权限)
5. [系统与部署](#系统与部署)
6. [娱乐与媒体](#娱乐与媒体)
7. [开发与容器](#开发与容器)
8. [已归档问题记录](#已归档问题记录)
9. [相关链接](#相关链接)

## 桌面与显示

- 屏幕亮度异常 / 全黑、Hyprland 缩放与模糊在 AMD 上的兼容问题 → [Hyprland 桌面](desktop/hyprland.md)
- 深色模式不生效 / 主题不一致 → [深色模式](desktop/darkmode.md)
- Noctalia 面板 / 登录器异常 → [Noctalia](desktop/noctalia.md)
- 密钥环（keyring）解锁失败 → [Keyring](desktop/keyring.md)

## 输入法

- fcitx5 无法切换、候选样式异常、Qt 应用浅色主题问题 → [fcitx5](desktop/fcitx5.md)
- fcitx5 主题相关归档记录 → [issues/archived/fcitx5-qt-light-theme.md](../issues/archived/fcitx5-qt-light-theme.md)

## 网络与代理

- 网络不通 / 代理异常 / TUN 接口未绑定 / sops 环境变量未注入 → [Mihomo 代理](networking/mihomo.md)
- 系统服务层面的网络诊断（NetworkManager、nftables、SSH）→ [系统服务](services.md#故障排查)
- mihomo 规则集格式无效 → [issues/archived/mihomo-rule-set-format-invalid.md](../issues/archived/mihomo-rule-set-format-invalid.md)

## 认证与权限

- Howdy 人脸识别失败、PAM 集成异常 → [PAM 认证](security/pam.md)
- 普通用户无法 rebuild / sudo 权限不足 → [部署与维护](deployment.md#故障排查)

## 系统与部署

- mihomo 无法启动、密钥缺失、rebuild 失败、文档门禁拒绝提交 → [部署与维护](deployment.md#故障排查)
- 音频 / 蓝牙 / 打印 / 电源服务异常 → [系统服务](services.md#故障排查)

## 娱乐与媒体

- Steam 崩溃、游戏黑屏、手柄无响应、性能骤降 → [游戏平台](leisure/gaming.md#故障排查)
- mpv 无法播放 / 无声、流媒体、缩略图不显示 → [媒体播放](leisure/media.md#故障排查)

## 开发与容器

- 容器镜像拉取慢 / TLS 错误、Distrobox 命令缺失 → [Distrobox](dev/distrobox.md)
- Bottles 离线运行问题 → [Bottles 离线](dev/bottles-offline-workaround.md)
- Podman 在 TUN 代理下拉取镜像 TLS 错误 → [issues/archived/podman-pull-tun-tls-error.md](../issues/archived/podman-pull-tun-tls-error.md)

## 已归档问题记录

`issues/archived/` 保存已解决问题的完整排查与修复记录，可作为同类问题的参考：

- [backlight-curve-overflow.md](../issues/archived/backlight-curve-overflow.md) — AMD 亮度曲线溢出导致全黑
- [fcitx5-qt-light-theme.md](../issues/archived/fcitx5-qt-light-theme.md) — fcitx5 在 Qt 应用中浅色主题
- [mihomo-rule-set-format-invalid.md](../issues/archived/mihomo-rule-set-format-invalid.md) — mihomo 规则集格式无效
- [onlyoffice-msfonts-cjk.md](../issues/archived/onlyoffice-msfonts-cjk.md) — OnlyOffice 缺 MS CJK 字体
- [podman-pull-tun-tls-error.md](../issues/archived/podman-pull-tun-tls-error.md) — TUN 代理下 podman pull TLS 错误

## 相关链接

- [系统服务](services.md) — 服务层排查入口
- [部署与维护](deployment.md) — 部署/升级/回滚排查
- [Mihomo 代理](networking/mihomo.md) ｜ [PAM 认证](security/pam.md) ｜ [Hyprland](desktop/hyprland.md) ｜ [fcitx5](desktop/fcitx5.md)
- memory：[mechrevo-amd-backlight-curve](../memory/cards/mechrevo-amd-backlight-curve.md)、[hyprland-056-blur-amd](../memory/cards/hyprland-056-blur-amd.md)、[portal-gtk-dangling-symlink](../memory/cards/portal-gtk-dangling-symlink.md)
