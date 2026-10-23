"""Capture confirmed boards in an owned background window at the real DPR."""
from pathlib import Path
from ctypes import wintypes
import ctypes
import json
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run as ui

DESTINATION=Path('V:/Code/frost_ui/docs/screenshots/booruflow-preview-rework')
REFERENCE=Path('V:/Code/frost_ui/docs/booruflow-preview')


def place(width, height):
    # Native resize only for the exact newly started automation HWND. No raise,
    # SetForegroundWindow, SendInput or mouse/keyboard APIs are used.
    state=ui.request('state'); owned=ui.session(); native=state['native']
    if native['pid'] != owned['pid'] or native['isForeground']:
        raise RuntimeError('Refusing to resize a mismatched or foreground window')
    user=ctypes.WinDLL('user32',use_last_error=True)
    user.SetThreadDpiAwarenessContext.argtypes=[ctypes.c_void_p]
    user.SetThreadDpiAwarenessContext.restype=ctypes.c_void_p
    previous=user.SetThreadDpiAwarenessContext(ctypes.c_void_p(-4))
    user.SetWindowPos.argtypes=[wintypes.HWND,wintypes.HWND,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_int,wintypes.UINT]
    try:
        ratio=state['viewSize']['pixelRatio']; bounds=native['windowBounds']; view=state['viewSize']
        frame_width=bounds['right']-bounds['left']-view['width']
        frame_height=bounds['bottom']-bounds['top']-view['height']
        if not user.SetWindowPos(native['hwnd'],wintypes.HWND(1),40,60,
            round(width*ratio+frame_width),round(height*ratio+frame_height),0x0010):
            raise ctypes.WinError(ctypes.get_last_error())
        ui.request('refresh')
        actual=ui.request('state'); pixels=actual['viewSize']
        if abs(pixels['width']/pixels['pixelRatio']-width)>.5 or abs(pixels['height']/pixels['pixelRatio']-height)>.5:
            raise RuntimeError(f'Preview client dimensions do not match: {pixels}')
        if actual['native']['isForeground']:
            raise RuntimeError('Target became foreground; stop the walkthrough')
        return actual
    finally:
        user.SetThreadDpiAwarenessContext(previous)


def observe():
    tree=ui.drive('tree')
    return tree


def click(label):
    semantics=json.loads(ui.drive('semantics'))['tree']
    if label not in semantics: raise RuntimeError(f'Unobserved semantics: {label}')
    center=ui.drive('center','semantics',label)
    ui.request('pointer',action='tap',**center)


def visible_card():
    tree=observe()
    keys=list(dict.fromkeys(re.findall(r"PostPreviewCard-\[<'([^']+)'>\]",tree)))
    for key in keys:
        center=ui.drive('center','key',key)
        view=ui.request('state')['viewSize']
        if 160<center['y']<view['height']/view['pixelRatio']-140:
            return center
    raise RuntimeError('No observed visible media card')


def scoped(of_type, text):
    tree=observe()
    if of_type not in tree or text not in tree:
        raise RuntimeError(f'Unobserved control {of_type}: {text}')
    return json.dumps({'of':{'kind':'type','value':of_type}, 'matching':{'kind':'text','value':text}},ensure_ascii=False)


def input_query(query):
    if 'EditableText' not in observe(): raise RuntimeError('No observed text field')
    ui.drive('tap','type','EditableText')
    ui.drive('text',query)
    ui.request('pumpFrames',count=30)


def prepare_search(board):
    # Observe natural background behavior, then use framework-only focus for
    # editing. This never makes the HWND foreground; capture verifies that.
    natural=ui.request('state')
    if natural['native']['isForeground']: raise RuntimeError('Expected background')
    ui.request('pretendForeground',enabled=True)
    if board=='Q01':
        tree=observe()
        key='history-hatsune_miku rating:general'
        if key not in tree: raise RuntimeError('Expected real history row')
        ui.request('pointer',action='hover',**ui.drive('center','key',key))
    elif board in {'Q02','Q09'}:
        terms=['landscape','sky'] if board=='Q02' else ['sky']
        completed=[]
        for term in terms:
            input_query(' '.join([*completed,term]))
            ui.request('key',key='ArrowDown')
            ui.request('key',key='Enter')
            ui.request('pumpFrames',count=20)
            completed.append(term)
        input_query(' '.join([*completed,'clou']))
        ui.request('key',key='ArrowDown')
    elif board in {'Q04','Q10'}:
        input_query('landscape sky')
        ui.request('key',key='Enter')
        ui.request('pumpFrames',count=60)
        if board=='Q10': ui.drive('scroll','type','CustomScrollView','0','-160')
    elif board in {'Q05','Q06','Q11'}:
        if board=='Q11': click('更多')
        click('标签管理')
        ui.request('pumpFrames',count=50)
        if board=='Q06':
            ui.drive('tap','text','壁纸')
            ui.request('pumpFrames',count=50)
            ui.drive('tap','scoped',scoped('FrostDialog','壁纸'))
    elif board=='Q07':
        ui.drive('tap','text','查看更多')
    elif board not in {'Q03','Q08'}:
        raise ValueError(f'Search interaction missing: {board}')


def prepare_detail(board):
    for _ in range(6):
        tree=observe()
        if 'PostDetailPage' in tree: break
        ui.request('pumpFrames',count=30)
    else: raise RuntimeError('The real detail route did not mount')
    if board in {'D05','D06','D10'}:
        if board=='D06': ui.request('pretendForeground',enabled=True)
        selector=json.dumps({'of':{'kind':'type','value':'PostDetailActions'}, 'matching':{'kind':'text','value':'查看原图'}},ensure_ascii=False)
        center=ui.drive('center','scoped',selector)
        ui.request('pointer',action='tap',**center)
        ui.request('pumpFrames',count=60)
        if 'ImageZoomPage' not in observe(): raise RuntimeError('Viewer did not open')
        center=ui.drive('center','type','FrostMediaViewport')
        ui.request('pointer',action='hover',**center)
        header=ui.drive('center','scoped',json.dumps({'of':{'kind':'type','value':'ImageZoomPage'},'matching':{'kind':'type','value':'PostMediaHeader'}}))
        ui.request('pointer',action='hover',**header)
        if board=='D06':
            # Actual view controls change zoom; no direct State mutation.
            ui.request('pretendForeground',enabled=True)
            ui.request('key',key='Equal')
            ui.request('pumpFrames',count=60)
            ui.request('key',key='Equal')
            ui.request('pumpFrames',count=60)
            diagnostics=ui.request('viewportDiagnostics')
            scales=[v['scale'] for v in diagnostics['viewports']]
            if len(scales)!=1 or abs(scales[0]-2.25)>.01:
                raise RuntimeError(f'Keyboard zoom did not reach the actual transform: {diagnostics}')
            print(f'{board}: verified actual viewport scale={scales[0]}',flush=True)
            ui.request('pointer',action='remove')
            ui.request('pumpFrames',count=120)
            ui.request('pumpFrames',count=120)
    elif board=='D09':
        selector=json.dumps({'of':{'kind':'type','value':'PostDetailPage'},'matching':{'kind':'type','value':'CustomScrollView'}})
        ui.drive('scroll','scoped',selector,'0','-760')
    elif board=='D03':
        if 'cityscape' not in observe(): raise RuntimeError('No canonical tag')
        ui.drive('tap','text','cityscape')
    elif board not in {'D01','D02','D04','D07','D08'}:
        raise ValueError(f'Unsupported detail board {board}')


def prepare_downloads(board):
    if board in {'L05','L06','L07','L08'}:
        ui.request('pretendForeground',enabled=True)
        input_query('landscape sky')
        ui.request('key',key='Enter')
        ui.request('pumpFrames',count=60)
        click('批量下载')
        ui.request('pumpFrames',count=60)
        if 'BatchDownloadDialog' not in observe(): raise RuntimeError('Batch dialog did not open')
        if board!='L05':
            ui.drive('tap','text','获取图片')
            ui.request('pumpFrames',count=60)
        if board in {'L07','L08'}:
            if '文件夹名' not in observe(): raise RuntimeError('Batch has not reached ready phase')
            selector=json.dumps({'of':{'kind':'type','value':'FrostTextField'},'matching':{'kind':'type','value':'EditableText'}},ensure_ascii=False)
            ui.drive('tap','scoped',selector)
            ui.drive('text','九月收藏')
            ui.request('pumpFrames',count=30)
            if board=='L08':
                ui.drive('tap','text','加入下载队列 · 1,240 张')
                for _ in range(8):
                    ui.request('pumpFrames',count=60)
                    if '已加入 1,237 张' in observe(): break
                else: raise RuntimeError('Actual batch operation did not reach partial success')
    elif board in {'L01','L02','L03','L09','L10'}:
        for _ in range(5):
            tree=observe()
            if 'DownloadTaskTile' in tree: break
            ui.request('pumpFrames',count=30)
        else: raise RuntimeError('No mounted download tasks')
        if board=='L01':
            ui.request('pointer',action='hover',**ui.drive('center','text','#1270269'))
        elif board=='L02':
            ui.drive('tap','text','九月收藏')
            ui.drive('tap','text','#1270269')
        elif board=='L03':
            ui.drive('tap','text','失败 3')
            ui.request('pumpFrames',count=50)
            ui.request('pointer',action='hover',**ui.drive('center','text','#1268412'))
        elif board=='L09':
            ui.drive('scroll','scoped',scoped('FrostTaskRow','#391020'),'-152','0')
        elif board=='L10':
            ui.drive('tap','text','#1270269')
    elif board not in {'L04','L11'}:
        raise ValueError(f'Unsupported download board {board}')


def prepare_settings(board):
    if board=='P05':
        ui.drive('tap','text','编辑账号…')
        ui.request('pumpFrames',count=60)
        if '_AccountCredentialsForm' not in observe(): raise RuntimeError('Account form did not open')
    elif board=='P07':
        ui.drive('tap','text','自定义代理')
        ui.request('pumpFrames',count=60)
        if 'ProxySettingsPanel' not in observe(): raise RuntimeError('Proxy form did not open')
    elif board=='P10':
        ui.drive('tap','text','语言')
        ui.request('pumpFrames',count=60)
    elif not re.fullmatch(r'P(0[1-9]|1[0-5])',board):
        raise ValueError(f'Unsupported settings board {board}')


def prepare(board):
    tree=observe()
    if 'FrostPageHeader' not in tree: raise RuntimeError('Fixture has no actual page header')
    if board in {'F04','F05'}:
        ui.drive('tap','text','验证')
        ui.request('pumpFrames',count=30)
        ui.drive('tap','text','退出登录')
        ui.request('pumpFrames',count=60)
        if '退出 Danbooru 账号？' not in observe(): raise RuntimeError('Source-specific confirmation missing')
    elif board in {'F01','F02','F03','W01','W02','Main'}:
        pass
    elif board.startswith('Q'):
        prepare_search(board)
    elif board.startswith('D'):
        prepare_detail(board)
    elif board.startswith('L'):
        prepare_downloads(board)
    elif board.startswith('P'):
        prepare_settings(board)
    elif board in {'B01','B03'}:
        if board=='B03':
            ui.drive('scroll','type','CustomScrollView','0','-160')
        ui.request('pointer',action='hover' if board=='B01' else 'secondaryTap',**visible_card())
    elif board=='B04':
        click('更多');click('重新加载')
    elif board=='B05':
        ui.drive('tap','text','错误详情')
    elif board=='B08':
        click('筛选')
    elif board=='B12':
        ui.request('pointer',action='longPress',**visible_card())
    elif board not in {'B02','B06','B07','B09','B10','B11','B13'}:
        raise ValueError(f'Board interaction not implemented: {board}')
    if board in {'Q08','Q09','Q11'}: ui.request('pointer',action='remove')
    ui.request('pumpFrames', count=60)


def capture(board, only_mode=None):
    if board=='F01' and only_mode is None:
        for mode in ['light','dark']: capture(board,mode)
        return
    reference={'W01':'F02','W02':'F03'}.get(board,board)
    metadata=json.loads((REFERENCE/'canvas.json').read_text(encoding='utf-8'))['boards'][reference+'.dc.html']
    ui.start(board)
    try:
        place(metadata['w'],metadata['h'])
        prepare(board)
        for mode in ([only_mode] if only_mode else ['light'] if board.startswith('W') else ['light','dark']):
            ui.request('platformBrightness',value=mode)
            ui.request('pumpFrames', count=30)
            if board=='F01':
                ui.request('previewNotices')
                ui.request('pumpFrames',count=45)
            if 'RenderErrorBox' in observe():
                raise RuntimeError(f'{board}-{mode} contains a real Flutter error widget')
            result=ui.pair(DESTINATION/f'{board}-{mode}.png')
            native=Path(result['native']['path'])
            native.replace(DESTINATION/f'{board}-{mode}.png')
            print(f'{board}-{mode}: client={result["app"]["width"]}x{result["app"]["height"]}, DPR={result["app"]["pixelRatio"]}, probe={result["native"]["probeMatched"]}, foreground={result["native"]["isForeground"]}',flush=True)
    finally:
        if board.startswith('Q') or board=='D06' or board in {'L05','L06','L07','L08'}:
            ui.request('pretendForeground',enabled=False)
            restored=ui.request('state')
            if restored['pretendForeground'] or restored['native']['isForeground']:
                raise RuntimeError('Background focus restoration failed')
        ui.close()

if __name__=='__main__':
    import traceback
    failed=False
    for board in sys.argv[1:]:
        try: capture(board)
        except Exception:
            failed=True
            traceback.print_exc()
    raise SystemExit(1 if failed else 0)
