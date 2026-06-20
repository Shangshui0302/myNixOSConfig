{ pkgs, lib, config, ... }: {
  home.packages = with pkgs; [
    wineWow64Packages.stable
    winetricks
    virt-manager
  ];

  services.flatpak.packages = [
    "com.usebottles.bottles"
    "com.github.tchx84.Flatseal"
  ];

  services.flatpak.overrides = {
    "com.usebottles.bottles" = {
      Context = {
        shared = [ "network" "ipc" ];
        sockets = [
          "wayland"
          "fallback-x11"
          "pulseaudio"
          "system-bus"
        ];
        devices = [ "all" ];
        filesystems = [
          "~/Downloads:rw"
          "~/.local/share/applications:rw"
          "~/Games:rw"
          "~/.local/share/bottles:rw"
          "~/.local/share/bottles-repos:ro"
          "/usr/share/fonts:ro"
        ];
      };
      Environment = {
        GIO_USE_NETWORK_MONITOR = "base";

        http_proxy = "http://127.0.0.1:7890";
        https_proxy = "http://127.0.0.1:7890";
        all_proxy = "socks5://127.0.0.1:7890";
        HTTP_PROXY = "http://127.0.0.1:7890";
        HTTPS_PROXY = "http://127.0.0.1:7890";
        ALL_PROXY = "socks5://127.0.0.1:7890";

        PERSONAL_COMPONENTS = "file://${config.home.homeDirectory}/.local/share/bottles-repos/components/";
        PERSONAL_DEPENDENCIES = "file://${config.home.homeDirectory}/.local/share/bottles-repos/dependencies/";
        PERSONAL_INSTALLERS = "file://${config.home.homeDirectory}/.local/share/bottles-repos/programs/";

        QT_IM_MODULE = "fcitx";
        GTK_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
      };
    };
  };

  # Activation script: maintain local repos and apply Bottles patches.
  # This keeps Bottles working even when repo.usebottles.com is down.
  home.activation = {
    bottlesOffline = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      REPO_DIR="$HOME/.local/share/bottles-repos"
      mkdir -p "$REPO_DIR"

      echo "[bottles-offline] Updating local repository indexes..."
      for repo in components dependencies programs; do
        if [ -d "$REPO_DIR/$repo/.git" ]; then
          ${pkgs.git}/bin/git -C "$REPO_DIR/$repo" pull --ff-only 2>/dev/null || echo "  git pull $repo failed (offline?), using cached copy"
        else
          ${pkgs.git}/bin/git clone "https://github.com/bottlesdevs/$repo.git" "$REPO_DIR/$repo" 2>/dev/null || echo "  clone $repo failed (offline?), skip"
        fi
      done

      # Apply source patches to Bottles flatpak so it can use local file:// repos
      BOTTLES_SRC="$HOME/.local/share/flatpak/app/com.usebottles.bottles/x86_64/stable/active/files/share/bottles/bottles/backend"
      if [ ! -d "$BOTTLES_SRC" ]; then
        echo "[bottles-offline] Bottles flatpak not found, skipping patches"
        exit 0
      fi

      ${pkgs.python3}/bin/python3 <<'PYEOF'
import os, sys

base = os.path.expanduser(
    "~/.local/share/flatpak/app/com.usebottles.bottles/"
    "x86_64/stable/active/files/share/bottles/bottles/backend"
)
patched = 0

# --- connection.py: always report online ---
conn = os.path.join(base, "utils/connection.py")
if os.path.exists(conn):
    with open(conn) as f:
        c = f.read()
    if "PATCHED:" not in c:
        old = '        if self.force_offline or "FORCE_OFFLINE" in os.environ:'
        new = (
            '        # PATCHED: repo.usebottles.com infrastructure is unstable.\n'
            '        # Local repos provide all data; always report online.\n'
            '        self.status = True\n'
            '        return True\n'
            + old
        )
        if old in c:
            c = c.replace(old, new, 1)
            with open(conn, "w") as f:
                f.write(c)
            print("  Patched: connection.py")
            patched += 1
        else:
            print("  WARNING: connection.py pattern not found, code may have changed")

# --- repo.py: file:// support ---
repo = os.path.join(base, "repos/repo.py")
if os.path.exists(repo):
    with open(repo) as f:
        c = f.read()
    if "PATCHED: support file://" not in c:
        # Add import
        old_import = "from io import BytesIO"
        new_import = "from io import BytesIO\nfrom urllib.request import url2pathname"
        if old_import in c:
            c = c.replace(old_import, new_import, 1)
        else:
            print("  WARNING: repo.py import pattern not found")

        # Patch __get_catalog
        old_cat = "        if index in [\"\", None] or offline:\n            return {}"
        new_cat = (
            "        if index in [\"\", None] or offline:\n"
            "            return {}\n\n"
            "        # PATCHED: support file:// URLs for local repos\n"
            "        if index.startswith(\"file://\"):\n"
            "            try:\n"
            '                local_path = url2pathname(index[7:])\n'
            '                with open(local_path, "r") as f:\n'
            "                    catalog = yaml.load(f.read())\n"
            '                logging.info(f"Catalog {self.name} loaded from local file")\n'
            "                return catalog\n"
            "            except Exception as e:\n"
            '                logging.error(f"Cannot load {self.name} from local file: {e}")\n'
            "                return {}"
        )
        if old_cat in c:
            c = c.replace(old_cat, new_cat, 1)
        else:
            print("  WARNING: __get_catalog pattern not found")

        # Patch get_manifest
        old_man = "    def get_manifest(self, url: str, plain: bool = False) -> str | dict | bool:\n        try:"
        new_man = (
            "    def get_manifest(self, url: str, plain: bool = False) -> str | dict | bool:\n"
            "        # PATCHED: support file:// URLs for local repos\n"
            "        if url.startswith(\"file://\"):\n"
            "            try:\n"
            '                local_path = url2pathname(url[7:])\n'
            '                with open(local_path, "r") as f:\n'
            "                    res = f.read()\n"
            "                if plain:\n"
            "                    return res\n"
            "                return yaml.load(res)\n"
            "            except Exception as e:\n"
            '                logging.error(f"Cannot load {self.name} manifest from local: {e}")\n'
            "                return False\n"
            "        try:"
        )
        if old_man in c:
            c = c.replace(old_man, new_man, 1)
        else:
            print("  WARNING: get_manifest pattern not found")

        with open(repo, "w") as f:
            f.write(c)
        print("  Patched: repo.py")
        patched += 1

# --- repository.py: file:// index support ---
repoman = os.path.join(base, "managers/repository.py")
if os.path.exists(repoman):
    with open(repoman) as f:
        c = f.read()
    if "PATCHED: handle file://" not in c:
        old_idx = (
            "                for url in (__index, __fallback):\n"
            "                    c = pycurl.Curl()"
        )
        new_idx = (
            "                for url in (__index, __fallback):\n"
            "                    # PATCHED: handle file:// URLs without pycurl\n"
            '                    if url.startswith("file://"):\n'
            "                        from urllib.request import url2pathname\n"
            '                        local_path = url2pathname(url[7:])\n'
            "                        if os.path.exists(local_path):\n"
            '                            _data["index"] = url\n'
            "                            SignalManager.send(\n"
            "                                Signals.RepositoryFetched, Result(True, data=total)\n"
            "                            )\n"
            "                            break\n"
            "                        continue\n"
            "                    c = pycurl.Curl()"
        )
        if old_idx in c:
            c = c.replace(old_idx, new_idx, 1)

            # Also fix the check after pycurl to remove file:// check
            old_check = (
                "                    if url.startswith(\"file://\") or c.getinfo(c.RESPONSE_CODE) == 200:"
            )
            new_check = (
                "                    if c.getinfo(c.RESPONSE_CODE) == 200:"
            )
            if old_check in c:
                c = c.replace(old_check, new_check, 1)
            else:
                print("  WARNING: response_code check pattern not found")

            with open(repoman, "w") as f:
                f.write(c)
            print("  Patched: repository.py")
            patched += 1
        else:
            print("  WARNING: repository.py __get_index pattern not found")

if patched == 0:
    print("[bottles-offline] Patches already applied, nothing to do")
else:
    print(f"[bottles-offline] Applied {patched}/3 patches")
PYEOF
    '';
  };
}
