# Fortress Audio

The bar sound chip opens the native audio panel. Scroll adjusts output by 5%,
middle click toggles output mute, right click opens Settings → Sound. The clock
still opens the existing Control Center, whose Audio button opens Settings → Sound.
Escape and outside clicks close it; the full-screen overlay consumes outside
clicks. Empty card space also consumes clicks. The card follows all four bar
positions and scrolls internally when necessary.

All colors, typography and geometry come from Theme.qml. Existing ControlSlider,
ChipButton and SettingToggle components are reused. There is no second palette.

## Architecture

- `modules/AudioService.qml`: one native PipeWire connection/model through
  Quickshell, tracked nodes, defaults, volume/mute, device selection and routing.
- `modules/AudioPanel.qml`: compact master/microphone popup with a Settings link.
- `modules/AudioSettingsPage.qml`: full mixer embedded in Desktop Settings → Sound.
- `modules/AudioNodeControl.qml`: device/stream volume, mute, optional routing
  and native peak monitor.
- `modules/AudioDeviceList.qml`: outputs, inputs and per-stream destinations.
- `scripts/audio-route.py`: on-demand pactl routing only, using PipeWire serials
  to resolve Pulse indexes. Native PipeWire streams not exposed through Pulse
  cannot be moved by this helper; failures leave audio untouched and show an
  error. No shell interpolation or background subprocess loops.
- `ControlState.qml` delegates its existing audio interface to AudioService;
  brightness, power profiles, media controls and other settings are preserved.
- Integration changes: `Bar.qml`, `ControlCenter.qml`, `ChipButton.qml`,
  `ControlSlider.qml`, `DesktopSettings.qml`, `qmldir`.

Native API reference:
https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Pipewire/PwNode/

Default switching writes Pipewire.preferredDefaultAudioSink/Source. WirePlumber
owns policy and migration of streams; streams explicitly pinned to a device may
need routing through the expanded mixer. Devices appear when their audio nodes
exist, including connected Bluetooth devices. This is not a Bluetooth manager.

Each live playback node has an independent volume/mute row. Multiple streams
from one application remain separate, rather than pretending one volume can
control all streams. Disappearing nodes remove their rows. Settings → Sound also
shows recording streams and allows playback/recording routing.

Volume changes preserve mute. Normal sliders and upward scrolling cap at 100%.
Existing volume above 100% remains visible; downward scrolling can reduce it
gradually. Settings → Sound offers explicit amplification to 150%, reset when leaving the Sound page
(the audio volume itself is never reset by closing the panel).

Output metering runs only while the panel is open. Microphone metering is
opt-in and stops on close. No audio polling. No service configuration changes,
package installation or audio daemon restarts. Hardware keys still use wpctl,
so they work independently if the shell is unavailable; native signals update
the panel after those changes. pavucontrol remains installed and available
from Settings → Sound.

Profiles (A2DP/HFP), channel balance and a separate volume OSD are deliberately
left to existing tools / future work. The fallback covers unsupported routing
and profiles. Search was not added to the compact mixer.

## Verification performed

- Installed Quickshell 0.3.2 QML type metadata checked for all used native APIs.
- Installed: wpctl, pactl, pw-cli, pw-dump, pavucontrol; PipeWire/Pulse sockets
  present. systemctl --user status pipewire pipewire-pulse wireplumber could
  not connect to the session bus inside the sandbox, so service health was not
  independently confirmed.
- QML lint: no new syntax/type failures; tooling warnings for Quickshell's
  dynamically provided PanelWindow backend / opaque ObjectModel.values remain.
- Offscreen component smoke test with unavailable native audio: loaded,
  expanded view opened/closed without a QML error. Only the test copy used a
  FloatingWindow because the sandbox cannot instantiate a Wayland backend.
- Rendered expanded UI with mock output, input and playback stream: inspected
  spacing, theme, long stream names, mute indicator and scroll clipping.
- Routing helper: playback/recording commands, ID matching, mismatched serial
  rejection verified using mocked pactl results. No live stream was moved.
- Running Fortress log confirmed successful configuration reload after edits.

## Desktop acceptance tests (still require the real session)

1. Click the sound chip; test scrolling +/-5%, middle mute/unmute, right-click
   Settings → Sound, gear link, Escape, outside click, and clicking card padding.
   An outside click must close the panel without activating the window below.
2. Adjust master volume and mute; change volume with hardware keys or
   `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-` and confirm immediate UI updates.
3. Select another output and switch back. Check existing playback follows
   WirePlumber policy. Adjust input volume/mute and select another microphone.
4. Play Firefox and another application together: change/mute each row
   independently. Stop/close a stream and confirm removal; start another and
   confirm its row appears. Paused applications may keep their stream alive.
5. In Settings → Sound, choose a stream destination and verify routing. Check
   recording-app rows during an actual recording/call.
6. Connect/disconnect USB/Bluetooth audio and verify devices update. Profile
   changes remain in pavucontrol. Verify the default devices after unplugging.
7. Check output meter; enable mic meter deliberately; close the panel and
   confirm capture/monitoring stops. Test internal scrolling with many streams
   and each bar edge you use, plus a second monitor if available.
8. Open the pavucontrol fallback. Confirm hardware keys still work when
   Quickshell is not running. Do not stop the audio services merely to test UI.

Pre-change Fortress backup for this session: `/tmp/fortress-before-audio.zip`.

## Settings integration

The detailed mixer now lives inside the existing Settings app's Sound page,
using its fixed header/sidebar and scrolling content. The bar popup contains
only master/microphone quick controls. Its gear button, the sound chip's right
click, and the Control Center's Audio action open Settings directly on Sound.
Devices, application volume/mute, recording streams, routing, amplification,
meters and pavucontrol fallback are all in that page. Leaving Sound or closing
Settings stops metering and resets the amplification permission, not volume.
