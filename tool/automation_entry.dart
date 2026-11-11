import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:booruflow/shared/app_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart'
    show simulateKeyDownEvent, simulateKeyUpEvent;

import 'sample_main.dart' show startSample;

final _user = DynamicLibrary.open('user32.dll');
final _alloc = DynamicLibrary.open('ole32.dll')
    .lookupFunction<
      Pointer<Void> Function(IntPtr),
      Pointer<Void> Function(int)
    >('CoTaskMemAlloc');
final _enumWindows = _user
    .lookupFunction<
      Int32 Function(
        Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>,
        IntPtr,
      ),
      int Function(Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>, int)
    >('EnumWindows');
const _noMoveNoZOrderNoActivate = 0x0002 | 0x0004 | 0x0010;
final _setWindowPos = _user
    .lookupFunction<
      Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
      int Function(int, int, int, int, int, int, int)
    >('SetWindowPos');
final _windowPid = _user
    .lookupFunction<
      Uint32 Function(IntPtr, Pointer<Uint32>),
      int Function(int, Pointer<Uint32>)
    >('GetWindowThreadProcessId');
final _className = _user
    .lookupFunction<
      Int32 Function(IntPtr, Pointer<Uint16>, Int32),
      int Function(int, Pointer<Uint16>, int)
    >('GetClassNameW');
final _foreground = _user.lookupFunction<IntPtr Function(), int Function()>(
  'GetForegroundWindow',
);
final _id = _alloc(4).cast<Uint32>();
final _name = _alloc(512).cast<Uint16>();
int _hwnd = 0;

int _visit(int handle, int _) {
  _windowPid(handle, _id);
  if (_id.value != pid) return 1;
  final length = _className(handle, _name, 256);
  final name = String.fromCharCodes(_name.asTypedList(length));
  if (name != 'FLUTTER_RUNNER_WIN32_WINDOW') return 1;
  _hwnd = handle;
  return 0;
}

int _window() {
  if (_hwnd != 0) return _hwnd;
  _enumWindows(
    Pointer.fromFunction<Int32 Function(IntPtr, IntPtr)>(_visit, 1),
    0,
  );
  return _hwnd;
}

bool _mouseAdded = false;

// The window handle lookups go through user32 and exist only on Windows.
Map<String, Object?> _state() => {
  'native': Platform.isWindows
      ? {
          'pid': pid,
          'hwnd': _window(),
          'isForeground': _foreground() == _window(),
        }
      : {'platform': Platform.operatingSystem, 'pid': pid},
};

Future<void> _frame() async {
  WidgetsBinding.instance.scheduleForcedFrame();
  await WidgetsBinding.instance.endOfFrame.timeout(const Duration(seconds: 3));
}

Future<Map<String, Object?>> _screenshot() async {
  await _frame();
  final view = WidgetsBinding.instance.renderViews.first;
  final ratio = view.flutterView.devicePixelRatio;
  final layer = view.debugLayer! as OffsetLayer;
  // The root layer already scales by the device ratio.
  final image = await layer.toImage(Offset.zero & (view.size * ratio));
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return {
      'png': base64Encode(bytes!.buffer.asUint8List()),
      'width': image.width,
      'height': image.height,
      'pixelRatio': ratio,
    };
  } finally {
    image.dispose();
  }
}

const _keys = {
  'Tab': LogicalKeyboardKey.tab,
  'Escape': LogicalKeyboardKey.escape,
  'Enter': LogicalKeyboardKey.enter,
  'ArrowDown': LogicalKeyboardKey.arrowDown,
  'ArrowUp': LogicalKeyboardKey.arrowUp,
};

Future<void> main() async {
  enableFlutterDriverExtension(
    enableTextEntryEmulation: false,
    handler: (message) async {
      final request = jsonDecode(message!) as Map<String, Object?>;
      switch (request['command']) {
        case 'state':
          return jsonEncode(_state());
        case 'refresh':
        case 'settle':
          await _frame();
          return jsonEncode({'refreshed': true});
        case 'appScreenshot':
          return jsonEncode(await _screenshot());
        case 'tapAt':
          final at = Offset(
            _num(request['x']).toDouble(),
            _num(request['y']).toDouble(),
          );
          GestureBinding.instance.handlePointerEvent(
            PointerDownEvent(
              pointer: 9001,
              kind: PointerDeviceKind.mouse,
              device: 9,
              position: at,
            ),
          );
          GestureBinding.instance.handlePointerEvent(
            PointerUpEvent(
              pointer: 9001,
              kind: PointerDeviceKind.mouse,
              device: 9,
              position: at,
            ),
          );
          await _frame();
          return jsonEncode(_state());
        case 'hoverAt':
          final at = Offset(
            _num(request['x']).toDouble(),
            _num(request['y']).toDouble(),
          );
          if (!_mouseAdded) {
            _mouseAdded = true;
            GestureBinding.instance.handlePointerEvent(
              PointerAddedEvent(
                kind: PointerDeviceKind.mouse,
                device: 9,
                position: at,
              ),
            );
          }
          GestureBinding.instance.handlePointerEvent(
            PointerHoverEvent(
              kind: PointerDeviceKind.mouse,
              device: 9,
              position: at,
            ),
          );
          await _frame();
          return jsonEncode(_state());
        case 'key':
          final key = _keys[request['key']]!;
          await simulateKeyDownEvent(key);
          await simulateKeyUpEvent(key);
          await _frame();
          return jsonEncode(_state());
        case 'errors':
          return jsonEncode(_errors);
        case 'toast':
          AppToast.show(request['text']! as String);
          await _frame();
          return jsonEncode(_state());
        case 'mouseDrag':
          final from = Offset(
            _num(request['x']).toDouble(),
            _num(request['y']).toDouble(),
          );
          final by = Offset(
            _num(request['dx']).toDouble(),
            _num(request['dy']).toDouble(),
          );
          const steps = 12;
          GestureBinding.instance.handlePointerEvent(
            PointerDownEvent(
              pointer: 9002,
              kind: PointerDeviceKind.mouse,
              device: 9,
              position: from,
            ),
          );
          for (var i = 1; i <= steps; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 16));
            GestureBinding.instance.handlePointerEvent(
              PointerMoveEvent(
                pointer: 9002,
                kind: PointerDeviceKind.mouse,
                device: 9,
                position: from + by * (i / steps),
                delta: by / steps.toDouble(),
              ),
            );
          }
          GestureBinding.instance.handlePointerEvent(
            PointerUpEvent(
              pointer: 9002,
              kind: PointerDeviceKind.mouse,
              device: 9,
              position: from + by,
            ),
          );
          await _frame();
          return jsonEncode(_state());
        case 'resize':
          final ratio = WidgetsBinding
              .instance
              .renderViews
              .first
              .flutterView
              .devicePixelRatio;
          _setWindowPos(
            _window(),
            0,
            0,
            0,
            (_num(request['width']) * ratio).round(),
            (_num(request['height']) * ratio).round(),
            _noMoveNoZOrderNoActivate,
          );
          await _frame();
          return jsonEncode(_state());
        default:
          throw UnsupportedError('${request['command']}');
      }
    },
  );
  final present = FlutterError.presentError;
  FlutterError.presentError = (details) {
    _errors.add(details.exceptionAsString());
    present(details);
  };
  await startSample();
}

final _errors = <String>[];

// The automation tool passes request arguments as strings.
num _num(Object? value) => value is num ? value : num.parse('$value');
