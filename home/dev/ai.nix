{ pkgs, inputs, ... }:

let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
in
{
  home.packages = with pkgs; [
    codex
    llmAgents.officecli
    cc-switch
    codexDesktop
    codebase-memory-mcp
    (import ../../local-deriv/qoder-ide.nix { inherit pkgs; })
    (import ../../local-deriv/rtk.nix { inherit pkgs; })
  ];

  systemd.user.services.cc-switch = {
    Unit = {
      Description = "CC Switch - AI API Router";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.cc-switch}/bin/cc-switch";
      Restart = "on-failure";
      RestartSec = 5;
      Slice = "app-graphical.slice";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  # 禁用 cc-switch 的 XDG autostart（已由 systemd service 接管）
  xdg.configFile."autostart/CC Switch.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
  
}
