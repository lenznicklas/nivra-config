# Wallpaper and shared palette

Wallpaper: `~/.config/wallpaper.jpg` (keep this file in place).
Hyprpaper uses it on all outputs, with `cover` fitting.

Palette source: `~/.config/quickshell/fortress/modules/Theme.qml`.
Colors were derived from the wallpaper's plum sky and orange/peach sunset:

- Background: #180c1d (existing 72% / 90% panel alpha retained).
- Text: #f8e1d0.
- Accent / active window border: #f5895c.
- Soft accent: #f7b98f.
- Danger: #e25549.

Launcher and notes now derive their translucent colors from Theme.qml.
Fonts, spacing, rounding and border thickness are unchanged.
Palette.qml is unused by the active shell and is left untouched.

After editing Theme.qml, press Super+W, or run:

```sh
python3 ~/.config/hypr/sync-theme.py --apply
```

This synchronizes Hyprland borders, hyprlock and Strata, reloads Hyprland,
and applies wallpaper through the installed hyprpaper wallpaper IPC command.
Quickshell watches QML changes. Close and reopen Strata to load its new palette.
If hyprpaper isn't running, start `hyprpaper` first; its saved config already
points at the new wallpaper.

The pre-change files are saved in `theme-backup-20261020-002351.zip`, with
paths relative to ~/.config. To restore them:

```sh
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile
config = Path.home() / '.config'
with ZipFile(config / 'hypr/theme-backup-20261020-002351.zip') as backup:
    backup.extractall(config)
PY
hyprctl reload
```

Restart hyprpaper and Strata after restoring. The sync helper and this README
can be removed afterward. Do not run the sync helper after restoring unless
you want to regenerate the palette files.
