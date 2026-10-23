import 'package:booruflow/app/licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bundled Noto and Lucide licenses remain available', (
    tester,
  ) async {
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);
    registerAppLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    final noto = entries.singleWhere(
      (entry) => entry.packages.contains('Noto Sans SC'),
    );
    final lucide = entries.singleWhere(
      (entry) => entry.packages.contains('Lucide Icons'),
    );
    expect(noto.packages, contains('Noto Sans JP'));
    expect(
      noto.paragraphs.map((p) => p.text).join('\n'),
      contains('SIL OPEN FONT LICENSE'),
    );
    expect(
      lucide.paragraphs.map((p) => p.text).join('\n'),
      contains('ISC License'),
    );
    expect(lucide.packages, contains('BooruFlowIcons'));
  });
}
