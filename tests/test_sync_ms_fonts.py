import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "home/theme/sync-ms-fonts.sh"


class FontSyncTest(unittest.TestCase):
    def test_sync_and_safe_guards(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "source"
            target = root / "target"
            source.mkdir()
            (source / "nested").mkdir()
            font = source / "nested/A.ttf"
            font.write_bytes(b"first")
            (source / "B.TTC").write_bytes(b"second")
            cache_log = root / "cache-log"
            cache = root / "fc-cache"
            cache.write_text(f"#!/bin/sh\nprintf 'refresh\\n' >> '{cache_log}'\n")
            cache.chmod(0o755)

            def sync(expected=0):
                result = subprocess.run(["bash", str(SCRIPT), str(source), str(target), str(cache)], capture_output=True, text=True)
                self.assertEqual(result.returncode, expected, result.stderr)

            def refreshes():
                return len(cache_log.read_text().splitlines()) if cache_log.exists() else 0

            sync()
            self.assertEqual((target / "A.ttf").read_bytes(), b"first")
            self.assertEqual(refreshes(), 1)
            sync()
            self.assertEqual(refreshes(), 1)
            # Same size and timestamp must still be detected by checksum.
            stat = font.stat()
            font.write_bytes(b"other")
            os.utime(font, ns=(stat.st_atime_ns, stat.st_mtime_ns))
            sync()
            self.assertEqual((target / "A.ttf").read_bytes(), b"other")
            self.assertEqual(refreshes(), 2)
            (source / "B.TTC").unlink()
            sync()
            self.assertFalse((target / "B.TTC").exists())
            self.assertEqual(refreshes(), 3)
            (source / "A.ttf").write_bytes(b"collision")
            sync(1)
            self.assertEqual((target / "A.ttf").read_bytes(), b"other")
            (source / "A.ttf").unlink()
            font.unlink()
            sync()
            self.assertEqual((target / "A.ttf").read_bytes(), b"other")
            source.rename(root / "missing")
            sync()
            self.assertEqual((target / "A.ttf").read_bytes(), b"other")
            self.assertEqual(refreshes(), 3)

    def test_failed_cache_is_retried_without_font_changes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, target, cache = root / "source", root / "target", root / "cache"
            source.mkdir()
            (source / "A.ttf").write_bytes(b"font")
            cache.write_text("#!/bin/sh\nexit 1\n")
            cache.chmod(0o755)
            command = ["bash", str(SCRIPT), str(source), str(target), str(cache)]
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertTrue(Path(str(target) + ".cache-pending").exists())
            cache.write_text("#!/bin/sh\nexit 0\n")
            self.assertEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertFalse(Path(str(target) + ".cache-pending").exists())


if __name__ == "__main__":
    unittest.main()
