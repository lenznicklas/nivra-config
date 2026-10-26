pragma ComponentBehavior: Bound
import QtQuick

Column {
  id: page
  required property var theme
  required property var audio
  property bool active: false
  property bool boost: false
  property bool micMeter: false
  onActiveChanged: if (!active) { boost = false; micMeter = false; }
  spacing: 18
  Text {
    visible: !page.audio.ready || (!page.audio.audioReady && !page.audio.micReady)
    width: parent.width
    text: !page.audio.ready ? "Waiting for PipeWire…" : "No audio devices connected"
    wrapMode: Text.WordWrap
    color: page.theme.textMuted
    font.family: page.theme.fontName; font.pixelSize: 11
  }
  AudioNodeControl {
    width: parent.width
    theme: page.theme; audio: page.audio
    node: page.audio.sink; heading: "Speakers"
    boost: page.boost
    meterEnabled: page.active
  }
  Text {
    text: "OUTPUT"
    color: page.theme.textMuted
    font.family: page.theme.fontName; font.pixelSize: 10
  }
  AudioDeviceList { width: parent.width; theme: page.theme; audio: page.audio }
  Rectangle { width: parent.width; height: 1; color: page.theme.chipBorder }
  Column {
    width: parent.width
    spacing: 12
    visible: page.audio.playback.length > 0
    Text {
      text: "APPLICATIONS"
      color: page.theme.textMuted
      font.family: page.theme.fontName; font.pixelSize: 10
    }
    Repeater {
      model: page.audio.playback
      delegate: AudioNodeControl {
        required property var modelData
        width: page.width
        theme: page.theme; audio: page.audio; node: modelData
        routing: true
        boost: page.boost
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: page.theme.workspaceAnimationMs } }
      }
    }
  }
  AudioNodeControl {
    width: parent.width
    theme: page.theme; audio: page.audio
    node: page.audio.source
    heading: page.audio.micMuted ? "Microphone · muted" : "Microphone"
    boost: page.boost
    meterEnabled: page.active && page.micMeter
  }
  Text {
    text: "INPUT"
    color: page.theme.textMuted
    font.family: page.theme.fontName; font.pixelSize: 10
  }
  AudioDeviceList { width: parent.width; theme: page.theme; audio: page.audio; input: true }
  Column {
    width: parent.width
    spacing: 12
    Rectangle { width: parent.width; height: 1; color: page.theme.chipBorder }
    SettingToggle {
      width: parent.width; theme: page.theme
      title: "Allow amplification"
      description: "Sliders up to 150%. May distort audio. Resets when leaving Sound."
      checked: page.boost
      onToggled: page.boost = !page.boost
    }
    SettingToggle {
      width: parent.width; theme: page.theme
      title: "Microphone level meter"
      description: "Monitor the input while this page is open."
      checked: page.micMeter
      onToggled: page.micMeter = !page.micMeter
    }
    Text {
      visible: page.audio.recording.length > 0
      text: "RECORDING APPLICATIONS"
      color: page.theme.textMuted
      font.family: page.theme.fontName; font.pixelSize: 10
    }
    Repeater {
      model: page.audio.recording
      delegate: AudioNodeControl {
        required property var modelData
        width: page.width
        theme: page.theme; audio: page.audio; node: modelData; boost: page.boost; routing: true
      }
    }
    Text {
      visible: page.audio.routingError.length > 0
      width: parent.width
      text: page.audio.routingError
      wrapMode: Text.WordWrap
      color: page.theme.textMuted
      font.family: page.theme.fontName; font.pixelSize: 10
    }
    ChipButton {
      theme: page.theme
      text: "Open pavucontrol ↗"
      tooltip: "Fallback: routing, profiles and channel balance"
      onClicked: page.audio.openFallback()
    }
  }
}
