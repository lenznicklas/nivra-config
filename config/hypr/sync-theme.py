#!/usr/bin/env python3
"""Sync Hyprland, hyprlock and Strata from the active Quickshell theme."""
from pathlib import Path
import re
import subprocess
import sys

config = Path(__file__).resolve().parent.parent
qml = (config / 'quickshell/fortress/modules/Theme.qml').read_text()
colors = {}
for name, args in re.findall(r'property color (\w+): Qt\.rgba\(([^)]+)\)', qml):
    def value(part):
        parts = part.strip().split('/')
        return float(parts[0]) / float(parts[1]) if len(parts) == 2 else float(parts[0])
    colors[name] = tuple(round(value(part) * 255) for part in args.split(',')[:3])

def hexcolor(role):
    return ''.join(f'{v:02x}' for v in colors[role])

p = config / 'hypr/hyprland.lua'
s = p.read_text()
for key, alpha in [('active_border','dd'),('inactive_border','66')]:
    s = re.sub(r'('+key+r'\s*=\s*)"rgba\([^)]+\)"',
               lambda m: m[1] + '"rgba(' + hexcolor('accent') + alpha + ')"', s)
p.write_text(s)

# Change only the lockscreen's existing color properties; preserve all geometry.
p = config / 'hypr/hyprlock.conf'
s = p.read_text()
lines = []
for line in s.splitlines():
    match = re.match(r'(\s*)([\w_]+)(\s*=\s*)rgba\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*([\d.]+)\s*\)', line)
    if match:
        key = match[2]
        role = {'border_color':'accent','outer_color':'accent','inner_color':'bg',
                'font_color':'text','check_color':'accentSoft',
                'fail_color':'danger','capslock_color':'accentSoft'}.get(key)
        if key == 'color':
            # Explicit semantic marker survives palette changes and widget reordering.
            marker = re.search(r'# theme: (\w+)', line)
            role = marker[1] if marker else 'bg'
        if role:
            rgb = ', '.join(map(str, colors[role]))
            line = f'{match[1]}{key}{match[3]}rgba({rgb}, {match[4]})' + ((' # theme: ' + role) if key == 'color' else '')
    lines.append(line)
p.write_text('\n'.join(lines) + '\n')
subprocess.run([sys.executable, str(config / 'strata/sync-fortress.py')], check=True)
subprocess.run([sys.executable, str(config / 'hypr/scripts/sync-toolkit-theme.py')], check=True)
print('Synced Hyprland, hyprlock, Strata and GTK/Qt toolkits from Quickshell Theme.qml.')
if '--apply' in sys.argv:
    wallpaper = config / 'wallpaper.jpg'
    commands = [[sys.executable, str(config / 'hypr/scripts/apply-ui-settings.py')],
                ['hyprctl', 'reload'],
                ['hyprctl', 'hyprpaper', 'wallpaper', f',{wallpaper},cover']]
    failed = False
    for command in commands:
        try:
            result = subprocess.run(command, timeout=8, check=False)
            failed |= result.returncode != 0
        except (OSError, subprocess.TimeoutExpired) as error:
            print(error, file=sys.stderr)
            failed = True
    if failed:
        print('Files saved. Apply again inside your running Hyprland session.', file=sys.stderr)
        sys.exit(1)
