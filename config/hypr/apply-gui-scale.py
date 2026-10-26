#!/usr/bin/env python3
"""Apply and persist a desktop-wide monitor scale; roll back rejected changes."""
from pathlib import Path
import json
import math
import os
import subprocess
import sys
import time

MODULE = Path(__file__).resolve().parent / 'modules/gui-scale.lua'


def hyprctl(*args):
    result = subprocess.run(['hyprctl', *args], text=True, capture_output=True, timeout=5)
    if result.returncode:
        raise RuntimeError('Cannot reach Hyprland. Apply the scale inside your desktop session.')
    return result.stdout


def monitors():
    try:
        outputs = json.loads(hyprctl('-j', 'monitors'))
    except json.JSONDecodeError as error:
        raise RuntimeError('Could not read the connected displays.') from error
    if not isinstance(outputs, list) or not outputs:
        raise RuntimeError('No active displays were found.')
    return outputs


def validate(scale, outputs):
    if not math.isfinite(scale) or not 0.75 <= scale <= 2:
        raise ValueError('Choose a scale between 75% and 200%.')
    # 175% needs fractional logical pixels on common display resolutions.
    # hyprland.lua permits those only for this preset, retaining normal checks
    # for every other scale. The live result is still verified below.
    if math.isclose(scale, 1.75, abs_tol=1e-9):
        return
    for output in outputs:
        if any(not math.isclose(output[key] / scale, round(output[key] / scale), abs_tol=1e-5)
               for key in ['width', 'height']):
            raise ValueError(f'{scale * 100:g}% is not supported at {output["name"]}\'s resolution. Try another scale.')


def write_module(text):
    temporary = MODULE.with_suffix('.lua.tmp')
    temporary.write_text(text)
    os.replace(temporary, MODULE)


def apply(scale):
    before = monitors()
    validate(scale, before)
    previous = MODULE.read_text()
    updated = f'-- Managed by Quickshell Settings. Desktop scale, applied once by Hyprland.\nreturn {scale:g}\n'
    if all(math.isclose(float(output['scale']), scale, abs_tol=0.001) for output in before):
        write_module(updated)
        return
    write_module(updated)
    try:
        hyprctl('reload')
        for _ in range(10):
            current = monitors()
            if all(math.isclose(float(output['scale']), scale, abs_tol=0.001) for output in current):
                return
            time.sleep(0.1)
        raise RuntimeError('Hyprland rejected this scale. The previous scale was restored.')
    except Exception:
        write_module(previous)
        try:
            hyprctl('reload')
        except Exception:
            pass
        raise


def main():
    try:
        scale = float(sys.argv[1])
        apply(scale)
        print(json.dumps({'ok': True, 'scale': scale}))
    except (ValueError, RuntimeError, OSError, subprocess.TimeoutExpired, IndexError, KeyError) as error:
        print(json.dumps({'ok': False, 'error': str(error)}))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
