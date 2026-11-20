import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/flake-candidate.py'


class CandidateTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.base = Path(temp.name)
        self.root = self.base / 'repo'
        self.root.mkdir()
        subprocess.run(['git', 'init', '-q'], cwd=self.root, check=True)
        for name in ('tracked', 'deleted'):
            (self.root / name).write_text('index version')
        (self.root / '.gitignore').write_text('memory/\n.agent-teams/\n')
        subprocess.run(['git', 'add', '.gitignore', 'tracked', 'deleted'], cwd=self.root, check=True)
        (self.root / 'tracked').write_text('working version')
        (self.root / 'deleted').unlink()
        for name in ('memory/marker', '.agent-teams/marker', 'scratch', 'src/new file'):
            p = self.root / name
            p.parent.mkdir(exist_ok=True)
            p.write_text('synthetic')
        (self.root / 'src/new file').chmod(0o755)

    def run_tool(self, *args):
        return subprocess.run([sys.executable, SCRIPT, *args], cwd=self.root,
                              env={**os.environ, 'TMPDIR': str(self.base)},
                              text=True, capture_output=True)

    def test_only_selected_worktree_files(self):
        index = self.root / '.git/index'
        before = index.read_bytes()
        result = self.run_tool('src/new file')
        self.assertEqual(result.returncode, 0, result.stderr)
        dest = Path(result.stdout.strip())
        self.assertEqual({str(p.relative_to(dest)) for p in dest.rglob('*')},
                         {'.gitignore', 'tracked', 'src', 'src/new file'})
        self.assertEqual((dest / 'tracked').read_text(), 'working version')
        self.assertTrue(os.access(dest / 'src/new file', os.X_OK))
        self.assertEqual(index.read_bytes(), before)

    def test_refuses_ignored_external_and_directory_args(self):
        (self.base / 'outside').write_text('synthetic')
        (self.root / 'link').symlink_to(self.base / 'outside')
        for arg in ('memory/marker', '../outside', self.base / 'outside', 'link', 'src', '.git/index'):
            with self.subTest(arg=arg):
                result = self.run_tool(str(arg))
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, '')

    def test_refuses_replaced_tracked_parent(self):
        subprocess.run(['git', 'add', 'src/new file'], cwd=self.root, check=True)
        (self.root / 'src').rename(self.base / 'elsewhere')
        (self.root / 'src').symlink_to(self.base / 'elsewhere', target_is_directory=True)
        self.assertNotEqual(self.run_tool().returncode, 0)


if __name__ == '__main__':
    unittest.main()
