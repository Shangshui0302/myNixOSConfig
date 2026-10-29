{
  lib,
  stdenv,
  cmake,
  ninja,
  kdePackages,
  src,
}:

# The immutable NextKDE input owns the version and source hash in flake.lock.
# Unlike tools/install-apps.sh, this only builds store artifacts: activation of
# the PIM D-Bus service is owned by the NextKDE specialisation consumer.
stdenv.mkDerivation {
  pname = "nextkde-apps";
  version = lib.removeSuffix "\n" (builtins.readFile "${src}/VERSION");
  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    kdePackages.extra-cmake-modules
    kdePackages.qttools
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = [
    kdePackages.qtbase
    kdePackages.qtdeclarative
    kdePackages.qtwayland
    kdePackages.qtsvg
    kdePackages.qt5compat
    kdePackages.kcalendarcore
    kdePackages.kwindowsystem
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DKOS_BUILD_PLATFORM=OFF"
    "-DKOS_BUILD_KWIN_PLUGINS=OFF"
    "-DKOS_BUILD_SPATIAL=OFF"
    "-DKOS_BUILD_CALENDAR=ON"
    "-DKOS_BUILD_TODO=ON"
    "-DKOS_BUILD_CALCULATOR=ON"
    "-DKOS_BUILD_WEATHER=OFF"
    "-DKOS_BUILD_LISTENFREE=OFF"
    "-DBUILD_TESTING=OFF"
  ];

  # Upstream uses share/systemd, while NixOS systemd.packages scans lib/systemd.
  # Keep the original unit (including Type=dbus) available for consumer drop-ins.
  postInstall = ''
    mkdir -p "$out/lib/systemd/user"
    mv "$out/share/systemd/user/kos-pim-service.service" "$out/lib/systemd/user/"
    rmdir "$out/share/systemd/user" "$out/share/systemd"
  '';

  meta = {
    description = "NextKDE Calendar, Todo and Calculator with their PIM service";
    homepage = "https://github.com/NextKde/NextKde";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
