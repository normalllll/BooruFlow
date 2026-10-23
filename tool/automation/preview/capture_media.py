"""R5 type-adaptation evidence from an owned background test instance."""
import json
import sys
from pathlib import Path
from capture import ui, place, observe, DESTINATION

BOARDS = [('M01','R5-video-grid'),('M02','R5-video-cover'),('M03','R5-gif-detail'),('M04','R5-unsupported')]

def capture_media(board, name):
    ui.start(board)
    try:
        place(1440, 900)
        diagnostics = None
        for _ in range(8):
            ui.request('pumpFrames', count=30)
            tree = observe()
            diagnostics = ui.request('mediaDiagnostics')
            if 'RenderErrorBox' in tree:
                raise RuntimeError('The actual media board contains a render error')
            media = diagnostics['media']
            target = [m for m in media if board == 'M01' or m['purpose'] == 'stage']
            if board == 'M04':
                if '无法预览' in tree and target: break
            elif any(any('pixels' in image for image in item['images']) for item in target):
                break
        else:
            raise RuntimeError(f'Media board did not reach its required rendered state: {diagnostics}')
        (Path('build') / (name+'-diagnostics.json')).write_text(json.dumps(diagnostics,ensure_ascii=False,indent=2),encoding='utf-8')
        for mode in ['light','dark']:
            ui.request('platformBrightness',value=mode)
            ui.request('pumpFrames',count=60)
            if 'RenderErrorBox' in observe(): raise RuntimeError('Render error before capture')
            result = ui.pair(DESTINATION / (name+'-'+mode+'.png'))
            Path(result['native']['path']).replace(DESTINATION / (name+'-'+mode+'.png'))
            print(name+'-'+mode, 'probe=', result['native']['probeMatched'], 'foreground=',result['native']['isForeground'],flush=True)
    finally:
        ui.close()

if __name__ == '__main__':
    selected = set(sys.argv[1:])
    for board, name in BOARDS:
        if not selected or board in selected:
            capture_media(board, name)
