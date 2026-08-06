# Mihomo 代理

Mihomo（原 Clash Meta）以 TUN 模式运行，配合 nftables 防火墙实现全局透明代理。配置模板由 Nix 管理，节点从机场订阅拉取，规则使用 MetaCubeX 社区规则集（MRS 格式）。

## 架构

```
preStart: envsubst 渲染模板 → /run/mihomo/config.yaml
proxy-providers (type: http): 每 24h 自动更新节点
rule-providers (type: http, MRS): 每 24h 自动更新社区规则集
```

规则来源：[MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)，MRS 二进制格式，每日自动构建。覆盖：
- 国内域名/IP 直连（geosite:cn + geoip:cn）
- 去广告（geosite:category-ads-all）
- 国外网站代理兜底（geosite:geolocation-!cn）
- 特定服务分流：
  - **AI 与受限服务**（OpenAI, Claude, Meta, Google/Gemini, Apple, Microsoft, Antigravity 等）：强制路由至 `🇺🇸 美国极速`（url-test 测速组），规避对香港 IP 的封锁。
  - **流媒体与常规服务**（Netflix, YouTube, Bilibili, Bahamut, GitHub, Telegram 等）：按区域或默认走选择节点。

**注**：`rule-providers` 采用了原生 `type: http` 并配置 `proxy: DIRECT`，下载规则集时直接使用物理网络，避免了 TUN 拦截导致的“鸡生蛋”死锁问题。

- **TUN 模式**：在系统层面创建虚拟网卡，所有流量自动经过代理，无需逐个应用配置
- **nftables 防火墙**：配合 TUN 模式，`Meta` 接口标记为受信任
- **反向路径检查**：设为 `loose`（兼容 TUN 流量）

## 配置文件

| 文件 | 用途 |
|------|------|
| `host/network.nix` | mihomo 服务声明、preStart |
| `host/mihomo-config.yaml.in` | 配置模板（envsubst 变量注入） |
| `/persist/secrets/mihomo.env` | `MIHOMO_SECRET`、`MIHOMO_SUBSCRIPTION_URL` |

## WebUI

| 项目 | 值 |
|------|-----|
| 地址 | `http://127.0.0.1:9090` |
| UI | zashboard（Nix 管理，`pkgs.zashboard`） |
| Secret | `/persist/secrets/mihomo.env` 中 `MIHOMO_SECRET` |

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

# 测 nix 下载大文件
cd /tmp && time nix-prefetch-url "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_1.24012.11_amd64.deb"
# 修复前: 30KB/s 卡死; 修复后: 1.4~2.5MB/s 正常下完
```
