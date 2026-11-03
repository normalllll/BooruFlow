import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Owns the [FrostActionRunner] of one control: frost_ui keeps a control's
/// press callback and its action state apart, so the caller holds the state.
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
  const ActionRunnerBuilder({required this.builder, super.key});
  final Widget Function(BuildContext context, FrostActionRunner runner) builder;

  @override
  State<ActionRunnerBuilder> createState() => _ActionRunnerBuilderState();
}

class _ActionRunnerBuilderState extends State<ActionRunnerBuilder> {
  final _runner = FrostActionRunner();

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
