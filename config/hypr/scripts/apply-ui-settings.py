#!/usr/bin/env python3
"""Publish the toolkit preferences once at graphical login, without restarting portals."""
import os
import colorsys
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]

def main():
    # Also make explicit/manual application publish the same central values.
    for line in (ROOT / 'environment.d/60-fortress-ui.conf').read_text().splitlines():
        if re.match(r'^[A-Z_]+=', line):
            key, value = line.split('=', 1)
            os.environ[key] = value
    theme = (ROOT / 'quickshell/fortress/modules/Theme.qml').read_text()
    font = re.search(r'property string fontName: "([^"]+)"', theme)[1]
    # GTK portal Settings reads GSettings, not the application settings.ini.
    values = {'gtk-theme': 'Adwaita-dark', 'icon-theme': 'Adwaita',
              'cursor-theme': 'Adwaita', 'cursor-size': '24',
              'font-name': font + ' 10', 'monospace-font-name': font + ' 10',
              'color-scheme': 'prefer-dark'}
    # Portals expose a standardized accent enum; host CSS retains the exact RGB.
    channels = re.search(r'property color accent: Qt\.rgba\(([^)]+)\)', theme)[1].split(',')[:3]
    def channel(value):
        parts = value.strip().split('/')
        return float(parts[0]) / float(parts[1]) if len(parts) == 2 else float(parts[0])
    hue, saturation, _ = colorsys.rgb_to_hsv(*(channel(v) for v in channels))
    hues = {'blue':0.61, 'teal':0.48, 'green':0.35, 'yellow':0.14, 'orange':0.065,
            'red':0.0, 'pink':0.94, 'purple':0.77}
    values['accent-color'] = 'slate' if saturation < 0.12 else min(
        hues, key=lambda name: min(abs(hue-hues[name]), 1-abs(hue-hues[name])))

    failed = False
    for key, value in values.items():
        try:
            result = subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', key, value],
                                    capture_output=True, text=True, timeout=4)
            # dconf may report failure in stderr while gsettings exits successfully.
            if result.returncode or 'failed to commit' in result.stderr or 'unable to create' in result.stderr:
                failed = True
        except (OSError, subprocess.TimeoutExpired):
            failed = True
    # Update only the UI/session variables, preserving all other manager state.
    names = ['QT_QPA_PLATFORMTHEME', 'QT_QPA_PLATFORM', 'XCURSOR_THEME', 'XCURSOR_SIZE',
             'GTK_USE_PORTAL', 'WAYLAND_DISPLAY', 'DISPLAY', 'XDG_CURRENT_DESKTOP', 'XDG_SESSION_TYPE']
    try:
        result = subprocess.run(['dbus-update-activation-environment', '--systemd'] +
                                [n for n in names if n in os.environ],
                                capture_output=True, text=True, timeout=5)
        failed |= result.returncode != 0
    except (OSError, subprocess.TimeoutExpired):
        failed = True
    if failed:
        print('UI files are saved; live GSettings/D-Bus activation could not be updated. '
              'This helper runs again at the next Hyprland login.', file=sys.stderr)
        return 1
    print('Fortress UI preferences published to GSettings and D-Bus/systemd.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
