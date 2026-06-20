# Podman 无法拉取 Docker 镜像（TUN 代理干扰 TLS）

**Status**: OPEN
**Created**: 2026-06-20
**Branch**: `main`

## 问题

`distrobox create` 和 `podman pull` 均失败，无法拉取 Docker Hub 镜像。

## 根因

mihomo TUN 模式劫持了 DNS（Docker Hub 域名解析为假 IP `198.18.x.x`）并通过 nftables 拦截 TCP 连接，但 TLS 转发失败，导致：

- **直连 registry-1.docker.io**：TLS `unexpected eof while reading`
- **docker.1ms.run 镜像**：API 可达，但 blob 下载走 `cloudfront-docker-cf.mrs.1ms.run` CDN，同样被 TUN 拦截

curl 测试确认：通过 HTTP 代理（`-x http://127.0.0.1:7890`）可正常访问 Docker Hub，但 podman 未正确读取 `HTTP_PROXY` / `HTTPS_PROXY` 环境变量。

## 已配置

- `registries.conf`：docker.io → docker.1ms.run 镜像
- `containers.conf.d/01-proxy.conf`：`[engine] env` 中设置了 `http_proxy`/`https_proxy`（但仅对容器生效，对 pull 操作无效）
- Podman 服务正常运行

## 待排查

1. podman（Go 实现）为什么不尊重 `HTTP_PROXY` 环境变量？
2. 是否需要通过 mihomo 规则将 Docker/CDN 域名加入代理列表？
3. 是否有不依赖海外 CDN 的 Docker 镜像源可用？
4. 是否可以用 `skopeo` 替代 podman 拉取镜像（待安装测试）？
