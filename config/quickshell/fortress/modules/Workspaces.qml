pragma ComponentBehavior: Bound
import Quickshell.Hyprland
import QtQuick

Flickable {
  id: workspaces

  property var theme
  property bool vertical: false

  property real maximumHeight: -1
  implicitWidth: workspaceGrid.implicitWidth
  implicitHeight: workspaceGrid.implicitHeight
  width: implicitWidth
  height: vertical && maximumHeight >= 0 ? Math.min(implicitHeight, maximumHeight) : implicitHeight
  contentWidth: workspaceGrid.width
  contentHeight: workspaceGrid.height
  interactive: vertical && contentHeight > height
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  function visibleWorkspaces() {
    // Show existing numbered Hyprland workspaces, sorted by ID.
    return Hyprland.workspaces.values
      .filter(function(ws) {
        return ws.id > 0;
      })
      .sort(function(a, b) {
        return a.id - b.id;
      });
  }

  Grid {
    id: workspaceGrid
    columns: workspaces.vertical ? 1 : Math.max(1, workspaceRepeater.count)
    horizontalItemAlignment: Grid.AlignHCenter
    spacing: workspaces.theme.workspaceSpacing
  Repeater {
    id: workspaceRepeater
    model: workspaces.visibleWorkspaces()

    Rectangle {
      id: wsButton

      required property var modelData
      property var workspace: modelData
      property bool active: workspace.focused
      property bool hovered: mouse.containsMouse

      width: Math.max(workspaceNumber.implicitWidth + 16, active ? workspaces.theme.workspaceActiveWidth : workspaces.theme.workspaceDotSize)
      height: workspaces.theme.workspaceDotSize
      radius: workspaces.theme.chipRadius

      color: workspace.urgent ? workspaces.theme.danger
           : active ? workspaces.theme.accent
           : hovered ? workspaces.theme.chipHover
           : workspaces.theme.chipSurface

      border.width: 1
      border.color: active || workspace.urgent ? color
                    : hovered ? workspaces.theme.accent : workspaces.theme.chipBorder

      Behavior on width {
        NumberAnimation {
          duration: workspaces.theme.workspaceAnimationMs
          easing.type: Easing.OutCubic
        }
      }

      Behavior on color {
        ColorAnimation { duration: 180 }
      }

      Text {
        id: workspaceNumber

        anchors.centerIn: parent
        text: String(wsButton.workspace.id)
        font.family: workspaces.theme.fontName
        font.pixelSize: 13
        font.bold: true
        color: wsButton.active || wsButton.workspace.urgent
               ? workspaces.theme.bg : workspaces.theme.text
      }

      MouseArea {
        id: mouse

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: wsButton.workspace.activate()
      }
    }
  }
  }
}
