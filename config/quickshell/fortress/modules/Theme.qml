import QtQuick

QtObject {
  // Local UI scale, independent of the compositor monitor scale.
  property real uiScale: 1.0
  // Fortress / sunset palette derived from ~/.config/wallpaper.jpg
  property color bg: Qt.rgba(24 / 255, 12 / 255, 29 / 255, 1.0)
  property color panel: Qt.rgba(24 / 255, 12 / 255, 29 / 255, 0.72)
  property color panelStrong: Qt.rgba(24 / 255, 12 / 255, 29 / 255, 0.90)
  property color muted: Qt.rgba(74 / 255, 39 / 255, 60 / 255, 0.68)
  property color text: Qt.rgba(248 / 255, 225 / 255, 208 / 255, 1.0)
  property color textMuted: Qt.rgba(248 / 255, 225 / 255, 208 / 255, 0.55)
  property color accent: Qt.rgba(245 / 255, 137 / 255, 92 / 255, 1.0)
  property color accentSoft: Qt.rgba(247 / 255, 185 / 255, 143 / 255, 1.0)
  property color danger: Qt.rgba(226 / 255, 85 / 255, 73 / 255, 1.0)
  property string fontName: "JetBrainsMono Nerd Font"

  // Bar geometry
  property int barHeight: 42
  property int barMarginTop: 2
  property int barMarginHorizontal: 0
  property int barRadius: 12
  // Match the Hyprland active border; sync with hypr/sync-theme.py.
  property int barBorderWidth: 3
  property color barBorderColor: Qt.rgba(245 / 255, 137 / 255, 92 / 255, 221 / 255)
  property int barPaddingHorizontal: 12
  property int chipHeight: 26
  property int chipRadius: 8
  property int moduleSpacing: 8
  property color chipSurface: Qt.rgba(245 / 255, 137 / 255, 92 / 255, 0.07)
  property color chipHover: Qt.rgba(245 / 255, 137 / 255, 92 / 255, 0.18)
  property color chipBorder: Qt.rgba(247 / 255, 185 / 255, 143 / 255, 0.16)

  // Workspace geometry / animation
  property int workspaceDotSize: 26
  property int workspaceActiveWidth: 34
  property int workspaceSpacing: 6
  property int workspaceAnimationMs: 180

  // Launcher geometry
  property int launcherWidth: 680
  property int launcherInputHeight: 48
  property int launcherRowHeight: 42
  property int launcherMaxResults: 6
  property int launcherTopGap: 8

  // Notes geometry
  property int notesWidth: 620
  property int notesHeight: 360
}
