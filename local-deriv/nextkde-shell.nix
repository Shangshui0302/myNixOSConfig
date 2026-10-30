{
  pkgs,
  src,
  buildWeather ? true,
}:

# Retain the pinned shell and native plugins; let zero really mean no blur
# for the two popups that otherwise enforce a nonzero Gaussian sigma.
let
  platform = pkgs.callPackage ./nextkde-platform-whitesur.nix { inherit src; };
  upstream = pkgs.callPackage "${src}/packaging/nix/package.nix" {
    inherit src buildWeather;
  };
in
upstream.overrideAttrs (old: {
  pname = "nextkde-shell";
  postPatch = (old.postPatch or "") + ''
    substituteInPlace shell/desktop/modules/bar/ControlCenterGlass.qml \
      --replace-fail 'Math.max(6, 18 * AppearanceConfigService.effectiveLauncherBlur)' \
                     'Math.max(0, 18 * AppearanceConfigService.effectiveLauncherBlur)'
    substituteInPlace shell/desktop/modules/applauncher/AppLauncherWindow.qml \
      --replace-fail 'blurSigma: tonal ? -1 : Math.max(6,' \
                     'blurSigma: tonal ? -1 : Math.max(0,'
  '';
  # All public entry points and bundled units must use the same platform build.
  # Repoint upstream's symlinks and text metadata to drop the unused daemon
  # from this package's runtime references.
  postInstall = (old.postInstall or "") + ''
    ln -sfn ${platform}/libexec/kos-platform "$out/libexec/kos-platform"
    ln -sfn ${platform}/libexec/kos-ai-worker "$out/libexec/kos-ai-worker"
    ln -sfn ${platform}/share/kos/platform/kwin/window-bridge.js \
      "$out/share/kos/platform/kwin/window-bridge.js"
    substituteInPlace "$out/lib/systemd/user/kos-platform.service" \
      "$out/share/applications/org.kos.Platform.desktop" \
      --replace-fail '${upstream.kos-platform}' '${platform}'
  '';
  passthru = (old.passthru or { }) // {
    kos-platform = platform;
  };
})
