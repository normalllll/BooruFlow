"""Owned Windows minimize/restore regression; no host input or activation."""
import argparse,ctypes,json,sys,threading,time
from ctypes import wintypes
from pathlib import Path
import run as r

def main():
 p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--capture-helper');args=p.parse_args()
 root=Path(args.output).resolve();root.parent.mkdir(parents=True,exist_ok=True)
 r.request('resize',width=1440,height=850)
 b=next(b for b in r.request('buttons') if b.get('hitTestable') and b['label']=='Settings');r.request('pointer',action='tap',x=b['x'],y=b['y']);time.sleep(.4)
 r.request('windowMetrics',enabled=True,clear=True)
 before=r.request('state');hwnd=before['native']['hwnd'];assert before['native']['pid']==r.session()['pid'] and not before['native']['isForeground']
 user=ctypes.WinDLL('user32',use_last_error=True);user.ShowWindow.argtypes=[wintypes.HWND,ctypes.c_int];user.ShowWindow.restype=wintypes.BOOL
 user.SetWindowPos.argtypes=[wintypes.HWND,wintypes.HWND,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_int,wintypes.UINT];user.SetWindowPos.restype=wintypes.BOOL
 result={};errors=[];events=[];started=time.monotonic();thread=None
 if args.capture_helper:
  r.HELPER=Path(args.capture_helper).resolve()
  def record():
   try:result.update(r.record_window(root.with_suffix('.mp4'),6,30))
   except Exception as e:errors.append(repr(e))
  thread=threading.Thread(target=record);thread.start();time.sleep(1)
 events.append({'step':'minimizeRequested','seconds':time.monotonic()-started});r.request('windowMinimize');time.sleep(.5)
 minimized=r.request('state');r.session()
 events.append({'step':'restoreRequested','seconds':time.monotonic()-started});user.ShowWindow(hwnd,4);user.SetWindowPos(hwnd,wintypes.HWND(1),0,0,0,0,0x0001|0x0002|0x0010|0x0040)
 if thread:thread.join()
 time.sleep(.2);after=r.request('state');metrics=r.request('windowMetrics',enabled=False)
 data={'before':before,'minimized':minimized,'after':after,'metrics':metrics,'events':events,'capture':result,'errors':errors}
 root.with_suffix('.json').write_text(json.dumps(data,indent=2),encoding='utf-8');print(json.dumps(data),flush=True)
 assert not errors,errors
 assert minimized['native']['minimized'] and minimized['viewSize']==before['viewSize'],data
 assert after['viewSize']==before['viewSize'],data
 assert not after['native']['isForeground'] and not after['native']['hasNativeFocus']
 assert after['native']['activationCount']==before['native']['activationCount']
 assert not any(m['sizeClass']=='compact' or m['width']==0 or m['height']==0 for m in metrics),metrics
if __name__=='__main__':main()
