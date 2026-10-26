import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: state
  readonly property alias audio: audioService
  AudioService { id: audioService }
  // Compatibility for existing settings and control-center components.
  readonly property var sink: audio.sink
  readonly property var source: audio.source
  readonly property bool audioReady: audio.audioReady
  readonly property bool micReady: audio.micReady
  readonly property real volume: audio.volume
  readonly property bool muted: audio.muted
  readonly property bool micMuted: audio.micMuted
  readonly property string volumeIcon: audio.volumeIcon
  property real brightness: -1
  property real pendingBrightness: 0
  property real sentBrightness: 0
  property int brightnessRevision: 0
  property var powerProfiles: []
  property string powerProfile: ""
  property string requestedProfile: ""
  property string powerError: ""
  readonly property bool powerBusy: profileSet.running

  function setVolume(value) { audio.setVolume(value); }
  function toggleMute() { audio.toggleMute(); }
  function toggleMic() { audio.toggleMic(); }
  function setBrightness(value) {
    const next = Math.max(1, Math.min(100, Math.round(value)));
    if (next === pendingBrightness && next === brightness) return;
    pendingBrightness = next;
    brightness = next;
    brightnessRevision += 1;
    // Leading-edge updates: never wait for dragging to stop.
    if (!brightnessSet.running && !brightnessWrite.running) flushBrightness();
  }
  function flushBrightness() {
    if (brightnessSet.running) return;
    sentBrightness = pendingBrightness;
    brightnessSet.running = true;
  }
  function refreshBrightness() {
    if (brightnessRead.running || brightnessSet.running || brightnessWrite.running) return;
    brightnessRead.revision = brightnessRevision;
    brightnessRead.running = true;
  }

  function refreshPowerProfiles() {
    if (!profileRead.running && !profileSet.running) profileRead.running = true;
  }
  function setPowerProfile(profile) {
    if (powerBusy || profileRead.running || !powerProfiles.includes(profile)) return;
    powerError = "";
    requestedProfile = profile;
    profileSet.running = true;
  }

  Process {
    id: profileRead
    command: ["powerprofilesctl", "list"]
    stdout: StdioCollector { id: profileOutput }
    stderr: StdioCollector {}
    onExited: function(code) {
      const profiles = [];
      let active = "";
      if (code === 0) {
        for (const line of profileOutput.text.split("\n")) {
          const match = line.match(/^\s*(\*)?\s*(performance|balanced|power-saver):\s*$/);
          if (match) {
            profiles.push(match[2]);
            if (match[1]) active = match[2];
          }
        }
      }
      state.powerProfiles = profiles;
      state.powerProfile = active;
    }
  }
  Process {
    id: profileSet
    command: ["powerprofilesctl", "set", state.requestedProfile]
    stderr: StdioCollector {}
    onExited: function(code) {
      if (code !== 0) state.powerError = "Could not switch power mode.";
      state.refreshPowerProfiles();
    }
  }

  Process {
    id: brightnessRead
    property int revision: 0
    command: ["brightnessctl", "-m"]
    stdout: StdioCollector {
      onStreamFinished: {
        const fields = text.trim().split(",");
        const value = fields.length >= 4 ? parseInt(fields[3]) : NaN;
        // Ignore an old poll if the user moved the slider in the meantime.
        if (brightnessRead.revision === state.brightnessRevision && !brightnessSet.running && !brightnessWrite.running)
          state.brightness = isNaN(value) ? -1 : value;
      }
    }
    onExited: function(code) {
      if (code !== 0 && revision === state.brightnessRevision && !brightnessSet.running && !brightnessWrite.running)
        state.brightness = -1;
    }
  }
  Process {
    id: brightnessSet
    command: ["brightnessctl", "set", state.sentBrightness + "%"]
    onExited: {
      // Coalesce motion events, but always deliver the final requested value.
      if (state.pendingBrightness !== state.sentBrightness) brightnessWrite.start();
      else state.refreshBrightness();
    }
  }
  Timer {
    id: brightnessWrite
    interval: 16
    onTriggered: state.flushBrightness()
  }
}
