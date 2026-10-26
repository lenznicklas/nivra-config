pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "LauncherSearch.js" as Search

PanelWindow {
  id: launcher
  property var theme
  property var targetScreen
  property string query: input.text
  property var recentIds: []
  property var hiddenApps: ["avahi-discover", "bssh", "bvnc", "qv4l2", "qvidcap",
    "org.gnome.Extensions", "org.gnome.Settings", "xgps", "xgpsspeed", "Neovim"]
  readonly property real launcherOffset: Math.max((theme.barHeight + 18) * theme.uiScale, (targetScreen ? targetScreen.height : 900) * 0.16)
  readonly property int resultLimit: Math.max(1, Math.min(theme.launcherMaxResults,
    targetScreen ? Math.floor(((targetScreen.height - launcherOffset) / theme.uiScale - 230) / 62) : theme.launcherMaxResults))
  readonly property var filteredEntries: {
    const q = query.trim();
    return DesktopEntries.applications.values
      .filter(app => !app.noDisplay && !hiddenApps.includes(app.id) && !hiddenApps.includes(app.name))
      .map(app => ({ app: app, score: q ? Search.score(app, q) : Search.suggestions(app, recentIds) }))
      .filter(result => result.score >= 0)
      .sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name))
      .slice(0, resultLimit)
      .map(result => result.app);
  }

  screen: targetScreen
  visible: false
  focusable: visible
  aboveWindows: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: Math.min(theme.launcherWidth * theme.uiScale, targetScreen ? targetScreen.width - 32 : theme.launcherWidth * theme.uiScale)
  implicitHeight: (card.height + 8) * theme.uiScale
  anchors.top: true
  margins.top: launcherOffset
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  HyprlandFocusGrab {
    active: launcher.visible
    windows: [launcher]
    onCleared: launcher.hideLauncher()
  }

  function toggle() { if (visible) hideLauncher(); else showLauncher(); }
  function showLauncher() {
    input.text = "";
    results.currentIndex = 0;
    visible = true;
    input.forceActiveFocus();
  }
  function hideLauncher() { visible = false; input.text = ""; }
  function moveSelection(delta) {
    const count = filteredEntries.length;
    if (!count) return;
    results.currentIndex = (Math.max(0, results.currentIndex) + delta + count) % count;
  }
  function launchSelected() {
    const app = filteredEntries[results.currentIndex];
    if (!app) return;
    recentIds = [app.id].concat(recentIds.filter(id => id !== app.id)).slice(0, 8);
    app.execute();
    hideLauncher();
  }

  Rectangle {
    id: card
    width: launcher.width / launcher.theme.uiScale
    scale: launcher.theme.uiScale
    transformOrigin: Item.TopLeft
    height: body.implicitHeight + 32
    radius: launcher.theme.barRadius
    color: launcher.theme.panelStrong
    border.width: 1
    border.color: Qt.rgba(launcher.theme.accent.r, launcher.theme.accent.g, launcher.theme.accent.b, 0.38)

    Column {
      id: body
      x: 16; y: 16
      width: parent.width - 32
      spacing: 12

      Rectangle {
        width: parent.width
        height: 58
        radius: launcher.theme.chipRadius
        color: launcher.theme.chipSurface
        border.width: 1
        border.color: launcher.theme.chipBorder
        Text {
          x: 16
          anchors.verticalCenter: parent.verticalCenter
          text: "󰍉"
          font.family: launcher.theme.fontName
          font.pixelSize: 23
          color: launcher.theme.accentSoft
        }
        Text {
          x: 54
          anchors.verticalCenter: parent.verticalCenter
          visible: input.text.length === 0
          text: "Where to next?"
          font.family: launcher.theme.fontName
          font.pixelSize: 18
          color: launcher.theme.textMuted
        }
        TextInput {
          id: input
          x: 54
          width: parent.width - 110
          height: parent.height
          verticalAlignment: TextInput.AlignVCenter
          color: launcher.theme.text
          selectionColor: launcher.theme.chipHover
          selectedTextColor: launcher.theme.text
          font.family: launcher.theme.fontName
          font.pixelSize: 18
          clip: true
          selectByMouse: true
          Accessible.name: "Search applications"
          onTextChanged: results.currentIndex = launcher.filteredEntries.length ? 0 : -1
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) launcher.hideLauncher();
            else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) launcher.moveSelection(1);
            else if (event.key === Qt.Key_Up || (event.key === Qt.Key_Backtab)) launcher.moveSelection(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) launcher.launchSelected();
            else return;
            event.accepted = true;
          }
        }
        Text {
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          text: "esc"
          font.family: launcher.theme.fontName
          font.pixelSize: 10
          color: launcher.theme.textMuted
        }
      }

      Row {
        width: parent.width
        Text {
          width: parent.width - 90
          text: launcher.query.trim() ? "APPLICATIONS" : launcher.recentIds.length ? "RECENT & SUGGESTED" : "QUICK START"
          font.family: launcher.theme.fontName
          font.pixelSize: 10
          font.letterSpacing: 1.2
          color: launcher.theme.textMuted
        }
        Text {
          width: 90
          horizontalAlignment: Text.AlignRight
          text: launcher.filteredEntries.length + " shown"
          font.family: launcher.theme.fontName
          font.pixelSize: 10
          color: launcher.theme.textMuted
        }
      }

      ListView {
        id: results
        width: parent.width
        height: count * 62
        model: launcher.filteredEntries
        currentIndex: 0
        interactive: false
        clip: true
        delegate: Rectangle {
          id: result
          required property var modelData
          required property int index
          readonly property bool selected: ListView.isCurrentItem
          width: results.width
          height: 62
          radius: launcher.theme.chipRadius
          color: selected ? launcher.theme.chipHover : mouse.containsMouse ? launcher.theme.chipSurface : "transparent"
          border.width: 1
          border.color: selected ? launcher.theme.chipBorder : "transparent"
          Behavior on color { ColorAnimation { duration: 100 } }
          Rectangle {
            x: 10; width: 40; height: 40; radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: launcher.theme.chipSurface
            Image {
              id: appIcon
              anchors.centerIn: parent
              width: 28; height: 28
              source: result.modelData.icon ? Quickshell.iconPath(result.modelData.icon, true) : ""
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }
            Text {
              anchors.centerIn: parent
              visible: appIcon.status !== Image.Ready
              text: (result.modelData.name || "?").slice(0, 1).toUpperCase()
              color: launcher.theme.accentSoft
              font.family: launcher.theme.fontName
              font.pixelSize: 19
            }
          }
          Column {
            x: 64; width: parent.width - 118
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text {
              width: parent.width
              text: result.modelData.name || "Unknown application"
              elide: Text.ElideRight
              color: result.selected ? launcher.theme.accentSoft : launcher.theme.text
              font.family: launcher.theme.fontName
              font.pixelSize: 13
              font.weight: Font.DemiBold
            }
            Text {
              width: parent.width
              text: result.modelData.genericName || result.modelData.comment || result.modelData.id
              elide: Text.ElideRight
              color: launcher.theme.textMuted
              font.family: launcher.theme.fontName
              font.pixelSize: 10
            }
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            visible: result.selected
            text: "↵"
            color: launcher.theme.accentSoft
            font.pixelSize: 20
          }
          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: results.currentIndex = result.index
            onClicked: { results.currentIndex = result.index; launcher.launchSelected(); }
          }
        }
      }

      Column {
        visible: results.count === 0
        width: parent.width
        spacing: 10
        topPadding: 18
        bottomPadding: 18
        Text {
          width: parent.width
          text: "No applications found"
          horizontalAlignment: Text.AlignHCenter
          color: launcher.theme.text
          font.family: launcher.theme.fontName
          font.pixelSize: 14
        }
        Text {
          width: parent.width
          text: "Try a shorter name or another keyword."
          horizontalAlignment: Text.AlignHCenter
          color: launcher.theme.textMuted
          font.family: launcher.theme.fontName
          font.pixelSize: 11
        }
      }

      Rectangle { width: parent.width; height: 1; color: launcher.theme.chipBorder }
      Text {
        text: "↑ ↓  navigate     ↵  launch     esc  close"
        color: launcher.theme.textMuted
        font.family: launcher.theme.fontName
        font.pixelSize: 10
      }
    }
  }
}
