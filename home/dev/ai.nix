{ pkgs, inputs, ... }:

let
  # ── 修改这里切换版本 ──
  # "latest" = 跟随 nixpkgs 里的 claude-code（默认，rebuild 时自动更新）
  # 或指定具体版本号（需在 claudeSrcs 里配 hash），如 "2.1.222"
  claudeVersion = "latest";

  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;

  claudeSrcs = {
    "2.1.222".hash = "sha256-EMqujyK5FcJr//DgE6TUVgjE8a4odYNiZWkVb0R3MOU=";
    "2.1.156".hash = "sha256-bYPNImRFDF5U/JiL4QMsKIz0GO5gQpSs+4/ErCj196M=";
    "2.1.148".hash = "sha256-OziDahgBpjl/hDHGpisSfOR+Pp0QPBpwD8p/nIq1+Kw=";
  };

  # latest 模式直接用 nixpkgs 的 claude-code（含其 src/hash），跟随最新
  claudePkg =
    if claudeVersion == "latest" then
      pkgs.claude-code
    else
      (pkgs.claude-code.overrideAttrs (_: {
        version = claudeVersion;
        src = pkgs.fetchurl {
          url = "https://downloads.claude.ai/claude-code-releases/${claudeVersion}/linux-x64/claude";
          hash = claudeSrcs.${claudeVersion}.hash;
        };
      }));
in
{
  home.packages = with pkgs; [
    claudePkg
    codex
    llmAgents.claude-desktop
    llmAgents.qoder-cli
    llmAgents.officecli
    llmAgents.pi
    llmAgents.reasonix
    llmAgents.opencode
    cc-switch
    codexDesktop
    (import ../../local-deriv/qoder-ide.nix { inherit pkgs; })
  ];
}
