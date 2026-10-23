"""Scoped emulator client: internal Flutter RPC, adb-only device evidence."""
import os,subprocess,json,urllib.request,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SERIAL=os.environ.get('BOORUFLOW_ANDROID_SERIAL','emulator-5580');RPC_PORT=int(os.environ.get('BOORUFLOW_ANDROID_RPC_PORT','9416'));PACKAGE='io.github.normalllll.booruflow'
ADB='V:/SDK/Android/platform-tools/adb.exe'
DEST=Path('V:/Code/frost_ui/docs/screenshots/booruflow-preview-rework/android')
ENV=os.environ.copy();ENV['ANDROID_USER_HOME']=str(ROOT/'build/android-validation')
def adb(*args,timeout=45):
 p=subprocess.run([ADB,'-s',SERIAL,*map(str,args)],env=ENV,capture_output=True,timeout=timeout);p.check_returncode();return p.stdout
def request(command,**kwargs):
 data=json.dumps({'command':command,**kwargs}).encode()
 req=urllib.request.Request(f'http://127.0.0.1:{RPC_PORT}',data=data,headers={'Content-Type':'application/json'})
 return json.loads(urllib.request.urlopen(req,timeout=20).read())
def wait_ready():
 for _ in range(30):
  try:return request('state')
  except Exception:time.sleep(1)
 raise RuntimeError('Android internal controls did not start')
def install(extra_fixtures=None):
 print('boot',adb('shell','getprop','sys.boot_completed'),flush=True)
 (ROOT/'build/android-validation/meminfo-before.txt').write_bytes(adb('shell','dumpsys','meminfo'))
 print(adb('install','-r',ROOT/'build/app/outputs/flutter-apk/app-debug.apk').decode(),flush=True)
 adb('shell','am','force-stop',PACKAGE);adb('shell','run-as',PACKAGE,'mkdir','-p','files/r5-fixtures')
 for file in (ROOT/'test/fixtures/media').iterdir():
  if file.is_file():
   adb('push',file,'/data/local/tmp/'+file.name)
   adb('shell','run-as',PACKAGE,'cp','/data/local/tmp/'+file.name,'files/r5-fixtures/'+file.name)
 for source,name in (extra_fixtures or {}).items():
  adb('push',source,'/data/local/tmp/'+name)
  adb('shell','run-as',PACKAGE,'cp','/data/local/tmp/'+name,'files/r5-fixtures/'+name)
 fixture=ROOT/'build/android-validation/booruflow-ui-fixture-x64.apk'
 if not fixture.is_file(): raise RuntimeError('Build the dedicated Android AOT fixture first; production APK is never used here')
 print(adb('install','-r',fixture).decode(),flush=True)
 adb('forward','--no-rebind',f'tcp:{RPC_PORT}','tcp:9415')
 print(adb('shell','am','start','-n',PACKAGE+'/.MainActivity').decode(),flush=True)
 print(wait_ready(),flush=True)
def shot(name):
 DEST.mkdir(parents=True,exist_ok=True)
 request('refresh')
 path=DEST/(name+'.png');path.write_bytes(adb('exec-out','screencap','-p'));return str(path)
def tap(label):
 rows=[b for b in request('buttons') if b['label']==label and b['width']>0 and b.get('hitTestable',True)]
 assert rows,(label,request('buttons'))
 b=rows[-1];request('pointer',action='tap',x=b['x'],y=b['y'])
def board(name):
 request('board',board=name)
 for _ in range(8):
  request('pumpFrames',count=10)
  if request('buttons'):break
if __name__=='__main__':install()
