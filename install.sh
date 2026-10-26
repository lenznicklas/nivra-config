#!/usr/bin/env bash
set -euo pipefail
# Copies only bundled files; unrelated files in ~/.config are preserved.
case "${1:-}" in
  -h|--help)
    printf 'Usage: %s [--dry-run]\nInstalls into ~/.config; backs up replaced files inside ~/.config/nivra-backups.\nRequires Python 3. Run as your desktop user.\n' "$0"
    exit 0 ;;
  ''|--dry-run) ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { printf 'Too many arguments\n' >&2; exit 2; }
command -v python3 >/dev/null || { printf 'Install python first.\n' >&2; exit 1; }
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 - "$script_dir/config" "${1:-}" <<'PY'
from pathlib import Path
from datetime import datetime
import os
import shutil
import sys

source = Path(sys.argv[1]).resolve()
target = Path.home() / '.config'
dry = sys.argv[2] == '--dry-run'
backup = target / 'nivra-backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
files = sorted(p for p in source.rglob('*') if p.is_file())
if not files:
    raise SystemExit('No bundled config files found.')
# Preflight all paths before modifying anything; never follow existing symlinks.
for path in files:
    rel = path.relative_to(source)
    dest = target / rel
    for parent in [target, *[target / p for p in rel.parents if str(p) != '.']]:
        if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
            raise SystemExit(f'Config parent must be a real directory: {parent}')
    if dest.is_dir() and not dest.is_symlink():
        raise SystemExit(f'Expected a file, found a directory: {dest}')
for path in files:
    rel = path.relative_to(source)
    dest = target / rel
    print(f'{"Would install" if dry else "Installing"}: {rel}')
    if dry:
        continue
    if dest.exists() or dest.is_symlink():
        saved = backup / rel
        saved.parent.mkdir(parents=True, exist_ok=True)
        if dest.is_symlink():
            saved.symlink_to(os.readlink(dest))
        else:
            shutil.copy2(dest, saved)
        dest.unlink()
    dest.parent.mkdir(parents=True, exist_ok=True)
    data = path.read_bytes()
    try:
        # Configs and helpers currently expect ~/.config (not XDG_CONFIG_HOME).
        data = data.decode('utf-8').replace('/home/lenz', str(Path.home())).encode('utf-8')
    except UnicodeDecodeError:
        pass
    dest.write_bytes(data)
    shutil.copymode(path, dest)
if not dry:
    if backup.exists():
        print(f'Original files backed up in: {backup}')
    print('Installed. Log out and start your Hyprland session to apply.')
PY
