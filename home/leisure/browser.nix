{ pkgs, ... }:

{
  home.packages = with pkgs; [
    firefox
    (google-chrome.override {
      commandLineArgs = "--password-store=kwallet6";
    })
  ];
}
