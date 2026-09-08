import 'package:flutter/material.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'source_picker.dart';

/// Shared geometry keeps navigation and query editing anchored across pages.
class DiscoveryToolbar extends StatelessWidget {
  const DiscoveryToolbar({
    super.key,
    required this.sourceId,
    required this.onSource,
    this.query,
    this.action,
    this.controls = const [],
  });
  final String sourceId;
  final ValueChanged<String> onSource;
  final Widget? query;
  final Widget? action;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    final height = appFieldHeight(context);
    final actionSize = height;
    final picker = SourcePicker(
      sourceId: sourceId,
      onChanged: onSource,
      height: height,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: query == null
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                primary: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [picker, const SizedBox(width: 8), ...controls],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  picker,
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(height: height, child: query!),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(width: actionSize, height: height, child: action!),
                  ],
                ],
              ),
      ),
    );
  }
}
