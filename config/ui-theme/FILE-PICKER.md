# Fortress File Picker

Der FileChooser ist unter Hyprland explizit `gtk` zugeordnet. Das installierte
`xdg-desktop-portal-gtk` 1.15.3 ist gegen GTK3 gelinkt und erzeugt native
GtkFileChooserDialog-Fenster. GTK4-CSS allein verändert diesen Portal-Picker
nicht. Die vorhandene Zuordnung ist korrekt und wurde nicht umgeschrieben;
Hyprland bleibt für ScreenCast, Screenshot und seine übrigen Interfaces zuständig.

Die Gestaltung stammt weiterhin aus Quickshell Theme.qml: Aubergine #180c1d,
warme Surface #271521, Selection #402228, Accent #f5895c, cremefarbener Text,
JetBrainsMono Nerd Font und 8/12-px-Rundungen. Adwaita-Icons und Cursor bleiben.

## Änderungen

- `gtk-3.0/settings.ini`: `gtk-dialogs-use-header=true`. Der Portal-Renderer
  verwendet den nativen Dialogkonstruktor ohne expliziten Headerbar-Override;
  GTK kann so Open/Cancel bzw. Save in der moderneren Headerbar anordnen.
- `gtk-3.0/filechooser.css`: separate Picker-Regeln für die warme Sidebar mit
  Accent-Markierung, kompakte Breadcrumbs, Such-/Pfad-/Dateiname-Felder,
  Spaltenköpfe, Auswahl, Dateifilter, Popovers, Kontextmenüs und Scrollbars.
- `gtk-4.0/filechooser.css`: dieselbe Designsprache, separat für die tatsächlich
  installierten GTK4-ColumnView-/GridView-Nodes.
- `gtk-3.0/gtk.css` und `gtk-4.0/gtk.css`: je ein Import des Picker-Stylesheets.
  Drei doppelte GTK4-Farbdefinitionen wurden bereinigt. Strata bleibt erhalten.
- `ui-theme/filechooser-gtk3.css.in` / `filechooser-gtk4.css.in`: editierbare
  Vorlagen; Radius-Werte werden aus Theme.qml übernommen.
- `hypr/scripts/sync-toolkit-theme.py`: erzeugt die Vorlagen mit; `--gtk-only`
  aktualisiert gezielt GTK. Der bestehende vollständige Theme-Sync bleibt nutzbar.

Alle neuen CSS-Regeln sind unter `filechooser` eingegrenzt. Native Suche,
Sortierung, Dateifilter, Mehrfachauswahl, Netzwerkorte, Preview, zusätzliche
App-Optionen und Überschreib-Bestätigung bleiben in der Hand von GTK. Kein
Widget wird versteckt oder per Script ersetzt. Dateilisten bleiben lesbar und
deckend; keine neuen Blur-/Window-Rules und keine zusätzlichen Pakete.

## Renderer je Anwendung

- Portal-Clients (Firefox, unterstützte Chromium-/Electron-Versionen, Qt mit
  den vorhandenen qt5ct/qt6ct-Einstellungen): GTK3-Portal-Picker, sofern der
  jeweilige Client den Portalweg tatsächlich verwendet.
- GTK3-Direktdialog: ebenfalls das GTK3-Styling.
- GTK4-Direktdialog: GTK4-Styling; die installierte 4.24-Version bietet auch
  eine GridView, die über die native Umschaltung erreichbar bleibt.
- Apps mit eigenem Dateidialog: behalten dessen Layout. Qt-Fallback-Dialoge
  verwenden das bereits konfigurierte Fortress-Kvantum-Theme.
- Flatpak ist nicht installiert; keine Sandbox-Overrides hinzugefügt. Der
  hostseitige Portal-Picker kann später von Flatpaks verwendet werden, ohne
  dass deren eigener GTK-Build die Host-CSS importieren muss.

GTK3 erhält durch CSS kein neues GTK4-Layout und keine zusätzliche Grid-Ansicht.
Auch einzelne native TreeView-Zeilen lassen sich nicht wie frei gestaltete
Quickshell-Karten umbauen. Diese Grenzen werden nicht durch fragile Eingriffe
in Toolkit oder Portal umgangen.

## Prüfung und Aktivierung

Bestanden: beide vollständigen Stylesheets einschließlich Imports ohne
GTK-CSS-Diagnosen; CSS-Nodes mit den installierten GTK-Templates abgeglichen;
Headerbar-Einstellung als vorhandene GTK3-Property geprüft; eindeutige
Farbdefinitionen/Imports; wiederholbare Generierung. Der GTK-only-Sync hat
Qt/Kvantum, Portals, Keybinds und Hyprland-Konfiguration bytegleich belassen.
Qt6-Fallback-FileChooser wurde mit der vorhandenen Palette offscreen gerendert;
Font-, Farb- und Icon-Prüfungen bestehen.

Nicht möglich: interaktive GTK-/Firefox-/Portal-Tests für Open, Save, Sidebar,
Suche und Kontextmenü. Sitzungs-D-Bus und Display-Verbindungen sind in der
Bearbeitungsumgebung gesperrt. `systemctl --user status` und der gezielte
`try-restart` des GTK-Portals scheitern daran. GTK4 init_check meldet auf diesem
Build zwar Erfolg, aber Gdk.Display.get_default() ist None; dies wurde nicht
als erfolgreicher GUI-Test gewertet. Auslesbare ältere Journal-Einträge belegen
GTK als FileChooser-Fallback, ersetzen aber keine aktuelle D-Bus-Introspektion.

Bereits laufende Dialoge/Portal-Prozesse können noch den zuvor geladenen Style
verwenden. Im Desktop-Terminal einmal:

```sh
python3 ~/.config/hypr/scripts/apply-ui-settings.py
systemctl --user restart xdg-desktop-portal-gtk.service
```

Danach einen neuen Dateidialog öffnen. Ein offener GTK-Dateidialog sollte vorher
geschlossen werden. Der Hyprland-Portal-Dienst wird dabei nicht neu gestartet.
Alternativ übernimmt ein neuer Hyprland-Login die vorhandene Start-Integration.

Backup vor dieser Änderung:
`ui-theme/file-picker-backup-20261020-163809.zip` (nur betroffene Dateien und
Manifest neu hinzugefügter Zieldateien).
