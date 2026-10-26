import Quickshell
import Quickshell.Io

Scope {
  id: prefs
  property bool showWindowTitle: true
  property bool showBattery: true
  property bool showDate: true
  property bool compactBar: true
  property string barPosition: "top"
  property real guiScale: 1.0
  property string error: ""
  property string scaleError: ""
  property real requestedScale: 1.0
  property bool initialized: false
  readonly property bool scaleBusy: scaleApply.running

  function setPreference(key, value) {
    if (!["showWindowTitle", "showBattery", "showDate", "compactBar"].includes(key) || typeof value !== "boolean") return;
    prefs[key] = value;
    save();
  }
  function setBarPosition(value) {
    if (!["top", "bottom", "left", "right"].includes(value)) return;
    barPosition = value;
    save();
  }
  function setGuiScale(value) {
    if (scaleBusy || typeof value !== "number" || !Number.isFinite(value)) return;
    requestedScale = Math.round(Math.max(0.75, Math.min(2, value)) * 100) / 100;
    scaleError = "";
    scaleApply.running = true;
  }

  function reset() {
    showWindowTitle = true;
    showBattery = true;
    showDate = true;
    compactBar = true;
    barPosition = "top";
    save();
    setGuiScale(1.0);
  }
  function save() {
    error = "";
    preferencesFile.setText(JSON.stringify({showWindowTitle, showBattery, showDate, compactBar, barPosition, guiScale}, null, 2) + "\n");
  }
  Process {
    id: scaleApply
    command: ["python3", Quickshell.shellPath("../../hypr/apply-gui-scale.py"), String(prefs.requestedScale)]
    stdout: StdioCollector { id: scaleOutput }
    stderr: StdioCollector {}
    onExited: function(code) {
      try {
        const result = JSON.parse(scaleOutput.text);
        if (code === 0 && result.ok) {
          prefs.guiScale = result.scale;
          prefs.save();
        } else prefs.scaleError = result.error || "Could not change desktop scale.";
      } catch (error) {
        prefs.scaleError = "Could not change desktop scale.";
      }
    }
  }
  FileView {
    id: preferencesFile
    path: Qt.resolvedUrl("../preferences.json")
    atomicWrites: true
    onLoaded: {
      try {
        const saved = JSON.parse(text());
        if (typeof saved.guiScale === "number" && Number.isFinite(saved.guiScale) && saved.guiScale >= 0.75 && saved.guiScale <= 2)
          prefs.guiScale = saved.guiScale;
        if (["top", "bottom", "left", "right"].includes(saved.barPosition)) prefs.barPosition = saved.barPosition;
        for (const key of ["showWindowTitle", "showBattery", "showDate", "compactBar"])
          if (typeof saved[key] === "boolean") prefs[key] = saved[key];
        if (!prefs.initialized) {
          prefs.initialized = true;
          prefs.setGuiScale(prefs.guiScale);
        }
      } catch (error) {
        prefs.error = "Saved preferences could not be read.";
      }
    }
    onSaveFailed: prefs.error = "Could not save preferences.";
  }
}
