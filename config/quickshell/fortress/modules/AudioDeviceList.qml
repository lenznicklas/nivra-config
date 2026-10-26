pragma ComponentBehavior: Bound
import QtQuick

Column {
  id: list
  required property var theme
  required property var audio
  property bool input: false
  property var stream: null
  signal chosen()
  spacing: 4
  Repeater {
    model: list.input ? list.audio.inputs : list.audio.outputs
    delegate: Rectangle {
      id: device
      required property var modelData
      readonly property bool selected: modelData === (list.stream ? list.audio.streamTarget(list.stream) : list.input ? list.audio.source : list.audio.sink)
      width: list.width
      height: 36
      radius: list.theme.chipRadius
      color: selected || mouse.containsMouse ? list.theme.chipHover : list.theme.chipSurface
      border.width: 1
      border.color: selected ? list.theme.chipBorder : "transparent"
      Behavior on color { ColorAnimation { duration: 140 } }
      Accessible.role: Accessible.Button
      Accessible.name: list.audio.label(modelData)
      Accessible.onPressAction: select()
      activeFocusOnTab: true
      function select() {
        if (list.stream) list.audio.routeStream(list.stream, modelData);
        else if (list.input) list.audio.selectInput(modelData);
        else list.audio.selectOutput(modelData);
        list.chosen();
      }
      Keys.onReturnPressed: select()
      Keys.onSpacePressed: select()
      Row {
        anchors.fill: parent; anchors.margins: 8
        spacing: 8
        Text {
          text: list.audio.icon(device.modelData)
          color: list.theme.accentSoft
          font.family: list.theme.fontName; font.pixelSize: 16
        }
        Text {
          width: parent.width - 54
          text: list.audio.label(device.modelData)
          elide: Text.ElideRight
          color: device.selected ? list.theme.accentSoft : list.theme.text
          font.family: list.theme.fontName; font.pixelSize: 11
        }
        Text {
          text: device.selected ? "●" : "○"
          color: device.selected ? list.theme.accent : list.theme.textMuted
          font.family: list.theme.fontName; font.pixelSize: 12
        }
      }
      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: device.select()
      }
    }
  }
}
