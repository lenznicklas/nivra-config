import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: win
  property var theme
  property var clock
  property var controls
  property var preferences
  readonly property string edge: preferences.barPosition
  readonly property bool vertical: edge === "left" || edge === "right"
  readonly property int thickness: (preferences.compactBar ? theme.barHeight : theme.barHeight + 8) + (vertical ? 14 : 0)
  signal lockRequested()
  signal launcherRequested()
  signal notesRequested()
  signal settingsRequested()
  signal audioSettingsRequested()

  color: "transparent"
  implicitWidth: vertical ? Math.ceil(thickness * theme.uiScale) : 1
  implicitHeight: vertical ? 1 : Math.ceil(thickness * theme.uiScale)
  exclusiveZone: Math.ceil((thickness + theme.barMarginTop) * theme.uiScale)
  anchors {
    top: win.edge !== "bottom"
    bottom: win.edge !== "top"
    left: win.edge !== "right"
    right: win.edge !== "left"
  }
  margins {
    top: win.edge === "top" ? (theme.barMarginTop * theme.uiScale) : win.vertical ? (theme.barMarginHorizontal * theme.uiScale) : 0
    bottom: win.edge === "bottom" ? (theme.barMarginTop * theme.uiScale) : win.vertical ? (theme.barMarginHorizontal * theme.uiScale) : 0
    left: win.edge === "left" ? (theme.barMarginTop * theme.uiScale) : !win.vertical ? (theme.barMarginHorizontal * theme.uiScale) : 0
    right: win.edge === "right" ? (theme.barMarginTop * theme.uiScale) : !win.vertical ? (theme.barMarginHorizontal * theme.uiScale) : 0
  }
  onEdgeChanged: { center.visible = false; audioPanel.close(); }

  Item {
    width: win.width / win.theme.uiScale
    height: win.height / win.theme.uiScale
    scale: win.theme.uiScale
    transformOrigin: Item.TopLeft
    Rectangle {
      anchors.fill: parent
      color: win.theme.panelStrong
      radius: win.theme.barRadius
      border.width: win.theme.barBorderWidth
      border.color: win.theme.barBorderColor

      Grid {
        id: leadingModules
        x: win.vertical ? (parent.width - width) / 2 : win.theme.barPaddingHorizontal
        y: win.vertical ? win.theme.barPaddingHorizontal : (parent.height - height) / 2
        horizontalItemAlignment: Grid.AlignHCenter
        columns: win.vertical ? 1 : 3
        columnSpacing: 8
        rowSpacing: 8
        ChipButton {
          tooltipsEnabled: !win.vertical
          theme: win.theme
          width: win.vertical ? win.theme.workspaceActiveWidth : implicitWidth
          text: "󰀻"
          tooltip: "Launcher · Super+Space"
          onClicked: win.launcherRequested()
        }
        Workspaces {
          theme: win.theme
          vertical: win.vertical
          maximumHeight: win.vertical ? Math.max(win.theme.workspaceDotSize,
            win.height / win.theme.uiScale - trailingModules.height - 2 * win.theme.barPaddingHorizontal - win.theme.chipHeight - 40) : -1
        }
        ChipButton {
          tooltipsEnabled: !win.vertical
          theme: win.theme
          width: win.vertical ? win.theme.workspaceActiveWidth : implicitWidth
          text: "󰎞"
          tooltip: "Notes · Super+N"
          visible: win.vertical ? win.height / win.theme.uiScale > 700 : win.width / win.theme.uiScale > 800
          onClicked: win.notesRequested()
        }
      }

      Item {
        x: win.vertical ? 0 : leadingModules.x + leadingModules.width + 20
        y: win.vertical ? leadingModules.y + leadingModules.height + 20 : 0
        width: win.vertical ? parent.width : Math.max(0, trailingModules.x - x - 20)
        height: win.vertical ? Math.max(0, trailingModules.y - y - 20) : parent.height
        visible: win.preferences.showWindowTitle
        Text {
          anchors.centerIn: parent
          width: win.vertical ? parent.height : parent.width
          visible: width > 120
          rotation: win.vertical ? (win.edge === "left" ? -90 : 90) : 0
          text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          color: win.theme.textMuted
          font.family: win.theme.fontName
          font.pixelSize: 11
          font.weight: Font.Medium
        }
      }

      Grid {
        id: trailingModules
        x: win.vertical ? (parent.width - width) / 2 : parent.width - width - win.theme.barPaddingHorizontal
        y: win.vertical ? parent.height - height - win.theme.barPaddingHorizontal : (parent.height - height) / 2
        columns: win.vertical ? 1 : 4
        columnSpacing: 6
        rowSpacing: 8
        ChipButton {
          tooltipsEnabled: !win.vertical
          theme: win.theme
          width: win.vertical ? win.theme.workspaceActiveWidth : implicitWidth
          text: win.controls.volumeIcon + (!win.vertical && win.width / win.theme.uiScale > 1000 && win.controls.audioReady ? " " + Math.round(win.controls.volume * 100) + "%" : "")
          tooltip: "Audio · scroll: volume · middle: mute · right: Sound settings"
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          selected: audioPanel.opened
          onClicked: { center.visible = false; audioPanel.toggle(); }
          onMiddleClicked: win.controls.toggleMute()
          onRightClicked: { center.visible = false; audioPanel.close(); win.audioSettingsRequested(); }
          onScrolled: function(delta) { win.controls.audio.stepVolume(delta * 0.05); }
        }
        ChipButton {
          tooltipsEnabled: !win.vertical
          theme: win.theme
          width: win.vertical ? win.theme.workspaceActiveWidth : implicitWidth
          text: "󰍭"
          tooltip: "Microphone is muted · click to unmute"
          visible: win.controls.micReady && win.controls.micMuted
          selected: true
          onClicked: win.controls.toggleMic()
        }
        BatteryChip {
          theme: win.theme
          compact: win.vertical
          visible: win.preferences.showBattery && (win.vertical || win.width / win.theme.uiScale > 650)
        }
        ChipButton {
          tooltipsEnabled: !win.vertical
          theme: win.theme
          width: win.vertical ? win.theme.workspaceActiveWidth : implicitWidth
          height: win.vertical ? 40 : win.theme.chipHeight
          text: Qt.formatDateTime(win.clock.date, win.vertical ? "hh\nmm" : win.preferences.showDate && win.width / win.theme.uiScale > 900 ? "ddd d MMM  hh:mm" : "hh:mm")
          tooltip: Qt.formatDateTime(win.clock.date, "dddd, d MMMM yyyy · hh:mm")
          selected: center.visible
          onClicked: { audioPanel.close(); center.visible = !center.visible; }
        }
      }
    }
  }

  AudioPanel {
    id: audioPanel
    screen: win.screen
    theme: win.theme
    audio: win.controls.audio
    edge: win.edge
    barThickness: win.thickness * win.theme.uiScale
    onDetailsRequested: win.audioSettingsRequested()
  }

  ControlCenter {
    id: center
    theme: win.theme
    controls: win.controls
    clock: win.clock
    anchor.window: win
    anchor.rect.x: win.edge === "left" ? win.width + 8
                 : win.edge === "right" ? -center.width - 8
                 : Math.max(0, win.width - center.width - 8)
    anchor.rect.y: win.edge === "top" ? win.height + 8
                 : win.edge === "bottom" ? -center.height - 8
                 : Math.max(0, win.height - center.height - 8)
    onAudioRequested: win.audioSettingsRequested()
    onLockRequested: win.lockRequested()
    onNotesRequested: win.notesRequested()
    onSettingsRequested: win.settingsRequested()
  }
}
