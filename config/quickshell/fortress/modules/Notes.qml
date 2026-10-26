import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: notes

  property var theme
  property var targetScreen
  property bool loadingFile: false

  screen: targetScreen
  visible: false
  focusable: visible
  aboveWindows: true
  color: "transparent"

  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
    left: true
    right: true
  }

  margins {
    top: (theme.barMarginTop + theme.barHeight + 10) * theme.uiScale
    left: 0
    right: 0
  }

  implicitHeight: (notesCard.height + 4) * theme.uiScale

  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  FileView {
    id: notesFile

    path: Qt.resolvedUrl("../notes.md")
    watchChanges: true
    atomicWrites: true

    onLoaded: {
      notes.loadingFile = true
      editor.text = notesFile.text()
      notes.loadingFile = false
    }

    onFileChanged: {
      if (!notes.visible)
        notesFile.reload()
    }

    onSaveFailed: function(error) {
      console.log("notes save failed:", error)
    }
  }

  Timer {
    id: saveTimer
    interval: 450
    repeat: false

    onTriggered: notesFile.setText(editor.text)
  }

  function toggle() {
    if (visible)
      hideNotes()
    else
      showNotes()
  }

  function showNotes() {
    visible = true
    editor.forceActiveFocus()
  }

  function hideNotes() {
    saveTimer.stop()
    notesFile.setText(editor.text)
    visible = false
  }

  Rectangle {
    id: notesCard

    width: Math.min(theme.notesWidth, notes.width / theme.uiScale - 32)
    height: Math.min(theme.notesHeight, targetScreen ? (targetScreen.height - notes.margins.top - 24) / theme.uiScale : theme.notesHeight)
    scale: notes.theme.uiScale
    transformOrigin: Item.Top
    radius: 24

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top

    color: theme.panelStrong
    border.width: 2
    border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.58)

    Column {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 10

      Item {
        width: parent.width
        height: 24

        Text {
          text: "󰎞 Notes"
          color: theme.text
          font.family: theme.fontName
          font.pixelSize: 16
          font.bold: true

          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "autosaved · esc closes"
          color: theme.textMuted
          font.family: theme.fontName
          font.pixelSize: 12

          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25)
      }

      Flickable {
        id: flick

        width: parent.width
        height: parent.height - 44
        clip: true

        contentWidth: width
        contentHeight: Math.max(editor.implicitHeight, height)

        TextEdit {
          id: editor

          width: flick.width
          height: Math.max(implicitHeight, flick.height)

          color: theme.text
          selectionColor: theme.accentSoft
          selectedTextColor: theme.bg

          font.family: theme.fontName
          font.pixelSize: 15

          wrapMode: TextEdit.Wrap
          selectByMouse: true
          persistentSelection: true
          textFormat: TextEdit.PlainText

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              notes.hideNotes()
              event.accepted = true
            }

            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
              saveTimer.stop()
              notesFile.setText(editor.text)
              event.accepted = true
            }
          }

          onTextChanged: {
            if (!notes.loadingFile)
              saveTimer.restart()
          }
        }
      }
    }
  }
}
