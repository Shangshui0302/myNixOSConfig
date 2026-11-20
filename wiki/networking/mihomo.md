---
title: Mihomo 代理
category: networking
tags: [mihomo, tun, proxy, nftables, vpn]
updated: 2026-11-20
---

# Mihomo 代理

日常修改共同规则、更新节点与跨设备分发，请看 [Mihomo 配置修改与分发](mihomo-distribution.md)。本文保留本机 TUN、WebUI 和网络排障说明。

> **目录**
> 1. [架构](#架构)
> 2. [配置文件](#配置文件)
> 3. [WebUI](#webui)
> 4. [验证代理](#验证代理)
> 5. [防火墙规则](#防火墙规则)
> 6. [故障排查](#故障排查)
> 7. [nix 下载慢](#nix-下载慢大文件极慢--挂起--curl-正常-nix-卡死)
> 8. [相关链接](#相关链接)

Mihomo（原 Clash Meta）以 TUN 模式运行，配合 nftables 防火墙实现全局透明代理。本机消费 Sub-Store 生成的完整 YAML，DNS、TUN、端口和路由规则统一由远端模板提供；仅覆盖本机控制端地址和密钥，不再维护本地配置模板。

共享配置由 Sub-Store 管理：Secret Gist 的 `mihomo-template.yaml` 是保留注释的人工编辑源；本机更新器每 6 小时请求本机 Sub-Store，重新获取模板和 IKUUU、PPVPN 节点，生成成品供本机消费。只编辑模板，不手改会被生成覆盖的成品；修改后可立即运行本机更新服务。需要分发给订阅 Gist 的其他客户端时，再手动发布 `mihomo-dual.yaml`。

共享配置保留模板中的策略组及节点原名，组数随模板修改：`🤖 AI/Dev`、`🐙 GitHub` 默认使用 `🏠 PPVPN 住宅`，可选 `🏢 PPVPN 机房`；`📦 大流量` 只列 IKUUU 节点，地区组仅保留美国。下载分流按目标域名判断，不按传输大小自动切换；Nix 缓存、容器镜像、包和模型下载已有专门规则。各设备独立保存具体节点选择。

PPVPN 住宅、机房组均可选择对应的自动测速组或具体节点。`🪙 欧易` 可选择自动、`DIRECT` 或两家机场的任意节点；自动池包含直连及全部机场节点，不按地区排除。三个自动组使用 `url-test`，每 300 秒检测、切换容差为 50 毫秒，均设为 `hidden: true` 并排列在分组列表末尾。已有设备会保留原来的选择，刷新订阅后可在原分组中手动选中自动项。

腾讯、阿里、字节、百度、网易、国内影音、电商与社区统一使用 `🇨🇳 国内网站`；`🌏 爱奇艺&哔哩哔哩` 保留独立选择。Steam 登录/下载与商店/社区继续按各自独立组分流。

更新器按配置内容验证节点、组成员、引用、循环和规则目标，并检查热加载后的实际组成员；不依赖组名或 `IK-`、`PP-` 节点前缀。bootstrap 需包含启用的 DNS 和 TUN，无需为日常更新改写 SOPS；网络或候选校验失败保留上次有效快照。

## 架构

```
首次启动：从完整 SOPS bootstrap 生成共享快照，注入本机控制端及 Secret，保存为 /var/lib/mihomo-config/active.yaml
后续启动：从共享快照重新合成、校验；systemd 将 root-only active.yaml 作为 credential 交给 DynamicUser，离线也可启动
定时更新：每 6h 请求本机 Sub-Store（最新 Gist 模板 + 机场节点）→ 注入本机控制端及密钥 → Mihomo 校验 → 控制端 API 热重载并核对运行策略组 → 原子发布共享快照及启动配置；失败回滚
rule-providers (type: http, MRS): 每 24h 自动更新社区规则集
```

规则来源：[MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)，MRS 二进制格式，每日自动构建。覆盖：
- 国内域名/IP 直连（geosite:cn + geoip:cn）
- 去广告（geosite:category-ads-all）
- 国外网站代理兜底（geosite:geolocation-!cn）
- 特定服务分流：
  - **AI 与开发服务**（OpenAI、Claude、Gemini、Copilot、Cursor 等）：路由至 `🤖 AI/Dev`，默认 PPVPN 住宅，可选择 PPVPN 机房或具体 PPVPN 节点。
  - **GitHub**：单独路由至 `🐙 GitHub` 选择组，避免与其他常规流量共用默认节点。
  - **欧易**：使用 `geosite-okx` 社区域名集合，路由至 `🪙 欧易`；自动测速比较直连与两家机场全部节点，使用欧易公开时间接口检查连通性，手选仍可指定 `DIRECT` 或具体节点。
  - **Slack**：使用 `geosite-slack` 社区规则集，直接路由至 `🇺🇸 美国节点`，优先于通用国外流量规则；具体美国节点可在 WebUI 中选择。
  - **流媒体与常规服务**（Netflix, YouTube, Bilibili, Bahamut, Telegram 等）：按区域或默认走选择节点。

**注**：`rule-providers` 采用了原生 `type: http` 并配置 `proxy: DIRECT`，下载规则集时直接使用物理网络，避免了 TUN 拦截导致的“鸡生蛋”死锁问题。

- **TUN 模式**：在系统层面创建虚拟网卡，所有流量自动经过代理，无需逐个应用配置
- **nftables 防火墙**：配合 TUN 模式，`Meta` 接口标记为受信任
- **反向路径检查**：设为 `loose`（兼容 TUN 流量）

## 配置文件

| 文件 | 用途 |
|------|------|
| `host/base/network.nix` | 主机网络、转发和防火墙设置 |
| `host/base/mihomo.nix` | Mihomo 原生服务、启动快照与六小时间隔更新 |
| `host/base/sub-store.nix` | 本机 Sub-Store 常驻服务与持久状态；只在更新时参与生成，不阻塞 Mihomo 启动 |
| `host/mihomo-config-sync.py` | 读取完整生成配置、注入本机控制端及密钥、校验和原子发布 |
| `host/secrets/mihomo-gist.yaml` | 沿用现有 SOPS 密文中的 `mihomo_bootstrap`；旧 Gist URL 已不部署、不消费 |
| `/run/secrets/mihomo_bootstrap` | sops-nix 在系统激活的 systemd 阶段解密的首次引导配置，root-only |
| `/var/lib/mihomo-config/` | systemd 管理的 `0700` 状态目录，保存 `0600` 的共享快照与 active 配置；失败时保留旧版，不自动回写 SOPS |
| `/run/secrets/mihomo_env` | 现有 SOPS 运行时文件，使用其中的 `MIHOMO_SECRET` |

准备好并加密 `host/secrets/mihomo-gist.yaml` 后，沿用正常的 NixOS rebuild 流程：

```bash
cd ~/myNixOSConfig
sudo nixos-rebuild switch --flake .#MechRevo-NixOS
```

这里使用 Git flake；若更改依赖新文件，先按[候选源码流程](../architecture/flake.md#未跟踪文件的候选源码)验证，再正常纳入 Git 后应用。无需额外运行安装脚本。系统配置会自动启用更新定时器，后续不必手动刷新。每次 rebuild 不保证立即重新生成订阅。

更新服务为 `Type=oneshot`，执行完即退出，两次任务之间没有同步脚本常驻。定时器在开机后 15 分钟、随后距上次启动更新服务 6 小时触发；未启用 `WakeSystem`，不会为更新唤醒休眠中的笔记本，单调计时在挂起期间暂停。候选配置不变时跳过核心校验与热加载；有变化才运行校验并更新。网络异常可能延长等待，但不是持续占用 CPU。

如需排查或重试更新，可手动运行：

```bash
sudo systemctl start mihomo-config-update.service
systemctl status mihomo.service mihomo-config-update.timer
```

每六小时更新只刷新共享快照，不会改写 SOPS 中的 bootstrap。恢复迁移数据时仍需原 SSH host key；若无法沿用，需将新 host key 的 Age 公钥加入接收者并重新授权/加密密文。

本机已完成旧状态迁移，服务统一使用 `mihomo-config-*` 和 `/var/lib/mihomo-config`，不再自动导入旧目录。启动只用本地快照或 bootstrap，无有效副本时报错；联网获取统一通过 Sub-Store，模板或机场失败时保留旧配置。NixOS 不覆盖 Sub-Store 的订阅与脚本，具体管理边界见[本机 Sub-Store](sub-store.md)。

## WebUI

| 项目 | 值 |
|------|-----|
| 地址 | `http://127.0.0.1:9090` |
| UI | zashboard（Nix 管理，`pkgs.zashboard`） |
| Secret | 现有 sops `MIHOMO_SECRET` |

## 验证代理

```bash
# 检查服务状态
systemctl status mihomo

# 检查 TUN 接口
ip addr show Meta

# 检查 IP 转发是否开启
sysctl net.ipv4.ip_forward

# 测试代理连通性
curl -x http://127.0.0.1:7890 https://www.google.com -I

# 查看路由表
ip route show table all | grep Meta
```

## 防火墙规则

nftables 已启用，核心规则：
- `Meta` 接口标记为受信任（trustedInterfaces）
- `loose` 反向路径检查
- IPv4/IPv6 转发已开启

## 故障排查

### 与 Tailscale 共存

远端共享模板将 `+.tailscale.com` 和 `+.tailscale.io` 加入 `dns.fake-ip-filter`，为 Tailscale 公共服务返回真实地址。`tailscaled` 的连接通过带标记的路由绕过 Mihomo TUN；若 DNS 返回 `198.18.*`，连接会把假地址发往物理网关而超时，表现为 `tailscale up` 长时间没有登录链接。

切换到完整配置消费后，修改远端模板并运行 `sudo systemctl start mihomo-config-update.service` 即可生成和应用；用 `getent ahostsv4 controlplane.tailscale.com` 确认不再返回 Fake-IP，然后重启 `tailscaled` 并重新登录。完整步骤见 [Tailscale](tailscale.md)。

### 服务与防火墙检查

```bash
# 查看 Mihomo 日志
journalctl -u mihomo -f

# 重启核心（先运行 seed，从完整有效快照和本机密钥准备配置）
sudo systemctl restart mihomo

# 检查 WebUI 是否可访问
curl http://127.0.0.1:9090 -I

# 检查 nftables 规则
sudo nft list ruleset
```

### 常见问题

| 问题 | 可能原因 | 解决 |
|------|----------|------|
| 无法访问外网 | Mihomo 未运行 | `sudo systemctl start mihomo` |
| WebUI 打不开 | zashboard 路径不对 | 检查 `systemctl status mihomo` |
| 部分应用不走代理 | TUN 路由问题 | 检查 `ip route` 和 `Meta` 接口状态 |
| 共享配置不生效 | 修改后未重新生成 | `sudo systemctl start mihomo-config-update.service` |
| 规则未生效 | rule-provider 下载失败 | 检查 WebUI → Providers 面板；确认 jsdelivr CDN 可访问 |
| nix 下载大文件极慢/挂起 | TUN 默认 mtu 9000 + system 栈 | 见下方「nix 下载慢」排查 |

## nix 下载慢（大文件极慢 / 挂起 / curl 正常 nix 卡死）

### 现象

- `nix-prefetch-url` / `nixos-rebuild` 下载大文件（几十~几百 MB）时极慢（30KB/s~360KB/s）或长时间"显示在下载但没流量跑"
- 同一个 URL 用 `curl` 却能稳定 2~4MB/s 下载——**网络、节点、TUN 都是通的**，问题在 nix 的 HTTP 客户端行为
- 走国内镜像（TUNA/USTC，DIRECT）的 nix 下载秒下，正常

### 根因

mihomo TUN 的两个默认值对 nix 的下载器不友好：

1. **`mtu: 9000`（默认）**：巨型帧，多数网络路径 MTU 是 1500，超大会强制分片 → 丢包/不稳定，**高流量传输（大文件下载）时最明显**，长连接中途断。修复：`mtu: 1500`。
2. **`stack: system`（默认）**：内核协议栈对大量并发长连接（nix 的 curl_multi + HTTP/2 复用）丢回包，吞吐暴跌。修复：`stack: gvisor`（用户态栈，自维护连接状态）。**需 mihomo 以 `with_gvisor` 构建**（nixpkgs 的 `pkgs.mihomo` 已带）。

### 修复（2026-08-05 已验证）

原本地模板中的以下设置已移入 Gist `mihomo-template.yaml`，维持本机既有 TUN 行为：

```yaml
tun:
  enable: true
  device: Meta
  stack: gvisor        # 原 system → gvisor（吞吐 47 倍提升）
  mtu: 1500            # 原默认 9000 → 1500（大文件不再中途断）
  auto-route: true
  ...
```

共享模板不启用嗅探；删除了本地 HTTP 嗅探、TFO、额外 GeoData 下载设置以及与默认上游相同的单域 DNS policy，不将未证实有益的设备差异继续维护为第二份配置。

### 验证

```bash
# 确认接口 MTU 生效
ip link show Meta | grep mtu   # 应显示 mtu 1500

# 测试 Nix 下载与构建计划
nix build --dry-run '.#nixosConfigurations.MechRevo-NixOS.config.system.build.toplevel'
# 修复前: 30KB/s 卡死; 修复后: 1.4~2.5MB/s 正常下完
```

> **决策背景**：为什么 TUN 用 `gvisor + mtu 1500`？见 [`memory/cards/mihomo-tun-stack.md`](../../memory/cards/mihomo-tun-stack.md)

## 相关链接

- [Mihomo 配置修改与分发](mihomo-distribution.md) — 模板维护、三端更新与加密恢复
- [Distrobox](../dev/distrobox.md) — 容器网络走 Mihomo TUN 全局代理
- [Bottles 离线韧性改造](../dev/bottles-offline-workaround.md) — 策略 B 用 mihomo DIRECT 规则
- [Memory: mihomo TUN 栈决策](../../memory/cards/mihomo-tun-stack.md) — 为何 gvisor + mtu 1500
- [wiki 首页](../README.md)
