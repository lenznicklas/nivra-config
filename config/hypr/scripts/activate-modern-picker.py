#!/usr/bin/env python3
"""Install/activate the Nautilus portal picker from a real Hyprland terminal.

No system changes in --check mode. Never installs a desktop environment.
Firefox is gracefully closed/reopened only when --restart-firefox is requested.
"""
import argparse
import configparser
import datetime
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
ACTIVE = ROOT / 'xdg-desktop-portal/hyprland-portals.conf'
BUS = 'org.freedesktop.impl.portal.desktop.gnome'
FORBIDDEN = {'plasma-meta','plasma-desktop','plasma-workspace','kwin','gnome','gnome-shell',
             'gnome-session','gdm','sddm','xfce4','xfce4-session','lxqt','lxqt-session'}

def run(args, *, timeout=30, check=True, env=None):
    p = subprocess.run(args, text=True, capture_output=True, timeout=timeout, env=env)
    if check and p.returncode:
        raise RuntimeError(f'{args[0]}: {p.stderr.strip() or p.stdout.strip()}')
    return p

def parse(path):
    p = configparser.ConfigParser(interpolation=None)
    p.optionxform = str
    p.read(path)
    return p

def plan():
    p = run(['pacman','-Sp','--needed','--print-format','%n','xdg-desktop-portal-gnome'])
    packages = [line for line in p.stdout.splitlines() if line.strip()]
    reject = FORBIDDEN.intersection(packages)
    if reject:
        raise RuntimeError('Abbruch: Desktop-Unterbau in Paketplan: ' + ', '.join(sorted(reject)))
    return packages

def introspect(destination):
    return run(['gdbus','introspect','--session','--dest',destination,
                '--object-path','/org/freedesktop/portal/desktop'],timeout=20).stdout

def restart_firefox(env):
    # Match only Firefox browser parents, never unrelated Gecko browsers or children.
    browser_pids = []
    for entry in Path('/proc').iterdir():
        if not entry.name.isdigit(): continue
        try:
            if entry.stat().st_uid != os.getuid(): continue
            executable = os.readlink(entry / 'exe')
            args = (entry / 'cmdline').read_bytes().split(b'\0')
            if executable == '/usr/lib/firefox/firefox' and b'-contentproc' not in args:
                browser_pids.append(int(entry.name))
        except (OSError, ValueError):
            continue
    for pid in browser_pids:
        try: os.kill(pid,signal.SIGTERM)
        except ProcessLookupError: pass
    deadline = time.monotonic() + 12
    while browser_pids and time.monotonic() < deadline:
        browser_pids = [pid for pid in browser_pids if Path(f'/proc/{pid}').exists()]
        time.sleep(0.2)
    if browser_pids:
        raise RuntimeError('Firefox hat das Beenden noch nicht abgeschlossen; er wird nicht zwangsweise beendet.')
    page = ROOT / 'ui-theme/modern-picker/test-upload.html'
    subprocess.Popen(['firefox',page.as_uri()],env=env,start_new_session=True,
                     stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)

def activate(args):
    packages = plan()
    print('Noch benötigte Pakete:', ', '.join(packages) or 'keine')
    if args.check:
        print('Prüfmodus: keine Installation, kein Service-Neustart, kein Backend-Wechsel.')
        return
    # Fail before installing/changing anything when launched outside the real session.
    run(['systemctl','--user','show-environment'],timeout=5)
    if not os.environ.get('WAYLAND_DISPLAY'):
        raise RuntimeError('Aus einem Terminal in der laufenden Hyprland-Sitzung starten.')
    if packages:
        if not args.install:
            raise RuntimeError('Backend fehlt. Mit --install ausführen, um die geprüften Pakete zu installieren.')
        # No -Sy, no dependency bypass, no whole desktop groups.
        subprocess.run(['sudo','pacman','-S','--needed','xdg-desktop-portal-gnome'],check=True)
    descriptor = parse('/usr/share/xdg-desktop-portal/portals/gnome.portal')
    if not descriptor.has_section('portal') or 'org.freedesktop.impl.portal.FileChooser' not in descriptor['portal'].get('Interfaces','').split(';'):
        raise RuntimeError('Installiertes GNOME-Backend bietet FileChooser nicht an.')
    if run(['pacman','-Q','nautilus'],check=False).returncode != 0:
        raise RuntimeError('Nautilus fehlt; kein unvollständiger Backend-Wechsel.')
    env = os.environ.copy()
    for line in (ROOT / 'environment.d/60-fortress-ui.conf').read_text().splitlines():
        if re.match(r'^[A-Z_]+=',line):
            key,value=line.split('=',1); env[key]=value
    # Publish the existing Fortress font/dark preference, without desktop-name spoofing.
    run([sys.executable,str(ROOT / 'hypr/scripts/apply-ui-settings.py')],timeout=45,env=env)
    # GNOME's portal requires graphical-session.target; bare Hyprland may not start it.
    # Relax only this portal's requisite, and only in that case. Do not start GNOME.
    override = ROOT / 'systemd/user/xdg-desktop-portal-gnome.service.d/60-hyprland.conf'
    if run(['systemctl','--user','is-active','--quiet','graphical-session.target'],check=False).returncode:
        override.parent.mkdir(parents=True,exist_ok=True)
        override.write_text('# FileChooser under bare Hyprland; no GNOME session required.\n[Unit]\nRequisite=\n')
    run(['systemctl','--user','daemon-reload'])
    started = datetime.datetime.now().astimezone().isoformat(timespec='seconds')
    run(['systemctl','--user','restart','xdg-desktop-portal-gnome.service'])
    xml = introspect(BUS)
    if 'org.freedesktop.impl.portal.FileChooser' not in xml or 'SaveFile' not in xml:
        raise RuntimeError('FileChooser-Schnittstelle antwortet nicht; bisherige Zuordnung bleibt erhalten.')
    # Verify the actual delegate (the modern file browser), not merely an installed binary.
    delegate = run(['gdbus','introspect','--session','--dest','org.gnome.Nautilus',
                    '--object-path','/org/freedesktop/portal/desktop'],timeout=20).stdout
    if 'org.freedesktop.impl.portal.FileChooser' not in delegate:
        raise RuntimeError('Nautilus exportiert den FileChooser nicht; bisherige Zuordnung bleibt erhalten.')
    before = ACTIVE.read_text()
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup = ACTIVE.with_name(ACTIVE.name + '.before-nautilus-' + stamp)
    backup.write_text(before)
    # Preserve other current mappings; replace exactly one portal interface.
    desired = re.sub(r'(?m)^org\.freedesktop\.impl\.portal\.FileChooser=.*$',
                     'org.freedesktop.impl.portal.FileChooser=gnome;gtk',before)
    if desired == before and 'org.freedesktop.impl.portal.FileChooser=gnome;gtk' not in before:
        raise RuntimeError('FileChooser-Zeile fehlt; keine fremden Portal-Einstellungen überschrieben.')
    try:
        ACTIVE.write_text(desired)
        run(['systemctl','--user','restart','xdg-desktop-portal.service'])
        if 'org.freedesktop.portal.FileChooser' not in introspect('org.freedesktop.portal.Desktop'):
            raise RuntimeError('Zentrales Portal exportiert FileChooser nicht.')
        # Report and reject new ERROR-level entries from the two changed portal services.
        errors = run(['journalctl','--user','--since',started,'--no-pager','-o','cat','-p','err',
                      '-u','xdg-desktop-portal.service','-u','xdg-desktop-portal-gnome.service']).stdout.strip()
        if errors and errors != '-- No entries --':
            raise RuntimeError('Neue Portal-Fehler; Zuordnung wird zurückgesetzt:\n' + errors)
    except (RuntimeError, OSError, subprocess.SubprocessError):
        ACTIVE.write_text(before)
        run(['systemctl','--user','restart','xdg-desktop-portal.service'],check=False)
        raise
    print('Aktiviert: FileChooser=gnome;gtk. Hyprland-Zuordnungen unverändert.')
    print('Open/Save und Dateisuche jetzt im echten Firefox-Dialog prüfen.')
    if args.restart_firefox:
        restart_firefox(env)
        print('Firefox mit lokalem Upload-Test neu gestartet. Kein Upload erfolgt automatisch.')
    else:
        print('Firefox vollständig beenden/neustarten; Testseite: ' + str(ROOT / 'ui-theme/modern-picker/test-upload.html'))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--install',action='store_true')
    parser.add_argument('--restart-firefox',action='store_true')
    args=parser.parse_args()
    try: activate(args)
    except (OSError,RuntimeError,subprocess.SubprocessError) as error:
        print(str(error),file=sys.stderr)
        sys.exit(1)
