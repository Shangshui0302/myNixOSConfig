"""Exercise the real packaged deploy helper using an isolated destination."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class ShellSyncTest(unittest.TestCase):
    def test_deploy_skip_upgrade_and_repair(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "kos"
            command = [os.environ["KOS_SYNC_SCRIPT"], str(destination)]
            environment = dict(os.environ, KOS_SYNC_FORCE="0")

            def deploy(force=False):
                result = subprocess.run(command, env=dict(environment, KOS_SYNC_FORCE=str(int(force))),
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)

            deploy()
            shell = destination / "shell.qml"
            original = shell.read_bytes()
            self.assertTrue((destination / "Kos/Spatial3D").is_dir())
            marker = destination / ".nix-shell-source"
            generation = marker.read_text()
            before = shell.stat().st_mtime_ns
            deploy()
            self.assertEqual(shell.stat().st_mtime_ns, before)

            shell.write_bytes(b"// temporary local edit\n")
            deploy()
            self.assertEqual(shell.read_bytes(), b"// temporary local edit\n")
            deploy(force=True)
            self.assertEqual(shell.read_bytes(), original)

            # A generation change (including rollback) replaces stale content.
            shell.write_bytes(b"// obsolete generation\n")
            marker.write_text("/nix/store/previous-generation\n")
            deploy()
            self.assertEqual(shell.read_bytes(), original)
            self.assertEqual(marker.read_text(), generation)

            shell.unlink()
            deploy()
            self.assertEqual(shell.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
