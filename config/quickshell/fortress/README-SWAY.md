# Fortress for Sway

This version was converted from the Hyprland configuration to Sway.

## Changes

- `Quickshell.Hyprland` workspaces -> `Quickshell.I3` (supports Sway IPC)
- workspace switching uses `I3Workspace.activate()`
- Hyprland-only `GlobalShortcut` -> `IpcHandler`
- Hyprland-only `HyprlandFocusGrab` removed
- `hyprlock` -> `swaylock`
- bar top margin reduced from 8 px to 2 px
- bar exclusive zone corrected to match bar height + top margin

## Install

Copy this directory to:

```text
~/.config/quickshell/fortress-sway/
```

Then add the contents of `sway-snippet.conf` to your Sway config and reload Sway:

```sh
swaymsg reload
```

You can also test Fortress manually with:

```sh
qs -c fortress-sway
```

IPC commands used by the Sway keybindings:

```sh
qs ipc call fortress launcherToggle
qs ipc call fortress notesToggle
```

Dependencies used by this config include Quickshell, Sway, swaylock, UPower and a Nerd Font (the theme currently uses `JetBrainsMono Nerd Font`).
