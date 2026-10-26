# Fortress lockscreen

`python3 ~/.config/hypr/scripts/lockscreen.py` starts the existing hyprlock/PAM
locker. Hypridle and the Quickshell lock button use this entry point. Idle
intervals, sleep hooks, and PAM configuration are unchanged. Direct `hyprlock`
remains functional using the defaults in `hyprlock.conf`.

The starter creates a private temporary configuration, chooses the focused
monitor, reads hyprpaper's active wallpaper (falling back to hyprpaper.conf),
and selects ~/.face, ~/.face.icon, or the AccountsService icon when present.
Without a profile picture, the included sunset monogram is used. Smaller logical
displays receive smaller type. IPC failure falls back to a visible login on all
outputs. The selected output is fixed for one lock session; output hotplug during
locking has not been verified.

The palette follows Quickshell Theme.qml through the existing sync-theme.py.
Semantic color comments must be retained. No theme sync is run by the locker.
The glass field uses translucency over the blurred wallpaper; no additional
per-widget blur pass is needed. hyprlock provides its own verification/error
colors and fast fade-out. It displays the small failure text inside the field;
there is no custom authentication, artificial success delay, or shake hack.
Caps Lock changes the field outline to the soft accent.

Media updates every five seconds through existing playerctl/MPRIS. Only a
playing player is shown. Local file:// album covers are supported; remote
covers are not downloaded. Missing covers remain transparent. Status updates
every fifteen seconds using existing nmcli, bluetoothctl, and sysfs batteries.
There are no background helper daemons. No weather source was found in the
current Rice. Power actions and media controls are intentionally omitted.

Validation: hyprlock 0.9.6 parses both the base and prepared configs before a
connection attempt to an intentionally nonexistent Wayland display. No config
errors were reported. A real visual/PAM unlock test needs the active session;
the editing environment cannot connect to its Hyprland IPC socket. Do not use
`--grace` for testing.
