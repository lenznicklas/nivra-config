import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Scope {
  id: audio
  readonly property bool ready: Pipewire.ready
  readonly property var nodes: Pipewire.nodes.values
  readonly property var outputs: nodes.filter(n => !n.isStream && n.audio && n.isSink)
  readonly property var inputs: nodes.filter(n => !n.isStream && n.audio && !n.isSink)
  readonly property var playback: nodes.filter(n => n.isStream && n.audio && !n.isSink)
  readonly property var recording: nodes.filter(n => n.isStream && n.audio && n.isSink)
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property bool audioReady: usable(sink)
  readonly property bool micReady: usable(source)
  readonly property real volume: audioReady ? sink.audio.volume : 0
  readonly property bool muted: audioReady && sink.audio.muted
  readonly property bool micMuted: micReady && source.audio.muted
  readonly property string volumeIcon: !audioReady || muted || volume === 0 ? "󰖁" : volume < 0.5 ? "󰖀" : "󰕾"

  property string routingError: ""
  readonly property bool routingBusy: routeProcess.running
  property var routeCommand: []
  readonly property var links: Pipewire.links.values
  function streamTarget(node) {
    if (!node) return null;
    const link = links.find(l => node.isSink ? l.target === node : l.source === node);
    return link ? (node.isSink ? link.source : link.target) : null;
  }
  function routeStream(node, target) {
    if (routingBusy || !usable(node) || !usable(target) || !node.isStream) return;
    if (!(node.isSink ? inputs : outputs).includes(target)) return;
    routingError = "";
    routeCommand = ["python3", Quickshell.shellPath("scripts/audio-route.py"),
      node.isSink ? "recording" : "playback", String(node.id), String(node.properties["object.serial"] || ""),
      String(target.id), String(target.properties["object.serial"] || "")];
    routeProcess.running = true;
  }
  Process {
    id: routeProcess
    command: audio.routeCommand
    stderr: StdioCollector {}
    onExited: function(code) {
      if (code !== 0) audio.routingError = "Could not move stream. It may have ended or lack PulseAudio support. Try pavucontrol.";
    }
  }

  // Track all audio nodes once. Their properties/volumes update via PipeWire signals.
  PwObjectTracker { objects: audio.nodes.filter(n => n.audio !== null) }

  function usable(node) { return ready && node !== null && node !== undefined && node.ready && node.audio !== null; }
  function setNodeVolume(node, value, boost) {
    if (!usable(node) || !Number.isFinite(value)) return;
    node.audio.volume = Math.max(0, Math.min(boost ? 1.5 : 1, value));
  }
  function setVolume(value) { setNodeVolume(sink, value, false); }
  function stepVolume(delta) {
    // Scrolling never raises above 100%; existing amplification can be reduced gradually.
    if (audioReady) setNodeVolume(sink, delta > 0 ? Math.min(1, volume + delta) : volume + delta, volume > 1);
  }
  function toggleNodeMute(node) { if (usable(node)) node.audio.muted = !node.audio.muted; }
  function toggleMute() { toggleNodeMute(sink); }
  function toggleMic() { toggleNodeMute(source); }
  function selectOutput(node) {
    if (usable(node) && outputs.includes(node)) Pipewire.preferredDefaultAudioSink = node;
  }
  function selectInput(node) {
    if (usable(node) && inputs.includes(node)) Pipewire.preferredDefaultAudioSource = node;
  }
  function label(node) {
    if (!node) return "Unavailable";
    const p = node.properties || {};
    return node.isStream ? (p["application.name"] || node.description || node.name) : (node.description || node.nickname || node.name);
  }
  function icon(node) {
    if (!node) return "󰖁";
    const p = node.properties || {};
    const hint = (node.name + " " + node.description + " " + (p["device.api"] || "")).toLowerCase();
    if (hint.includes("bluez") || hint.includes("bluetooth")) return "󰂯";
    if (!node.isStream && !node.isSink) return "󰍬";
    if (hint.includes("hdmi") || hint.includes("displayport")) return "󰍹";
    if (hint.includes("headphone") || hint.includes("headset")) return "󰋋";
    if (hint.includes("usb")) return "󰕓";
    return node.isStream ? "󰎆" : "󰓃";
  }
  function appIcon(node) {
    const p = node ? node.properties || {} : {};
    return p["application.icon-name"] || "";
  }
  function openFallback() { Quickshell.execDetached(["pavucontrol"]); }
}
