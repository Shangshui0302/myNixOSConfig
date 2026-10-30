"""Isolated behavioral tests for power-actions script."""

import fcntl
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

TEMPLATE = Path(__file__).resolve().parents[1] / "home/env/scripts/power-actions.sh"


class PowerActionsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

        self.home = self.root / "home"
        self.home.mkdir()
        self.runtime_dir = self.root / "runtime"
        self.runtime_dir.mkdir()
        self.sysfs = self.root / "sysfs"
        self.sysfs.mkdir()
        self.log = self.root / "calls.log"

        # Mock bin directory
        self.bin_dir = self.root / "bin"
        self.bin_dir.mkdir()

        # State storage for fake commands
        self.state_dir = self.root / "mock_state"
        self.state_dir.mkdir()
        (self.state_dir / "profile").write_text("balanced")
        (self.state_dir / "darkman").write_text("light")
        (self.state_dir / "units_active").write_text("onedrive\n")

        # Fake commands dispatcher
        fake_dispatcher = f"""#!{sys.executable}
import json, os, pathlib, sys

cmd = pathlib.Path(sys.argv[0]).name
calls_file = os.environ.get('CALLS_FILE')
state_dir = pathlib.Path(os.environ['MOCK_STATE_DIR'])

if calls_file:
    with open(calls_file, 'a') as f:
        f.write(cmd + ' ' + ' '.join(sys.argv[1:]) + '\\n')

if cmd == 'tlpctl':
    if len(sys.argv) > 1 and sys.argv[1] == 'get':
        print((state_dir / 'profile').read_text().strip())
        sys.exit(0)
    elif len(sys.argv) > 2 and sys.argv[1] == 'set':
        if os.environ.get('TLPCTL_FAIL') == '1':
            sys.exit(1)
        (state_dir / 'profile').write_text(sys.argv[2])
        sys.exit(0)
    sys.exit(0)

if cmd == 'darkman':
    if len(sys.argv) > 1 and sys.argv[1] == 'get':
        print((state_dir / 'darkman').read_text().strip())
        sys.exit(0)
    elif len(sys.argv) > 2 and sys.argv[1] == 'set':
        if os.environ.get('DARKMAN_FAIL') == '1':
            sys.exit(1)
        (state_dir / 'darkman').write_text(sys.argv[2])
        sys.exit(0)
    sys.exit(0)

if cmd == 'systemctl':
    # systemctl --user is-active [--quiet] <unit>
    # systemctl --user stop <unit>
    # systemctl --user start <unit>
    positional = [a for a in sys.argv[1:] if not a.startswith('-')]
    action = positional[0] if positional else ''
    unit = positional[1] if len(positional) > 1 else ''
    active_file = state_dir / 'units_active'
    active = set(active_file.read_text().splitlines()) if active_file.exists() else set()

    if action == 'is-active':
        sys.exit(0 if unit in active else 3)
    elif action == 'stop':
        if os.environ.get('SYSTEMCTL_STOP_FAIL') == '1':
            sys.exit(1)
        active.discard(unit)
        active_file.write_text('\\n'.join(sorted(active)) + ('\\n' if active else ''))
        sys.exit(0)
    elif action == 'start':
        if os.environ.get('SYSTEMCTL_START_FAIL') == '1':
            sys.exit(1)
        active.add(unit)
        active_file.write_text('\\n'.join(sorted(active)) + '\\n')
        sys.exit(0)
    sys.exit(0)

if cmd == 'hyprctl':
    # hyprctl -j getoption <kw>
    # hyprctl eval <lua>
    opts_file = state_dir / 'hypr_options.json'
    opts = json.loads(opts_file.read_text()) if opts_file.exists() else {{}}
    if '-j' in sys.argv and 'getoption' in sys.argv:
        kw = sys.argv[sys.argv.index('getoption') + 1]
        val = opts.get(kw, {{'option': kw, 'int': 0, 'set': False}})
        print(json.dumps(val))
        sys.exit(0)
    elif 'eval' in sys.argv:
        if os.environ.get('HYPRCTL_FAIL') == '1':
            print('error: syntax error')
            sys.exit(0)
        # Parse update if simple hl.config({{ ["kw"] = val }})
        expr = sys.argv[sys.argv.index('eval') + 1]
        print('ok')
        sys.exit(0)
    sys.exit(0)
"""

        for cmd_name in ["tlpctl", "darkman", "systemctl", "hyprctl"]:
            p = self.bin_dir / cmd_name
            p.write_text(fake_dispatcher)
            p.chmod(0o755)

        # Set default hypr options
        hypr_defaults = {
            "animations:enabled": {"option": "animations:enabled", "bool": True, "set": True},
            "decoration:active_opacity": {"option": "decoration:active_opacity", "float": 0.88, "set": True},
            "decoration:inactive_opacity": {"option": "decoration:inactive_opacity", "float": 0.82, "set": True},
            "decoration:blur:passes": {"option": "decoration:blur:passes", "int": 4, "set": True},
            "decoration:blur:size": {"option": "decoration:blur:size", "int": 15, "set": True},
            "decoration:shadow:enabled": {"option": "decoration:shadow:enabled", "bool": True, "set": True},
        }
        import json
        (self.state_dir / "hypr_options.json").write_text(json.dumps(hypr_defaults))

        # Setup mock Hyprland socket
        self.hypr_sig_dir = self.runtime_dir / "hypr" / "test-instance"
        self.hypr_sig_dir.mkdir(parents=True)
        (self.hypr_sig_dir / ".socket.sock").touch()

        # Instantiate test script with configuration substitutions
        source = TEMPLATE.read_text()
        subs = {
            "@power_saver_profile@": "power-saver",
            "@dark_mode@": "true",
            "@effects_enabled@": "true",
            "@policy_enabled@": "true",
            "@power_saver_below@": "40",
            "@balanced_above@": "60",
            "@pause_units@": "onedrive",
            "@effects_values@": (
                "animations:enabled false\n"
                "decoration:active_opacity 1.0\n"
                "decoration:blur:passes 2\n"
                "decoration:blur:size 5\n"
                "decoration:inactive_opacity 1.0\n"
                "decoration:shadow:enabled false"
            ),
        }
        for k, v in subs.items():
            source = source.replace(k, v)
        self.assertNotIn("@", [line for line in source.splitlines() if "@" in line and not line.strip().startswith("#")])

        bash_bin = shutil.which("bash") or "/bin/bash"
        if source.startswith("#!"):
            source = f"#!{bash_bin}\n" + source.split("\n", 1)[1]
        else:
            source = f"#!{bash_bin}\n" + source

        self.script = self.root / "power-actions"
        self.script.write_text(source)
        self.script.chmod(0o755)

        # Base environment
        self.env = dict(
            os.environ,
            HOME=str(self.home),
            XDG_RUNTIME_DIR=str(self.runtime_dir),
            POWER_SUPPLY_DIR=str(self.sysfs),
            CALLS_FILE=str(self.log),
            MOCK_STATE_DIR=str(self.state_dir),
            PATH=f"{self.bin_dir}:{os.environ.get('PATH', '')}",
        )

    def set_battery(self, capacity=50, ac=False, status="Discharging"):
        """Configure mock sysfs power supply files."""
        shutil.rmtree(self.sysfs)
        self.sysfs.mkdir()

        bat = self.sysfs / "BAT0"
        bat.mkdir()
        (bat / "type").write_text("Battery\n")
        (bat / "capacity").write_text(f"{capacity}\n")
        (bat / "status").write_text(f"{status}\n")

        ac_dir = self.sysfs / "AC0"
        ac_dir.mkdir()
        (ac_dir / "type").write_text("Mains\n")
        (ac_dir / "online").write_text("1\n" if ac else "0\n")

    def run_cmd(self, *args, **env_overrides):
        cmd_env = {**self.env, **env_overrides}
        return subprocess.run(
            ["bash", str(self.script), *args],
            env=cmd_env,
            capture_output=True,
            text=True,
            timeout=15,
        )

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def clear_calls(self):
        if self.log.exists():
            self.log.unlink()

    def test_subcommand_parsing_and_locking(self):
        # Unknown subcommand exits with 2
        res = self.run_cmd("invalid-subcmd")
        self.assertEqual(res.returncode, 2)
        self.assertIn("用法: power-actions", res.stdout)

        # mode without argument prints current profile
        res = self.run_cmd("mode")
        self.assertEqual(res.returncode, 0)
        self.assertIn("当前档位: balanced", res.stdout)

        # mode with invalid argument exits with 2
        res = self.run_cmd("mode", "turbo")
        self.assertEqual(res.returncode, 2)
        self.assertIn("未知档位: turbo", res.stderr)

        # help exits with 0
        res = self.run_cmd("help")
        self.assertEqual(res.returncode, 0)
        self.assertIn("用法: power-actions", res.stdout)

        # flock serializes concurrent execution
        lock_file = self.runtime_dir / "power-actions" / "lock"
        lock_file.parent.mkdir(parents=True, exist_ok=True)
        with lock_file.open("w") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            proc = subprocess.Popen(
                ["bash", str(self.script), "mode"],
                env=self.env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            try:
                with self.assertRaises(subprocess.TimeoutExpired):
                    proc.wait(timeout=0.3)
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)
                stdout, stderr = proc.communicate(timeout=5)
            self.assertEqual(proc.returncode, 0)

    def test_battery_threshold_and_hysteresis_policy(self):
        band_file = self.runtime_dir / "power-actions" / "band"

        # 1. On battery, cap=39% (< 40%) -> switch to power-saver, band saver
        self.set_battery(capacity=39, ac=False)
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertTrue(band_file.exists())
        self.assertEqual(band_file.read_text().strip(), "saver")
        self.assertEqual((self.state_dir / "profile").read_text().strip(), "power-saver")
        self.assertTrue(any("tlpctl set power-saver" in c for c in self.calls()))

        # 2. Repeated run with battery in saver band (cap=35%) is edge-triggered idempotent
        self.clear_calls()
        self.set_battery(capacity=35, ac=False)
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(band_file.read_text().strip(), "saver")
        # Should NOT call tlpctl set again
        self.assertFalse(any("tlpctl set" in c for c in self.calls()))

        # 3. Battery at 50% on battery -> hysteresis neutral, band neutral, does not switch profile
        self.clear_calls()
        self.set_battery(capacity=50, ac=False)
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(band_file.read_text().strip(), "neutral")
        self.assertFalse(any("tlpctl set" in c for c in self.calls()))

        # 4. Plugged in, cap=59% (< 60%) -> neutral, does not switch to balanced
        self.clear_calls()
        self.set_battery(capacity=59, ac=True)
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(band_file.read_text().strip(), "neutral")
        self.assertFalse(any("tlpctl set" in c for c in self.calls()))

        # 5. Plugged in, cap=60% (>= 60%) -> switch to balanced, band balanced
        self.clear_calls()
        self.set_battery(capacity=60, ac=True)
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(band_file.read_text().strip(), "balanced")
        self.assertEqual((self.state_dir / "profile").read_text().strip(), "balanced")
        self.assertTrue(any("tlpctl set balanced" in c for c in self.calls()))

        # 6. Exact boundary on battery: cap=40% is not < 40%, so neutral
        self.clear_calls()
        self.set_battery(capacity=40, ac=False)
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(band_file.read_text().strip(), "neutral")
        self.assertFalse(any("tlpctl set" in c for c in self.calls()))

        # 7. No battery (e.g. desktop): logs message and does not switch profile
        shutil.rmtree(self.sysfs)
        self.sysfs.mkdir()
        self.clear_calls()
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertIn("探测不到电池", res.stdout)
        self.assertFalse(any("tlpctl set" in c for c in self.calls()))

    def test_polkit_and_external_failure_preserves_state(self):
        band_file = self.runtime_dir / "power-actions" / "band"
        state_file = self.runtime_dir / "power-actions" / "state"

        # 1. tlpctl set failure does NOT advance band_file
        self.set_battery(capacity=35, ac=False)
        res = self.run_cmd("run", TLPCTL_FAIL="1")
        self.assertEqual(res.returncode, 0)
        self.assertFalse(band_file.exists())  # band not advanced
        self.assertIn("tlpctl set power-saver 失败", res.stderr)

        # Next run without failure succeeds and writes band
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(band_file.read_text().strip(), "saver")

        # 2. Failure during session_leave retains failed items in state_file for retry
        # First ensure we are in power-saver with recorded kw and unit in state_file
        self.run_cmd("mode", "power-saver")
        self.assertTrue(state_file.exists())
        self.assertIn("unit:onedrive=stopped", state_file.read_text())

        # Now switch to balanced with systemctl start failure
        res = self.run_cmd("mode", "balanced", SYSTEMCTL_START_FAIL="1")
        self.assertEqual(res.returncode, 0)
        # onedrive start failed, so unit:onedrive=stopped must remain in state_file
        self.assertTrue(state_file.exists())
        self.assertIn("unit:onedrive=stopped", state_file.read_text())

        # Subsequent run retries starting onedrive
        self.clear_calls()
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        self.assertTrue(any("start onedrive" in c for c in self.calls()))
        self.assertNotIn("unit:onedrive", state_file.read_text() if state_file.exists() else "")

    def test_session_enter_and_leave_semantics(self):
        state_file = self.runtime_dir / "power-actions" / "state"

        # In balanced: darkman light, unit onedrive active
        self.run_cmd("mode", "power-saver")
        self.assertEqual((self.state_dir / "darkman").read_text().strip(), "dark")
        self.assertNotIn("onedrive", (self.state_dir / "units_active").read_text().splitlines())
        state_content = state_file.read_text()
        self.assertIn("unit:onedrive=stopped", state_content)
        self.assertIn("kw:decoration:blur:passes=int:4", state_content)
        self.assertIn("kw:decoration:active_opacity=float:0.88", state_content)

        # Switch back to balanced:
        # darkman must NOT be changed back ("darkman 按设计不动")
        self.clear_calls()
        self.run_cmd("mode", "balanced")
        self.assertEqual((self.state_dir / "darkman").read_text().strip(), "dark")
        self.assertFalse(any("darkman set" in c for c in self.calls()))
        self.assertIn("onedrive", (self.state_dir / "units_active").read_text().splitlines())

    def test_revert_semantics_and_session_pause(self):
        state_file = self.runtime_dir / "power-actions" / "state"

        # Enter power-saver
        self.run_cmd("mode", "power-saver")
        self.assertIn("unit:onedrive=stopped", state_file.read_text())

        # Revert restores units/effects and marks session=paused
        self.clear_calls()
        res = self.run_cmd("revert")
        self.assertEqual(res.returncode, 0)
        self.assertIn("已恢复：Hyprland 特效与用户单元", res.stdout)
        self.assertIn("onedrive", (self.state_dir / "units_active").read_text().splitlines())
        self.assertIn("session=paused", state_file.read_text())

        # 30s timer (run) while still in power-saver profile must respect paused session
        self.clear_calls()
        self.set_battery(capacity=30, ac=False)
        (self.runtime_dir / "power-actions" / "band").write_text("saver\n")
        res = self.run_cmd("run")
        self.assertEqual(res.returncode, 0)
        # Unit should NOT be stopped again!
        self.assertIn("onedrive", (self.state_dir / "units_active").read_text().splitlines())

        # Explicit mode unpauses session
        res = self.run_cmd("mode", "power-saver")
        self.assertEqual(res.returncode, 0)
        self.assertNotIn("session=paused", state_file.read_text())
        self.assertNotIn("onedrive", (self.state_dir / "units_active").read_text().splitlines())

    def test_desktop_branch_niri_or_missing_hyprland(self):
        # Remove Hyprland socket to simulate niri or non-Hyprland session
        shutil.rmtree(self.runtime_dir / "hypr")

        # Command must succeed without error
        res = self.run_cmd("mode", "power-saver")
        self.assertEqual(res.returncode, 0)
        self.assertEqual((self.state_dir / "darkman").read_text().strip(), "dark")
        self.assertNotIn("onedrive", (self.state_dir / "units_active").read_text().splitlines())

        # Status displays Hyprland as skipped
        res = self.run_cmd("status")
        self.assertEqual(res.returncode, 0)
        self.assertIn("Hyprland   : 无运行实例", res.stdout)


if __name__ == "__main__":
    unittest.main()
