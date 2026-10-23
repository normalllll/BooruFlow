import 'package:booruflow/intl/translations.g.dart';
import 'package:intl/intl.dart';

String formatCount(int value) => NumberFormat.decimalPattern(
  LocaleSettings.currentLocale.languageTag,
).format(value);

/// Compact list metadata follows one M/K convention in every app locale.
String formatCompactCount(int value) {
  if (value >= 1000000) {
    final text = (value / 1000000)
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.0$'), '');
    return '${text}M';
  }
  if (value >= 1000) return '${(value / 1000).round()}K';
  return formatCount(value);
}
