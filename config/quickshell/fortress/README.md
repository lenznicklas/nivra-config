# Fortress for Hyprland

Run with `quickshell -n -c fortress`. Hyprland already starts this shell
from `~/.config/hypr/hyprland.lua`.

- Super+Space: toggle launcher.
- Super+N: toggle notes.
- Click a workspace dot to switch workspaces.
- Click the lock button to run hyprlock.

Dependencies: Quickshell with Hyprland support, hyprlock, UPower,
and JetBrainsMono Nerd Font.

## Reload

Reload Hyprland from a terminal inside the running Hyprland session:

```sh
hyprctl reload
hyprctl configerrors
```

Quickshell automatically reloads edited QML files. If Fortress is not running:

```sh
quickshell -n -d -c fortress
```

To restart only Fortress manually:

```sh
quickshell kill -c fortress
quickshell -n -d -c fortress
```

Reloading Hyprland does not rerun its startup callback, so start Fortress
manually if needed. No reboot or Arch-wide reload is required.

Optional IPC commands:

```sh
quickshell ipc -c fortress call fortress launcherToggle
quickshell ipc -c fortress call fortress notesToggle
```

README-SWAY.md and sway-snippet.conf describe the previous Sway setup only;
do not apply them to Hyprland.

## Menu bar and Control Center

The sunset menu bar includes numbered workspaces, active window title,
launcher and notes shortcuts, battery, live volume, a muted-microphone indicator,
and date/time. Secondary items collapse on narrower displays.

- Click sound or the clock to open Control Center.
- Scroll over sound to adjust volume in 5% steps (capped at 100%).
- Use the sound slider or speaker/microphone mute buttons in Control Center.
- Display brightness appears when `brightnessctl` can access a backlight.
- Audio opens `pavucontrol` for device selection and per-application volumes.
- Playback controls appear for MPRIS-compatible players; unsupported actions
  are disabled. The currently playing player takes priority.
- Click outside, press Escape, or use × to dismiss Control Center.
- Bar launcher and notes buttons open on the display where they were clicked.

Audio uses Quickshell's native PipeWire service. Its object tracker keeps volume
and mute state current, including changes from the keyboard or another mixer.
Brightness is queried only while Control Center is open. The existing font,
wallpaper palette and 3px window-matching border remain in use.

The previous shell and modules are backed up in
`bar-backup-20261020-002949.zip`, with paths relative to this directory.
To restore the previous bar, close Fortress and extract that archive here;
the three new Control*.qml files can then be deleted. No Hyprland settings
were changed for this bar update.

Validation: new controls and the complete Control Center instantiated in an
offscreen Quickshell 0.3.2 check. Live display, PipeWire, and session D-Bus were
unavailable in the editing environment, so hardware interactions and popup
placement still need checking in the desktop session.

## Spotlight-style launcher

Super+Space or the bar's launcher button opens the centered launcher.
It displays installed app icons, descriptions and quick-start suggestions before
you type. Recently launched apps are prioritized for the current shell session;
no history file is written. Search prioritizes exact names and prefixes, then
keywords and abbreviations (for example `ffx` for Firefox).

Use Up/Down or Tab/Shift+Tab to select, Enter to launch, and Escape or an outside
click to dismiss. Missing icons fall back to the app's initial. The result count
adapts to the screen height. Existing hidden-app exclusions remain in effect.
The original launcher is saved beside Launcher.qml with a `.backup-*` suffix.

## Battery and power modes

Control Center displays battery charge and Performance, Balanced, and Power Saver
choices through the installed `powerprofilesctl`. The active choice is highlighted;
unsupported modes are disabled. Changes are re-read from the service after setting,
and failures are reported instead of displaying a false successful selection.
The service is queried on opening and every four seconds while the panel is open.
The separate settings icon was removed from the bar. Long Control Center contents
scroll to fit smaller displays.

## Settings app

Open Control Center by clicking sound or the clock, then select **Open Settings**.
The app opens on that monitor as a centered overlay above desktop windows,
with a dimmed backdrop. It does not create a regular tiled Hyprland window.
Escape, ×, or a click outside closes it.

Pages:

- Appearance: show/hide window title, battery and date; compact/roomier menu bar.
- Sound: live output volume, speaker mute, microphone mute, advanced audio link.
- Display: immediate backlight control and current shared palette information.
- Power: battery charge and supported performance/balanced/power-saver modes.

Appearance preferences apply immediately and are saved atomically to
`preferences.json`. Hardware settings are managed by the existing desktop
services and shared with Control Center. The existing wallpaper/theme source
is not overwritten by the settings app. **Reset bar preferences** restores
only the bar appearance choices.

Optional terminal commands:

```sh
quickshell ipc -c fortress call fortress settingsShow
quickshell ipc -c fortress call fortress settingsHide
```

Before adding Settings, the modified existing shell files were backed up in
`settings-backup-20261020-010350.zip`. New components are DesktopSettings.qml,
SettingToggle.qml and ShellPreferences.qml, registered in modules/qmldir.

### Bar position

Settings → Appearance → Bar position offers Top, Bottom, Left and Right.
The choice applies immediately to every monitor and is saved as `barPosition`
in preferences.json. Existing preferences without this field default to Top.
Left/right use a vertical rail with stacked workspaces, compact battery status,
and a two-line clock. Control Center opens inward from the chosen edge, and
Hyprland reserves the correct edge for the bar. Reset restores Top.

The four layouts were checked in an offscreen Qt scene; live compositor anchor
placement still needs desktop-session verification.

### GUI scale

Settings → Appearance → GUI scale now sets Hyprland's monitor scale for the
whole desktop, including native application windows and Quickshell. Quickshell
keeps its additional UI multiplier at 1.0 to avoid double scaling.

The helper `~/.config/hypr/apply-gui-scale.py` checks the connected resolutions,
writes `~/.config/hypr/modules/gui-scale.lua`, reloads Hyprland and checks the
actual scale before confirming the choice. Unsupported scales show an error;
failed changes restore the previous monitor configuration. The existing
preferred mode and automatic monitor placement rule is preserved. Both the
module and preferences.json retain the confirmed value across restarts.

Hover tooltips are disabled on left/right bars. Top/bottom bar tooltips and
Control Center/Settings tooltips remain available.

175% is allowed even when it produces fractional logical pixels. Hyprland's
`debug.disable_scale_checks` is enabled only while that exact preset is active;
all other presets retain normal scale validation. This permits exact 175%
instead of silently substituting another scale, with possible pixel-rounding
differences. Applying and rolling back are still verified through monitor state.


### Workspace overview

Super+Tab toggles the Fortress overview on the focused monitor. It is exclusively
workspace navigation: click anywhere on a workspace card (including a window
preview), or press an unmodified number 1–9 to switch and close. Escape or a
background click closes without switching. Empty workspaces 1–9 stay visible;
existing workspaces above 9 remain clickable. The current workspace retains
its accent border while other cards can be hovered.

Window previews remain live and purely visual. There are no window-focus,
drag, drop, move, resize or reorder actions in the overview. The full-screen
surface consumes clicks, including during its short closing animation.
Number keys are handled locally by the focused overview, with no global
unmodified number bindings. The existing theme, wallpaper, screencopy and
native Hyprland integration are retained.

Files: modules/Overview.qml, modules/qmldir, shell.qml, and
~/.config/hypr/modules/binds.lua. The existing Super+Tab binding is unchanged.

Navigation validation: offscreen Qt input checks with a mocked Hyprland service
cover toggle, unmodified 1/9, empty workspace 7, card/preview clicks, Escape,
cancelled card/preview drags, background close, the closed-view dispatch guard,
Lua/legacy dispatch, current-workspace marking and preview model updates.
The temporary test uses FloatingWindow in place of PanelWindow because this
environment cannot connect to Wayland. Real Super+Tab delivery, live capture,
keys reaching other apps after close, and compositor-level click blocking
still require verification in the desktop session. Quickshell automatically
reloads the edited overview; no new Hyprland binding is required.
