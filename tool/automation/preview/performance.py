"""Profile only: six internal batch toggles, no OS input or production data."""
import json
import os
from pathlib import Path
import sys
import time
os.environ['BOORUFLOW_AUTOMATION_CONFIGURATION'] = 'Profile'
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run as ui

def measure(label):
    samples = []
    try:
        state = ui.start('L12')
        if state['native']['isForeground'] or state['native']['hasNativeFocus']:
            raise RuntimeError('Profile instance must remain in background')
        print('profile view', state['viewSize'], 'foreground', state['native']['isForeground'], flush=True)
        ui.drive('app-shot', f'build/r4-profile-{label}.png')
        ui.drive('center', 'text', 'muryo 1')
        for index in range(6):
            ui.request('frameTimings')
            ui.drive('tap', 'text', 'muryo 1')
            ui.request('pumpFrames', count=80)
            # FrameTiming batches are delivered asynchronously, outside frames.
            time.sleep(1.1)
            result = ui.request('frameTimings')
            if result['mode'] != 'profile' or not result['frames']:
                raise RuntimeError('Missing real Profile FrameTiming samples')
            samples.append({'action': 'collapse' if index % 2 == 0 else 'expand', **result})
            print(index, result['mode'], len(result['frames']),
                'build max', max(f['buildUs'] for f in result['frames']),
                'raster max', max(f['rasterUs'] for f in result['frames']), flush=True)
        Path(f'build/r4-profile-{label}.json').write_text(json.dumps(samples), encoding='utf-8')
    finally:
        ui.close()

if __name__ == '__main__':
    measure(sys.argv[1])
