---
title: GNOME Keyring
category: desktop
tags: [keyring, gnome-keyring, libsecret, pam, electron, secret-service]
updated: 2026-08-06
---

# GNOME Keyring

## 概览

GNOME Keyring 是 Linux 上的**加密凭据存储服务**。它在 D-Bus 上暴露 `org.freedesktop.secrets` 接口（Secret Service API），应用通过 `libsecret` 库与之通信，安全存储密码、token、证书等敏感数据。

```
应用 (Qoder / VS Code / Chrome / ...)
  │
  │ libsecret (secret-tool / libsecret-1.so)
  │
  ▼
D-Bus: org.freedesktop.secrets
  │
  ▼
gnome-keyring-daemon
  │
  ├── login keyring  (登录时 PAM 自动解锁)
  ├── user keyring   (用户自管)
  └── ssh keyring    (SSH agent 集成, 可选)
```

## 为什么需要

Electron 应用（Qoder、VS Code、Claude Desktop、Chrome 等）依赖 Secret Service 存储加密数据：

- **VS Code / Qoder**：Settings Sync 加密 token、GitHub 认证
- **Chrome / Firefox**：保存的密码
- **Git credential helper**：`libsecret` 后端
- **SSH agent**：passphrase 缓存

没有 keyring 时会报错：

> An OS keyring couldn't be identified for storing the encryption related data in your current desktop environment

## 配置

### NixOS 侧 (`host/desktop.nix`)

```nix
services.gnome.gnome-keyring.enable = true;
```

这一行自动完成三件事：

| 功能 | 实现 |
|------|------|
| 安装软件 | `gnome-keyring` + `gcr`（含 `libsecret`） |
| PAM 集成 | `pam_gnome_keyring.so` 注入登录流程，自动解锁 login keyring |
| D-Bus 注册 | `/etc/xdg/autostart/gnome-keyring-*.desktop` → session 启动时拉起 daemon |

### 应用侧

Qoder 需要显式指定 `--password-store=gnome-libsecret`：

```nix
# local-deriv/qoder-ide.nix
makeWrapper $out/share/qoder/qoder $out/bin/qoder \
  --add-flags "--no-sandbox --disable-gpu-sandbox --password-store=gnome-libsecret"
```

其他 VS Code 系应用同理：`code --password-store=gnome-libsecret`

## 工作原理

```
登录输入密码
  │
  ▼
PAM (password-auth)
  ├─ pam_unix.so              ← 验证密码
  └─ pam_gnome_keyring.so     ← 用同一密码解锁 login keyring
  │
  ▼
Session 启动
  │
  ▼
gnome-keyring-daemon --start  ← 注册 D-Bus service
  │
  ▼
应用通过 libsecret 读写凭据
```

**关键**：PAM 只在登录时触发，所以配置 keyring 后必须**注销重新登录**，不能只重启应用。

## 不支持 keyring 时的备选

如果某个应用不需要加密存储，用 `basic` 存明文：

```
--password-store=basic   # 存 ~/.config/<app>/ 下的 JSON 文件（明文）
```

**不推荐**，仅作为临时绕过。

## 调试命令

```bash
# 检查 keyring daemon 是否运行
ps aux | grep gnome-keyring-daemon | grep -v grep

# 检查 D-Bus secret service 是否可用
busctl --user list | grep org.freedesktop.secrets

# 查看 keyring 内容
secret-tool search xdg:schema org.gnome.keyring.Note

# 查看 PAM 配置
cat /etc/pam.d/login | grep gnome_keyring

# 手动锁/解锁
gnome-keyring-daemon --unlock
gnome-keyring-daemon --lock
```

## 故障排查

### 注销重登后 keyring 仍未解锁

检查 PAM 配置是否包含 gnome_keyring：

```bash
grep gnome_keyring /etc/pam.d/login
```

输出应包含 `pam_gnome_keyring.so auto_start`。如果没有，确认 `services.gnome.gnome-keyring.enable = true` 已生效（rebuild 后可查）。

### secret-tool 报 "Cannot create an item in a locked collection"

login keyring 没解锁。**注销重新登录**（不是锁屏再解锁），PAM 才会触发。

### Qoder 仍然报 keyring 错误

1. 确认 Qoder 的 flag 已更新：`cat $(which qoder) | grep password-store`
2. 确认 gnome-keyring-daemon 在运行：`ps aux | grep gnome-keyring`
3. 确认 D-Bus service 已注册：`busctl --user introspect org.freedesktop.secrets /org/freedesktop/secrets`

## 注意事项

- **必须注销重登**，PAM 只在认证流程中触发，重启应用无效
- `services.gnome.gnome-keyring` 依赖很小（只拉 `gnome-keyring` + `gcr`），不引入整个 GNOME 桌面
- Hyprland + UWSM 下正常工作，PAM 不依赖特定 compositor
- keyring 文件存在 `~/.local/share/keyrings/`，受登录密码保护
- 修改登录密码后，keyring 密码需要手动同步（`gnome-keyring-daemon --change-password`）

## 相关链接

- [PAM — 可插拔认证模块](../pam.md)
- [约束与惯例](../constraints.md)
- [wiki 首页](../README.md)
