import 'package:booruflow/intl/translations.g.dart';
import 'package:intl/intl.dart';

String formatCount(int value) => NumberFormat.decimalPattern(
  LocaleSettings.currentLocale.languageTag,
).format(value);

/// A count shortened for a tight place, such as 1.2M or 120万.
String formatCompactCount(int value) => NumberFormat.compact(
  locale: LocaleSettings.currentLocale.languageTag,
).format(value);
