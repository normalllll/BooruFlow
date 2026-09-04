import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';

void main() {
  for (final constraints in [
    const BoxConstraints.tightFor(width: 32, height: 32),
    const BoxConstraints(maxWidth: 32, maxHeight: 32),
    const BoxConstraints(minWidth: 48, minHeight: 48),
    null,
  ]) {
    testWidgets('copy button respects $constraints under Material 3', (
      tester,
    ) async {
      var copied = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            visualDensity: VisualDensity.compact,
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: Row(
                  children: [
                    const SizedBox(width: 94, child: Text('Source')),
                    const Expanded(
                      child: Text(
                        'A long source URL',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AppIconButton(
                      constraints: constraints,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => copied = true,
                      icon: const Icon(Icons.content_copy_outlined, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(AppIconButton));
      expect(copied, isTrue);
    });
  }
}
