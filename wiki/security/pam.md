---
title: PAM — 可插拔认证模块
category: 安全
tags: [pam, authentication, security, login, sudo, keyring]
updated: 2026-08-07
---
# PAM — 可插拔认证模块

## 概览

PAM（Pluggable Authentication Modules）是 Linux 的**身份认证框架**。它把"认证"这个动作拆成可插拔的模块，每个模块做一件事，最终串联成一条认证链。

```text
你输入密码
  │
  ▼
PAM (认证链)
  ├─ pam_unix.so            ← 验证密码是否匹配 /etc/shadow
  ├─ pam_env.so             ← 加载环境变量
  ├─ pam_gnome_keyring.so   ← 自动解锁 login keyring
  └─ pam_systemd.so         ← 注册用户 session
  │
  ▼
认证通过 → 进入系统
```

## PAM 的设计原则

PAM 的核心思想是**分离策略和机制**：

- **应用**（login、sudo、sshd、greetd）只告诉 PAM："我要认证这个用户"
- **模块**（`pam_unix.so`、`pam_fprintd.so`）知道怎么做
- **配置文件**（`/etc/pam.d/<service>`）定义用哪些模块、什么顺序

应用不需要知道密码怎么验证的、指纹怎么读的——PAM 替它们操心。

## PAM 的四种 facility

每个 PAM 模块可以在以下阶段介入：

| 阶段               | 英文                | 含义                  | 例子                                     |
| ------------------ | ------------------- | --------------------- | ---------------------------------------- |
| **auth**     | authentication      | 验证你是谁            | 核对密码、指纹、人脸                     |
| **account**  | account management  | 检查是否有权限        | 账户过期了？只允许工作时间登录？         |
| **session**  | session management  | 登录/登出时的收尾工作 | 创建 home 目录、挂载加密盘、解锁 keyring |
| **password** | password management | 修改密码时            | 强制密码复杂度                           |

## 控制行为

模块返回结果后，PAM 根据控制位决定继续还是中止：

| 控制位         | 含义                                                 |
| -------------- | ---------------------------------------------------- |
| `required`   | 必须通过，但即使失败也继续跑完所有模块（最后才报错） |
| `requisite`  | 必须通过，失败立刻中止                               |
| `sufficient` | 如果通过，直接跳过后续模块（成功短路）               |
| `optional`   | 通过与否不影响整体结果                               |

实际中更常用复合控制：`[success=ok default=bad]` 这种精确控制。

## 我们的 PAM 配置

### 登录 (`/etc/pam.d/login`)

```text
auth       requisite   pam_unix.so
auth       optional    pam_gnome_keyring.so
session    required    pam_systemd.so
session    optional    pam_gnome_keyring.so auto_start
```

关键行：

| 行                                            | 作用                             |
| --------------------------------------------- | -------------------------------- |
| `pam_unix.so` (auth)                        | 用`/etc/shadow` 验证密码       |
| `pam_gnome_keyring.so` (auth)               | 用登录密码尝试解锁 login keyring |
| `pam_systemd.so` (session)                  | 注册 systemd user session        |
| `pam_gnome_keyring.so auto_start` (session) | 如果 keyring 还没跑，启动它      |

### sudo (`/etc/pam.d/sudo`, NixOS 默认)

```text
auth       sufficient   pam_unix.so   likeauth try_first_pass
auth       sufficient   pam_rootok.so
```

NOPASSWD 规则（`host/users.nix`）绕过了密码质询，但 PAM 栈仍然跑。

### 人脸登录与 keyring 的矛盾

Howdy（`pam_howdy.so`）用红外摄像头做人脸识别。典型配置是 `sufficient` 控制位——扫脸成功直接跳过密码：

```text
auth sufficient  pam_howdy.so              ← 人脸识别成功！
auth required    pam_unix.so                ← 被跳过，没拿到密码
auth optional    pam_gnome_keyring.so       ← 没有密码，无法解锁 keyring
```

**根因**：`pam_gnome_keyring.so` 在 auth 阶段需要用登录密码来解密 keyring。但 Howdy 用 `sufficient` 短路了整个 auth 链——密码从来没被捕获过，keyring 就只能保持锁定。

这不是 Howdy 的 bug，是 **无密码认证 × 密码解锁 keyring** 这个根本矛盾。指纹（`pam_fprintd.so`）和 FIDO2 同样会遇到。

**三种应对**：

| 方案            | 做法                                                                  | 取舍                                     |
| --------------- | --------------------------------------------------------------------- | ---------------------------------------- |
| 空密码 keyring  | `gnome-keyring-daemon --change-password` 设为空，或初始创建时就留空 | 凭据文件可被任何登录用户读取             |
| 扫脸 + 密码双重 | `pam_howdy.so` 用 `required` 代替 `sufficient`                  | 人脸白用了，每次还得输密码               |
| 接受手动解锁    | 人脸登录后，有应用需要 keyring 时会弹解锁对话框，输一次密码           | 不额外操作；弹出时才输，不是每次开机都输 |

实际上 `pam_gnome_keyring.so` 在 auth 阶段是 `optional` 控制位——有密码就用，没密码就静默跳过。所以默认行为是第三种：人脸登录后 keyring 锁定，Electron 应用（Qoder、VS Code、Chrome）触发 keyring 访问时弹出解锁提示，输一次登录密码即可，不是每次重启都要输。

## 常见 PAM 模块

| 模块                     | 用途                                             |
| ------------------------ | ------------------------------------------------ |
| `pam_unix.so`          | 传统 UNIX 密码验证（读`/etc/shadow`）          |
| `pam_systemd.so`       | 注册 logind session，管理 cgroup                 |
| `pam_gnome_keyring.so` | 解锁/启动 GNOME Keyring                          |
| `pam_env.so`           | 读取`/etc/environment`、`~/.pam_environment` |
| `pam_fprintd.so`       | 指纹认证                                         |
| `pam_faillock.so`      | 失败锁定（防暴力破解）                           |
| `pam_rootok.so`        | 检查是否 root — 如果是，直接通过                |

## 调试命令

```bash
# 查看某服务的 PAM 配置
cat /etc/pam.d/login
cat /etc/pam.d/sudo
cat /etc/pam.d/greetd

# 列出所有 PAM 服务
ls /etc/pam.d/

# 查看 PAM 相关系统服务
ls /run/current-system/sw/share/X11/fonts  # 不相关，改用：
systemctl --user status dbus

# 查看 login 日志（PAM 错误记录在此）
journalctl -u systemd-logind -f
journalctl -b | grep -i pam
```

## 故障排查

### 登录变慢

特定模块超时（如 `pam_fprintd.so` 等指纹非必需模块）。查 `journalctl -b | grep pam` 看哪个阶段卡住。

### 忘记密码

如果是单用户机器，可以用 NixOS live USB 启动 → mount 硬盘 → `passwd` 改密码。但 `chmod u+s` 也放了，正常操作不需要。

### keyring 没自动解锁

检查 `/etc/pam.d/login` 是否有 `pam_gnome_keyring.so` 行。NixOS 中由 `services.gnome.gnome-keyring.enable` 控制。确认后注销重登（锁屏解锁不走 PAM auth）。

## 注意事项

- **修改 PAM 配置要极度小心** — 配错会导致无法登录。NixOS 通过 option 管理 PAM 是安全的，不要手动改 `/etc/pam.d/`
- `services.gnome.gnome-keyring.enable` 只改动 `login` 和 `greetd` 的 PAM 配置
- PAM 是串行的 — 一个模块超时会拖慢整个认证链
- NixOS 中 PAM 配置由 `security.pam.services` 声明式管理，rebuild 后生效

## 相关链接

- [GNOME Keyring](../desktop/keyring.md) — 依赖 PAM 自动解锁
- [安全总览](index.md) — SOPS、用户权限、网络安全概览
- [wiki 首页](../README.md)

