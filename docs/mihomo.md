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
