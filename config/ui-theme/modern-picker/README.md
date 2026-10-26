# Struktureller FileChooser-Wechsel ohne Plasma

## Tatsächlich vorgefunden

- Firefox 158.0, Installationsprofil `t6mebvf1.default-release` laut installs.ini.
- Kein gespeicherter Override für `widget.use-xdg-desktop-portal.file-picker`.
  Mozilla definiert standardmäßig `2` (Auto: Flatpak oder GTK_USE_PORTAL=1).
  Der Pref-Schlüssel ist auch in der installierten libxul vorhanden.
- Die persistierte Session-Umgebung enthält GTK_USE_PORTAL=1. Ob die bereits
  laufende Firefox-Instanz diesen Wert beim Start geerbt hat, lässt sich hier
  nicht feststellen. Ein bereits geöffneter Firefox-Dialog wurde nicht live
  inspiziert. Ein exakter Native-vs-Portal-Nachweis für diese Instanz fehlt.
- FileChooser ist explizit GTK zugeordnet; das GTK-Backend verwendet GTK3.
  Sowohl Firefox-GTK-Direktdialoge als auch dieser Portal-Picker behalten also
  das strukturelle GTK3-Grundlayout.
- Installierte Backends: gtk, hyprland, wlr (zusätzlich kwallet.portal als
  Descriptor). KDE-, GNOME- und LXQt-FileChooser-Backends fehlen.
- Screensharing/Screenshot/GlobalShortcuts/InputCapture sind Hyprland zugeordnet.
- Fortress GTK4/libadwaita-Farben, Adwaita-Icons, Cursor und JetBrainsMono sind
  bereits konfiguriert. Qt6ct/Kvantum besitzen ebenfalls die Fortress-Palette.

`systemctl --user status` und aktuelle D-Bus-Introspektion sind durch die
Bearbeitungsumgebung gesperrt. Es wird daher weder behauptet, welche Variante
Firefox gerade live verwendet, noch dass alle Portal-Services jetzt fehlerfrei
laufen.

## Auswahl

Das offizielle Arch `xdg-desktop-portal-kde` 6.8.0 zieht hier 64 fehlende Pakete
nach, darunter plasma-workspace, kwin, breeze und plasma-integration. Das
widerspricht der anschließend ausdrücklich gewählten Vorgabe „kein
Plasma-Unterbau“. Keine Dependency-Bypässe, extrahierten unsystemischen
Backend-Binaries oder Desktop-Name-Spoofings wurden eingerichtet.

LXQt wäre mit fünf fehlenden Paketen am kleinsten, aber sein libfm-qt-Dialog
bietet keinen vergleichbaren eingebauten Suchbereich. Um die gewünschte
Suchfunktion nicht nur durch eine Dateinamenfilterung zu ersetzen, ist der
vorbereitete Zielweg:

    Firefox / Portal-App
      → xdg-desktop-portal
        → nur FileChooser: xdg-desktop-portal-gnome
          → moderner Nautilus-Dateidialog (GTK4/libadwaita)
        → ScreenCast/Screenshot/etc.: Hyprland
        → übrige Fallbacks/Settings: GTK

GNOME-Portal 51 delegiert die Dateiauswahl an Nautilus. Hierfür sind laut lokalem
Pacman-Dry-Run 29 zusätzliche Pakete mit insgesamt 19.0 MiB Download erforderlich
(siehe package-plan.txt). Der Plan enthält weder gnome-shell/gnome-session noch
Plasma/KWin oder ein Desktop-Metapaket. Nautilus ist in dieser Architektur der
Renderer, nicht ein Ersatz für Hyprland oder Quickshell. GNOME-Portal und Nautilus
nutzen die bereits vorhandene Fortress-GTK4-Palette; keine neue Preset-Farbwelt.
Die tatsächliche Darstellung muss nach der Installation noch visuell geprüft
werden. Eine Vorschau des neuen Renderers wurde nicht vorgetäuscht.

## Bereits geändert

- `~/.config/mozilla/firefox/t6mebvf1.default-release/user.js`: genau ein Override,
  `user_pref("widget.use-xdg-desktop-portal.file-picker", 1);`.
- `hypr/scripts/activate-modern-picker.py`: vorbereiteter Installations-/Aktivierungshelfer.
- In diesem Verzeichnis: vorbereitete portals.conf, Paketplan, Upload-Testseite,
  diese Dokumentation und Backup der konkret betroffenen Ausgangsdateien.

Die aktive `xdg-desktop-portal/hyprland-portals.conf` ist noch unverändert.
**Der neue FileChooser ist noch NICHT installiert oder aktiviert.** Es wurden
keine Pakete installiert und Firefox wurde nicht neu gestartet. Die Umgebung
macht /usr nicht beschreibbar; sudo wird durch das gesetzte no-new-privileges
verhindert. Der Sitzungs-D-Bus ist ebenfalls nicht zugänglich.

## In der echten Desktop-Sitzung fertigstellen

```sh
python3 ~/.config/hypr/scripts/activate-modern-picker.py --install --restart-firefox
```

Der Helper beendet Firefox dabei per SIGTERM und startet ihn mit der lokalen
Testseite neu. Er erzwingt kein SIGKILL. Laufende Datei-Dialoge sollten vor dem
Aufruf geschlossen sein. Das zentrale Portal wird während der Aktivierung
neu gestartet; deshalb außerhalb laufender Screensharing-Sitzungen ausführen.

Der Helper prüft den aktuellen Pacman-Plan erneut und bricht ab, falls ein
Desktop-Unterbau hinzukäme. Er installiert ausschließlich das Portal-Paket
mit seinen vom Paketmanager aufgelösten Abhängigkeiten. Danach veröffentlicht
er die vorhandenen Fortress-Settings/Session-Variablen, prüft beide FileChooser-
Schnittstellen, sichert die aktuelle Zuordnung und ändert nur FileChooser auf
`gnome;gtk`. Bei neuen ERROR-Level-Portal-Logs oder fehlender zentraler
FileChooser-Schnittstelle stellt er die vorherige Zuordnung wieder her.

Falls bare Hyprland graphical-session.target nicht gestartet hat, erhält nur
xdg-desktop-portal-gnome eine kleine systemd-User-Ergänzung mit `Requisite=`.
Kein GNOME-Session-Target wird gestartet und XDG_CURRENT_DESKTOP bleibt Hyprland.
Die GTK- und Hyprland-Backends werden nicht entfernt oder neu konfiguriert.

Nur den Paketplan prüfen, ohne Nebenwirkungen:

```sh
python3 ~/.config/hypr/scripts/activate-modern-picker.py --check
```

## Praktische Abnahme

Auf der automatisch geöffneten lokalen Testseite beide Auswahlbuttons testen:
Einzelauswahl, Mehrfachauswahl mit Bildfilter. Dateien werden nicht hochgeladen.
Dann im Dialog Suche, Pfadeingabe, Breadcrumbs, Devices, versteckte Dateien,
Kontextmenü, Listen-/Icon-Ansicht und Sidebar prüfen. In Firefox zusätzlich
„Seite speichern unter …“ für Save-As und Dateityp-Filter testen.

Portal-fähige andere Apps verwenden dieselbe FileChooser-Zuordnung. Eigene
GTK-/Qt-Direktdialoge dürfen bei ihren vorhandenen funktionsfähigen Dialogen
bleiben. Flatpak ist nicht installiert und wurde nicht verändert.

Geprüft wurden Python-/JavaScript-Syntax, Paketplan ohne Desktop-Unterbau,
ein einzelner Firefox-Override und die vorbereitete Aufteilung ohne Änderungen
an den Hyprland-Schnittstellen. Der Aktivierungsversuch hat am gesperrten D-Bus
vor Installation/Backend-Wechsel korrekt abgebrochen. Interaktive Abnahme und
ein erfolgreicher Neustart der Portal-Services stehen noch aus.

Quellen: Mozilla StaticPrefList.yaml, GNOME-Portal 51.0 src/filechooser.c sowie
die lokalen pacman -Si/-Sp-Daten. GTK/Kvantum/Quickshell/Keybinds und sonstige
Desktop-Logik wurden in diesem Schritt nicht verändert.
