"""Windows R9 slow-stream capture and display-sized decoder measurements.

Requires the dedicated Profile automation bundle and build/r9-fixtures;
all input is internal Flutter input and native captures stay in the background.
"""
import sys,os,json,time,threading,ctypes
from ctypes import wintypes
from pathlib import Path
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tool/automation'))
import release_video as rv
import run as ui
rv.EXE=root/'build/automation-windows/x64/runner/Profile/booruflow.exe'
os.environ['BOORUFLOW_PREVIEW_LOCALE']='en';os.environ['BOORUFLOW_AUTOMATION_PLACEMENT']='primary'
dest=Path('V:/Code/frost_ui/docs/screenshots/booruflow-preview-rework/r9');dest.mkdir(exist_ok=True)
class Counters(ctypes.Structure):
 _fields_=[('cb',wintypes.DWORD),('faults',wintypes.DWORD)]+[(s,ctypes.c_size_t) for s in ['peakWorkingSet','workingSet','pagedPool','peakPagedPool','nonPagedPool','peakNonPagedPool','pagefile','peakPagefile']]
open_process=ctypes.windll.kernel32.OpenProcess;open_process.restype=wintypes.HANDLE
ctypes.windll.psapi.GetProcessMemoryInfo.argtypes=[wintypes.HANDLE,ctypes.POINTER(Counters),wintypes.DWORD]
ctypes.windll.kernel32.CloseHandle.argtypes=[wintypes.HANDLE]
def memory(pid):
 h=open_process(0x410,False,pid);c=Counters();c.cb=ctypes.sizeof(c)
 try:
  if not ctypes.windll.psapi.GetProcessMemoryInfo(h,ctypes.byref(c),c.cb):raise ctypes.WinError()
  return c.workingSet,c.peakWorkingSet
 finally:ctypes.windll.kernel32.CloseHandle(h)
results=[]
metrics_only='--metrics-only' in sys.argv
files=[a for a in sys.argv[1:] if a!='--metrics-only']
for name in files or ['r9-baseline.jpg','r9-progressive.jpg','r9-noninterlaced.png','r9-large.jpg']:
 a=rv.ReleaseApp('D01',fixtures=root/'build/r9-fixtures');orig=(ui.request,ui.drive,ui.session)
 ui.request=a.request;ui.drive=a.drive;ui.session=lambda:{'pid':a.process.pid}
 stop=threading.Event();mem=[];failures=[]
 try:
  state=a.request('state');assert not state['native']['isForeground'],state
  a.request('resize',width=1100,height=800);a.request('pretendForeground',enabled=True)
  a.request('platformBrightness',value='light');a.request('pumpFrames',count=35)
  a.request('progressiveProbe',file=name);a.request('pumpFrames',count=35)
  buttons=a.request('buttons');b=next(b for b in buttons if b['label']=='Load image' and b['width']>0 and b.get('hitTestable',False))
  print('observed load',b,flush=True)
  before=memory(a.process.pid);a.request('frameTimings')
  def sample():
   while not stop.is_set():
    try:mem.append(memory(a.process.pid))
    except Exception as e:failures.append(str(e));break
    stop.wait(.05)
  monitor=threading.Thread(target=sample);monitor.start()
  def load():
   try:a.request('pointer',action='tap',x=b['x'],y=b['y'])
   except Exception as e:failures.append(str(e))
  if metrics_only:
   load();recording={}
   deadline=time.monotonic()+15
   while time.monotonic()<deadline:
    diagnostic=a.request('progressiveDiagnostics')
    if diagnostic and (diagnostic['complete'] or diagnostic['error']):break
    time.sleep(.15)
  else:
   timer=threading.Timer(.7,load);timer.start()
   recording=ui.record_window(dest/(Path(name).stem+'.mp4'),6,12)
   timer.join()
  stop.set();monitor.join()
  assert not failures,failures
  diagnostic=a.request('progressiveDiagnostics');assert diagnostic['complete'] and diagnostic['partialFrames']>=3,diagnostic
  frames=a.request('frameTimings');errors=a.request('flutterErrors');assert not errors,errors
  image=ui.pair(dest/(Path(name).stem+'-complete.png'))
  result={'implementation':'coalesced','file':name,'diagnostic':diagnostic,'frameTimings':frames,'beforeWorkingSet':before[0],'peakObservedWorkingSet':max(x[0] for x in mem),'processPeakWorkingSet':memory(a.process.pid)[1],'recording':recording,'probeMatched':image['native']['probeMatched'],'isForeground':image['native']['isForeground'],'failures':failures}
  results.append(result);(root/'build/r9-progressive-native-metrics.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
  print(name,json.dumps({'partialFrames':diagnostic['partialFrames'],'decodeUs':diagnostic['decodeUs'],'baselineMiB':before[0]/1048576,'peakMiB':result['peakObservedWorkingSet']/1048576,'recordFrames':recording.get('verifiedFrames'),'probeMatched':image['native']['probeMatched']}),flush=True)
 finally:
  stop.set();a.close();ui.request,ui.drive,ui.session=orig
