import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

import "modules"

ShellRoot {
  id: root

  Theme {
    id: appTheme
    // Hyprland scales the whole desktop; do not multiply the UI a second time.
    uiScale: 1.0
  }

  ControlState { id: controlState }
  // Shared, persisted appearance settings: bar edge and GUI scale.
  ShellPreferences { id: shellPreferences }

  DesktopSettings {
    id: desktopSettings
    theme: appTheme
    controls: controlState
    preferences: shellPreferences
    targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
  }

  SystemClock {
    id: sysClock
    precision: SystemClock.Minutes
  }

  Process {
    id: lockProc
    command: ["bash", "-lc", "pidof hyprlock >/dev/null || python3 ~/.config/hypr/scripts/lockscreen.py"]
  }

  Overview {
    id: overview
    theme: appTheme
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "overview"
    description: "Toggle workspace overview"
    onPressed: {
      launcher.hideLauncher()
      notes.hideNotes()
      desktopSettings.close()
      overview.toggle()
    }
  }

  Launcher {
    id: launcher
    targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    theme: appTheme
  }

  Notes {
    id: notes
    targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    theme: appTheme
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "launcher"
    description: "Toggle Fortress launcher"
    onPressed: { overview.close(); launcher.toggle() }
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "notes"
    description: "Toggle Fortress notes"
    onPressed: { overview.close(); notes.toggle() }
  }

  // Retain IPC commands for terminal and script control.
  IpcHandler {
    target: "fortress"

    function overviewToggle(): void {
      overview.toggle()
    }

    function settingsShow(): void {
      launcher.hideLauncher()
      notes.hideNotes()
      desktopSettings.show(Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }

    function settingsHide(): void {
      desktopSettings.close()
    }

    function launcherToggle(): void {
      overview.close()
      launcher.toggle()
    }

    function notesToggle(): void {
      notes.toggle()
    }

    function launcherHide(): void {
      launcher.hideLauncher()
    }

    function notesHide(): void {
      notes.hideNotes()
    }
  }

  Variants {
    model: Quickshell.screens

    Bar {
      required property var modelData

      screen: modelData
      theme: appTheme
      clock: sysClock
      controls: controlState
      preferences: shellPreferences

      onAudioSettingsRequested: {
        overview.close()
        launcher.hideLauncher()
        notes.hideNotes()
        desktopSettings.show(modelData, "sound")
      }
      onSettingsRequested: {
        launcher.hideLauncher()
        notes.hideNotes()
        desktopSettings.show(modelData)
      }
      onLockRequested: lockProc.startDetached()
      onLauncherRequested: {
        launcher.targetScreen = modelData
        launcher.toggle()
      }
      onNotesRequested: {
        notes.targetScreen = modelData
        notes.toggle()
      }
    }
  }
}
