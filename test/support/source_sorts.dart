import 'package:booruflow/src/rust/api/booru_models.dart';

const _newest = [SortOption(order: SortOrder.latest, primary: true)];

/// The sorts of a source that only orders newest first.
const newestOnlySorts = SortCapabilities(feed: _newest, search: _newest);
