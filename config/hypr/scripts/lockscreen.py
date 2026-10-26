#!/usr/bin/env python3
"""Fortress presentation helpers. Authentication belongs exclusively to hyprlock/PAM."""
import html
import json
import os
from pathlib import Path
import pwd
import re
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
HOME = Path.home()

def run(*args):
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=0.6)
        return p.stdout.strip() if p.returncode == 0 else ''
    except (OSError, subprocess.TimeoutExpired):
        return ''

def safe(value):
    value = ' '.join(value.split())
    return html.escape(value[:39] + '…' if len(value) > 40 else value)

def status():
    items = []
    network = run('nmcli', '-t', '-f', 'TYPE,STATE', 'device')
    if 'wifi:connected' in network:
        items.append('󰤨')
    elif 'wifi:' in network:
        items.append('󰤭')
    if 'Powered: yes' in run('bluetoothctl', 'show'):
        items.append('󰂯')
    for battery in sorted(Path('/sys/class/power_supply').glob('*')):
        try:
            if (battery / 'type').read_text().strip() != 'Battery':
                continue
            percent = int((battery / 'capacity').read_text())
            charging = (battery / 'status').read_text().strip() in ('Charging', 'Full')
            icon = '󰂄' if charging else '󰁹' if percent >= 80 else '󰁾' if percent >= 30 else '󰁻'
            items.append(f'{icon} {percent}%')
        except (OSError, ValueError):
            pass
    print('  ·  '.join(items))

def media(kind):
    # One snapshot per refresh; no daemon, follow process, or shell interpolation.
    raw = run('playerctl', '--all-players', 'metadata', '--format',
              '{{status}}\t{{xesam:title}}\t{{xesam:artist}}\t{{mpris:artUrl}}')
    track = next((line.split('\t') for line in raw.splitlines()
                  if line.startswith('Playing\t')), None)
    if kind == 'media':
        if track and len(track) >= 3:
            print(f'<b>{safe(track[1])}</b>\n<span size="small" alpha="65%">{safe(track[2])}</span>')
        return
    # Only local cover art. Never fetch arbitrary remote URLs on the lockscreen.
    if track and len(track) >= 4:
        uri = urlparse(track[3])
        if uri.scheme == 'file' and uri.netloc in ('', 'localhost'):
            path = Path(unquote(uri.path))
            if path.is_file():
                print(path)
                return
    print(ROOT / 'scripts/transparent.png')

def prepare():
    text = (ROOT / 'hyprlock.conf').read_text()
    monitors_raw = run('hyprctl', 'monitors', '-j')
    try:
        monitors = json.loads(monitors_raw)
        primary = next((m for m in monitors if m.get('focused')), monitors[0])
        monitor = primary['name']
    except (ValueError, IndexError, KeyError, TypeError):
        monitor = ''  # Safe visible login on all outputs when IPC is unavailable.
    if monitors_raw and monitor:
        height = primary.get('height', 1080) / primary.get('scale', 1)
        width = primary.get('width', 1920) / primary.get('scale', 1)
        factor = min(1.0, max(0.62, height / 900))
        text = re.sub(r'font_size = (\d+)', lambda m: 'font_size = ' + str(max(10, round(int(m[1]) * factor))), text)
        text = text.replace('size = 340, 52', f'size = {min(340, max(240, int(width - 64)))}, 52')
    text = text.replace('$lockMonitor =', '$lockMonitor = ' + monitor, 1)
    # Ask the running wallpaper service first, then read its existing config.
    active = run('hyprctl', 'hyprpaper', 'listactive')
    papers = dict(re.findall(r'^\s*([^=\n]+?)\s*=\s*(.+)$', active, re.M))
    fallback = re.search(r'^\s*path\s*=\s*(.+)$', (ROOT / 'hyprpaper.conf').read_text(), re.M)
    wallpaper = papers.get(monitor) or (fallback[1].strip() if fallback else '')
    if wallpaper and Path(wallpaper).is_file() and not any(c in wallpaper for c in '\n\r#$'):
        text = text.replace('$lockWallpaper = ~/.config/wallpaper.jpg', '$lockWallpaper = ' + wallpaper)
    avatar = next((p for p in [HOME / '.face', HOME / '.face.icon',
                  Path('/var/lib/AccountsService/icons') / pwd.getpwuid(os.getuid()).pw_name]
                  if p.is_file()), None)
    if avatar and not any(c in str(avatar) for c in '\n\r#$'):
        text = text.replace('$lockAvatar = ~/.config/hypr/scripts/avatar.png', '$lockAvatar = ' + str(avatar))
    return text

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else 'lock'
    if mode == 'status':
        status()
    elif mode in ('media', 'cover'):
        media(mode)
    elif mode == 'prepare':
        print(prepare(), end='')
    elif mode == 'lock':
        if run('pidof', 'hyprlock'):
            return
        # Private per-invocation config; never shared between simultaneous lockers.
        try:
            with tempfile.TemporaryDirectory(prefix='fortress-lock-') as directory:
                path = Path(directory) / 'hyprlock.conf'
                path.write_text(prepare())
                result = subprocess.run(['hyprlock', '--config', str(path)])
                sys.exit(result.returncode)
        except (OSError, ValueError):
            os.execvp('hyprlock', ['hyprlock', '--config', str(ROOT / 'hyprlock.conf')])
    else:
        raise SystemExit('Unknown presentation helper')

if __name__ == '__main__':
    main()
