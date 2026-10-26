# Fortress: GTK, Qt und Portals

Die Quelle bleibt `quickshell/fortress/modules/Theme.qml`. Kein fremdes
Farbschema und keine zusätzlichen Pakete wurden installiert.

| Rolle | Aus dem Rice abgeleiteter Wert |
|---|---|
| Hintergrund | #180c1d |
| Surface | #271521, 7 % Accent über Hintergrund |
| Secondary Surface | #3a1e32, bestehendes Muted über Hintergrund |
| Accent / Soft Accent | #f5895c / #f7b98f |
| Text / Secondary Text | #f8e1d0 / #93817f |
| Dezenter Border | #3c282f, 16 % Soft Accent über Hintergrund |
| Selection / Hover | #402228, 18 % Accent über Hintergrund |
| Controls / Panels | 8 px / 12 px Rundung |
| Schrift | JetBrainsMono Nerd Font, 10 pt, Regular; native Überschriften bleiben erhalten |
| Icons / Cursor | vorhandenes Adwaita / Adwaita, 24 px Cursor |
| Spacing | 8 px Layout-Abstand, kompakte 4–10 px Control-Paddings |

Die Bar nutzt Panels mit 72/90 % Deckkraft. App-Arbeitsflächen sind bewusst
deckend, damit Text, Dokumente und Dialoge lesbar bleiben. Hyprland hat bislang
keine explizite Blur-Stärke in seiner Config; die Bar selbst definiert keinen
Blur-Pass. Compositor-Blur und globale Fenster-Opacity wurden nicht verändert.
GTK/CSS und Kvantum implementieren keinen künstlichen Hintergrund-Blur.

## Dateien

- `gtk-3.0/{settings.ini,gtk.css}`: Adwaita-dark als vollständige Widget-Basis,
  Fortress-Farben, Inputs, Buttons, Sidebar, Menüs, Tooltips und Scrollbars.
- `gtk-4.0/{settings.ini,gtk.css}`: semantische Farben, öffentliche
  libadwaita-CSS-Variablen, zurückhaltende Rundungen und Scrollbars.
  Der bisherige Import von `strata/style.css` bleibt erhalten.
- `qt5ct/qt5ct.conf`, `qt6ct/qt6ct.conf` und deren `colors/Fortress.conf`:
  identische Fonts, Icons und Paletten; Kvantum; Portal-Dateidialoge.
- `Kvantum/Fortress/{Fortress.svg,Fortress.kvconfig}` und `kvantum.kvconfig`:
  eigenes Fortress-Skin mit flachen SVG-Controls, 8/12-px-Ecken und dünnen Borders.
  Die vollständige ursprüngliche Indikator-/Widget-Grammatik stammt aus dem
  installierten KvGnomeDark von Tsu Jan/Kvantum (GPL-3.0).
  Die unveränderten Ausgangsassets liegen unter `ui-theme/kvantum-base`;
  Farben und Hauptcontrols werden vom Generator ersetzt.
- `environment.d/60-fortress-ui.conf`: zentrale Toolkit-/Xcursor-Werte.
- `hypr/modules/ui-environment.lua`: liest dieselbe Datei für direkt von
  Hyprland gestartete Apps. `hyprland.lua` lädt dieses Modul vor den Binds.
- `hypr/scripts/apply-ui-settings.py`: veröffentlicht GSettings und die
  Aktivierungsumgebung einmal beim Hyprland-Start. Für das standardisierte
  Portal-Accent-Enum wird die nächstliegende Farbe gewählt (aktuell Orange);
  die Host-Stylesheets verwenden weiterhin die exakten RGB-Werte.
- `xdg-desktop-portal/hyprland-portals.conf`: GTK für FileChooser/Settings und
  Fallbacks, Hyprland für ScreenCast/Screenshot/GlobalShortcuts/InputCapture.
  Die ebenfalls installierten wlr-/kwallet-Komponenten bleiben unangetastet.
- `hypr/scripts/sync-toolkit-theme.py`: erzeugt die Toolkit-Farben aus Theme.qml.
  Es ist in den vorhandenen `hypr/sync-theme.py` eingebunden (Super+W).

Die installierte qt6ct-Version bietet zusätzlich den Plugin-Schlüssel `qt5ct`
an. Deshalb genügt `QT_QPA_PLATFORMTHEME=qt5ct` für BEIDE Versionen; dies wurde
mit Qt5 und Qt6 geprüft. Keine konkurrierenden Plattformtheme-Variablen, kein
globales GTK_THEME und kein QT_STYLE_OVERRIDE. Native Qt-Wayland-Nutzung wird
mit XWayland-Fallback bevorzugt. `qt5-wayland` fehlt derzeit und ist optional
für native Qt5-Wayland-Fenster; Qt5 funktioniert bis dahin über XWayland.

## Aktivierung und Tests

Einmal ab- und wieder in Hyprland anmelden, damit Apps und Aktivierungsdienste
die neue Umgebung erben. Alternativ im Desktop `hyprctl reload`, danach
`python3 ~/.config/hypr/scripts/apply-ui-settings.py` ausführen und Apps neu
starten. Laufende Portal-Dienste wurden nicht ungefragt neu gestartet.

Geprüft: GTK3/GTK4-CSS fehlerfrei, bestehende Strata-Regeln mitgeladen,
Hyprland-Config gültig, Python/INI/SVG gültig, keine doppelten SVG-IDs,
wiederholbare Generierung, jede Portal-Zuordnung vom installierten Backend
unterstützt. Qt5 und Qt6 laden die Palette/Schrift/Adwaita-Icons korrekt;
Ordner-, Open-/Save-, Navigations- und Warn-Icons sind vorhanden.
Widgets, Menüs und Qt-Fallback-Open-Dialoge wurden offscreen gerendert und
visuell geprüft. Auch qt5ct und qt6ct starteten offscreen ohne Abbruch.

Die Live-Prüfung von GIMP (GTK3), pavucontrol (GTK4), Portal-Dateidialogen und
`systemctl --user status` war wegen gesperrtem Display-/D-Bus-Zugriff nicht
möglich. Der erste Versuch, GSettings live zu veröffentlichen, scheiterte aus
demselben Grund; der Login-Hook holt dies in der echten Sitzung nach.
Ein erfolgreicher Live-FileChooser-/Screensharing-Test wird nicht behauptet.

Firefox/Chromium/Electron können ihre nativen Portal-Picker verwenden;
Anwendungen mit eigenem Picker bleiben bei ihrem Toolkit. Flatpak ist hier
nicht installiert: keine globalen Sandbox-Freigaben wurden hinzugefügt.
Spätere Flatpaks nutzen den hostseitigen Portal-Picker; ihre eigenen internen
Widgets benötigen ggf. passende Runtime-Themes und sehen Host-CSS nicht
zwangsläufig. Keine Browserprofile oder App-Dokumente wurden verändert.

## Backup / Rücknahme

`ui-theme/backup-20261020-162415.zip` enthält nur die vorher vorhandenen,
betroffenen Configs sowie ein Manifest zuvor fehlender Zieldateien. Die neuen
Dateien sind oben aufgeführt. Zum vollständigen Rückbau die gesicherten Dateien
wiederherstellen und die neu hinzugefügten Dateien entfernen. Keine großen
Home- oder App-Verzeichnisse wurden kopiert.
