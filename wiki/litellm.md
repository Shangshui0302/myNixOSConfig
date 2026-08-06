# LiteLLM AI 代理

LiteLLM 运行在 `0.0.0.0:4000`，将 Claude/GPT API 请求路由到 DeepSeek API 后端，供 Claude Code、Codex CLI 和其他 AI 工具使用。

## 服务信息

| 项目 | 值 |
|------|-----|
| 地址 | `0.0.0.0:4000`（仅本机访问，未开放防火墙） |
| 后端 | DeepSeek API |
| 路由策略 | simple-shuffle |
| 环境文件 | `/persist/secrets/litellm.env` |

## 模型映射表

### Claude 系列 → DeepSeek（Anthropic 兼容端点）

| 模型名 | 后端模型 | max_tokens | timeout |
|--------|---------|------------|---------|
| `claude-opus-4-7` | anthropic/deepseek-v4-pro | 32K | 600s |
| `claude-opus-4-6` | anthropic/deepseek-v4-pro | 32K | 600s |
| `claude-sonnet-4-6` | anthropic/deepseek-v4-flash | 24K | 600s |
| `claude-sonnet-4-6-1m` | anthropic/deepseek-v4-flash | 64K | 1200s |
| `claude-haiku-4-5` | anthropic/deepseek-v4-flash | 12K | 300s |
| `claude-haiku-4-5-20251001` | anthropic/deepseek-v4-flash | 12K | 300s |

### GPT 系列 → DeepSeek（OpenAI 兼容端点）

| 模型名 | 后端模型 | max_tokens | timeout |
|--------|---------|------------|---------|
| `gpt-4o` | openai/deepseek-v4-pro | 64K | 600s |
| `gpt-4.1` | openai/deepseek-v4-pro | 64K | 600s |
| `gpt-4o-mini` | openai/deepseek-v4-flash | 32K | 600s |

## Fallback 链路

当主模型不可用时自动降级：

```
claude-opus-4-7 / claude-opus-4-6  →  claude-sonnet-4-6  →  claude-haiku-4-5
claude-sonnet-4-6-1m               →  claude-sonnet-4-6
gpt-4o / gpt-4.1                   →  gpt-4o-mini
```

## 密钥管理

密钥存储在 `/persist/secrets/litellm.env`（不进 git）：

```bash
DEEPSEEK_API_KEY=sk-xxxxxxxx
LITELLM_MASTER_KEY=sk-litellm-xxxxxxxx
```

- `DEEPSEEK_API_KEY` — DeepSeek API 密钥（所有模型共用）
- `LITELLM_MASTER_KEY` — LiteLLM 管理 API 密钥（`/health` 等端点使用）

## 客户端配置

### Claude Code

使用环境变量或 settings.json 指向本地代理：

```
ANTHROPIC_BASE_URL=http://127.0.0.1:4000/v1
ANTHROPIC_API_KEY=sk-litellm-xxxxxxxx
```

### Codex CLI

```
OPENAI_BASE_URL=http://127.0.0.1:4000/v1
OPENAI_API_KEY=sk-litellm-xxxxxxxx
```

## 健康检查

```bash
# 检查服务状态
systemctl status litellm

# 健康检查端点（需要 master key）
curl -H "Authorization: Bearer sk-litellm-yourkey" http://127.0.0.1:4000/health

# 查看可用模型列表
curl http://127.0.0.1:4000/v1/models

# 测试模型连通性
curl -X POST http://127.0.0.1:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-litellm-yourkey" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-haiku-4-5","messages":[{"role":"user","content":"hi"}]}'
```

## 添加新模型

编辑 `host/litellm.nix`，在 `model_list` 中添加条目：

```nix
{
  model_name = "new-model-name";
  litellm_params = {
    model = "anthropic/deepseek-v4-pro";        # 或 openai/deepseek-v4-flash
    api_base = "https://api.deepseek.com/anthropic";  # 或 https://api.deepseek.com
    api_key = "os.environ/DEEPSEEK_API_KEY";
    max_tokens = 32000;
    timeout = 600;
  };
}
```

如果需要 fallback，在 `router_settings.fallbacks` 中添加对应规则。

修改后执行 `sudo nixos-rebuild switch --flake .` 重启服务。

## 故障排查

```bash
# 查看日志
journalctl -u litellm -f

# 重启服务
sudo systemctl restart litellm

# 检查端口监听
ss -tlnp | grep 4000

# 验证环境变量
cat /persist/secrets/litellm.env

# 测试 API 密钥是否有效
curl -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
  https://api.deepseek.com/anthropic/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"hi"}],"max_tokens":10}'
```

### 常见问题

| 问题 | 可能原因 | 解决 |
|------|----------|------|
| `Connection refused` | 服务未启动 | `sudo systemctl start litellm` |
| `401 Unauthorized` | API key 错误 | 检查 `/persist/secrets/litellm.env` |
| `Model not found` | 模型名拼写错误 | 检查 `model_name` 是否与配置一致 |
| 响应很慢 | 路由到错误的模型 | 检查 fallback 链是否触发 |
