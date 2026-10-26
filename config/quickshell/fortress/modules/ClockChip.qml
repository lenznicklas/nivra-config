import QtQuick

Rectangle {
  id: chip

  property var theme
  property string timeText: "--:--"

  width: clockText.implicitWidth + 32
  height: chip.theme.chipHeight
  radius: chip.theme.chipRadius
  color: chip.theme.chipSurface
  border.width: 1
  border.color: chip.theme.chipBorder

  Text {
    id: clockText

    anchors.centerIn: parent
    text: chip.timeText
    color: chip.theme.accentSoft
    font.family: chip.theme.fontName
    font.pixelSize: 14
    font.bold: true
  }
}
