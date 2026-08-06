---
id: qoder-ide-source
type: decision
tags: [ai, tools, packaging]
date: 2026-08-06
---

# Qoder IDE 用国际版而非 CN 版

## 问题
`local-deriv/qoder-ide.nix` 之前打包的是 Qoder CN 国内版（`https://ide.qoder.com.cn/qoder/release/lastest/qoder-cn_amd64.deb`），用户要求换成国际版。

## 决策
Qoder IDE 改用国际版，下载源 `https://download.qoder.com/release/latest/qoder_amd64.deb`。

国际版与 CN 版打包结构差异（改写 derivation 时必须注意）：
- 目录: `usr/share/qoder-cn` → `usr/share/qoder`
- 主二进制: `qoder-cn` → `qoder`
- CLI 脚本: `usr/share/qoder/bin/qoder`（VSCode 系启动脚本，可忽略）
- 图标: `QoderCN.png` → `Qoder.png`（1024x1024）
- desktop: `qoder-cn.desktop` → `qoder.desktop`，另有 `qoder-url-handler.desktop`

## Why
- 用户指定用国际版 qoder.com 的包，不用 qoder.com.cn 的国内版
- 升级方式不同：CN 版用 `lastest` 路径下固定文件；国际版 `latest` 目录可查最新版本号

## How to apply
- 升级时从 https://download.qoder.com/release/latest/ 重新下载 deb，换 sha256 和 version
- 二进制/图标/desktop 路径保持上表结构，不要退回 CN 版的 `qoder-cn` 命名
- 相关: [[ai-tools-source]]
