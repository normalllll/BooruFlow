import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

String categoryLabel(TagCategory category) => switch (category) {
  TagCategory.artist => t.discovery.artist,
  TagCategory.character => t.discovery.character,
  TagCategory.copyright => t.discovery.copyright,
  TagCategory.meta => t.discovery.meta,
  TagCategory.general => t.discovery.general,
};
