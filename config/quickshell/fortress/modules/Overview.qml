pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: overview
  required property var theme
  property var targetScreen: null
  property bool opened: false
  readonly property var workspaceIds: {
    const ids = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    for (const ws of Hyprland.workspaces.values)
      if (ws.id > 9) ids.push(ws.id);
    return ids.sort((a, b) => a - b);
  }

  screen: targetScreen
  // Keep the surface mapped throughout the fade; restarting an animation must
  // never hide and remap it during close.
  visible: opened || canvas.reveal > 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  aboveWindows: true
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.namespace: "fortress-overview"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  function toggle() {
    if (opened) close(); else open();
  }
  function open() {
    targetScreen = Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0] || null;
    Hyprland.refreshToplevels();
    opened = true;
    entrance.restart();
    canvas.forceActiveFocus();
  }
  function close() {
    if (!opened) return;
    opened = false;
    entrance.restart();
  }
  function activate(id) {
    if (!opened || !workspaceIds.includes(id)) return;
    close();
    Hyprland.dispatch(Hyprland.usingLua ? 'hl.dsp.focus({workspace = "' + id + '"})' : "workspace " + id);
  }

  // The surface is mapped asynchronously; request focus again once it is visible.
  onVisibleChanged: if (visible && opened) Qt.callLater(function() {
    if (overview.opened) canvas.forceActiveFocus();
  })

  NumberAnimation {
    id: entrance
    target: canvas
    property: "reveal"
    to: overview.opened ? 1 : 0
    duration: overview.opened ? 230 : 80
    easing.type: Easing.OutCubic
  }

  Item {
    id: canvas
    anchors.fill: parent
    property real reveal: 0
    focus: true
    Keys.onPressed: event => {
      if (!overview.opened) return;
      // Consume keyboard input only while open. No global unmodified number binds.
      event.accepted = true;
      if (event.isAutoRepeat) return;
      if (event.key === Qt.Key_Escape) overview.close();
      else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9
               && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
        overview.activate(event.key - Qt.Key_0);
    }

    Rectangle {
      anchors.fill: parent
      color: overview.theme.bg
      opacity: canvas.reveal * 0.94
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: overview.close()
        onWheel: event => { event.accepted = true; }
      }
    }
    Image {
      anchors.fill: parent
      source: "file://" + Quickshell.env("HOME") + "/.config/wallpaper.jpg"
      fillMode: Image.PreserveAspectCrop
      opacity: canvas.reveal * 0.10
    }
    Item {
      id: content
      anchors.fill: parent
      anchors.margins: Math.max(20, Math.min(canvas.width, canvas.height) * 0.045)
      opacity: canvas.reveal

      Text {
        id: heading
        text: "󰕮  Workspaces"
        color: overview.theme.text
        font { family: overview.theme.fontName; pixelSize: 24; bold: true }
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: heading.verticalCenter
        text: "SUPER + TAB  /  ESC"
        color: overview.theme.accentSoft
        font { family: overview.theme.fontName; pixelSize: 11 }
      }
      Text {
        id: hint
        anchors.top: heading.bottom
        anchors.topMargin: 8
        text: "Choose a workspace · click or press 1–9"
        color: overview.theme.textMuted
        font { family: overview.theme.fontName; pixelSize: 12 }
      }

      Grid {
        id: grid
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 18
        columns: 3
        rows: Math.ceil(overview.workspaceIds.length / columns)
        spacing: Math.max(10, Math.min(22, content.width * 0.015))
        readonly property real cardWidth: Math.max(1, Math.min((content.width - spacing * 2) / 3, ((content.height - 104 - spacing * (rows - 1)) / rows - 30) * 1.78))
        scale: overview.opened ? 1 + (1 - canvas.reveal) * 0.85 : 1
        Repeater {
          model: overview.workspaceIds
          Rectangle {
            id: card
            required property int modelData
            readonly property var workspace: Hyprland.workspaces.values.find(ws => ws.id === modelData) || null
            readonly property var windows: workspace ? workspace.toplevels.values : []
            readonly property bool current: card.workspace !== null && card.workspace === Hyprland.focusedWorkspace
            width: grid.cardWidth
            height: width / 1.78 + 30
            radius: overview.theme.barRadius
            color: cardMouse.containsMouse ? overview.theme.muted : overview.theme.panelStrong
            border.width: current ? 2 : 1
            border.color: current || cardMouse.containsMouse ? overview.theme.accent : overview.theme.chipBorder
            Behavior on color { ColorAnimation { duration: 120 } }
            Item {
              id: desktop
              x: 6; y: 6
              width: parent.width - 12
              height: parent.height - 36
              clip: true
              Image {
                anchors.fill: parent
                source: "file://" + Quickshell.env("HOME") + "/.config/wallpaper.jpg"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.60
              }
              Text {
                anchors.centerIn: parent
                visible: card.windows.length === 0
                text: "Quiet space"
                color: overview.theme.textMuted
                font { family: overview.theme.fontName; pixelSize: 11 }
              }
              Repeater {
                model: card.windows
                Rectangle {
                  id: thumbnail
                  required property var modelData
                  readonly property var geo: modelData.lastIpcObject
                  readonly property var monitor: modelData.monitor || Hyprland.focusedMonitor
                  readonly property real mw: monitor ? monitor.width / monitor.scale : 1920
                  readonly property real mh: monitor ? monitor.height / monitor.scale : 1080
                  x: Math.max(0, Math.min(desktop.width - width, ((geo.at ? geo.at[0] : 0) - (monitor ? monitor.x : 0)) / mw * desktop.width))
                  y: Math.max(0, Math.min(desktop.height - height, ((geo.at ? geo.at[1] : 0) - (monitor ? monitor.y : 0)) / mh * desktop.height))
                  width: Math.min(desktop.width, Math.max(38, (geo.size ? geo.size[0] : mw * 0.7) / mw * desktop.width))
                  height: Math.min(desktop.height, Math.max(28, (geo.size ? geo.size[1] : mh * 0.7) / mh * desktop.height))
                  radius: 6
                  color: overview.theme.bg
                  border.width: 1
                  border.color: overview.theme.chipBorder
                  clip: true
                  ScreencopyView {
                    id: capture
                    anchors.fill: parent
                    anchors.margins: 1
                    captureSource: overview.visible ? thumbnail.modelData.wayland : null
                    live: overview.opened
                    paintCursor: false
                    constraintSize: Qt.size(thumbnail.width * 2, thumbnail.height * 2)
                  }
                  Text {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    visible: !capture.hasContent
                    text: thumbnail.geo.class || thumbnail.modelData.title
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: overview.theme.textMuted
                    font { family: overview.theme.fontName; pixelSize: 10 }
                  }
                  Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: Math.min(22, parent.height)
                    color: overview.theme.panelStrong
                    Text {
                      anchors.fill: parent
                      anchors.leftMargin: 6
                      text: thumbnail.modelData.title
                      elide: Text.ElideRight
                      verticalAlignment: Text.AlignVCenter
                      color: overview.theme.text
                      font { family: overview.theme.fontName; pixelSize: 9 }
                    }
                  }
                }
              }
            }
            Text {
              x: 12
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 8
              text: String(card.modelData).padStart(2, "0") + (card.current ? "  ·  CURRENT" : "")
              color: card.current ? overview.theme.accentSoft : overview.theme.text
              font { family: overview.theme.fontName; pixelSize: 10; bold: true }
            }
            Text {
              anchors { right: parent.right; bottom: parent.bottom; rightMargin: 12; bottomMargin: 8 }
              text: card.windows.length ? card.windows.length + (card.windows.length === 1 ? " window" : " windows") : "+"
              color: overview.theme.textMuted
              font { family: overview.theme.fontName; pixelSize: 10 }
            }
            MouseArea {
              id: cardMouse
              objectName: "workspaceCard" + card.modelData
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.AllButtons
              TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.DragThreshold
                onTapped: overview.activate(card.modelData)
              }
              onWheel: event => { event.accepted = true; }
            }
          }
        }
      }
      Text {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        text: "CLICK TO ENTER   ·   1–9 TO JUMP   ·   ESC TO CLOSE"
        color: overview.theme.textMuted
        font { family: overview.theme.fontName; pixelSize: 10 }
      }
    }
  }
}
