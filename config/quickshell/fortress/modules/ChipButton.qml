import QtQuick
import QtQuick.Controls

Rectangle {
  id: chip
  property var theme
  property alias text: label.text
  property string tooltip: ""
  property bool tooltipsEnabled: true
  property bool selected: false
  property int acceptedButtons: Qt.LeftButton
  signal middleClicked()
  signal rightClicked()
  signal clicked()
  signal scrolled(real delta)

  implicitWidth: label.implicitWidth + 20
  width: implicitWidth
  height: chip.theme.chipHeight
  radius: chip.theme.chipRadius
  color: mouse.pressed ? chip.theme.accent : chip.selected || mouse.containsMouse ? chip.theme.chipHover : chip.theme.chipSurface
  border.width: 1
  opacity: enabled ? 1 : 0.4
  Accessible.role: Accessible.Button
  Accessible.name: tooltip || label.text
  Accessible.onPressAction: chip.clicked()
  activeFocusOnTab: true
  Keys.onReturnPressed: chip.clicked()
  Keys.onSpacePressed: chip.clicked()
  border { color: chip.activeFocus ? chip.theme.accent : chip.selected || mouse.containsMouse ? chip.theme.chipBorder : "transparent" }

  Behavior on color { ColorAnimation { duration: 140 } }
  Text {
    id: label
    anchors.centerIn: parent
    width: Math.min(implicitWidth, Math.max(0, chip.width - 20))
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    color: mouse.pressed ? chip.theme.bg : chip.selected || mouse.containsMouse ? chip.theme.accentSoft : chip.theme.text
    font.family: chip.theme.fontName
    font.pixelSize: 12
    font.weight: Font.DemiBold
  }
  MouseArea {
    id: mouse
    anchors.fill: parent
    acceptedButtons: chip.acceptedButtons
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(event) {
      if (event.button === Qt.MiddleButton) chip.middleClicked();
      else if (event.button === Qt.RightButton) chip.rightClicked();
      else chip.clicked();
    }
    onWheel: function(event) { chip.scrolled(event.angleDelta.y / 120); }
  }
  ToolTip {
    visible: chip.tooltipsEnabled && mouse.containsMouse && chip.tooltip.length > 0
    delay: 600
    text: chip.tooltip
    contentItem: Text {
      text: chip.tooltip
      color: chip.theme.text
      font.family: chip.theme.fontName
      font.pixelSize: 11
    }
    background: Rectangle {
      color: chip.theme.panelStrong
      radius: chip.theme.chipRadius
      border.width: 1
      border.color: chip.theme.chipBorder
    }
  }
}
