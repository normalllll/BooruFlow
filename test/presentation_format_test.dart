import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocale.values) {
    test('compact metadata uses consistent uppercase units in $locale', () {
      LocaleSettings.setLocaleSync(locale);
      expect(formatCompactCount(1200000), '1.2M');
      expect(formatCompactCount(88400), '88K');
      expect(formatCompactCount(1000000), '1M');
      expect(formatCompactCount(1204), '1K');
      expect(formatCompactCount(42), '42');
      expect(formatCount(1204), isNot('1K'));
    });
  }
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
