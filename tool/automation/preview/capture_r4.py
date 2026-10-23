"""Only R4 affected native evidence; reuses the owned background harness."""
import json
import sys
from pathlib import Path
from capture import ui, capture, place, prepare_detail, observe, DESTINATION

def pair(name):
    result=ui.pair(DESTINATION / (name+'.png'))
    Path(result['native']['path']).replace(DESTINATION / (name+'.png'))
    print(name, 'probe=',result['native']['probeMatched'],'foreground=',result['native']['isForeground'],flush=True)

if '--only-technical' not in sys.argv:
    capture('L01')
    ui.start('L12')
    try:
        place(1440,900)
        ui.request('platformBrightness',value='light');ui.request('pumpFrames',count=90)
        tree=observe()
        if 'muryo 1' not in tree or 'DownloadTaskTile' not in tree:
            raise RuntimeError('The large batch fixture is not mounted')
        ui.drive('tap','text','muryo 1'); ui.request('pumpFrames',count=90)
        tree=observe()
        if 'muryo 2' not in tree: raise RuntimeError('Second batch header is not visible')
        ui.drive('tap','text','muryo 2'); ui.request('pumpFrames',count=90)
        if 'muryo 3' not in observe(): raise RuntimeError('Third expanded batch is missing')
        if '2-0.png' not in observe(): raise RuntimeError('Expanded task rows are missing')
        ui.request('pumpFrames',count=40)
        pair('L12-r4-3x208-light')
    finally:
        ui.close()
ui.start('D01')
try:
    place(1440,900);prepare_detail('D01')
    selector=json.dumps({'of':{'kind':'type','value':'PostDetailPage'},'matching':{'kind':'type','value':'CustomScrollView'}})
    if 'CustomScrollView' not in observe(): raise RuntimeError('No observed detail viewport')
    ui.drive('scroll','scoped',selector,'0','-1400');ui.request('pumpFrames',count=60)
    if 'PostTechnicalInformation' not in observe(): raise RuntimeError('Missing actual technical row')
    for mode in ['light','dark']:
        ui.request('platformBrightness',value=mode);ui.request('pumpFrames',count=30)
        # Scroll a little immediately before capturing so the real thumb is
        # visible rather than accepting only a static theme configuration.
        ui.drive('scroll','scoped',selector,'0','80');ui.drive('scroll','scoped',selector,'0','-80')
        rect=ui.drive('rect','scoped',selector)
        ui.request('pointer',action='hover',x=rect['right']-2,y=(rect['top']+rect['bottom'])/2)
        ui.request('pumpFrames',count=30)
        pair('D01-r4-technical-'+mode)
finally:
    ui.close()
