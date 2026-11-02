---
title: KWallet 共享凭据存储
category: desktop
tags: [keyring, kwallet, libsecret, pam, electron, secret-service]
updated: 2026-11-02
---

# KWallet 共享凭据存储

## 概览

Hyprland、niri 和 NextKDE 共用同一套 KWallet。GNOME Keyring 服务已禁用，现有钱包文件不会被配置删除或迁移。

当前 KWallet 6.31 分为两个进程：`kwalletd6` 提供传统 KWallet 接口，`ksecretd` 提供 Secret Service。`libsecret` 是协议客户端，保留它不代表启用 GNOME Keyring。

```text
Chrome --password-store=kwallet6
  → org.kde.kwalletd6 → ksecretd → KDE 钱包
其他 Secret Service 客户端
  → org.freedesktop.secrets → ksecretd → KDE 钱包
```

## 为什么需要

Chrome 的 Cookie 数据库位于用户 HOME，桌面变体不会为它各保存一份。浏览器根据桌面自动更换密钥后端，可能导致解密失败；上游存在清理加载失败 Cookie 的路径，切回原桌面也不能恢复已删记录。

共享配置固定 Chrome 的后端，避免每次切换桌面重新选择。已失效的登录需要重新登录；该配置不恢复已删除的 Cookie。

## 配置

### NixOS 侧

`host/base/desktop.nix` 负责：

| 功能 | 实现 |
| --- | --- |
| 唯一凭据服务 | 禁用 GNOME Keyring，注册 KWallet 与标准 Secret Service 激活入口 |
| KWallet 后端 | 系统级 `kwalletrc` 固定启用 KSecretD |
| 密码登录 | `security.pam.services.login.kwallet.enable`；greetd 和 SDDM 引用 login 栈 |
| TTY 会话 | 主桌面启用 `forceRun`，会话启动时执行 `pam_kwallet_init` |
| 管理界面 | KWalletManager；NextKDE 由 Plasma 模块提供 |

### 应用侧

`home/leisure/browser.nix` 为 Chrome 包统一加入 `--password-store=kwallet6`，菜单、默认浏览器和终端入口一致。应用后可在 `chrome://version` 核对命令行。

其他 Electron 应用并未统一修改启动参数；通过 Secret Service 访问凭据的客户端会使用 KWallet。以前保存在 GNOME Keyring 的应用凭据不会自动迁移，必要时需重新登录。Firefox 的登录存储不能直接等同于 Chrome。

## 工作原理

密码登录时，PAM 收集密码并启动钱包进程；进入图形会话后 `pam_kwallet_init` 传递会话环境。自动解锁要求使用兼容的 `kdewallet`，且钱包密码与登录密码一致。

人脸登录没有提供钱包密码，首次需要凭据时可能弹出解锁提示。用 KWalletManager 解锁，或在应用请求时输入钱包密码；不要为了免提示改用浏览器 `basic` 后端。

## 应用与桌面切换

修改后由用户手动执行系统应用，然后重启，避免旧 GNOME Keyring 进程继续持有服务名。仅更新 Nix 文件或重启 Chrome 不会完成服务切换。

两个桌面都必须来自包含本修复的新 generation。旧 generation 仍保留旧启动参数和服务配置。

检查顺序：Hyprland 登录网站 → 完全退出 Chrome → 切换 NextKDE → 检查网站登录 → 完全退出 Chrome → 切回 Hyprland 再检查。构建通过不等于此往返测试已通过。

## 调试命令

以下命令在实际图形会话的终端中运行，只查看服务状态，不读取密码：

```bash
busctl --user list | grep -E 'org.freedesktop.secrets|org.kde.kwalletd6'
systemctl --user status plasma-kwallet-pam.service
grep kwallet /etc/pam.d/login
journalctl -b | grep pam_kwallet
```

主桌面的初始化服务是 oneshot，成功后显示 inactive 并不代表失败；检查退出状态和日志。它只处理 PAM 凭据，不是常驻钱包服务。

## 故障排查

- **钱包未自动解锁**：确认是否人脸登录、钱包名称和密码是否匹配；用 KWalletManager 手动解锁。
- **服务名仍由 GNOME 占用**：检查是否启动了旧 generation，完成新配置应用后重启。
- **Chrome 再次掉登录**：核对 `chrome://version` 的参数、实际 Profile Path 和钱包服务。不要反复更换后端测试现有资料。
- **Electron 应用提示无法解密**：服务已更换，但原 GNOME Keyring 中的凭据未迁移，需按应用重新登录；不要清空整个钱包。

## 其他桌面组件

Hyprland/niri 的文件选择器单独指定 Strata（GTK 为后续候选），其他接口保留 Hyprland/wlr 与 GTK 的默认选择顺序；录屏分别使用 Hyprland/wlr，深浅模式仍由 Darkman 提供。没有额外设置 `none` 禁用接口。NextKDE 保留 Plasma 默认 Portal 组合。

Strata 的文件选择器面向本地文件和目录，仅作用于使用 Portal 的应用。系统包提供 Portal 元数据与 D-Bus 激活入口，无需运行 `strata --install-portal`，Home Manager 为 Hyprland/niri 链接与系统同源的桌面专用配置，优先于历史用户 `portals.conf`；不删除该旧文件。

AT-SPI、GTK/GSettings、GVfs 保留给现有无障碍及 GTK/GIO 消费者，它们不能通过换装 KIO 直接替代。名称中出现 GNOME 不等于运行 GNOME 桌面。

## 相关链接

- [PAM — 可插拔认证模块](../security/pam.md)
- [深浅模式](darkmode.md)
- [KWallet 6.31 上游说明](https://github.com/KDE/kwallet/blob/v6.31.0/README.md)
- [wiki 首页](../README.md)
