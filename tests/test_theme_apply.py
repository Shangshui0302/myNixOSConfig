import fcntl
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

TEMPLATE = Path(__file__).resolve().parents[1] / 'home/theme/scripts/theme-apply.sh'

class ThemeApplyTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'home'
        self.home.mkdir()
        self.log = self.root / 'calls'
        self.wallpaper = self.root / 'wallpaper'
        self.wallpaper.write_text('wallpaper')
        source = TEMPLATE.read_text()
        # The Matugen double supplies every output expected by this script.
        required = source.split('required_files="', 1)[1].split('"', 1)[0].split()
        self.files = self.root / 'required'
        self.files.write_text('\n'.join(required))
        real = {'coreutils': ['date','dirname','mktemp','cp','mv','rm','head','sha256sum','cut','chmod','touch'],
                'util_linux': ['flock'], 'gnugrep': ['grep'], 'diffutils': ['cmp'], 'gawk': ['awk']}
        values = {}
        for name, commands in real.items():
            prefix = self.root / name
            (prefix / 'bin').mkdir(parents=True)
            for command in commands:
                os.symlink(shutil.which(command), prefix / 'bin' / command)
            values['pkgs_' + name] = str(prefix)
        fake = f'''#!{sys.executable}
import os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
with open(os.environ['CALLS'], 'a') as f: f.write(name + ' ' + ' '.join(sys.argv[1:]) + '\\n')
if name == 'matugen':
    if os.environ.get('MATUGEN_FAIL') == '1': sys.exit(1)
    root = pathlib.Path(os.environ['HOME']) / '.cache/wallpaper-colors/staging'
    files = pathlib.Path(os.environ['REQUIRED']).read_text().splitlines()
    if os.environ.get('INCOMPLETE') == '1': files = files[:-1]
    for rel in files:
        p = root / rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text('content ' + rel)
if name == 'darkman': print('dark')
if name == 'systemctl' and 'app-org.fcitx.Fcitx5@autostart.service' in sys.argv and os.environ.get('RESTART_FAIL') == '1': sys.exit(1)
if name == 'fcitx5-remote' and os.environ.get('REMOTE_FAIL') == '1': sys.exit(1)
'''
        names = {'util_linux': ['logger'], 'matugen':['matugen'], 'darkman':['darkman'],
                 'libnotify':['notify-send'], 'waypaper':['waypaper'], 'jq':['jq'],
                 'kdePackages_kconfig':['kwriteconfig6'], 'glib':['gsettings'],
                 'systemd':['systemctl'], 'noctalia':['noctalia'], 'hyprland':['hyprctl'],
                 'procps':['pkill'], 'fcitx5':['fcitx5-remote']}
        for name, commands in names.items():
            prefix = self.root / name
            (prefix / 'bin').mkdir(parents=True, exist_ok=True)
            for command in commands:
                p = prefix / 'bin' / command
                p.write_text(fake); p.chmod(0o755)
            values['pkgs_' + name] = str(prefix)
        helper = self.root / 'papirus'
        helper.write_text(fake); helper.chmod(0o755)
        values.update(cacheIdentity='test-identity', defaultWallpaper=str(self.wallpaper),
                      matugenConfig=str(self.root / 'config'), papirusFolderApply=str(helper))
        for key, value in values.items(): source = source.replace('@' + key + '@', value)
        self.assertNotRegex(source, r'@[A-Za-z0-9_]+@')
        self.script = self.root / 'theme-apply'
        self.script.write_text(source)
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_CACHE_HOME=str(self.home / '.cache'), XDG_DATA_HOME=str(self.home / '.local/share'),
                        XDG_RUNTIME_DIR=str(self.root / 'runtime'), CALLS=str(self.log), REQUIRED=str(self.files))
        self.env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
        self.env.pop('DBUS_SESSION_BUS_ADDRESS', None)
        self.env.pop('WAYLAND_DISPLAY', None)

    def run_apply(self, *args, **env):
        return subprocess.run(['bash', str(self.script), *args], env={**self.env, **env}, capture_output=True, text=True, timeout=15)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_arguments_and_lock(self):
        self.assertEqual(self.run_apply('invalid').returncode, 2)
        lock = self.home / '.cache/wallpaper-colors/.lock'
        lock.parent.mkdir(parents=True, exist_ok=True)
        with lock.open('w') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            p = subprocess.Popen(['bash', str(self.script), 'dark'], env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                with self.assertRaises(subprocess.TimeoutExpired): p.wait(timeout=0.3)
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)
                p.communicate(timeout=15)
            self.assertEqual(p.returncode, 0)

    def test_cache_explicit_wallpaper_and_unchanged_files(self):
        self.assertEqual(self.run_apply('dark').returncode, 0)
        target = self.home / '.cache/matugen/nvim-colors.lua'
        before = target.stat().st_ino
        self.log.unlink()
        self.assertEqual(self.run_apply('dark').returncode, 0)
        self.assertEqual(target.stat().st_ino, before)
        self.assertFalse(any(x.startswith('matugen ') for x in self.calls()))
        self.assertEqual(self.run_apply('dark', str(self.wallpaper)).returncode, 0)
        self.assertFalse(any(x.startswith('matugen ') for x in self.calls()))
        self.wallpaper.write_text('changed')
        self.assertEqual(self.run_apply('dark', str(self.wallpaper)).returncode, 0)
        self.assertTrue(any(x.startswith('matugen ') for x in self.calls()))

    def test_failure_does_not_publish(self):
        for env in ({'MATUGEN_FAIL':'1'}, {'INCOMPLETE':'1'}):
            result = self.run_apply('dark', **env)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertFalse((self.home / '.cache/wallpaper-colors/current-key').exists())
            self.assertFalse((self.home / '.cache/matugen/nvim-colors.lua').exists())
            self.assertFalse(any((self.home / '.cache/wallpaper-colors/cache').iterdir()))

    def test_symlink_replaced_without_writing_target(self):
        original = self.root / 'original'; original.write_text('untouched')
        target = self.home / '.cache/matugen/nvim-colors.lua'
        target.parent.mkdir(parents=True); target.symlink_to(original)
        self.assertEqual(self.run_apply('dark').returncode, 0)
        self.assertFalse(target.is_symlink())
        self.assertEqual(original.read_text(), 'untouched')

    def test_fcitx_decisions_and_fallbacks(self):
        self.assertEqual(self.run_apply('dark', RESTART_FAIL='1').returncode, 0)
        relevant = [x.split()[0] for x in self.calls() if 'app-org.fcitx.Fcitx5@autostart.service' in x or x.startswith('fcitx5-remote ')]
        self.assertEqual(relevant, ['systemctl', 'fcitx5-remote'])
        self.log.unlink()
        result = self.run_apply('dark')
        self.assertIn('stage=fcitx action=noop', result.stderr)
        self.assertFalse(any('app-org.fcitx.Fcitx5@autostart.service' in x or x.startswith('fcitx5-remote ') for x in self.calls()))
        self.log.unlink()
        result = self.run_apply('light', REMOTE_FAIL='1')
        self.assertIn('stage=fcitx action=reload', result.stderr)
        relevant = [x.split()[0] for x in self.calls() if 'app-org.fcitx.Fcitx5@autostart.service' in x or x.startswith('fcitx5-remote ')]
        self.assertEqual(relevant, ['fcitx5-remote', 'systemctl'])

if __name__ == '__main__': unittest.main()
