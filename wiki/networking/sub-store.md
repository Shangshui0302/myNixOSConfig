---
title: 本机 Sub-Store
category: networking
tags: [sub-store, mihomo, gist, backup, systemd]
updated: 2026-10-25
---

# 本机 Sub-Store

本机 Sub-Store 是一个仅监听回环地址的 Mihomo 订阅编辑与发布服务。每台机器运行自己的实例，并在本机浏览器打开本机服务。

截至 2026-10-25，本机服务已部署，并从 Gist 的 age 加密备份恢复了两家订阅、生成配置和发布/备份任务。本机两项同步任务保留手动运行，未启用自动计划；其他机器与云端原始备份未修改。

配置使用 NixOS 的 `pkgs.sub-store` 2.42.5 与 `pkgs.sub-store-frontend` 2.34.1，单进程同时提供界面和后端，监听 `127.0.0.1:3001`，后端 API 路径为 `/backend`。首次应用后以空白库启动，不会自动迁移 Windows 实例的数据。

状态目录是 `/var/lib/sub-store`，由 systemd `StateDirectory` 为静态系统用户 `sub-store` 创建并管理，权限为 `0700`，数据库文件为 `0600`。服务直接使用该目录，不再绑定映射 `/persist/secrets`。状态和凭据属于敏感数据，不要写入仓库或共享日志。

本机已完成旧数据库迁移，迁移兼容单元已移除，后续直接使用新目录。本机 `/var/lib` 在持久根文件系统上，重启后数据仍保留；在新机器上应用配置会创建空白库，需从加密备份恢复。

## 打开与查看状态

配置应用并启动服务后，在本机浏览器打开：

```text
http://127.0.0.1:3001/?magicpath=backend
```

`magicpath=backend` 用于首次进入时连接本机后端。服务只监听本机回环地址。

查看服务状态和日志：

```bash
systemctl status sub-store.service
journalctl -u sub-store.service -n 50 --no-pager
```

应用配置后，`systemctl status sub-store.service` 输出的 `Docs:` 行会显示上述管理地址；忘记地址时无需翻配置文件。

## 恢复数据与发布

首次应用后需从备份恢复数据。恢复需要该备份专用的 Gist Token 和已保存的 age 私钥。下载加密备份时选择保留当前 Token。备份中包含两家机场订阅、双机场文件、模板和成品地址、生成脚本、同步任务及设置。不要将凭据写入命令行参数、仓库或共享日志。

恢复数据时注意计划任务：后端重启会登记计划，单项任务修改也可能刷新所有计划。选择以下一种方式：

- **多机手动发布：**先导出备份副本，在副本中清除所有同步任务的 cron，再将副本恢复到各实例；保留手动同步。
- **转移唯一自动发布端：**先停用旧端自动计划，再将备份恢复到新端，并只在新端启用自动发布和备份计划。

恢复后逐项核对订阅、模板地址、成品地址、脚本和同步任务。需要向订阅 Gist 成品的客户端分发时，手动发布 `mihomo-dual.yaml`，确认成品已更新，再让这些客户端刷新。本机可以直接消费下述生成接口。

## 本机消费与管理边界

应用本次 Nix 配置后，`mihomo-config-update.timer` 每 6 小时请求本机 `dual-provider-mihomo` 生成接口。请求使用 `noCache=true`；文件保持远程模板来源、关闭来源合并、`ignoreFailedRemoteFile=false`，模板地址不固定 revision，也不使用 `#cacheKey` 乐观缓存。节点脚本也跳过缓存。每次生成重新请求 Gist 的 `mihomo-template.yaml` 和两家订阅，不等待任何机器先上传成品；Gist 上游仍可能有短暂传播延迟。

模板下载或生成失败时，本次更新报错并保留正在使用的有效配置，不把备份 `content` 或旧 Gist 成品冒充最新结果。开机优先使用已有快照或 bootstrap，Mihomo 启动不依赖 Sub-Store 成功联网。

| 管理位置 | 负责内容 |
| --- | --- |
| Gist `mihomo-template.yaml` | 策略组、规则、规则集和节点分组指令；节点由 Sub-Store 填入 |
| Sub-Store | 机场订阅地址、生成脚本、发布与备份设置；状态保存在持久目录 |
| NixOS | 服务、更新周期、本机 TUN/DNS/端口及控制密钥；合并和校验生成结果 |

NixOS 更新器只替换 `proxies`、`proxy-groups`、`rule-providers`、`rules`，不重写 Sub-Store 数据库或 Gist 模板。正常 rebuild 保留 Sub-Store 中的订阅编辑；日常改模板和订阅无需 rebuild。不要手改运行快照，也不要在 Sub-Store 中维护本机 TUN/DNS，否则这些字段不会进入本机配置。

Gist 成品发布与加密备份仍为手动任务。本机更新仅生成、读取和应用配置，不上传 Gist；其他订阅 Gist 成品的客户端仍需先发布再刷新。

## 多实例与模板更新

各机器的 Sub-Store 各自保存订阅 URL、生成脚本、同步任务和 Token。它们可以读取同一个 Gist 模板并写入同一个成品 Gist，但互不推送这些本地状态。模板规则变更在生成时可读取最新模板；如果生成脚本或同步任务有变更，仍需在各实例中恢复或同步对应状态。Gist 成品只保存发布结果，不会反向更新旧实例中的模板地址、脚本或任务。

建议只让一台机器自动发布和自动加密备份，其余机器保留手动发布。若各实例在线，从任一实例手动发布后，客户端刷新即可获取该成品。

## 停止与回退

临时停止本机服务：

```bash
sudo systemctl stop sub-store.service
```

更新服务会按需启动 Sub-Store；若要持续暂停本机生成，先停止 `mihomo-config-update.timer`，再停止 Sub-Store。Mihomo 继续使用已有配置。

系统配置回退不会撤销数据库编辑或已经写入 Gist 的成品。若退回仍使用旧目录的系统代际，会读到迁移时保留的旧副本；在新目录有编辑后，先手动生成加密备份，回退后再恢复所需数据。若准备弃用实例，先在 Sub-Store 中处理其自动计划，再停用服务。

在目标配置目录应用系统配置后即可访问服务。用户可在配置目录执行：

```bash
sudo nixos-rebuild switch --flake path:.#MechRevo-NixOS
```

系统应用由用户手动执行；已有数据库会保留，新机器需从加密备份恢复。参见[部署与维护](../deployment.md)。

## 故障排查

| 现象 | 检查 |
| --- | --- |
| 本机无法打开界面 | 确认配置已应用、`sub-store.service` 正在运行，并检查服务日志；确认使用 `127.0.0.1:3001` |
| 恢复后任务重复发布 | 停止多余实例的自动计划；不要继续逐项修改 cron，单项修改可能刷新其他计划 |
| 本机 Mihomo 仍显示旧内容 | 查看 `mihomo-config-update.service` 日志，检查模板与订阅获取、生成和校验；修复后重试更新 |
| 订阅 Gist 的客户端仍显示旧内容 | 确认某个在线实例已成功手动发布并更新 Gist 成品，再在客户端刷新 |
| 服务启动失败 | 查看 `journalctl -u sub-store.service`；确认 `/var/lib/sub-store` 由 systemd 管理且服务用户可访问 |

## 上游实现依据

以下文件来自 Sub-Store commit `832d3a0412bf92e79b46d6610217117010c589ec`，用于核对 API 恢复与计划任务行为：[服务入口](https://github.com/sub-store-org/Sub-Store/blob/832d3a0412bf92e79b46d6610217117010c589ec/backend/src/restful/index.js)、[备份恢复](https://github.com/sub-store-org/Sub-Store/blob/832d3a0412bf92e79b46d6610217117010c589ec/backend/src/restful/miscs.js)、[单任务计划](https://github.com/sub-store-org/Sub-Store/blob/832d3a0412bf92e79b46d6610217117010c589ec/backend/src/utils/artifact-cron.js)。

## 相关链接

- [Mihomo 配置修改与分发](mihomo-distribution.md)
- [系统服务](../services.md)
- [部署与维护](../deployment.md)
