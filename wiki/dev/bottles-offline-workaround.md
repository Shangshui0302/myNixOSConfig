---
title: Bottles 离线韧性改造
category: dev
tags: [bottles, wine, flatpak, offline]
updated: 2026-08-06
---

# Bottles 离线韧性改造

## 触发原因

Flatpak 版 Bottles 的组件/依赖/安装器索引托管在 `proxy.usebottles.com`，
该项目服务器靠捐款维持，无专职运维，历史上域名换过三代
(mirror → proxy → repo)，每代都有过类似故障。

初始化阶段卡死在 "setting up" 的根因：
1. `check_connection()` 尝试访问 `ping.usebottles.com` → 超时或 TLS 错误
2. 连接检查失败 → `fetch_catalog()` 直接返回 `{}`
3. 所有组件/依赖/安装器列表为空
4. 初始化流程无法继续

## 解决方案

### 策略 A：本地索引接管（`compat.nix` 管理）

`home/productivity/compat.nix` 中的 `home.activation.bottlesOffline` 在
每次 `nixos-rebuild` 时自动：

1. 从 GitHub 拉取/更新三个索引仓库到 `~/.local/share/bottles-repos/`
2. 修补 Bottles Flatpak 的 Python 源码，让 `file://` 本地路径替代网络请求
3. 通过 `services.flatpak.overrides` 设置 `PERSONAL_*` 环境变量指向本地仓库

### 策略 B：mihomo DIRECT 规则

在 `/persist/mihomo/config.yaml` 的 rules 最前面添加：
```yaml
- DOMAIN-SUFFIX,usebottles.com,DIRECT
```

所有 `*.usebottles.com` 域名解析到 Linode `172.105.68.126`，直连可用，
绕过慢速代理节点。

### 修补的源码文件

| 文件 | 修改 |
|------|------|
| `backend/utils/connection.py` | `check_connection()` 永远返回 True |
| `backend/repos/repo.py` | `__get_catalog()` 和 `get_manifest()` 支持 `file://` |
| `backend/managers/repository.py` | `__get_index()` 在 pycurl 之前检查 `file://` |

### 组件手动预装

初始化卡死时手动放入 `~/.var/app/com.usebottles.bottles/data/bottles/`：

```
dxvk/dxvk-2.7.1/        # doitsujin/dxvk releases
vkd3d/vkd3d-proton-3.0.1/ # HansKristian-Work/vkd3d-proton releases
runners/soda-9.0-1/     # bottlesdevs/wine releases
winebridge/             # bottlesdevs/winebridge releases, 含 VERSION 文件
```

### 更新本地索引

```bash
for repo in components dependencies programs; do
  git -C ~/.local/share/bottles-repos/$repo pull
done
```

### 回滚

```bash
flatpak override --user --reset com.usebottles.bottles
rm -rf ~/.local/share/bottles-repos
rm -rf ~/.var/app/com.usebottles.bottles/data/bottles/{dxvk,vkd3d,nvapi,runners}
```

下次 `nixos-rebuild` 会重新应用 `compat.nix` 中定义的原始 overrides。

## 已知限制

- SourceForge 等外部下载源在部分网络环境下可能不可达（如 arial32 字体依赖），
  这是依赖组件自身的问题，与 Bottles 基础设施无关
- Flatpak 更新 Bottles 后，Python 补丁需要由 activation script 重新应用
  （`nixos-rebuild` 自动处理）
- GitHub API 限流：如果频繁 rebuild，`api.github.com` 可能临时限流，
  但不影响已缓存的本地仓库

## 相关链接

- [Mihomo 代理](../networking/mihomo.md) — 策略 B 的 mihomo DIRECT 规则
- [wiki 首页](../README.md)
