---
id: nix-flake-tracked-files
type: constraint
tags: [nix, flake, build]
date: 2026-08-13
---

# nix flake 复制 `./` 只含 git tracked 文件

## 问题
flake 里 `src = ./.` 作为 derivation 源时，nix 复制到 store 的目录**只包含 git tracked 文件**——untracked 的新文件不在 store source 里。现象：新增 `completions/`、`locales/` 后 `nix build` 报"找不到文件"或静默丢翻译，而 `cargo build`（本地文件系统）正常。

## 决策
- 新增文件后先 `git add`（staging 即可进 flake source），再 `nix build`
- 怀疑缺件时先查 `ls $src`（store source）里有没有该文件

## Why
dev 构建用本地工作区，nix 构建用 store 快照——两者 source 集不一致，本地跑得好、nix 构建静默缺件的差异很隐蔽。

## How to apply
- 给 flake 项目（`src = ./.`）加新文件，务必先 stage 再 build
- nix 构建产物与本地行为不一致时，优先查 store source 完整性

相关: [[shell-switcher-generic]] | wiki/desktop/shell-switcher.md
