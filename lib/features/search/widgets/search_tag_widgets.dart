import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

// The preview content width includes its page insets; headers stay full width.
const searchContentMaxWidth = 800.0;

String compactCount(String count) {
  final number = int.tryParse(count);
  if (number == null) return count;
  return formatCompactCount(number);
}

String categoryLabel(TagCategory category) => switch (category) {
  TagCategory.artist => t.discovery.artist,
  TagCategory.character => t.discovery.character,
  TagCategory.copyright => t.discovery.copyright,
  TagCategory.meta => t.discovery.meta,
  TagCategory.general => t.discovery.general,
};
