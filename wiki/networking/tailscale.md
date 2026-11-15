---
title: Tailscale
category: networking
tags: [tailscale, vpn, networking]
updated: 2026-11-15
---

# Tailscale

Tailscale 用于连接同一私有网络中的设备。系统配置提供客户端和开机启动的 `tailscaled` 服务；首次使用需要手动登录账户。

## 本机配置

| 项目 | 行为 |
|------|------|
| 配置入口 | `host/base/network.nix`，主桌面与 NextKDE 共用 |
| 版本来源 | `flake.lock` 锁定的 nixpkgs；当前为 Tailscale 1.104.5 |
| 网络接口 | `tailscale0` |
| 入站端口 | 原生模块放行 UDP 41641，供隧道连接使用 |
| DNS | `--accept-dns=false`，保留现有 Mihomo/NetworkManager DNS |
| 登录状态 | 由 Tailscale 保存在 `/var/lib/tailscale`，不写入 Git |
| 使用范围 | 普通客户端；配置不启用出口节点、子网路由发布或 Tailscale SSH |

关闭接收 Tailscale DNS 后，普通应用不会自动使用 MagicDNS。优先通过 `tailscale status` 查看设备的 Tailscale IP 并连接。

## 首次应用与登录

在本机终端手动应用配置：

```bash
cd /home/lishangshui/myNixOSConfig
sudo nixos-rebuild switch --flake .
sudo tailscale up --accept-dns=false
```

打开终端输出的登录链接，在浏览器中选择所需账户并授权此设备；若网络要求管理员审批，还需等待设备获批。

确认运行状态及本机地址：

```bash
systemctl status tailscaled.service tailscaled-set.service
tailscale status
tailscale ip -4
```

`tailscaled-set` 是设置偏好的 oneshot 服务，成功退出后显示 inactive 属正常情况；检查退出码和日志。`tailscaled` 应保持运行。

## 连接设备

先用 `tailscale status` 找到对方，再将下面的占位符替换为实际 IP 和用户名：

```bash
tailscale ping <对方的Tailscale-IP>
ssh <用户名>@<对方的Tailscale-IP>
```

从其他设备访问本机时，使用本机的 Tailscale IP 和 `lishangshui` 用户。SSH 使用已有 OpenSSH 服务，能否访问还取决于 tailnet 访问策略及本机防火墙。

## 与 Mihomo 共存

本机继续使用现有 Mihomo TUN 和 DNS。Tailscale 的 DNS 偏好由 Nix 管理，服务启动时重新设置；首次 `up` 也显式带上同一参数。

Mihomo 的 `fake-ip-filter` 排除 `+.tailscale.com` 与 `+.tailscale.io`，使控制服务器、DERP 和日志服务域名返回真实 IP。`tailscaled` 的带标记连接优先查物理网络路由，绕过 Mihomo；若拿到 `198.18.*` 假地址，会直接发往物理网关并超时。此排除项不等于启用 MagicDNS，也不改变其他域名的代理分流。

配置检查通过不代表两套 TUN 已实测互通。应用并登录后，应同时检查 Tailscale 对端连接与日常网页访问。

若有异常，先检查具体对端的路由，避免直接改动全局代理规则：

```bash
ip rule show
ip -6 rule show
ip route get <对方的Tailscale-IPv4>
tailscale netcheck
```

## 故障排查与回退

- **找不到命令或服务**：确认已成功 switch 到包含本次配置的系统代际。
- **服务启动但未连接**：运行 `tailscale status`，按提示登录或完成设备审批。
- **`tailscale up` 长时间不输出登录链接**：检查日志中的连接超时及 `getent ahostsv4 controlplane.tailscale.com`；若返回 `198.18.*`，先应用包含上述 Fake-IP 排除项的系统配置。Mihomo 重载后重启 `tailscaled` 清除旧解析状态，再重新运行登录命令。
- **IP 可用、名称不可用**：本机关闭了 Tailscale DNS 接管，先用 IP；需要 MagicDNS 时再设计与 Mihomo 的分域解析。
- **对端不可达**：检查双方在线状态、tailnet 访问策略、防火墙及上面的路由输出。
- **需要日志**：运行 `journalctl -b -u tailscaled -u tailscaled-set --no-pager`。

临时断开但保留登录状态：`sudo tailscale down`。再次连接运行 `sudo tailscale up --accept-dns=false`。

若本次系统切换导致异常，可在本机终端运行 `sudo nixos-rebuild switch --rollback`，恢复前一系统代际；回退不会删除 Tailscale 的登录状态。

## 相关链接

- [系统服务](../services.md)
- [Mihomo 代理](mihomo.md)
- [NixOS Tailscale 文档](https://wiki.nixos.org/wiki/Tailscale)
- [Tailscale 客户端偏好](https://tailscale.com/docs/features/client/manage-preferences)
- [配置源码](../../host/base/network.nix)
