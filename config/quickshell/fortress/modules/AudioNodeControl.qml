pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Column {
  id: row
  required property var theme
  required property var audio
  property var node: null
  property string heading: ""
  property bool boost: false
  property bool routing: false
  property bool choosingTarget: false
  property bool meterEnabled: false
  readonly property bool available: audio.usable(node)
  spacing: theme.moduleSpacing
  opacity: available ? 1 : 0.5

  Row {
    width: parent.width
    spacing: 8
    Item {
      width: 24; height: 26
      Image {
        id: appImage
        anchors.centerIn: parent
        width: 20; height: 20
        source: row.audio.appIcon(row.node) ? Quickshell.iconPath(row.audio.appIcon(row.node), true) : ""
        visible: status === Image.Ready
      }
      Text {
        anchors.centerIn: parent
        visible: appImage.status !== Image.Ready
        text: row.audio.icon(row.node)
        color: row.theme.accentSoft
        font.family: row.theme.fontName
        font.pixelSize: 19
      }
    }
    Text {
      width: parent.width - 32 - mute.width - 8
      anchors.verticalCenter: parent.verticalCenter
      text: row.heading || row.audio.label(row.node)
      elide: Text.ElideRight
      color: row.theme.text
      font.family: row.theme.fontName
      font.pixelSize: 12
      font.weight: Font.DemiBold
    }
    ChipButton {
      id: mute
      theme: row.theme
      text: row.available && row.node.audio.muted ? "󰖁" : "󰕾"
      tooltip: row.available && row.node.audio.muted ? "Unmute" : "Mute"
      selected: row.available && row.node.audio.muted
      enabled: row.available
      onClicked: row.audio.toggleNodeMute(row.node)
    }
  }
  ControlSlider {
    width: parent.width
    theme: row.theme
    title: row.heading ? row.audio.label(row.node) : "Volume"
    detail: !row.available ? "Unavailable" : (row.node.audio.muted ? "Muted · " : "") + Math.round(row.node.audio.volume * 100) + "%"
    maximum: row.boost ? 1.5 : 1
    value: row.available ? row.node.audio.volume : 0
    enabled: row.available
    onMoved: function(value) { row.audio.setNodeVolume(row.node, value, row.boost); }
  }
  ChipButton {
    width: parent.width
    visible: row.routing && row.node !== null && row.node.isStream
    theme: row.theme
    text: "󰕾  " + (row.audio.streamTarget(row.node) ? row.audio.label(row.audio.streamTarget(row.node)) : "Choose device")
    tooltip: "Route this stream to another device"
    enabled: !row.audio.routingBusy
    onClicked: row.choosingTarget = !row.choosingTarget
  }
  AudioDeviceList {
    width: parent.width
    visible: row.routing && row.choosingTarget
    theme: row.theme; audio: row.audio
    input: row.node !== null && row.node.isSink
    stream: row.node
    onChosen: row.choosingTarget = false
  }
  // No monitor stream remains active after the panel closes. Mic monitoring is opt-in.
  PwNodePeakMonitor {
    id: monitor
    node: row.meterEnabled && row.available ? row.node : null
    enabled: row.meterEnabled && row.available
  }
  Rectangle {
    visible: row.meterEnabled
    width: parent.width; height: 3; radius: 1.5
    color: row.theme.muted
    Rectangle {
      width: parent.width * Math.min(1, Math.max(0, monitor.peak))
      height: parent.height; radius: parent.radius
      color: row.theme.accentSoft
    }
  }
  Text {
    visible: row.available && row.node.audio.volume > 1
    text: "Above 100% · amplification"
    color: row.theme.accentSoft
    font.family: row.theme.fontName
    font.pixelSize: 10
  }
}
