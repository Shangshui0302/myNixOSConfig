{ pkgs, inputs, ... }:

let
  # ── 修改这里切换版本 ──
  claudeVersion = "2.1.156";

  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  claudeSrcs = {
    "2.1.156".hash = "sha256-bYPNImRFDF5U/JiL4QMsKIz0GO5gQpSs+4/ErCj196M=";
    "2.1.148".hash = "sha256-OziDahgBpjl/hDHGpisSfOR+Pp0QPBpwD8p/nIq1+Kw=";
  };
in
{
  home.packages = with pkgs; [
    (claude-code.overrideAttrs (_: {
      version = claudeVersion;
      src = pkgs.fetchurl {
        url = "https://downloads.claude.ai/claude-code-releases/${claudeVersion}/linux-x64/claude";
        hash = claudeSrcs.${claudeVersion}.hash;
      };
    }))
    codex
    llmAgents.claude-desktop
    llmAgents.qoder-cli
    llmAgents.officecli
    llmAgents.pi
    llmAgents.reasonix
    llmAgents.opencode
    cc-switch
  ];
}
