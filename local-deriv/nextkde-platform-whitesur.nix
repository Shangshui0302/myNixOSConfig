{ pkgs, src }:

# Keep the pinned upstream daemon and all its integrations. Only replace the
# palette pair used by theme.apply-system; never apply a full Look-and-Feel.
(pkgs.callPackage "${src}/packaging/nix/kos-platform.nix" { inherit src; }).overrideAttrs
  (old: {
    pname = "nextkde-platform-whitesur";
    patches = (old.patches or [ ]) ++ [ ./nextkde-platform-preserve-theme.patch ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/daemon/PlatformServerTheme.cpp \
        --replace-fail 'QStringLiteral("BreezeDark")' 'QStringLiteral("WhiteSurDark")' \
        --replace-fail 'QStringLiteral("BreezeLight")' 'QStringLiteral("WhiteSur")'
    '';
    # KWin checks this desktop entry's Exec against the running executable
    # before permitting window thumbnails (ScreenShot2).
    postInstall = (old.postInstall or "") + ''
      mkdir -p "$out/share/applications"
      substitute ${src}/packaging/desktop/org.kos.Platform.desktop.in \
        "$out/share/applications/org.kos.Platform.desktop" \
        --replace-fail '@KOS_PLATFORM_EXEC@' "$out/libexec/kos-platform"
    '';
  })
