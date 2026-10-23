---
title: Mihomo 代理
category: networking
tags: [mihomo, tun, proxy, nftables, vpn]
updated: 2026-10-23
---

# Mihomo 代理

> **目录**
> 1. [架构](#架构)
> 2. [配置文件](#配置文件)
> 3. [WebUI](#webui)
> 4. [验证代理](#验证代理)
> 5. [防火墙规则](#防火墙规则)
> 6. [故障排查](#故障排查)
> 7. [nix 下载慢](#nix-下载慢大文件极慢--挂起--curl-正常-nix-卡死)
> 8. [相关链接](#相关链接)

Mihomo（原 Clash Meta）以 TUN 模式运行，配合 nftables 防火墙实现全局透明代理。本机模板保留 DNS、TUN、嗅探和控制端设置；从私有 Gist 完整 YAML 仅提取 `proxies`、`proxy-groups`、`rule-providers`、`rules` 四项共享配置。

共享配置由发布端 Sub-Store 管理：Secret Gist 的 `mihomo-template.yaml` 是保留注释的人工编辑源；Sub-Store 每 6 小时读取最新模板和 IKUUU、PPVPN 节点，生成 `mihomo-dual.yaml`。NixOS 继续订阅同一个成品地址，不读取未填节点的模板。只编辑模板，不手改会被同步覆盖的成品；修改后可在发布端手动同步，再等待本机定时更新。

新版保留 17 个表情策略组及节点原名：`🤖 AI/Dev`、`🐙 GitHub` 默认使用 `🏠 PPVPN 住宅`，可选 `🏢 PPVPN 机房`；`📦 大流量` 只列 IKUUU 节点，地区组仅保留美国。下载分流按目标域名判断，不按传输大小自动切换；Nix 缓存、容器镜像、包和模型下载已有专门规则。各设备独立保存具体节点选择。

更新器按配置内容验证节点、组成员、引用、循环和规则目标，并检查热加载后的实际组成员；不依赖组名或 `IK-`、`PP-` 节点前缀。旧 bootstrap 仍可读取，无需改写 SOPS；网络或候选校验失败保留上次有效快照。

## 架构

```
首次启动：从 SOPS 机密读取 Gist URL 与 bootstrap，生成共享快照，并与当前本机模板及 Secret 合成 /persist/secrets/mihomo-gist-state/active.yaml
后续启动：从共享快照重新合成、校验；systemd 将 root-only active.yaml 作为 credential 交给 DynamicUser，离线也可启动
定时更新：每 6h 下载 Gist → 白名单合并 → Mihomo 校验 → 控制端 API 热重载并核对运行策略组 → 原子发布共享快照及启动配置；失败回滚
rule-providers (type: http, MRS): 每 24h 自动更新社区规则集
```

规则来源：[MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)，MRS 二进制格式，每日自动构建。覆盖：
- 国内域名/IP 直连（geosite:cn + geoip:cn）
- 去广告（geosite:category-ads-all）
- 国外网站代理兜底（geosite:geolocation-!cn）
- 特定服务分流：
  - **AI 与开发服务**（OpenAI、Claude、Gemini、Copilot、Cursor 等）：路由至 `🤖 AI/Dev`，默认 PPVPN 住宅，可选择 PPVPN 机房或具体 PPVPN 节点。
  - **GitHub**：单独路由至 `🐙 GitHub` 选择组，避免与其他常规流量共用默认节点。
  - **Slack**：使用 `geosite-slack` 社区规则集，直接路由至 `🇺🇸 美国节点`，优先于通用国外流量规则；具体美国节点可在 WebUI 中选择。
  - **流媒体与常规服务**（Netflix, YouTube, Bilibili, Bahamut, Telegram 等）：按区域或默认走选择节点。

**注**：`rule-providers` 采用了原生 `type: http` 并配置 `proxy: DIRECT`，下载规则集时直接使用物理网络，避免了 TUN 拦截导致的“鸡生蛋”死锁问题。

- **TUN 模式**：在系统层面创建虚拟网卡，所有流量自动经过代理，无需逐个应用配置
- **nftables 防火墙**：配合 TUN 模式，`Meta` 接口标记为受信任
- **反向路径检查**：设为 `loose`（兼容 TUN 流量）

## 配置文件

| 文件 | 用途 |
|------|------|
| `host/base/network.nix` | Mihomo 服务、首次引导和六小时间隔更新 |
| `host/mihomo-config.yaml.in` | 本机配置模板，保留控制端 Secret 占位符 |
| `host/mihomo-gist-sync.py` | 下载、白名单合并、校验和原子发布 |
| `host/secrets/mihomo-gist.yaml` | SOPS 加密的 `mihomo_gist_url` 与 `mihomo_bootstrap`；与现有 `secrets.yaml` 分开维护 |
| `/run/secrets/mihomo_gist_url`、`/run/secrets/mihomo_bootstrap` | sops-nix 在系统激活的 systemd 阶段解密并安装，root-only |
| `/persist/secrets/mihomo-gist-state/` | root 私有的 last-good 共享快照与 active 配置；失败时保留旧版，作为动态运行状态，不自动回写 SOPS |
| `/run/secrets/mihomo_env` | 现有 SOPS 运行时文件，使用其中的 `MIHOMO_SECRET` |

准备好并加密 `host/secrets/mihomo-gist.yaml` 后，沿用正常的 NixOS rebuild 流程：

```bash
cd ~/myNixOSConfig
sudo nixos-rebuild switch --flake path:.#MechRevo-NixOS
```

`path:.` 使尚未加入 Git 的新文件也参与本次构建；应用会包含当前仓库的其他已有修改。无需额外运行安装脚本。系统配置会自动启用更新定时器，后续不必手动刷新。每次 rebuild 不保证立即下载 Gist。

更新服务为 `Type=oneshot`，执行完即退出，两次任务之间没有同步脚本常驻。定时器在开机后 15 分钟、随后距上次启动更新服务 6 小时触发；未启用 `WakeSystem`，不会为更新唤醒休眠中的笔记本，单调计时在挂起期间暂停。候选配置不变时跳过核心校验与热加载；有变化才运行校验并更新。网络异常可能延长等待，但不是持续占用 CPU。

如需排查或重试更新，可手动运行：

```bash
sudo systemctl start mihomo-gist-update.service
systemctl status mihomo.service mihomo-gist-update.timer
```

每六小时更新只刷新共享快照，不会改写 SOPS 中的 bootstrap。原先 `/persist/secrets/mihomo-gist-url` 与 `/persist/secrets/mihomo-bootstrap.yaml` 不再部署。恢复迁移数据时仍需原 SSH host key；若无法沿用，需将新 host key 的 Age 公钥加入接收者并重新授权/加密密文。

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

```bash
# 查看 Mihomo 日志
journalctl -u mihomo -f

# 重启服务（触发 preStart 重新渲染模板）
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
| 配置文件不生效 | 修改后未重载 | `sudo systemctl restart mihomo` |
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

`host/mihomo-config.yaml.in`：

```yaml
tun:
  enable: true
  device: Meta
  stack: gvisor        # 原 system → gvisor（吞吐 47 倍提升）
  mtu: 1500            # 原默认 9000 → 1500（大文件不再中途断）
  auto-route: true
  ...
```

配套：`sniffer` 去掉 TLS 443/8443 嗅探（每条连接缓存包嗅探是纯开销，16 个 geosite 规则集已足够分流）。

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

- [Distrobox](../dev/distrobox.md) — 容器网络走 Mihomo TUN 全局代理
- [Bottles 离线韧性改造](../dev/bottles-offline-workaround.md) — 策略 B 用 mihomo DIRECT 规则
- [Memory: mihomo TUN 栈决策](../../memory/cards/mihomo-tun-stack.md) — 为何 gvisor + mtu 1500
- [wiki 首页](../README.md)
