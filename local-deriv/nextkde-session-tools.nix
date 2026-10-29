{ writeShellApplication, systemd }:

# KOS invokes LightDM's command name. Implement only its switch-to-greeter
# operation using the same lock-then-switch protocol as Plasma 6.8.1.
writeShellApplication {
  name = "dm-tool";
  runtimeInputs = [ systemd ];
  text = ''
    if [[ $# -ne 1 || $1 != switch-to-greeter ]]; then
      echo "Usage: dm-tool switch-to-greeter" >&2
      exit 2
    fi
    seatPath="''${XDG_SEAT_PATH:?SDDM did not provide XDG_SEAT_PATH}"
    busctl --user call org.freedesktop.ScreenSaver /ScreenSaver \
      org.freedesktop.ScreenSaver Lock
    exec busctl --system call org.freedesktop.DisplayManager "$seatPath" \
      org.freedesktop.DisplayManager.Seat SwitchToGreeter
  '';
}
