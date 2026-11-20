#!/usr/bin/env python3
"""Print a private flake source directory, without staging or invoking Nix."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def git_files(*args):
    data = subprocess.check_output(['git', '--literal-pathspecs', 'ls-files', '-z', *args])
    return {Path(os.fsdecode(p)) for p in data.split(b'\0') if p}


def candidate(extras):
    root = Path.cwd()
    if subprocess.check_output(['git', 'rev-parse', '--show-prefix']) != b'\n':
        raise ValueError('run from the worktree root')
    tracked = git_files('--cached')
    for path in extras:
        if path.is_absolute() or '..' in path.parts or '.git' in path.parts or not path.is_file():
            raise ValueError(f'expected a repository-relative file: {path}')
        if git_files('--others', '--exclude-standard', '--', path) != {path}:
            raise ValueError(f'not a non-ignored untracked file: {path}')

    # Never walk a source directory. A former tracked file can now be a
    # directory, or a tracked parent can have become a link outside the repo.
    files = []
    for path in sorted(tracked | set(extras)):
        source = root / path
        if source.resolve() != source:
            raise ValueError(f'refusing symlink or symlinked parent: {path}')
        if path in tracked and not source.exists():
            continue  # unstaged deletion
        if not source.is_file():
            raise ValueError(f'not a regular file: {path}')
        files.append(path)

    tmp = Path(tempfile.gettempdir()).resolve()
    if tmp.is_relative_to(root):
        raise ValueError('TMPDIR must be outside the worktree')
    dest = Path(tempfile.mkdtemp(prefix='flake-candidate.', dir=tmp))
    try:
        for path in files:
            target = dest / path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(root / path, target, follow_symlinks=False)
    except BaseException:
        shutil.rmtree(dest)
        raise
    return dest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files', type=Path, nargs='*', help='reviewed untracked files to include')
    try:
        print(candidate(parser.parse_args().files))
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f'flake-candidate: {exc}\n')
