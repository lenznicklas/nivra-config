import QtQuick
import QtQuick.Controls

Column {
  id: control
  property var theme
  property string title
  property string detail
  property real value: 0
  property real minimum: 0
  property real maximum: 1
  signal moved(real value)
  spacing: 8
  opacity: enabled ? 1 : 0.45

  Row {
    width: parent.width
    Text {
      width: parent.width * 0.6
      elide: Text.ElideRight
      text: control.title
      color: control.theme.text
      font.family: control.theme.fontName
      font.pixelSize: 12
      font.weight: Font.DemiBold
    }
    Text {
      width: parent.width * 0.4
      horizontalAlignment: Text.AlignRight
      text: control.detail
      elide: Text.ElideRight
      color: control.theme.textMuted
      font.family: control.theme.fontName
      font.pixelSize: 11
    }
  }
  Slider {
    id: slider
    width: parent.width
    height: 26
    from: control.minimum
    to: control.maximum
    value: control.value
    enabled: control.enabled
    Accessible.name: control.title
    onMoved: control.moved(value)
    background: Rectangle {
      x: slider.leftPadding
      y: (slider.height - height) / 2
      width: slider.availableWidth
      height: 8
      radius: 4
      color: control.theme.muted
      Rectangle {
        width: slider.visualPosition * parent.width
        height: parent.height
        radius: parent.radius
        color: control.enabled ? control.theme.accent : control.theme.textMuted
      }
    }
    handle: Rectangle {
      x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
      y: (slider.height - height) / 2
      width: 18; height: 18; radius: 9
      color: control.theme.text
      border.width: slider.activeFocus ? 2 : 0
      border.color: control.theme.accent
      scale: slider.pressed ? 1.12 : 1
      Behavior on scale { NumberAnimation { duration: 120 } }
    }
  }
}
