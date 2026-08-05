# Hermes Agent — NixOS 配置指南

当前部署架构：**容器模式**，LiteLLM 代理 (`127.0.0.1:4000`) 做模型后端。

## 快速索引

- `host/hermes.nix` — 系统级模块
- `~/.claude.json` → `mcpServers.hermes` — Claude Code 的 MCP 配置
- `~/.hermes/` → 实际是 `/var/lib/hermes/.hermes` 的 symlink（容器模式）
- `~/.hermes/config.yaml` — **运行时配置**（手动编辑生效，不走 rebuild）
- `/persist/secrets/hermes.env` — 密钥文件

## 基础配置

```nix
# flake.nix
{
  inputs.hermes-agent.url = "github:NousResearch/hermes-agent";
  outputs = { nixpkgs, hermes-agent, ... }: {
    nixosConfigurations.xxx = nixpkgs.lib.nixosSystem {
      modules = [
        hermes-agent.nixosModules.default
        ./host/default.nix
        ./host/hermes.nix
      ];
    };
  };
}
```

```nix
# host/hermes.nix (当前配置)
services.hermes-agent = {
  enable = true;
  container.enable = true;                      # 容器模式 (Ubuntu, 支持 apt/pip/npm)
  container.hostUsers = [ "lishangshui" ];      # 宿主机 ~/.hermes → 容器 /data/.hermes
  addToSystemPackages = true;                   # hermes CLI 加到系统 PATH
  environmentFiles = [ "/persist/secrets/hermes.env" ];
};
```

## config.yaml 运行时配置

路径：`~/.hermes/config.yaml`（容器内 `/data/.hermes/config.yaml`）

编辑后执行 `sudo docker restart hermes-agent` 即刻生效，**无需 rebuild**。

### 当前配置

```yaml
model:
  default: openai/claude-sonnet-4-6

providers:
  openai:
    base_url: http://127.0.0.1:4000/v1   # LiteLLM 代理
    api_key: "030222"
```

### 模型命名规则

模型名前缀 `openai/`、`anthropic/`、`google/` 需对应 provider。不设 `base_url` 时默认走 OpenRouter。

### 常用配置项

| 路径 | 说明 |
|------|------|
| `model.default` | 默认模型 |
| `model.base_url` | API endpoint（不填默认 OpenRouter） |
| `memory.provider` | 记忆后端：`holographic` / `hindsight` / … |
| `memory.memory_enabled` | 是否启用记忆 |
| `memory.user_profile_enabled` | 是否提取用户画像 |
| `toolsets` | 工具集，通常 `["all"]` |
| `compression.enabled` | 上下文压缩（长对话用） |
| `compression.threshold` | 触发压缩的比例阈值 |
| `terminal.backend` | 终端后端 `local` / `modal` / `daytona` |

```yaml
toolsets: ["all"]
max_turns: 100
compression:
  enabled: true
  threshold: 0.85
terminal:
  backend: local
  timeout: 180
display:
  compact: false
```

## 工作流程

### 日常使用

```
编辑 ~/.hermes/config.yaml → sudo docker restart hermes-agent → 生效
```

### 持久化数据

容器模式下，**不重建容器**就不会丢数据（apt/pip/npm 安装的东西都在 writable layer 里）。以下变更会触发容器重建（丢失写在 writable layer 的东西）：

- `container.image` 改变
- `container.extraVolumes` / `container.extraOptions` 改变

换版本（更新 flake input）不触发重建 —— `nixos-rebuild` 只更新 symlink，重启容器即生效。

### 密钥管理

`/persist/secrets/hermes.env` 当前内容：

```bash
OPENAI_BASE_URL=http://127.0.0.1:4000/v1
OPENAI_API_KEY=030222
HERMES_DEFAULT_MODEL=openai/claude-sonnet-4-6
```

Nix 会在 rebuild 时把 `environment` 和 `environmentFiles` 合并写入 `$HERMES_HOME/.env`。

## Clair AI 对接

Claude Code 和 AGY 通过 MCP 协议调用 Hermes：

```json
// ~/.claude.json (Claude Code)
"mcpServers": {
  "hermes": {
    "command": "hermes",
    "args": ["mcp", "serve"]
  }
}
```

```json
// 任意 Agent 的 MCP 配置（Claude Code 用 ~/.claude.json）
{
  "mcpServers": {
    "hermes": {
      "command": "hermes",
      "args": ["mcp", "serve"]
    }
  }
}
```

## Nix settings 配置（可选，后续固化）

当前用 `config.yaml` 手动管理，稳定后可改为 Nix 声明式：

```nix
services.hermes-agent.settings = {
  model.default = "openai/claude-sonnet-4-6";
  model.base_url = "http://127.0.0.1:4000/v1";
  memory = {
    memory_enabled = true;
  };
  toolsets = [ "all" ];
};
```

`settings` 使用 deep-merge：多个模块定义会递归合并，Nix 声明值优先级高于已有 config.yaml 中的值，但 Nix 未触及的手动 key 会被保留。

## 常用命令

```bash
# 查看状态
systemctl status hermes-agent
docker logs hermes-agent --tail 20

# 重启
sudo docker restart hermes-agent

# 进入容器
sudo docker exec -it hermes-agent bash

# 查看当前运行的包版本
sudo docker exec hermes-agent readlink /data/current-package

# 测试 MCP 连接
hermes mcp serve --help

# 打开 Memory Viewer
# 浏览器访问 http://127.0.0.1:18800
```

## 故障排查

| 现象 | 原因 | 解决 |
|------|------|------|
| 401 错误 | LiteLLM key 不对 | 检查 `/persist/secrets/hermes.env` |
| Memory Viewer 打不开 | Bridge 没起来 | `docker restart hermes-agent` 等 10 秒 |
| hermes 命令找不到 | 不在 PATH | `addToSystemPackages = true` 或直接用 `/run/current-system/sw/bin/hermes` |
| "managed by NixOS" | CLI 写操作被锁 | 编辑 config.yaml + restart，不要用 `hermes config set` |

## 更新版本

```bash
cd ~/myNixOSConfig
sudo nix flake update hermes-agent    # 更新 flake.lock
sudo nixos-rebuild switch --flake .   # 重建
sudo docker restart hermes-agent      # 重启容器（不需要重建容器）
```

## 参考

- [Hermes Agent Nix Setup](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup)
