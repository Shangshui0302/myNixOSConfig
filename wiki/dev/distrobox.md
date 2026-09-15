---
title: Distrobox
category: dev
tags: [distrobox, podman, containers]
updated: 2026-09-15
---

# Distrobox

Distrobox 用 Podman 创建和管理 Linux 发行版容器，每个容器与主机共享 HOME 目录、X11/Wayland、音频、USB 等资源，实现"在其他发行版里跑应用"而无需完整虚拟机。

## 架构

```
Nix / Home Manager → Containerfile → Podman 镜像
                   → assemble manifest → Distrobox 容器 (arch / fedora / ubuntu)
                                          └→ ~/distrobox/<name> 持久化 home
```

- **引擎**：Podman（rootless，DNS 已开启）
- **网络**：Mihomo TUN 全局代理 + Docker Hub 镜像加速（`docker.1ms.run`）
- **配置管理**：manifest、Containerfile 和 `distrobox-images` 命令由 Nix 管理
- **镜像状态**：Podman 保存构建结果，Home Manager activation 不自动联网构建
- **用户状态**：项目和容器 home 保存在 `~/distrobox/<name>`，独立于容器生命周期
- **用户配置**：Bash、ble.sh、Fish、Starship 和 Neovim 入口由 Home Manager 同步到三个 container home

## 预配置容器

`distrobox-assemble create` 一键创建以下容器：

| 容器名 | 镜像 | 用途 |
|--------|------|------|
| `arch` | localhost/distrobox-arch:managed | Arch Linux 综合开发环境 |
| `fedora` | localhost/distrobox-fedora:managed | Fedora 嵌入式及通用开发环境 |
| `ubuntu` | localhost/distrobox-ubuntu:managed | Ubuntu 开发/测试环境 |

### 创建预配置容器

先应用 Home Manager 配置，再按需构建镜像：

```bash
distrobox-images build arch
distrobox-images build fedora
distrobox-images build ubuntu
```

构建不会替换现有容器。先查看 assemble 计划：

```bash
distrobox-images plan arch
```

确认需要迁移时，再显式执行 `distrobox assemble create --replace --name arch`。
替换前应停止目标容器并确认 `~/distrobox/arch` 中的持久数据可用。

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
| `home/dev/containers.nix` | 镜像管理命令和 assemble manifest |
| `home/dev/container-images/*.Containerfile` | 三个发行版的基础镜像与软件包清单 |
| `home/dev/container-images/manage.sh` | 构建、预览和状态检查实现 |
| `~/.config/distrobox/distrobox.ini` | Nix 生成的容器清单 |
| `~/.config/distrobox/images/` | Nix 部署的只读镜像配方 |

Containerfile 是镜像的声明式来源；Podman image、容器可写层和包管理数据库都是可变运行状态。
更新软件版本时修改配方并重新构建，不能把容器内手工升级当作可重建来源。
三份配方都锁定 Toolbx 基础镜像 digest；发行版仓库中的软件包版本仍随仓库更新，
所以当前目标是可审查、可重建的功能环境，而不是逐字节相同的镜像。

### Shell 与 Neovim 配置

Home Manager 在每个 `~/distrobox/<name>` 中维护以下入口：

- `.bashrc`、`.config/fish`、`.config/starship.toml` 指向主机当前 Home Manager 配置；
- `.config/blesh/init.sh` 指向主机 ble.sh 配置；
- `.config/nvim/init.lua` 使用 `home/dev/nvim/init.lua`；
- `.local/bin/nvim` 指向 `programs.neovim.finalPackage`，复用主机的 Nix 插件闭包；
- `.local/bin/starship` 指向 Nix 提供的 Starship。

因此容器重建不会依赖旧容器可写层中的配置。Neovim 必须通过容器 home 的
`.local/bin/nvim` 启动；Fish 的 Distrobox PATH 规则会确保它优先于 `/usr/bin/nvim`。

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
| `distrobox list` 为空 | 未创建容器 | 先构建镜像，再运行 `distrobox assemble create` |
| manifest 引用的镜像不存在 | 尚未构建 Nix 管理的镜像 | `distrobox-images build <name>` |
| 进入容器报错 | 容器未启动 | `podman start <container_name>` |
| 容器内无网络 | podman 网络异常 | `podman system reset --force` 后重建 |
| assemble 未找到命令 | distrobox 未安装 | rebuild 确认 `host/base/containers.nix` 已生效 |

## 相关链接

- [Mihomo 代理](../networking/mihomo.md) — 容器流量走 TUN 全局代理，Docker Hub 走镜像加速
- [wiki 首页](../README.md)
