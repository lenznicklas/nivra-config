# Nivra config

Arch Linux desktop rice copied from `.config`: Fortress Quickshell (bar,
launcher, overview, audio, notes and settings), Hyprland, Hyprpaper, Hyprlock,
Hypridle, Kitty, Fastfetch, wallpaper, GTK 3/4, Qt 5/6, Kvantum and portal settings.
Includes Strata CSS required by the GTK theme. Old archives, caches, personal
notes, application profiles and file-manager session history are excluded.

```sh
./install.sh --dry-run
./install.sh
```

Run as your normal desktop user. The installer copies bundled files to
`~/.config`, adjusts `/home/lenz` references for the installing user and preserves
unrelated files. Existing files are backed up under
`~/.config/nivra-backups/<timestamp>/`, with their relative paths intact.
To restore a file, copy it from that backup to its original location. Files that
were newly installed have no backup; remove those separately to undo them.
Installation uses copies so the shell's settings/theme helpers can edit them.
Existing symlinked config subdirectories are backed up and replaced with real
directories. Their contents are copied first to preserve unrelated files; the
original linked directories are left untouched. File/dangling-link conflicts in
parent paths are backed up too. The `.config` root itself must be a real directory.
The configs expect `~/.config`; custom `XDG_CONFIG_HOME` locations are unsupported.

## Dependencies

Install dependencies yourself before starting the desktop. This script only
installs configuration, and does not change packages, services or your shell.
A starting Arch package command is:

```sh
sudo pacman -S --needed hyprland quickshell hyprpaper hyprlock hypridle \
  kitty fastfetch python qt6-declarative qt6-svg qt5ct qt6ct kvantum \
  gtk3 gtk4 adwaita-icon-theme ttf-jetbrains-mono-nerd \
  pipewire pipewire-pulse wireplumber libpulse upower power-profiles-daemon \
  brightnessctl grim slurp wl-clipboard playerctl rofi firefox \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  gsettings-desktop-schemas
```

**The copied Hyprland configuration uses `hyprland.lua` and the `hl` API.**
Your Hyprland build must support that API; older builds that only load
`hyprland.conf` cannot use this config directly. Package availability and API
compatibility depend on your repositories. No compositor conversion is performed.

The optional Super+B binding launches `zen-browser`; install it separately or
change that binding. Strata itself is optional; only its theme assets are bundled.
Enable the appropriate audio, UPower and power-profile services for your system.
Hypridle's config is included, but the copied startup does not launch Hypridle;
start it through your preferred session/service setup if wanted.

Log out and start Hyprland after installing. The layout uses a German keyboard
(`de`) and the saved GUI scale. Review `config/hypr/hyprland.lua` and
`config/hypr/modules/binds.lua` for machine-specific changes.

| Shortcut | Action |
| --- | --- |
| Super+Return | Kitty |
| Super+F | Firefox |
| Super+Space | Launcher |
| Super+Tab | Overview |
| Super+N | Notes |
| Super+W | Sync theme |
| Super+Q | Close window |
| Super+1…9 | Switch workspace |
| Super+Shift+1…9 | Move window to workspace |
| Print | Copy screenshot selection |

`config/hypr/scripts/avatar.png` is the copied lockscreen avatar; replace it
before sharing if you prefer a different image. Quickshell's original component
README files are kept alongside the config.
