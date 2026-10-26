import QtQuick
import Quickshell.Services.UPower

Rectangle {
  id: root

  property var theme
  property bool compact: false
  property var battery: UPower.displayDevice

  function percent() {
    if (!battery)
      return "--";

    const raw = battery.percentage;

    if (raw === undefined || raw === null || isNaN(raw))
      return "--";

    // Quickshell/UPower may expose either 0.79 or 79 depending on version/device.
    if (raw <= 1)
      return Math.round(raw * 100);

    return Math.round(raw);
  }

  function charging() {
    // onBattery=false means AC/charging/full. This is stable and avoids enum-name issues.
    return !UPower.onBattery;
  }

  function icon() {
    const p = percent();

    if (p === "--")
      return "󰂑";

    if (charging())
      return "󰂄";

    if (p >= 90) return "󰁹";
    if (p >= 80) return "󰂂";
    if (p >= 70) return "󰂁";
    if (p >= 60) return "󰂀";
    if (p >= 50) return "󰁿";
    if (p >= 40) return "󰁾";
    if (p >= 30) return "󰁽";
    if (p >= 20) return "󰁼";
    if (p >= 10) return "󰁻";

    return "󰂎";
  }

  function isLow() {
    const p = percent();
    return p !== "--" && p <= 15 && !charging();
  }

  width: compact ? theme.workspaceActiveWidth : batteryText.implicitWidth + 12
  height: root.theme.chipHeight
  radius: root.theme.chipRadius

  color: "transparent"
  border.width: isLow() ? 1 : 0
  border.color: isLow() ? root.theme.danger : root.theme.chipBorder

  Behavior on color {
    ColorAnimation { duration: 180 }
  }

  Text {
    id: batteryText

    anchors.centerIn: parent
    text: root.compact ? (root.percent() === "--" ? "AC" : root.percent() + "%")
          : root.percent() === "--" ? "󰂑 AC" : root.icon() + " " + root.percent() + "%"
    color: root.isLow() ? root.theme.danger : root.charging() ? root.theme.accentSoft : root.theme.text
    font.family: root.theme.fontName
    font.pixelSize: root.compact ? 10 : 12
    font.weight: Font.Medium
  }
}
