import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/shared/app_theme.dart';

class ImmersiveSystemUi extends StatefulWidget {
  const ImmersiveSystemUi({super.key, required this.child});
  final Widget child;

  @override
  State<ImmersiveSystemUi> createState() => _ImmersiveSystemUiState();
}

class _ImmersiveSystemUiState extends State<ImmersiveSystemUi>
    with WidgetsBindingObserver {
  SystemUiOverlayStyle? _overlayStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlayStyle = appSystemUiOverlayStyle(Theme.of(context).brightness);
    if (!AppPlatform.isDesktop) {
      SystemChrome.setSystemUIOverlayStyle(_overlayStyle!);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apply();
  }

  Future<void> _apply() async {
    if (AppPlatform.isDesktop) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted && _overlayStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_overlayStyle!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _apply();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: _overlayStyle!,
    child: widget.child,
  );
}
