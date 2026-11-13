import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Owns the [FrostActionRunner] of one control: frost_ui keeps a control's
/// press callback and its action state apart, so the caller holds the state.
///
/// A control draws the succeeded or failed glyph after its action. Where the
/// action reports its result somewhere else (a toast, a dialog, a status row),
/// set [showsResult] to false: the control then shows only the running state.
///
/// ```dart
/// ActionRunnerBuilder(
///   builder: (context, runner) => FrostButton(
///     label: label,
///     onPressed: () => runner.run(action),
///     state: runner.state,
///   ),
/// )
/// ```
class ActionRunnerBuilder extends StatefulWidget {
  const ActionRunnerBuilder({
    required this.builder,
    this.showsResult = true,
    super.key,
  });
  final Widget Function(BuildContext context, FrostActionRunner runner) builder;

  /// Whether the control keeps a succeeded or failed glyph after the action.
  final bool showsResult;

  @override
  State<ActionRunnerBuilder> createState() => _ActionRunnerBuilderState();
}

class _ActionRunnerBuilderState extends State<ActionRunnerBuilder> {
  late final FrostActionRunner _runner = widget.showsResult
      ? FrostActionRunner()
      : _RunningOnlyRunner();

  @override
  void dispose() {
    _runner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _runner,
    builder: (context, _) => widget.builder(context, _runner),
  );
}

/// A runner that is running or idle, and never keeps a result: the same
/// contract as [FrostActionRunner] without its succeeded and failed states.
class _RunningOnlyRunner extends FrostActionRunner {
  FrostActionState _state = FrostActionState.idle;
  bool _running = false;
  bool _disposed = false;

  @override
  FrostActionState get state => _state;

  @override
  Future<void> run(Future<bool> Function() action) async {
    if (_running) return;
    _running = true;
    _set(const FrostActionState.running());
    try {
      await action();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'booruflow',
          context: ErrorDescription('while running a control action'),
        ),
      );
    } finally {
      _running = false;
      _set(FrostActionState.idle);
    }
  }

  @override
  void cancel() => _set(FrostActionState.idle);

  void _set(FrostActionState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
