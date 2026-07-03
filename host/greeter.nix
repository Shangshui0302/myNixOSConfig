{ pkgs, ... }:

{
  # Disable SDDM just in case
  services.displayManager.sddm.enable = false;

  # Enable Noctalia Greeter (requires inputs.noctalia-greeter.nixosModules.default in flake.nix)
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      output = {
        scale = 1.5;
      };
      appearance = {
        password_style = "random";
        hide_logo = true;
      };
    };
  };
}
