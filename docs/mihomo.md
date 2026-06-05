# Mihomo 代理

Mihomo（原 Clash Meta）以 TUN 模式运行，配合 nftables 防火墙实现全局透明代理。

## 架构

```
应用流量 → TUN 虚拟网卡 (Meta) → Mihomo 内核 → 代理节点
                                    ↑
                            /persist/mihomo/config.yaml
```

- **TUN 模式**：在系统层面创建虚拟网卡，所有流量自动经过代理，无需逐个应用配置
- **nftables 防火墙**：配合 TUN 模式，`Meta` 接口标记为受信任
- **反向路径检查**：设为 `loose`（兼容 TUN 流量）

## WebUI

| 项目 | 值 |
|------|-----|
| 地址 | `http://127.0.0.1:9090` |
| Secret | `030222` |

在浏览器中打开 WebUI 可以查看节点、规则、连接状态，切换代理策略。

## 配置文件

Mihomo 配置文件位于 `/persist/mihomo/config.yaml`（持久化存储，不随 rebuild 清除）。

```bash
# 编辑配置
sudo nvim /persist/mihomo/config.yaml

# 重新加载配置（无需重启服务）
# 在 WebUI 中操作，或重启服务
sudo systemctl restart mihomo
```

## 验证代理

```bash
# 检查服务状态
systemctl status mihomo

# 检查 TUN 接口
ip addr show Meta

# 检查 IP 转发是否开启
sysctl net.ipv4.ip_forward
# 应返回: net.ipv4.ip_forward = 1

# 测试代理连通性（示例）
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

# 重启服务
sudo systemctl restart mihomo

# 检查 WebUI 是否可访问
curl http://127.0.0.1:9090 -I

# 检查 nftables 规则
sudo nft list ruleset

# 验证转发
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
```

### 常见问题

| 问题 | 可能原因 | 解决 |
|------|----------|------|
| 无法访问外网 | Mihomo 未运行 | `sudo systemctl start mihomo` |
| WebUI 打不开 | metacubexd 未部署 | 检查 `systemctl status mihomo` |
| 部分应用不走代理 | TUN 路由问题 | 检查 `ip route` 和 `Meta` 接口状态 |
| 配置文件不生效 | 修改后未重载 | 重启服务或在 WebUI 中重载 |
