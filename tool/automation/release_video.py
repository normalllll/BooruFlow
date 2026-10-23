"""Owned background AOT playback verification using the installed capture skill."""
import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import run as ui

ROOT=Path(__file__).resolve().parents[2]
EXE=ROOT/'build/automation-release/x64/runner/Release/booruflow.exe'
DEST=Path('V:/Code/frost_ui/docs/screenshots/booruflow-preview-rework')

class ReleaseApp:
    def __init__(self,board,fixtures=None):
        # A normal Flutter build rewrites the shared generated target config.
        # Reject a production bundle before launching any process/profile code.
        ui.require_automation_bundle(EXE, file_rpc=True)
        self.root=ROOT/'build/ui-automation'/('release-'+str(time.time_ns()))
        self.root.mkdir(parents=True)
        env=os.environ.copy()
        env.update(BOORUFLOW_AUTOMATION_PROFILE=str(self.root),BOORUFLOW_PREVIEW_BOARD=board,BOORUFLOW_AUTOMATION_FIXTURES=str(fixtures or ROOT/'test/fixtures/media'))
        self.log=(self.root/'app.log').open('wb')
        self.process=subprocess.Popen([str(EXE)],cwd=EXE.parent,env=env,stdin=subprocess.DEVNULL,stdout=self.log,stderr=self.log,creationflags=ui.NO_WINDOW)
        self.sequence=0
    def request(self,command,**kwargs):
        self.sequence+=1
        payload={'id':self.sequence,'request':{'command':command,**kwargs}}
        temporary=self.root/'request.next'
        temporary.write_text(json.dumps(payload),encoding='utf-8')
        # Windows can briefly keep the request open while Dart reads it. Retry
        # only the undelivered atomic replacement, never the Flutter action.
        replace_deadline=time.monotonic()+3
        while True:
            try:
                temporary.replace(self.root/'request.json')
                break
            except PermissionError:
                if time.monotonic()>=replace_deadline: raise
                time.sleep(.02)
        deadline=time.monotonic()+45
        while time.monotonic()<deadline:
            if self.process.poll() is not None:
                raise RuntimeError(f'AOT test process exited: {(self.root/"app.log").read_text(encoding="utf-8",errors="replace")[-3000:]}')
            try:
                response=json.loads((self.root/'response.json').read_text(encoding='utf-8'))
                if response['id']==self.sequence:
                    if 'error' in response: raise RuntimeError(response)
                    return response['result']
            except (FileNotFoundError,PermissionError,json.JSONDecodeError): pass
            time.sleep(.05)
        raise TimeoutError(f'AOT request {command}: {self.root}')
    def drive(self,action,*args):
        if action!='app-shot': raise ValueError('Release uses internal controls, no VM Driver')
        data=self.request('appScreenshot')
        path=Path(args[0]);path.write_bytes(base64.b64decode(data.pop('png')))
        return {**data,'path':str(path)}
    def close(self):
        if self.process.poll() is None:
            # Close the owned HWND through its existing scoped native channel.
            self.sequence+=1
            (self.root/'request.json').write_text(json.dumps({'id':self.sequence,'request':{'command':'close'}}),encoding='utf-8')
            try: self.process.wait(timeout=10)
            except subprocess.TimeoutExpired: self.process.terminate();self.process.wait(timeout=10)
        self.log.close()

def verify(board):
    app=ReleaseApp(board)
    original=(ui.request,ui.drive,ui.session)
    ui.request=app.request;ui.drive=app.drive;ui.session=lambda:{'pid':app.process.pid}
    try:
        state=app.request('state')
        assert state['native']['pid']==app.process.pid and not state['native']['isForeground']
        print(board,'natural background',state['effectiveLifecycle'],flush=True)
        app.request('resize',width=1440,height=900)
        app.request('pretendForeground',enabled=True)
        app.request('platformBrightness',value='light')
        for _ in range(15):
            app.request('pumpFrames',count=15)
            buttons=app.request('buttons')
            play=[b for b in buttons if b['label']=='播放' and b['width']>0]
            if play: break
        else: raise RuntimeError(f'No play button in actual AOT element tree: {buttons}')
        target=play[-1]
        print('observed play',target,flush=True)
        app.request('pointer',action='tap',x=target['x'],y=target['y'])
        for _ in range(30):
            app.request('pumpFrames',count=10)
            players=app.request('videoDiagnostics')
            if players and players[-1]['error']: raise RuntimeError(players)
            if players and players[-1]['ready'] and players[-1]['positionMs']>1200: break
        else: raise RuntimeError(f'No decoded AOT video frame and advancing position: {players}')
        print('decoded AOT',players,flush=True)
        kind='mp4' if board=='M02' else 'webm'
        before=players[-1]['positionMs']
        # The actual shared frame receives exactly one temporal keyboard seek.
        app.request('key',key='Space')
        for _ in range(15):
            app.request('pumpFrames',count=3)
            paused=app.request('videoDiagnostics')[-1]
            if not paused['playing']: break
        assert not paused['playing'],paused
        app.request('key',key='ArrowRight')
        for _ in range(15):
            app.request('pumpFrames',count=3)
            sought=app.request('videoDiagnostics')[-1]
            if 4900 <= sought['positionMs']-paused['positionMs'] <=5100: break
        assert 4900 <= sought['positionMs']-paused['positionMs'] <=5100,(paused,sought)
        app.request('key',key='Space')
        for mode in ['light','dark']:
            app.request('platformBrightness',value=mode)
            app.request('pumpFrames',count=30)
            result=ui.pair(DEST/f'R5-video-playing-{kind}-{mode}.png')
            Path(result['native']['path']).replace(DEST/f'R5-video-playing-{kind}-{mode}.png')
            print('native',mode,result['native']['probeMatched'],result['native']['isForeground'],flush=True)
        if board=='M02':
            recording=ui.record_window(DEST/'R5-video-playing-release.mp4',3,12)
            print('recording',json.dumps(recording),flush=True)
        # Disabling framework foreground simulation restores the actual inactive
        # state without Windows activation and must release the native decoder.
        app.request('pretendForeground',enabled=False)
        closed=app.request('videoDiagnostics')[-1]
        assert closed['closed'],closed
        print('released',closed,flush=True)
        (ROOT/f'build/r5-release-{kind}-result.json').write_text(json.dumps({'mode':'release','played':players,'paused':paused,'seek':sought,'released':closed},indent=2),encoding='utf-8')
    finally:
        app.close();ui.request,ui.drive,ui.session=original

if __name__=='__main__':
    for board in sys.argv[1:] or ['M02','M05']: verify(board)
