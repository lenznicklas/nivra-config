pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: panel
  required property var theme
  required property var audio
  property string edge: "top"
  property real barThickness: 42
  property bool opened: false
  signal detailsRequested()
  property real reveal: opened ? 1 : 0
  function open() { opened = true; card.forceActiveFocus(); }
  function close() { opened = false; }
  function toggle() { if (opened) close(); else open(); }

  visible: opened || reveal > 0
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  WlrLayershell.namespace: "fortress-audio"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  // A full-screen input surface consumes outside clicks instead of forwarding them.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: panel.close()
    onWheel: function(event) { event.accepted = true; }
  }
  Behavior on reveal { NumberAnimation { duration: panel.theme.workspaceAnimationMs; easing.type: Easing.OutCubic } }

  Rectangle {
    id: card
    readonly property real gap: panel.theme.moduleSpacing
    readonly property real inset: panel.barThickness + gap + panel.theme.barMarginTop
    width: Math.max(1, Math.min(350 * panel.theme.uiScale, panel.width - 2 * gap - (panel.edge === "left" || panel.edge === "right" ? inset : 0)))
    height: Math.min(content.implicitHeight * panel.theme.uiScale + 36 * panel.theme.uiScale,
      Math.max(80, panel.height - (panel.edge === "top" || panel.edge === "bottom" ? inset : gap) - gap))
    x: panel.edge === "left" ? inset : Math.max(gap, panel.width - width - (panel.edge === "right" ? inset : gap))
    y: panel.edge === "top" ? inset : Math.max(gap, panel.height - height - (panel.edge === "bottom" ? inset : gap))
    opacity: panel.reveal
    transform: Translate { y: (1 - panel.reveal) * (panel.edge === "bottom" ? 12 : -12) }
    radius: panel.theme.barRadius
    color: panel.theme.panelStrong
    border.width: 1
    border.color: panel.theme.chipBorder
    focus: true
    Keys.onEscapePressed: panel.close()
    // Stop events over padding and empty card space, too.
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: function(event) { event.accepted = true; } }

    Flickable {
      anchors.fill: parent
      anchors.margins: 18 * panel.theme.uiScale
      contentWidth: width
      contentHeight: content.implicitHeight * panel.theme.uiScale
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: content
        width: parent.width / panel.theme.uiScale
        scale: panel.theme.uiScale
        transformOrigin: Item.TopLeft
        spacing: 16
        Row {
          width: parent.width
          spacing: 8
          Text {
            width: parent.width - detailsButton.width - closeButton.width - 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Audio"
            color: panel.theme.text
            font.family: panel.theme.fontName
            font.pixelSize: 15; font.weight: Font.DemiBold
          }
          ChipButton {
            id: detailsButton
            theme: panel.theme
            text: "󰒓"
            tooltip: "Open Sound settings"
            onClicked: { panel.close(); panel.detailsRequested(); }
          }
          ChipButton { id: closeButton; theme: panel.theme; text: "×"; tooltip: "Close audio"; onClicked: panel.close() }
        }
        AudioNodeControl {
          width: parent.width
          theme: panel.theme; audio: panel.audio
          node: panel.audio.sink; heading: "Speakers"
          meterEnabled: panel.opened
        }
        AudioNodeControl {
          width: parent.width
          theme: panel.theme; audio: panel.audio
          node: panel.audio.source
          heading: panel.audio.micMuted ? "Microphone · muted" : "Microphone"
          meterEnabled: false
        }

      }
    }
  }
}
