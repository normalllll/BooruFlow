// Local development entry point: export the running native Flutter frame at
// the actual view DPR, using the same RepaintBoundary path as Frost R3/R4.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:booruflow/app/bootstrap.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

Future<void> main() => bootstrap(appBuilder: (app) => _Capture(child: app));

class _Capture extends StatefulWidget {
  const _Capture({required this.child});
  final Widget child;
  @override
  State<_Capture> createState() => _CaptureState();
}

class _CaptureState extends State<_Capture> {
  final _boundary = GlobalKey();
  late final FrostAppearance _original;
  @override
  void initState() {
    super.initState();
    _original = SettingsService.appearance;
  }

  Future<void> _capture() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final dpr = View.of(context).devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: dpr);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File(
      '${Directory.systemTemp.path}/booruflow-rebuild/live.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    debugPrint(
      'Native PNG: ${boundary.size} DPR=$dpr ${image.width}x${image.height} ${file.path}',
    );
    image.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.f12, control: true, shift: true):
          _capture,
      const SingleActivator(
        LogicalKeyboardKey.f11,
        control: true,
        shift: true,
      ): () => SettingsService.saveAppearance(
        SettingsService.appearance.copyWith(
          mode: SettingsService.appearance.mode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
      ),
      const SingleActivator(
        LogicalKeyboardKey.f10,
        control: true,
        shift: true,
      ): () =>
          SettingsService.saveAppearance(_original),
    },
    child: RepaintBoundary(key: _boundary, child: widget.child),
  );
}
