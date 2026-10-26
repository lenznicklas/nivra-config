import Quickshell
import Quickshell.Services.Mpris
import QtQuick

PopupWindow {
  id: popup
  property var theme
  property var controls
  property var clock
  readonly property var mediaPlayer: Mpris.players.values.find(player => player.isPlaying) || Mpris.players.values[0] || null
  signal audioRequested()
  signal lockRequested()
  signal notesRequested()
  signal settingsRequested()

  implicitWidth: Math.min(350 * theme.uiScale, screen ? screen.width - 24 : 350 * theme.uiScale)
  implicitHeight: card.height * theme.uiScale
  color: "transparent"
  grabFocus: true
  onVisibleChanged: if (visible) {
    controls.refreshBrightness()
    controls.refreshPowerProfiles()
  }

  Timer {
    interval: 4000
    running: popup.visible
    repeat: true
    onTriggered: {
      popup.controls.refreshBrightness()
      popup.controls.refreshPowerProfiles()
    }
  }
  Rectangle {
    id: card
    focus: true
    Keys.onEscapePressed: popup.visible = false
    width: popup.width / popup.theme.uiScale
    scale: popup.theme.uiScale
    transformOrigin: Item.TopLeft
    height: Math.min(content.implicitHeight + 36, popup.screen ? Math.max(240, popup.screen.height / popup.theme.uiScale - popup.theme.barHeight - 40) : 640)
    radius: popup.theme.barRadius
    color: popup.theme.panelStrong
    border.width: 1
    border.color: popup.theme.chipBorder

    Flickable {
      anchors.fill: parent
      anchors.margins: 18
      contentHeight: content.implicitHeight
      contentWidth: width
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: content
        width: parent.width
        spacing: 16

        Row {
          width: parent.width
          Column {
            width: parent.width - closeButton.width
            spacing: 4
            Text {
              text: "Control Center"
              color: popup.theme.text
              font.family: popup.theme.fontName
              font.pixelSize: 15
              font.weight: Font.DemiBold
            }
            Text {
              text: Qt.formatDateTime(popup.clock.date, "dddd, d MMMM")
              color: popup.theme.textMuted
              font.family: popup.theme.fontName
              font.pixelSize: 10
            }
          }
          ChipButton {
            id: closeButton
            theme: popup.theme
            text: "×"
            tooltip: "Close controls"
            onClicked: popup.visible = false
          }
        }

        Rectangle {
          width: parent.width
          height: audioContent.implicitHeight + 24
          radius: popup.theme.chipRadius
          color: popup.theme.chipSurface
          Column {
            id: audioContent
            x: 12; y: 12
            width: parent.width - 24
            spacing: 10
            ControlSlider {
              width: parent.width
              theme: popup.theme
              title: "Sound"
              detail: !popup.controls.audioReady ? "Unavailable" : popup.controls.muted ? "Muted" : Math.round(popup.controls.volume * 100) + "%"
              enabled: popup.controls.audioReady
              value: popup.controls.volume
              onMoved: function(value) { popup.controls.setVolume(value); }
            }
            Row {
              spacing: 8
              ChipButton {
                theme: popup.theme
                text: popup.controls.muted ? "󰖁 Unmute" : "󰕾 Mute"
                tooltip: "Toggle speaker mute"
                enabled: popup.controls.audioReady
                selected: popup.controls.muted
                onClicked: popup.controls.toggleMute()
              }
              ChipButton {
                theme: popup.theme
                text: popup.controls.micMuted ? "󰍭 Mic off" : "󰍬 Mic on"
                tooltip: "Toggle microphone mute"
                enabled: popup.controls.micReady
                selected: popup.controls.micMuted
                onClicked: popup.controls.toggleMic()
              }
            }
            Text {
              width: parent.width
              text: popup.controls.sink ? popup.controls.sink.description : "No audio output connected"
              elide: Text.ElideRight
              color: popup.theme.textMuted
              font.family: popup.theme.fontName
              font.pixelSize: 10
            }
          }
        }

        ControlSlider {
          width: parent.width
          theme: popup.theme
          title: "Display brightness"
          detail: popup.controls.brightness < 0 ? "Unavailable" : Math.round(popup.controls.brightness) + "%"
          minimum: 1; maximum: 100
          enabled: popup.controls.brightness >= 0
          value: Math.max(1, popup.controls.brightness)
          onMoved: function(value) { popup.controls.setBrightness(value); }
        }

        BatteryControl {
          width: parent.width
          theme: popup.theme
          controls: popup.controls
        }

        Rectangle {
          visible: popup.mediaPlayer !== null
          width: parent.width
          height: nowPlaying.implicitHeight + 24
          radius: popup.theme.chipRadius
          color: popup.theme.chipSurface
          Column {
            id: nowPlaying
            x: 12; y: 12
            width: parent.width - 24
            spacing: 8
            Text {
              width: parent.width
              text: popup.mediaPlayer ? popup.mediaPlayer.trackTitle || popup.mediaPlayer.identity : ""
              elide: Text.ElideRight
              color: popup.theme.text
              font.family: popup.theme.fontName
              font.pixelSize: 12
              font.weight: Font.DemiBold
            }
            Text {
              width: parent.width
              text: popup.mediaPlayer ? popup.mediaPlayer.trackArtist || popup.mediaPlayer.identity : ""
              elide: Text.ElideRight
              color: popup.theme.textMuted
              font.family: popup.theme.fontName
              font.pixelSize: 10
            }
            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 10
              ChipButton {
                theme: popup.theme; text: "󰒮"; tooltip: "Previous track"
                enabled: popup.mediaPlayer !== null && popup.mediaPlayer.canGoPrevious
                onClicked: popup.mediaPlayer.previous()
              }
              ChipButton {
                theme: popup.theme
                text: popup.mediaPlayer && popup.mediaPlayer.isPlaying ? "󰏤" : "󰐊"
                tooltip: "Play / pause"
                selected: true
                enabled: popup.mediaPlayer !== null && (popup.mediaPlayer.isPlaying ? popup.mediaPlayer.canPause : popup.mediaPlayer.canPlay)
                onClicked: popup.mediaPlayer.togglePlaying()
              }
              ChipButton {
                theme: popup.theme; text: "󰒭"; tooltip: "Next track"
                enabled: popup.mediaPlayer !== null && popup.mediaPlayer.canGoNext
                onClicked: popup.mediaPlayer.next()
              }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: popup.theme.chipBorder }
        ChipButton {
          width: parent.width
          theme: popup.theme
          text: "󰒓  Open Settings"
          tooltip: "Desktop settings"
          onClicked: { popup.visible = false; popup.settingsRequested(); }
        }
        Row {
          spacing: 8
          ChipButton {
            theme: popup.theme; text: "󰓃 Audio"
            tooltip: "Output devices and application volumes"
            onClicked: { popup.visible = false; popup.audioRequested(); }
          }
          ChipButton {
            theme: popup.theme; text: "󰎞 Notes"
            tooltip: "Open notes"
            onClicked: { popup.visible = false; popup.notesRequested(); }
          }
          ChipButton {
            theme: popup.theme; text: "󰌾 Lock"
            tooltip: "Lock screen"
            onClicked: { popup.visible = false; popup.lockRequested(); }
          }
        }
      }
  }
}
}
