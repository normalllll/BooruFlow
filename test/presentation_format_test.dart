import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inspector and list groups use the same local today and yesterday', () {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final now = DateTime(2026, 10, 19, 21, 4);
    expect(
      downloadDay(DateTime(2026, 10, 19, 0, 1), now: now),
      t.downloads.today,
    );
    expect(
      downloadDay(DateTime(2026, 10, 18, 23, 59), now: now),
      t.downloads.yesterday,
    );
    expect(
      downloadDay(DateTime(2026, 10, 17), now: now),
      isNot(anyOf(t.downloads.today, t.downloads.yesterday)),
    );
  });
}
