pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: settings
  property var theme
  property var controls
  property var preferences
  property var targetScreen
  property string section: "appearance"
  readonly property var sections: [
    {key: "appearance", icon: "󰏘", title: "Appearance", description: "Make the menu bar yours."},
    {key: "sound", icon: "󰕾", title: "Sound", description: "Devices, application volumes and microphone controls."},
    {key: "display", icon: "󰃟", title: "Display", description: "A comfortable brightness for your screen."},
    {key: "power", icon: "󰁹", title: "Power", description: "Battery status and energy preferences."}
  ]
  readonly property var currentSection: sections.find(item => item.key === section) || sections[0]

  screen: targetScreen
  visible: false
  focusable: visible
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  function show(screen, requestedSection) {
    if (sections.some(item => item.key === requestedSection)) section = requestedSection;
    pages.contentY = 0;
    targetScreen = screen;
    visible = true;
    card.forceActiveFocus();
    controls.refreshBrightness();
    controls.refreshPowerProfiles();
  }
  function close() { visible = false; }

  Timer {
    interval: 4000
    repeat: true
    running: settings.visible
    onTriggered: {
      settings.controls.refreshBrightness();
      settings.controls.refreshPowerProfiles();
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(settings.theme.bg.r, settings.theme.bg.g, settings.theme.bg.b, 0.42)
    MouseArea { anchors.fill: parent; onClicked: settings.close() }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: Math.min(840, settings.width / settings.theme.uiScale - 32)
    height: Math.min(590, settings.height / settings.theme.uiScale - 48)
    scale: settings.theme.uiScale
    transformOrigin: Item.Center
    radius: settings.theme.barRadius
    color: settings.theme.panelStrong
    border.width: settings.theme.barBorderWidth
    border.color: settings.theme.barBorderColor
    focus: true
    Keys.onEscapePressed: settings.close()
    MouseArea { anchors.fill: parent }

    // Fixed header and sidebar; only the content page scrolls.
    Row {
      id: header
      x: 24; y: 20
      width: parent.width - 48
      spacing: 12
      Text {
        width: parent.width - closeButton.width - 12
        height: closeButton.height
        verticalAlignment: Text.AlignVCenter
        text: "󰒓  Settings"
        color: settings.theme.text
        font.family: settings.theme.fontName
        font.pixelSize: 17
        font.weight: Font.DemiBold
      }
      ChipButton {
        id: closeButton
        theme: settings.theme
        text: "×"
        tooltip: "Close settings · Esc"
        onClicked: settings.close()
      }
    }

    Rectangle {
      x: 24; y: header.y + header.height + 18
      width: parent.width - 48; height: 1
      color: settings.theme.chipBorder
    }
    Column {
      id: navigation
      x: 24; y: header.y + header.height + 36
      width: card.width < 620 ? 44 : 164
      spacing: 8
      Repeater {
        model: settings.sections
        ChipButton {
          required property var modelData
          width: navigation.width
          height: 38
          theme: settings.theme
          text: navigation.width > 44 ? modelData.icon + "  " + modelData.title : modelData.icon
          tooltip: modelData.title
          selected: settings.section === modelData.key
          onClicked: { settings.section = modelData.key; pages.contentY = 0; }
        }
      }
    }
    Rectangle {
      x: navigation.x + navigation.width + 18
      y: navigation.y
      width: 1
      height: card.height - y - 24
      color: settings.theme.chipBorder
    }
    Flickable {
      id: pages
      x: navigation.x + navigation.width + 38
      y: navigation.y
      width: card.width - x - 24
      height: card.height - y - 24
      contentHeight: page.implicitHeight
      contentWidth: width
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: page
        width: parent.width
        spacing: 14
        Text {
          text: settings.currentSection.title
          color: settings.theme.text
          font.family: settings.theme.fontName
          font.pixelSize: 22
          font.weight: Font.DemiBold
        }
        Text {
          width: parent.width
          text: settings.currentSection.description
          color: settings.theme.textMuted
          font.family: settings.theme.fontName
          font.pixelSize: 11
          wrapMode: Text.WordWrap
        }

        Column {
          visible: settings.section === "appearance"
          width: parent.width
          spacing: 10
          Text {
            text: settings.preferences.scaleBusy ? "Applying desktop scale…" : "GUI scale · " + Math.round(settings.preferences.guiScale * 100) + "%"
            color: settings.theme.text
            font.family: settings.theme.fontName
            font.pixelSize: 12
            font.weight: Font.DemiBold
          }
          Grid {
            id: scaleChoices
            width: parent.width
            columns: width < 300 ? 2 : 3
            spacing: 8
            Repeater {
              model: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
              ChipButton {
                required property real modelData
                width: (scaleChoices.width - (scaleChoices.columns - 1) * scaleChoices.spacing) / scaleChoices.columns
                height: 34
                theme: settings.theme
                text: Math.round(modelData * 100) + "%"
                selected: Math.abs(settings.preferences.guiScale - modelData) < 0.001
                enabled: !settings.preferences.scaleBusy
                onClicked: settings.preferences.setGuiScale(modelData)
              }
            }
          }
          Text {
            width: parent.width
            text: "Scale Hyprland and all apps together."
            wrapMode: Text.WordWrap
            color: settings.theme.textMuted
            font.family: settings.theme.fontName
            font.pixelSize: 10
          }
          Text {
            text: "Bar position"
            color: settings.theme.text
            font.family: settings.theme.fontName
            font.pixelSize: 12
            font.weight: Font.DemiBold
          }
          Grid {
            id: positionChoices
            width: parent.width
            columns: width < 300 ? 2 : 4
            spacing: 8
            Repeater {
              model: [
                {edge: "top", label: "↑ Top"},
                {edge: "bottom", label: "↓ Bottom"},
                {edge: "left", label: "← Left"},
                {edge: "right", label: "→ Right"}
              ]
              ChipButton {
                required property var modelData
                width: (positionChoices.width - (positionChoices.columns - 1) * positionChoices.spacing) / positionChoices.columns
                height: 36
                theme: settings.theme
                text: modelData.label
                selected: settings.preferences.barPosition === modelData.edge
                onClicked: settings.preferences.setBarPosition(modelData.edge)
              }
            }
          }
          Text {
            width: parent.width
            text: "Applies immediately on every screen."
            color: settings.theme.textMuted
            font.family: settings.theme.fontName
            font.pixelSize: 10
          }
          SettingToggle {
            width: parent.width; theme: settings.theme
            title: "Window title"; description: "Show the active app title in the menu bar."
            checked: settings.preferences.showWindowTitle
            onToggled: function(value) { settings.preferences.setPreference("showWindowTitle", value); }
          }
          SettingToggle {
            width: parent.width; theme: settings.theme
            title: "Battery in menu bar"; description: "Keep battery status visible on wider screens."
            checked: settings.preferences.showBattery
            onToggled: function(value) { settings.preferences.setPreference("showBattery", value); }
          }
          SettingToggle {
            width: parent.width; theme: settings.theme
            title: "Date beside the clock"; description: "Show the day and month when there is room."
            checked: settings.preferences.showDate
            onToggled: function(value) { settings.preferences.setPreference("showDate", value); }
          }
          SettingToggle {
            width: parent.width; theme: settings.theme
            title: "Compact menu bar"; description: "Use a slimmer bar with less vertical padding."
            checked: settings.preferences.compactBar
            onToggled: function(value) { settings.preferences.setPreference("compactBar", value); }
          }
          ChipButton {
            theme: settings.theme; text: "Reset appearance"
            onClicked: settings.preferences.reset()
          }
          Text {
            width: parent.width
            visible: settings.preferences.error.length > 0 || settings.preferences.scaleError.length > 0
            text: settings.preferences.scaleError || settings.preferences.error
            wrapMode: Text.WordWrap
            color: settings.theme.danger
            font.family: settings.theme.fontName
            font.pixelSize: 11
          }
        }

        AudioSettingsPage {
          visible: settings.section === "sound"
          active: settings.visible && visible
          width: parent.width
          theme: settings.theme
          audio: settings.controls.audio
        }

        Column {
          visible: settings.section === "display"
          width: parent.width
          spacing: 20
          ControlSlider {
            width: parent.width; theme: settings.theme
            title: "Display brightness"
            detail: settings.controls.brightness >= 0 ? Math.round(settings.controls.brightness) + "%" : "Unavailable"
            minimum: 1; maximum: 100
            value: Math.max(1, settings.controls.brightness)
            enabled: settings.controls.brightness >= 0
            onMoved: function(value) { settings.controls.setBrightness(value); }
          }
          Text {
            width: parent.width
            text: settings.controls.brightness < 0 ? "This display does not expose an accessible backlight." : "Brightness changes are applied immediately."
            wrapMode: Text.WordWrap
            color: settings.theme.textMuted
            font.family: settings.theme.fontName
            font.pixelSize: 11
          }
          Rectangle {
            width: parent.width
            height: 86
            radius: settings.theme.chipRadius
            color: settings.theme.chipSurface
            Text {
              anchors.fill: parent; anchors.margins: 16
              text: "Sunset palette\nYour wallpaper colors are shared across the desktop."
              wrapMode: Text.WordWrap
              color: settings.theme.text
              font.family: settings.theme.fontName
              font.pixelSize: 11
            }
          }
        }

        BatteryControl {
          visible: settings.section === "power"
          width: parent.width
          theme: settings.theme
          controls: settings.controls
        }
      }
    }
  }
}
