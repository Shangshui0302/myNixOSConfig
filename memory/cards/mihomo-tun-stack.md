---
id: mihomo-tun-stack
type: decision
tags: [mihomo, tun, networking]
date: 2026-08-05
---

# mihomo TUN: 为什么 gvisor + mtu 1500

## 问题
`nixos-rebuild` / `nix-prefetch-url` 下载大文件（几十~几百 MB）时极慢（30KB/s~360KB/s）或长时间卡死；同一 URL 用 `curl` 却稳定 2~4MB/s。走国内镜像（TUNA/USTC，DIRECT）则秒下——说明网络、节点、TUN 都是通的，问题出在 nix HTTP 客户端与 mihomo TUN 的交互。

## 决策
`host/mihomo-config.yaml.in` 的 TUN 配置：
- `stack: gvisor`（原默认 `system` → 用户态协议栈）
- `mtu: 1500`（原默认 `9000` → 标准 MTU）

配套：`sniffer` 去掉 TLS 443/8443 嗅探（每条连接缓存包嗅探是纯开销，16 个 geosite 规则集已足够分流）。

## Why
- **`mtu: 9000` 巨型帧**：多数网络路径 MTU 是 1500，9000 强制分片 → 丢包/不稳定，高流量传输（大文件下载）时最明显，长连接中途断。
- **`stack: system` 内核协议栈**：对大量并发长连接（nix 的 curl_multi + HTTP/2 复用）丢回包，吞吐暴跌。
- 修复后吞吐提升 **47 倍**（2026-08-05 实测）。`pkgs.mihomo` 已带 `with_gvisor` 构建。

## How to apply
改 TUN 相关配置时保持 `gvisor + mtu 1500`。如调整先验证：
```bash
ip link show Meta | grep mtu   # 应显示 mtu 1500
nix build --dry-run '.#nixosConfigurations.MechRevo-NixOS.config.system.build.toplevel'
```

完整排查记录见 [[wiki/networking/mihomo.md#nix-下载慢]]
