import 'package:booruflow/app/frost_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../../features/discovery/home_page_test.dart' show browseTestApp;

void main() {
  for (final (size, scale) in [
    (FrostControlSize.compact, 1.0),
    (FrostControlSize.compact, 2.0),
    (FrostControlSize.regular, 1.0),
    (FrostControlSize.large, 1.0),
  ]) {
    testWidgets('shared copy icon fits the source row at $size/$scale', (
      tester,
    ) async {
      var copied = false;
      await tester.pumpWidget(
        browseTestApp(
          Center(
            child: SizedBox(
              key: const ValueKey('source-row'),
              width: 260,
              child: Row(
                children: [
                  const FrostText('Source'),
                  const SizedBox(width: FrostGap.related),
                  const Expanded(child: FrostText('A long source URL')),
                  const SizedBox(width: FrostGap.inline),
                  FrostButton.icon(
                    label: 'Copy',
                    icon: appIcons.copy,
                    size: size,
                    onPressed: () => copied = true,
                  ),
                ],
              ),
            ),
          ),
          scale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(FrostButton)).right,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const ValueKey('source-row'))).right,
        ),
      );
      await tester.tap(find.byType(FrostButton));
      expect(copied, isTrue);
    });
  }
}
