---
title: Distrobox
category: dev
tags: [distrobox, podman, containers]
updated: 2026-08-12
---

# Distrobox

Distrobox 用 Podman 创建和管理 Linux 发行版容器，每个容器与主机共享 HOME 目录、X11/Wayland、音频、USB 等资源，实现"在其他发行版里跑应用"而无需完整虚拟机。

## 架构

```
podman (system) → distrobox assemble → 容器 (arch / ubuntu)
                                    → distrobox create / enter → 临时容器
```

- **引擎**：Podman（rootless，DNS 已开启）
- **网络**：Mihomo TUN 全局代理 + Docker Hub 镜像加速（`docker.1ms.run`）
- **配置管理**：`~/.config/distrobox/distrobox.ini` 由 Nix 管理

## 预配置容器

`distrobox-assemble create` 一键创建以下容器：

| 容器名 | 镜像 | 用途 |
|--------|------|------|
| `arch` | quay.io/toolbx/arch-toolbox:latest | Arch Linux，预装 sudo + 用户配置 |
| `ubuntu` | docker.io/library/ubuntu:latest | Ubuntu 开发/测试环境 |

### 创建预配置容器

```bash
distrobox-assemble create
```

首次使用需等镜像下载。后续 rebuild 不会自动重建容器，定义不变则无需重复执行。

## 常用操作

### 容器管理

```bash
# 列出所有容器
distrobox list

# 创建新容器
distrobox create -n <name> -i <image> --yes

# 删除容器
distrobox rm <name> --force

# 停止 / 启动
distrobox stop <name>
podman start <container_id>
```

### 进入容器

```bash
# 交互式进入
distrobox enter <name>

# 在容器中执行单个命令
distrobox enter <name> -- <command>
```

### 导出应用到主机

```bash
# 导出容器中的 app 到主机应用菜单
distrobox enter <name> -- distrobox-export --app <app_name>

# 导出二进制
distrobox enter <name> -- distrobox-export --bin /usr/bin/<binary>
```

## 配置说明

| 文件 | 用途 |
|------|------|
| `host/base/containers.nix` | Podman 服务、distrobox 包、镜像加速 |
| `home/dev/containers.nix` | assemble manifest (arch + ubuntu 定义) |
| `~/.config/distrobox/distrobox.ini` | Nix 生成的容器清单 |

### 镜像加速

Docker Hub 走 `docker.1ms.run` 镜像代理，Quay 直连：

```bash
# 查看生效的 registries 配置
cat /etc/containers/registries.conf
```

## 故障排查

```bash
# 检查 podman 状态
systemctl --user status podman

# 检查容器列表
distrobox list

# 查看容器日志
podman logs <container_name>

# 进入容器失败时，尝试直接用 podman 启动
podman start <container_name>
podman exec -it <container_name> /bin/bash

# 测试 podman 网络
podman run --rm alpine:latest wget -qO- https://archlinux.org
```

### 常见问题

| 问题 | 可能原因 | 解决 |
|------|----------|------|
| 拉镜像失败 | 代理未运行 | `systemctl status mihomo` |
| `distrobox list` 为空 | 未创建容器 | `distrobox-assemble create` |
| 进入容器报错 | 容器未启动 | `podman start <container_name>` |
| 容器内无网络 | podman 网络异常 | `podman system reset --force` 后重建 |
| assemble 未找到命令 | distrobox 未安装 | rebuild 确认 `host/base/containers.nix` 已生效 |

## 相关链接

- [Mihomo 代理](../networking/mihomo.md) — 容器流量走 TUN 全局代理，Docker Hub 走镜像加速
- [wiki 首页](../README.md)
