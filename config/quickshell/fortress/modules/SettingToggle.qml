import QtQuick
import QtQuick.Controls

Rectangle {
  id: setting
  property var theme
  property string title
  property string description
  property bool checked: false
  signal toggled(bool value)
  implicitHeight: Math.max(64, labels.implicitHeight + 24)
  height: implicitHeight
  radius: theme.chipRadius
  color: theme.chipSurface
  opacity: enabled ? 1 : 0.45

  Column {
    id: labels
    x: 14
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width - toggle.width - 42
    spacing: 5
    Text {
      width: parent.width
      text: setting.title
      color: setting.theme.text
      font.family: setting.theme.fontName
      font.pixelSize: 12
      font.weight: Font.DemiBold
      wrapMode: Text.WordWrap
    }
    Text {
      width: parent.width
      text: setting.description
      color: setting.theme.textMuted
      font.family: setting.theme.fontName
      font.pixelSize: 10
      wrapMode: Text.WordWrap
    }
  }
  Switch {
    id: toggle
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    checked: setting.checked
    Accessible.name: setting.title
    onToggled: setting.toggled(checked)
    padding: 0
    indicator: Rectangle {
      implicitWidth: 38; implicitHeight: 22
      radius: 11
      color: toggle.checked ? setting.theme.accent : setting.theme.muted
      border.width: toggle.activeFocus ? 2 : 1
      border.color: toggle.activeFocus ? setting.theme.accentSoft : setting.theme.chipBorder
      Rectangle {
        x: toggle.checked ? parent.width - width - 3 : 3
        y: 3
        width: 16; height: 16; radius: 8
        color: toggle.checked ? setting.theme.bg : setting.theme.text
        Behavior on x { NumberAnimation { duration: 120 } }
      }
    }
  }
}
