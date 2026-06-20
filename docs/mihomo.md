# Mihomo 代理

Mihomo（原 Clash Meta）以 TUN 模式运行，配合 nftables 防火墙实现全局透明代理。配置模板由 Nix 管理，节点和规则从机场订阅动态拉取。

## 架构

```
preStart: 下载订阅 → awk 提取 rules → envsubst 渲染模板 → /run/mihomo/config.yaml
proxy-providers (type: http, interval: 86400): 每 24h 自动更新节点
mihomo-rule-refresh.timer (每日 4:17): 刷新规则 → PUT /providers/rules/sub-rules
```

- **TUN 模式**：在系统层面创建虚拟网卡，所有流量自动经过代理，无需逐个应用配置
- **nftables 防火墙**：配合 TUN 模式，`Meta` 接口标记为受信任
- **反向路径检查**：设为 `loose`（兼容 TUN 流量）

## 配置文件

| 文件 | 用途 |
|------|------|
| `host/network.nix` | mihomo 服务声明、preStart、timer |
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

# 检查规则刷新 timer
systemctl status mihomo-rule-refresh.timer
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

# 重启服务（触发 preStart 重新拉取规则）
sudo systemctl restart mihomo

# 手动刷新规则（不中断服务）
sudo systemctl start mihomo-rule-refresh

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
| 节点/规则过期 | 自动更新失败 | `sudo systemctl start mihomo-rule-refresh` |
