import fcntl
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
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
                'util_linux': ['flock'], 'gnugrep': ['grep'], 'diffutils': ['cmp'], 'gnused': ['sed'],
                'kdePackages_kconfig': ['kwriteconfig6']}
        values = {'runtimeShell': shutil.which('bash')}
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
                 'glib':['gsettings'],
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
        values.update(themePython=sys.executable, strataSelector=str(TEMPLATE.with_name('select-strata-theme.py')),
                      fcitxSelector=str(TEMPLATE.with_name('select-fcitx-theme.py')),
                      cacheIdentity='test-identity', defaultWallpaper=str(self.wallpaper),
                      matugenConfig=str(self.root / 'config'), papirusFolderApply=str(helper))
        for key, value in values.items(): source = source.replace('@' + key + '@', value)
        self.assertNotRegex(source, r'@[A-Za-z0-9_]+@')
        self.script = self.root / 'theme-apply'
        self.script.write_text(source)
        self.script.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_CACHE_HOME=str(self.home / '.cache'), XDG_DATA_HOME=str(self.home / '.local/share'),
                        XDG_RUNTIME_DIR=str(self.root / 'runtime'), CALLS=str(self.log), REQUIRED=str(self.files))
        self.env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
        self.env.pop('DBUS_SESSION_BUS_ADDRESS', None)
        self.env.pop('WAYLAND_DISPLAY', None)

    def run_apply(self, *args, **env):
        return subprocess.run([str(self.script), *args], env={**self.env, **env}, capture_output=True, text=True, timeout=15)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_arguments_and_lock(self):
        self.assertEqual(self.run_apply('invalid').returncode, 2)
        lock = self.home / '.cache/wallpaper-colors/.lock'
        lock.parent.mkdir(parents=True, exist_ok=True)
        with lock.open('w') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            p = subprocess.Popen([str(self.script), 'dark'], env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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

    def test_noctalia_palette_recovers_without_reloading_a_healthy_palette(self):
        palette = self.home / '.config/noctalia/palettes/matugen.json'
        self.assertEqual(self.run_apply('dark').returncode, 0)
        original = palette.read_bytes()
        palette.unlink()
        self.log.unlink()
        result = self.run_apply('dark')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(palette.is_file(), 'same-key apply did not restore the palette')
        self.assertEqual(palette.read_bytes(), original)
        before = palette.stat()
        self.assertEqual(self.run_apply('light').returncode, 0)
        after = palette.stat()
        self.assertEqual((before.st_ino, before.st_mtime_ns), (after.st_ino, after.st_mtime_ns))
        self.assertFalse(any(x.startswith('matugen ') for x in self.calls()))

    def test_empty_cached_palette_is_not_published(self):
        self.assertEqual(self.run_apply('dark').returncode, 0)
        palette = self.home / '.config/noctalia/palettes/matugen.json'
        original = palette.read_bytes()
        cache = self.home / '.cache/wallpaper-colors'
        key = (cache / 'current-key').read_text().strip()
        cached = cache / 'cache' / key / 'dual/noctalia/palettes/matugen.json'
        cached.write_bytes(b'')
        result = self.run_apply('dark', MATUGEN_FAIL='1')
        self.assertNotEqual(result.returncode, 0, result.stderr)
        self.assertEqual(palette.read_bytes(), original)
        self.assertEqual(self.run_apply('dark').returncode, 0)
        self.assertEqual(cached.read_bytes(), original)

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

    def test_classicui_seeds_vertical_only_for_a_new_file(self):
        path = self.home / '.config/fcitx5/conf/classicui.conf'
        result = self.run_apply('dark')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Vertical Candidate List=True\n', path.read_text())
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        # Removing the preference or leaving an existing file empty is not first use.
        for existing in (b'Font=Example 15', b''):
            with self.subTest(existing=existing):
                path.write_bytes(existing)
                result = self.run_apply('light')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn(b'Vertical Candidate List=', path.read_bytes())
                self.assertIn(existing, path.read_bytes())
                self.assertIn(b'Theme=mellow-matugen\n', path.read_bytes())

    def test_classicui_preserves_preferences_across_modes_and_wallpaper_changes(self):
        path = self.home / '.config/fcitx5/conf/classicui.conf'
        path.parent.mkdir(parents=True)
        prefs = b'# User settings\r\nFont=Example 15\r\nVertical Candidate List=False\r\n'
        section = b'[Other]\r\nTheme=section-theme\r\nDarkTheme=keep\r\nUseDarkTheme=False'
        path.write_bytes(prefs + b'Theme=mellow-kde-dark\r\n' + section)
        path.chmod(0o640)
        for mode, theme in [('light', b'mellow-matugen'), ('dark', b'mellow-matugen-dark')]:
            result = self.run_apply(mode)
            self.assertEqual(result.returncode, 0, result.stderr)
            root, tail = path.read_bytes().split(b'[Other]', 1)
            self.assertIn(prefs, root)
            self.assertEqual(b'[Other]' + tail, section)
            self.assertEqual([x for x in root.splitlines() if x.startswith(b'Theme=')], [b'Theme=' + theme])
            self.assertIn(b'DarkTheme=mellow-matugen-dark', root.splitlines())
            self.assertIn(b'UseDarkTheme=True', root.splitlines())
            self.assertEqual(path.stat().st_mode & 0o777, 0o640)
        before = path.stat()
        content = path.read_bytes()
        self.wallpaper.write_text('different wallpaper')
        result = self.run_apply('dark', str(self.wallpaper))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(path.read_bytes(), content)
        self.assertEqual((before.st_ino, before.st_mtime_ns), (path.stat().st_ino, path.stat().st_mtime_ns))

    def test_classicui_symlink_is_not_replaced(self):
        path = self.home / '.config/fcitx5/conf/classicui.conf'
        path.parent.mkdir(parents=True)
        target = self.root / 'user-classicui'
        target.write_text('Font=Example 15\n')
        path.symlink_to(target)
        result = self.run_apply('dark')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('skipping non-regular classicui.conf', result.stderr)
        self.assertEqual(path.readlink(), target)
        self.assertEqual(target.read_text(), 'Font=Example 15\n')

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

    def test_fcitx_retry_on_previous_failure(self):
        pending_file = self.home / '.cache/wallpaper-colors/fcitx-pending'

        # Both restart and remote fail; assets and config are written to disk,
        # but pending refresh state is retained for retry.
        res1 = self.run_apply('dark', RESTART_FAIL='1', REMOTE_FAIL='1')
        self.assertEqual(res1.returncode, 0)
        self.assertIn('stage=fcitx action=restart status=failed', res1.stderr)
        self.assertTrue(pending_file.exists())
        self.assertEqual(pending_file.read_text().strip(), 'restart')

        # Second run: same wallpaper & theme, files on disk are identical, but
        # failure flags are cleared. It must retry the restart rather than noop.
        self.log.unlink()
        res2 = self.run_apply('dark')
        self.assertEqual(res2.returncode, 0)
        self.assertIn('stage=fcitx action=restart', res2.stderr)
        self.assertNotIn('status=failed', res2.stderr)
        self.assertFalse(pending_file.exists())
        relevant = [x.split()[0] for x in self.calls() if 'app-org.fcitx.Fcitx5@autostart.service' in x or x.startswith('fcitx5-remote ')]
        self.assertEqual(relevant, ['systemctl'])

        # Third run: everything up-to-date and pending flag cleared -> noop.
        self.log.unlink()
        res3 = self.run_apply('dark')
        self.assertEqual(res3.returncode, 0)
        self.assertIn('stage=fcitx action=noop', res3.stderr)
        self.assertFalse(any('app-org.fcitx.Fcitx5@autostart.service' in x or x.startswith('fcitx5-remote ') for x in self.calls()))

        # Also verify config reload failure retry:
        res4 = self.run_apply('light', RESTART_FAIL='1', REMOTE_FAIL='1')
        self.assertEqual(res4.returncode, 0)
        self.assertIn('stage=fcitx action=reload status=failed', res4.stderr)
        self.assertTrue(pending_file.exists())
        self.assertEqual(pending_file.read_text().strip(), 'reload')

        self.log.unlink()
        res5 = self.run_apply('light')
        self.assertEqual(res5.returncode, 0)
        self.assertIn('stage=fcitx action=reload', res5.stderr)
        self.assertNotIn('status=failed', res5.stderr)
        self.assertFalse(pending_file.exists())
        relevant = [x.split()[0] for x in self.calls() if 'app-org.fcitx.Fcitx5@autostart.service' in x or x.startswith('fcitx5-remote ')]
        self.assertEqual(relevant, ['fcitx5-remote'])

    def test_strata_selects_only_root_keys(self):
        path = self.home / '.config/strata/settings.toml'
        path.parent.mkdir(parents=True)
        fixtures = {
            'quoted key': "  'mode' = 'dark' # keep comment\n",
            'multiline string': 'note = """first line\ntheme = not a key\nlast line"""\n',
            'indented table': 'ratio = nan\n  [pane]\nmode = "nested"\ntheme = "keep"',
            'already selected': "  'theme' = 'matugen'\nmode='theme' # keep comment\n",
        }
        for label, source in fixtures.items():
            with self.subTest(label=label):
                path.write_text(source)
                path.chmod(0o640)
                before = path.stat()
                expected = {**tomllib.loads(source, parse_float=str), 'theme': 'matugen', 'mode': 'theme'}
                result = self.run_apply('dark')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn('settings-assert-failed', result.stderr)
                updated = path.read_text()
                self.assertEqual(tomllib.loads(updated, parse_float=str), expected)
                self.assertEqual(path.stat().st_mode & 0o777, 0o640)
                if '# keep comment' in source:
                    self.assertIn('# keep comment', updated)
                if label == 'already selected':
                    self.assertEqual(updated, source)
                    self.assertEqual(path.stat().st_ino, before.st_ino)
                before = path.stat()
                again = self.run_apply('light')
                self.assertEqual(again.returncode, 0, again.stderr)
                self.assertNotIn('stage=strata', again.stderr)
                self.assertEqual(path.stat().st_ino, before.st_ino)
                self.assertEqual(path.stat().st_mtime_ns, before.st_mtime_ns)

    def test_strata_refuses_invalid_or_conflicting_settings(self):
        path = self.home / '.config/strata/settings.toml'
        path.parent.mkdir(parents=True)
        for source in (b'mode = "one"\nmode = "two"\n', b'other = [\n',
                       b'[theme]\ncustom = true\n', b'other = "\xff"\n'):
            with self.subTest(source=source):
                path.write_bytes(source)
                before = path.stat()
                result = self.run_apply('dark')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('stage=strata status=settings-assert-failed', result.stderr)
                self.assertIn('complete mode=dark', result.stderr)
                self.assertEqual(path.read_bytes(), source)
                self.assertEqual(path.stat().st_ino, before.st_ino)
                self.assertEqual(list(path.parent.glob('.settings.toml.*')), [])

    def test_strata_leaves_user_symlink_intact(self):
        path = self.home / '.config/strata/settings.toml'
        path.parent.mkdir(parents=True)
        original = self.root / 'strata-user-settings'
        original.write_text('mode = "dark"\n')
        path.symlink_to(original)
        result = self.run_apply('dark')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('stage=strata status=settings-assert-failed', result.stderr)
        self.assertEqual(path.readlink(), original)
        self.assertEqual(original.read_text(), 'mode = "dark"\n')

    def test_strata_first_apply_creates_minimal_settings(self):
        result = self.run_apply('dark')
        self.assertEqual(result.returncode, 0, result.stderr)
        path = self.home / '.config/strata/settings.toml'
        self.assertEqual(tomllib.loads(path.read_text()), {'theme': 'matugen', 'mode': 'theme'})
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_dolphinrc_immutable_cleared_on_theme_apply(self):
        # Simulate NextKDE leftover immutable ColorScheme in ~/.config/dolphinrc
        dolphinrc = self.home / '.config/dolphinrc'
        dolphinrc.parent.mkdir(parents=True, exist_ok=True)
        dolphinrc.write_text('[UiSettings]\nColorScheme[$i]=\n')

        res = self.run_apply('dark')
        self.assertEqual(res.returncode, 0)
        # Verify [$i] was cleared and the WhiteSur dark palette was selected.
        content = dolphinrc.read_text()
        self.assertNotIn('[$i]=', content)
        self.assertIn('ColorScheme=WhiteSurDark', content)
        # Verify subsequent stages were reached and executed (gsettings, etc.)
        self.assertTrue(any(x.startswith('gsettings ') and 'color-scheme' in x for x in self.calls()))

    def test_qt_whitesur_tracks_mode_without_matugen_qt_assets(self):
        selector = self.home / '.config/Kvantum/kvantum.kvconfig'
        selector.parent.mkdir(parents=True)
        old = self.root / 'old-selector'
        old.write_text('[General]\ntheme=MaterialAdw\n')
        selector.symlink_to(old)
        self.assertEqual(self.run_apply('dark').returncode, 0)
        self.assertFalse(selector.is_symlink())
        self.assertEqual(selector.read_text(), '[General]\ntheme=WhiteSurDark\n')
        self.assertEqual(old.read_text(), '[General]\ntheme=MaterialAdw\n')
        self.log.unlink()
        self.assertEqual(self.run_apply('light').returncode, 0)
        self.assertEqual(selector.read_text(), '[General]\ntheme=WhiteSur\n')
        self.assertIn('ColorScheme=WhiteSur\n', (self.home / '.config/dolphinrc').read_text())
        self.assertFalse(any(x.startswith('matugen ') for x in self.calls()))
        self.assertFalse((self.home / '.config/qt5ct/colors/matugen.conf').exists())
        self.assertFalse((self.home / '.config/Kvantum/MaterialAdw').exists())

if __name__ == '__main__': unittest.main()
