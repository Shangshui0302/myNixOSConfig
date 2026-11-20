"""Exercise the evaluated theme hooks, never the whole activation or a desktop session."""
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


def snapshot(home):
    # Detect creation, removal, chmod, in-place writes and same-content replacements.
    result = {}
    for path in (home, *home.rglob('*')):
        info = path.lstat()
        result[path.relative_to(home)] = (info.st_ino, info.st_mode, info.st_mtime_ns)
    return result


class ThemeActivationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.steps = json.loads(Path(os.environ['STEPS']).read_text())

    def prepare_home(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.home = self.root / 'home'
        self.calls = self.root / 'calls'
        self.runtime = self.root / 'runtime'
        self.runtime.mkdir(mode=0o700)
        # Make the session-dependent branches reachable, without a real session.
        (self.home / '.local/bin').mkdir(parents=True)
        (self.home / '.local/bin/theme-apply').symlink_to(os.environ['SESSION_PROBE'])
        (self.home / '.config').mkdir()
        (self.home / '.config/kdeglobals').write_text('[General]\nAccentColor=1,2,3\n')

    def activate(self, body, *, dry_run):
        env = dict(os.environ, HOME=str(self.home), XDG_RUNTIME_DIR=str(self.runtime),
                   CALLS=str(self.calls))
        for name in ('DBUS_SESSION_BUS_ADDRESS', 'DISPLAY', 'WAYLAND_DISPLAY', 'DRY_RUN'):
            env.pop(name, None)
        if dry_run:
            env['DRY_RUN'] = '1'
        subprocess.run(['bash', '-euo', 'pipefail', '-c', 'source "$HM_BASH_LIB"\n' + body],
                       env=env, cwd=self.root, check=True, timeout=15)

    def test_dry_run_does_not_write_or_call_a_session(self):
        for variant, steps in self.steps.items():
            for name, body in steps.items():
                with self.subTest(variant=variant, name=name):
                    self.prepare_home()
                    before = snapshot(self.home)
                    self.activate(body, dry_run=True)
                    self.assertEqual(snapshot(self.home), before)
                    self.assertFalse(self.calls.exists(), 'a session command ran during dry-run')

    def test_live_mode_in_fixture(self):
        self.prepare_home()
        main = self.steps['main']
        self.activate(main['installFcitx5MatugenRuntimeThemes'], dry_run=False)
        for name in ('mellow-matugen', 'mellow-matugen-dark'):
            theme = self.home / '.local/share/fcitx5/themes' / name
            self.assertTrue((theme / 'panel.svg').is_file())
            self.assertTrue(os.access(theme / 'theme.conf', os.W_OK))
        self.activate(main['setupDarkmanMode'], dry_run=False)
        mode = self.home / '.cache/darkman/mode.txt'
        self.assertEqual(mode.read_text(), 'dark')
        self.assertEqual(stat.S_IMODE(mode.stat().st_mode), 0o600)
        mode.write_text('light')
        self.activate(main['setupDarkmanMode'], dry_run=False)
        self.assertEqual(mode.read_text(), 'light')
        css = self.home / '.themes/Material-Gnome-Matugen/gtk-4.0/colors.css'
        css.parent.mkdir(parents=True)
        css.write_text('@media (prefers-color-scheme: dark) {}\n')
        self.activate(main['setupMatugenGtkTheme'], dry_run=False)
        self.assertEqual(css.read_text(), '@media (prefers-color-scheme: dark) {}\n')
        self.activate(main['initializeWhiteSurQt'], dry_run=False)
        self.assertIn('theme=WhiteSurDark', (self.home / '.config/Kvantum/kvantum.kvconfig').read_text())
        # Already-provisioned Waypaper: install its wrapper and config.ini without
        # asking the real wallpaper backend to bootstrap a graphical session.
        for rel in ('.cache/matugen/nvim-colors.lua', '.config/btop/themes/matugen.theme',
                    '.config/yazi/flavors/matugen-runtime.yazi/flavor.toml',
                    '.config/mpv/script-opts/modernz.conf', '.config/zellij/themes/matugen.kdl',
                    '.local/share/icons/Papirus-Matugen/index.theme'):
            target = self.home / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.touch()
        self.activate(main['setupWaypaperTheme'], dry_run=False)
        self.assertIn('backend = awww', (self.home / '.config/waypaper/config.ini').read_text())
        self.assertTrue(os.access(self.home / '.local/bin/wallpaper-theme', os.X_OK))
        self.activate(main['applyRuntimeTheme'], dry_run=False)
        self.activate(self.steps['nextkde']['applyKdeColors'], dry_run=False)
        self.assertEqual(self.calls.read_text().splitlines(), ['called get', 'called light', 'called '])


if __name__ == '__main__':
    unittest.main()
