import 'package:booruflow/src/rust/api/booru_models.dart';

/// One categorical-palette mapping for tags, suggestions and common-tag rows.
extension TagCategoryPresentation on TagCategory {
  int get colorIndex => index;
}
