pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.UPower

Rectangle {
  id: section
  property var theme
  property var controls
  readonly property var battery: UPower.displayDevice
  readonly property bool hasBattery: battery !== null && battery.isPresent
  readonly property int percent: hasBattery ? Math.round(battery.percentage * 100) : 0

  implicitHeight: content.implicitHeight + 24
  height: implicitHeight
  radius: theme.chipRadius
  color: theme.chipSurface

  Column {
    id: content
    x: 12; y: 12
    width: parent.width - 24
    spacing: 8
    Text {
      text: section.hasBattery ? "Battery · " + section.percent + "%" : "Power"
      color: section.theme.text
      font.family: section.theme.fontName
      font.pixelSize: 12
      font.weight: Font.DemiBold
    }
    Text {
      width: parent.width
      text: section.controls.powerBusy ? "Applying power mode…"
            : section.controls.powerError || (section.controls.powerProfiles.length === 0
              ? "Power profile service unavailable"
              : (UPower.onBattery ? "On battery" : "Plugged in") + " · Choose a power mode")
      wrapMode: Text.WordWrap
      color: section.controls.powerError ? section.theme.danger : section.theme.textMuted
      font.family: section.theme.fontName
      font.pixelSize: 10
    }
    Rectangle {
      visible: section.hasBattery
      width: parent.width
      height: 4
      radius: 2
      color: section.theme.muted
      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, section.percent / 100))
        height: parent.height
        radius: 2
        color: section.percent <= 15 && UPower.onBattery ? section.theme.danger : section.theme.accent
      }
    }
    Repeater {
      model: [
        {profile: "performance", label: "󰓅  Performance"},
        {profile: "balanced", label: "󰾅  Balanced"},
        {profile: "power-saver", label: "󰌪  Power Saver"}
      ]
      ChipButton {
        required property var modelData
        width: content.width
        theme: section.theme
        text: modelData.label + (selected ? "  ✓" : "")
        selected: section.controls.powerProfile === modelData.profile
        enabled: !section.controls.powerBusy && section.controls.powerProfiles.includes(modelData.profile)
        tooltip: section.controls.powerProfiles.includes(modelData.profile) ? modelData.label.trim() : "Not supported by this system"
        onClicked: section.controls.setPowerProfile(modelData.profile)
      }
    }
  }
}
