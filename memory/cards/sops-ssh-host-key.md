---
id: sops-ssh-host-key
type: decision
tags: [sops, secrets, ssh, security, mihomo]
date: 2026-08-09
---

# sops 解密密钥: SSH host key + useSystemdActivation

## 问题

1. **sops 解密时序故障**：开机 initrd 阶段 `setupSecrets` activation script 尝试读 `/persist/sops-age-key.txt`，但 `/persist` 是 stage-2 才挂载的 subvol，initrd 阶段不可用 → secrets 从未解密 → `/run/secrets/mihomo_env` 缺失 → mihomo 因 `EnvironmentFile` 加载失败启动崩溃。
2. **独立 age key 维护成本**：`/persist/sops-age-key.txt` 需要单独保管/备份/迁移，换机容易遗漏，丢失 = secrets 永久锁死。
3. **服务名潜伏 bug**：`host/network.nix` 依赖 `sops-nix.service`，但 sops-nix 模块实际生成的服务名是 `sops-install-secrets.service`——顺序依赖从未真正生效。

## 决策

`host/sops.nix` 改为：

```nix
sops = {
  age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  useSystemdActivation = true;
  defaultSopsFile = ./secrets/secrets.yaml;
};
```

`.sops.yaml` 的 recipient 换成 SSH host key 的 age 公钥（`age14h8vny4...`）。`host/network.nix` 依赖改为 `sops-install-secrets.service`。旧 `/persist/sops-age-key.txt` 已删除。

## Why

- **SSH host key 在正确时机可用**：`/etc/ssh/` 位于根文件系统（subvol=@），initrd 阶段即挂载，而 `/home`、`/persist` 都是 stage-2 才挂载。sops 要在开机早期解密，只能用根文件系统上能读到的 key——这是由挂载时序倒推的选择。
- **`useSystemdActivation = true` 让解密走 systemd service**（`sops-install-secrets.service`，`after = local-fs.target`），而非 initrd activation script，从根上避免"stage-2 挂载点被 initrd 阶段依赖"的时序问题。
- **零额外密钥**：host key 是 OpenSSH 自动生成的系统身份，随机器迁移，无需单独备份。

## How to apply

- 改 sops 解密相关配置时，注意 key 必须在 initrd 可读的文件系统上（`/` 或 `/etc`），**不要放回 `/persist` 或 `/home`**，否则重演时序故障。
- secrets.yaml 的解密私钥是 SSH host key：本地解密/重加密需 root（key 文件 root 所有），用 `sudo nix shell nixpkgs#sops -c` 包装，`SOPS_AGE_KEY_FILE` 需为 `ssh-to-age -private-key` 转换后的 age 私钥。
- 换 key 流程：`.sops.yaml` 加新接收者 → `sops updatekeys` 双保险 → 验证 → 移除旧接收者。完整流程见 [迁移指南](../../../Documents/MyVault/01_Inbox/sops%20迁移指南：SSH%20host%20key%20切换案例.md)。

相关: [[wiki/security/sops.md]] | [[memory/cards/mihomo-tun-stack]]
