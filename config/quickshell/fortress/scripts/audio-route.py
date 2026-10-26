#!/usr/bin/env python3
"""Move one Pulse-compatible stream, matching PipeWire IDs without guessing indexes."""
import json
import subprocess
import sys


def query(kind):
    result = subprocess.run(['pactl', '--format=json', 'list', kind],
                            capture_output=True, text=True, timeout=3, check=True)
    return json.loads(result.stdout)


def find(items, node_id, serial):
    for item in items:
        props = item.get('properties', {})
        # Prefer serials (not reused after hotplug); fall back only when unavailable.
        if serial:
            matches = str(props.get('object.serial', '')) == serial
        else:
            matches = str(props.get('object.id', '')) == node_id
        if matches:
            return item['index']
    raise ValueError('Stream or device is no longer available through PulseAudio.')


def route(direction, stream_id, stream_serial, target_id, target_serial):
    if direction not in ('playback', 'recording'):
        raise ValueError('Invalid stream direction.')
    playback = direction == 'playback'
    stream = find(query('sink-inputs' if playback else 'source-outputs'), stream_id, stream_serial)
    target = find(query('sinks' if playback else 'sources'), target_id, target_serial)
    subprocess.run(['pactl', 'move-sink-input' if playback else 'move-source-output',
                    str(stream), str(target)], capture_output=True, text=True, timeout=3, check=True)


if __name__ == '__main__':
    try:
        if len(sys.argv) != 6:
            raise ValueError('Expected direction, stream ID/serial and target ID/serial.')
        route(*sys.argv[1:])
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print('Audio routing failed: ' + str(error), file=sys.stderr)
        sys.exit(1)
