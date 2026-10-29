{ runCommand, kdePackages }:

# NextKDE's Stage and other QML helpers use the distro-specific qdbus6 name.
# The locked Nixpkgs Qt 6 package installs the same tool as qdbus.
runCommand "nextkde-qdbus6" { } ''
  mkdir -p "$out/bin"
  ln -s ${kdePackages.qttools}/bin/qdbus "$out/bin/qdbus6"
''
