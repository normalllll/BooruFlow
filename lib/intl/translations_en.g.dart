///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element

class Translations with BaseTranslations<AppLocale, Translations> {
  /// Returns the current translations of the given [context].
  ///
  /// Usage:
  /// final t = Translations.of(context);
  static Translations of(BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.en,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  Translations $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => Translations(meta: meta ?? this.$meta);

  // Translations
  late final Translations$generic$en generic = Translations$generic$en.internal(
    _root,
  );
  late final Translations$booruError$en booruError =
      Translations$booruError$en.internal(_root);
  late final Translations$update$en update = Translations$update$en.internal(
    _root,
  );
  late final Translations$postList$en postList =
      Translations$postList$en.internal(_root);
  late final Translations$postDetail$en postDetail =
      Translations$postDetail$en.internal(_root);
  late final Translations$postSearch$en postSearch =
      Translations$postSearch$en.internal(_root);
  late final Translations$imageZoom$en imageZoom =
      Translations$imageZoom$en.internal(_root);
  late final Translations$downloads$en downloads =
      Translations$downloads$en.internal(_root);
  late final Translations$about$en about = Translations$about$en.internal(
    _root,
  );
  late final Translations$settings$en settings =
      Translations$settings$en.internal(_root);
  late final Translations$discovery$en discovery =
      Translations$discovery$en.internal(_root);
  late final Translations$mediaError$en mediaError =
      Translations$mediaError$en.internal(_root);
  late final Translations$webChallenge$en webChallenge =
      Translations$webChallenge$en.internal(_root);
  late final Translations$nativeWindow$en nativeWindow =
      Translations$nativeWindow$en.internal(_root);
  late final Translations$batchDownload$en batchDownload =
      Translations$batchDownload$en.internal(_root);
  late final Translations$frost$en frost = Translations$frost$en.internal(
    _root,
  );
  late final Translations$navigation$en navigation =
      Translations$navigation$en.internal(_root);
  late final Translations$settingsV2$en settingsV2 =
      Translations$settingsV2$en.internal(_root);
  late final Translations$settingsDetails$en settingsDetails =
      Translations$settingsDetails$en.internal(_root);
  late final Translations$verificationPage$en verificationPage =
      Translations$verificationPage$en.internal(_root);
  late final Translations$ugoira$en ugoira = Translations$ugoira$en.internal(
    _root,
  );
}

// Path: generic
class Translations$generic$en {
  Translations$generic$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'OK'
  String get ok => 'OK';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Clear'
  String get clear => 'Clear';

  /// en: 'Confirm'
  String get confirm => 'Confirm';

  /// en: 'Enabled'
  String get enabled => 'Enabled';

  /// en: 'Disabled'
  String get disabled => 'Disabled';

  /// en: 'Copied to clipboard: $value'
  String copiedWithValue({required Object value}) =>
      'Copied to clipboard: ${value}';

  /// en: 'An error occurred: $value'
  String errorWithValue({required Object value}) =>
      'An error occurred: ${value}';

  /// en: 'Loading'
  String get loading => 'Loading';

  /// en: 'Load failed'
  String get loadFailed => 'Load failed';

  /// en: 'Retry'
  String get retry => 'Retry';

  /// en: 'No more items'
  String get noMoreData => 'No more items';

  /// en: 'Not found'
  String get notFound => 'Not found';
}

// Path: booruError
class Translations$booruError$en {
  Translations$booruError$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'The request is invalid.'
  String get invalidRequest => 'The request is invalid.';

  /// en: 'This source does not support the requested operation.'
  String get unsupportedCapability =>
      'This source does not support the requested operation.';

  /// en: 'Sign in to this source and try again.'
  String get authenticationRequired => 'Sign in to this source and try again.';

  /// en: 'The source rejected the account credentials.'
  String get authenticationRejected =>
      'The source rejected the account credentials.';

  /// en: 'The source denied access to this resource.'
  String get permissionDenied => 'The source denied access to this resource.';

  /// en: 'The source is limiting requests. Access will resume shortly.'
  String get rateLimited =>
      'The source is limiting requests. Access will resume shortly.';

  /// en: 'The source requires browser verification. Try opening it in a browser to complete verification, or choose another source.'
  String get challengeRequired =>
      'The source requires browser verification. Try opening it in a browser to complete verification, or choose another source.';

  /// en: 'No route is available for this domain. Refresh routes in Network settings; system DNS fallback is disabled.'
  String get routeUnavailable =>
      'No route is available for this domain. Refresh routes in Network settings; system DNS fallback is disabled.';

  /// en: 'The source is currently unavailable.'
  String get sourceUnavailable => 'The source is currently unavailable.';

  /// en: 'Network request failed. Check your connection and retry.'
  String get network =>
      'Network request failed. Check your connection and retry.';

  /// en: 'The request timed out. Check your internet connection or try again later.'
  String get timeout =>
      'The request timed out. Check your internet connection or try again later.';

  /// en: 'The source returned an invalid response.'
  String get invalidResponse => 'The source returned an invalid response.';

  /// en: 'The source returned an unsafe redirect.'
  String get unsafeRedirect => 'The source returned an unsafe redirect.';

  /// en: 'The media response could not be validated or decoded.'
  String get mediaValidationFailed =>
      'The media response could not be validated or decoded.';

  /// en: 'The request was cancelled.'
  String get cancelled => 'The request was cancelled.';

  /// en: 'An internal booru engine error occurred.'
  String get internal => 'An internal booru engine error occurred.';
}

// Path: update
class Translations$update$en {
  Translations$update$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Checking for updates'
  String get checkUpdateStart => 'Checking for updates';

  /// en: 'Failed to check for updates. Please check your internet connection.'
  String get checkUpdateFailed =>
      'Failed to check for updates. Please check your internet connection.';

  /// en: 'Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project issue page.'
  String get selectDownloadUrlFailed =>
      'Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project issue page.';

  /// en: 'Version $version is available. Open About to download the update.'
  String newVersionFound({required Object version}) =>
      'Version ${version} is available. Open About to download the update.';

  /// en: 'No new version found.'
  String get noNewVersionFound => 'No new version found.';
}

// Path: postList
class Translations$postList$en {
  Translations$postList$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Home'
  String get short => 'Home';

  /// en: 'Home'
  String get title => 'Home';

  /// en: 'Posts with tags: $tags'
  String titleWithTags({required Object tags}) => 'Posts with tags: ${tags}';
}

// Path: postDetail
class Translations$postDetail$en {
  Translations$postDetail$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'View fullscreen'
  String get fullscreen => 'View fullscreen';

  /// en: 'Post not found'
  String get notFound => 'Post not found';

  /// en: '$count parent'
  String parentCount({required Object count}) => '${count} parent';

  /// en: '$count children'
  String childCount({required Object count}) => '${count} children';

  /// en: 'Zoom in'
  String get zoomIn => 'Zoom in';

  /// en: 'Zoom out'
  String get zoomOut => 'Zoom out';

  /// en: 'Original image failed to load'
  String get originalFailed => 'Original image failed to load';

  /// en: 'Showing the preview image.'
  String get previewShown => 'Showing the preview image.';

  /// en: 'Uploaded $date'
  String uploadedAt({required Object date}) => 'Uploaded ${date}';

  /// en: 'pixels'
  String get pixels => 'pixels';

  /// en: 'Dimensions'
  String get dimensions => 'Dimensions';

  /// en: 'Search this tag'
  String get searchTag => 'Search this tag';

  /// en: 'Add to search'
  String get addToSearch => 'Add to search';

  /// en: 'Exclude this tag'
  String get excludeTag => 'Exclude this tag';

  /// en: 'Open source'
  String get openSource => 'Open source';

  /// en: 'Reset zoom'
  String get resetZoom => 'Reset zoom';

  /// en: 'General'
  String get ratingGeneral => 'General';

  /// en: 'Sensitive'
  String get ratingSensitive => 'Sensitive';

  /// en: 'Questionable'
  String get ratingQuestionable => 'Questionable';

  /// en: 'Explicit'
  String get ratingExplicit => 'Explicit';

  /// en: 'Unknown'
  String get ratingUnknown => 'Unknown';

  /// en: 'Post: $id'
  String titleWithId({required Object id}) => 'Post: ${id}';

  /// en: 'Tags'
  String get tags => 'Tags';

  /// en: 'Details'
  String get details => 'Details';

  /// en: 'Actions'
  String get actions => 'Actions';

  /// en: 'Rating'
  String get rating => 'Rating';

  /// en: 'File type'
  String get fileType => 'File type';

  /// en: 'View original'
  String get viewOriginal => 'View original';

  /// en: 'Download'
  String get download => 'Download';

  /// en: 'Failed to load related images. You can retry.'
  String get relatedLoadFailed =>
      'Failed to load related images. You can retry.';

  /// en: 'Created at'
  String get createdAt => 'Created at';

  /// en: 'Author'
  String get author => 'Author';

  /// en: 'Unknown'
  String get unknownAuthor => 'Unknown';

  /// en: 'Image source'
  String get imageSource => 'Image source';

  /// en: 'Source'
  String get source => 'Source';

  /// en: 'Width'
  String get width => 'Width';

  /// en: 'Height'
  String get height => 'Height';

  /// en: 'Score'
  String get score => 'Score';

  /// en: 'Size'
  String get size => 'Size';

  /// en: 'Parent ID'
  String get parent => 'Parent ID';

  /// en: 'Has child posts'
  String get hasChildren => 'Has child posts';

  /// en: 'Related images'
  String get similarPosts => 'Related images';

  /// en: 'Parent post'
  String get parentPost => 'Parent post';

  /// en: 'Child post'
  String get childPost => 'Child post';
}

// Path: postSearch
class Translations$postSearch$en {
  Translations$postSearch$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Search'
  String get title => 'Search';
}

// Path: imageZoom
class Translations$imageZoom$en {
  Translations$imageZoom$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Zoom image'
  String get title => 'Zoom image';
}

// Path: downloads
class Translations$downloads$en {
  Translations$downloads$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'File is no longer in its original location'
  String get fileMissing => 'File is no longer in its original location';

  /// en: 'File or folder not found'
  String get locationMissing => 'File or folder not found';

  /// en: 'Download again'
  String get redownload => 'Download again';

  /// en: 'Delete'
  String get remove => 'Delete';

  /// en: 'Downloading $count items'
  String activeTasks({required Object count}) => 'Downloading ${count} items';

  /// en: '$count downloads failed'
  String failedTasks({required Object count}) => '${count} downloads failed';

  /// en: 'Retry all'
  String get retryAll => 'Retry all';

  /// en: 'Today'
  String get today => 'Today';

  /// en: 'Yesterday'
  String get yesterday => 'Yesterday';

  /// en: '$value/s'
  String transferRate({required Object value}) => '${value}/s';

  /// en: 'About $count s'
  String remainingSeconds({required Object count}) => 'About ${count} s';

  /// en: 'About $count min'
  String remainingMinutes({required Object count}) => 'About ${count} min';

  /// en: 'About $count h'
  String remainingHours({required Object count}) => 'About ${count} h';

  /// en: 'Format'
  String get format => 'Format';

  /// en: 'Started'
  String get startedAt => 'Started';

  /// en: 'Browse'
  String get browse => 'Browse';

  /// en: 'All'
  String get all => 'All';

  /// en: 'Pause'
  String get pause => 'Pause';

  /// en: 'Resume'
  String get resume => 'Resume';

  /// en: 'Pause all'
  String get pauseAll => 'Pause all';

  /// en: 'Resume all'
  String get resumeAll => 'Resume all';

  /// en: 'Retry failed tasks'
  String get retryFailed => 'Retry failed tasks';

  /// en: 'Clear completed'
  String get clearCompleted => 'Clear completed';

  /// en: 'Open download directory'
  String get openDirectory => 'Open download directory';

  /// en: 'Open post'
  String get openPost => 'Open post';

  /// en: 'Batch download'
  String get batch => 'Batch download';

  /// en: '$completed / $total'
  String batchProgress({required Object completed, required Object total}) =>
      '${completed} / ${total}';

  /// en: 'Save path'
  String get path => 'Save path';

  /// en: 'Task details'
  String get taskDetails => 'Task details';

  /// en: 'Logs'
  String get viewLog => 'Logs';

  /// en: 'Downloads'
  String get title => 'Downloads';

  /// en: 'Download tasks'
  String get tasksTitle => 'Download tasks';

  /// en: 'No download tasks'
  String get noTasks => 'No download tasks';

  /// en: 'Downloaded images will appear here.'
  String get noTasksMessage => 'Downloaded images will appear here.';

  /// en: 'Total'
  String get total => 'Total';

  /// en: 'Active'
  String get active => 'Active';

  /// en: 'Saved'
  String get saved => 'Saved';

  /// en: 'Completed'
  String get completed => 'Completed';

  /// en: 'Failed'
  String get failed => 'Failed';

  /// en: 'Waiting'
  String get waiting => 'Waiting';

  /// en: 'Downloading'
  String get downloading => 'Downloading';

  /// en: 'Needs attention'
  String get needsAttention => 'Needs attention';

  /// en: 'Queued'
  String get queued => 'Queued';

  /// en: 'Downloading'
  String get running => 'Downloading';

  /// en: 'Paused'
  String get paused => 'Paused';

  /// en: 'Downloaded'
  String get downloaded => 'Downloaded';

  /// en: 'Cancelled'
  String get cancelled => 'Cancelled';

  /// en: 'Waiting to save'
  String get savePending => 'Waiting to save';

  /// en: 'Saving'
  String get saving => 'Saving';

  /// en: 'Save failed'
  String get saveFailed => 'Save failed';

  /// en: 'Retry save'
  String get retrySave => 'Retry save';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Delete task'
  String get deleteTask => 'Delete task';

  /// en: 'Sync'
  String get sync => 'Sync';

  /// en: 'Download sync failed'
  String get syncFailed => 'Download sync failed';

  /// en: 'Download action failed'
  String get actionFailed => 'Download action failed';

  /// en: 'Expand'
  String get expand => 'Expand';

  /// en: 'Collapse'
  String get collapse => 'Collapse';

  late final Translations$downloads$messages$en messages =
      Translations$downloads$messages$en.internal(_root);
}

// Path: about
class Translations$about$en {
  Translations$about$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'About'
  String get title => 'About';

  /// en: 'Project URL'
  String get projectUrl => 'Project URL';

  /// en: 'Publish page'
  String get publishPage => 'Publish page';

  /// en: 'App version'
  String get appVersion => 'App version';

  /// en: 'Discover freepiv'
  String get freepivPromotionTitle => 'Discover freepiv';

  /// en: 'A modern, smooth, cross-platform third-party Pixiv client.'
  String get freepivPromotionSubtitle =>
      'A modern, smooth, cross-platform third-party Pixiv client.';

  /// en: 'Community'
  String get discussion => 'Community';

  /// en: 'Download update'
  String get downloadUpdate => 'Download update';

  /// en: 'Download the latest version for your device via your browser.'
  String get downloadUpdateHint =>
      'Download the latest version for your device via your browser.';
}

// Path: settings
class Translations$settings$en {
  Translations$settings$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Settings'
  String get title => 'Settings';

  /// en: 'Theme'
  String get theme => 'Theme';

  /// en: 'Language'
  String get language => 'Language';

  /// en: 'Bypass SNI'
  String get bypassSni => 'Bypass SNI';

  /// en: 'Download directory'
  String get downloadDirectory => 'Download directory';

  /// en: 'Default to platform settings'
  String get defaultToPlatformSettings => 'Default to platform settings';

  /// en: 'Images per row'
  String get columnsPerRow => 'Images per row';

  /// en: 'Concurrent downloads'
  String get maxConcurrentDownloads => 'Concurrent downloads';

  /// en: 'Segments per task'
  String get maxSegmentsPerTask => 'Segments per task';

  /// en: 'Platform default'
  String get platformDefault => 'Platform default';

  /// en: 'System'
  String get system => 'System';

  /// en: 'Light'
  String get light => 'Light';

  /// en: 'Dark'
  String get dark => 'Dark';

  /// en: 'Auto'
  String get auto => 'Auto';

  /// en: 'Save location and download concurrency'
  String get downloadsOverview => 'Save location and download concurrency';

  late final Translations$settings$sections$en sections =
      Translations$settings$sections$en.internal(_root);
  late final Translations$settings$source$en source =
      Translations$settings$source$en.internal(_root);
  late final Translations$settings$account$en account =
      Translations$settings$account$en.internal(_root);
  late final Translations$settings$network$en network =
      Translations$settings$network$en.internal(_root);
  late final Translations$settings$languageDialog$en languageDialog =
      Translations$settings$languageDialog$en.internal(_root);
  late final Translations$settings$themeModeDialog$en themeModeDialog =
      Translations$settings$themeModeDialog$en.internal(_root);
  late final Translations$settings$downloadDirectoryDialog$en
  downloadDirectoryDialog =
      Translations$settings$downloadDirectoryDialog$en.internal(_root);
  late final Translations$settings$bypassSniDialog$en bypassSniDialog =
      Translations$settings$bypassSniDialog$en.internal(_root);
  late final Translations$settings$columnsPerRowDialog$en columnsPerRowDialog =
      Translations$settings$columnsPerRowDialog$en.internal(_root);
  late final Translations$settings$maxSegmentsPerTaskDialog$en
  maxSegmentsPerTaskDialog =
      Translations$settings$maxSegmentsPerTaskDialog$en.internal(_root);
}

// Path: discovery
class Translations$discovery$en {
  Translations$discovery$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Mode'
  String get mode => 'Mode';

  /// en: 'Time range'
  String get timeRange => 'Time range';

  /// en: 'Choose date'
  String get chooseDate => 'Choose date';

  /// en: 'Week'
  String get menuWeek => 'Week';

  /// en: 'Month'
  String get menuMonth => 'Month';

  /// en: 'Content rating'
  String get ratingsTitle => 'Content rating';

  /// en: 'Rating'
  String get ratingLabel => 'Rating';

  /// en: ', '
  String get ratingSeparator => ', ';

  /// en: 'Calendar periods'
  String get calendarRanges => 'Calendar periods';

  /// en: 'Rolling periods'
  String get rollingRanges => 'Rolling periods';

  /// en: 'Too many requests'
  String get tooManyRequests => 'Too many requests';

  /// en: 'Copy link'
  String get copyLink => 'Copy link';

  /// en: 'Copy query link'
  String get copyQueryLink => 'Copy query link';

  /// en: 'Copy image'
  String get copyImage => 'Copy image';

  /// en: 'Search this artist'
  String get searchAuthor => 'Search this artist';

  /// en: 'Animated'
  String get mediaAnimation => 'Animated';

  /// en: 'Video'
  String get mediaVideo => 'Video';

  /// en: 'Related images'
  String get mediaCollection => 'Related images';

  /// en: 'Retry in $seconds s'
  String retryIn({required Object seconds}) => 'Retry in ${seconds} s';

  /// en: 'Search results'
  String get searchResults => 'Search results';

  /// en: 'Search ${count} terms'
  String searchTermsTitle({required Object count}) => 'Search ${count} terms';

  /// en: 'All available'
  String get allAvailable => 'All available';

  /// en: 'Leave all unchecked to show all content available from the current source.'
  String get defaultRatingsHint =>
      'Leave all unchecked to show all content available from the current source.';

  /// en: 'Restore defaults'
  String get resetFilters => 'Restore defaults';

  /// en: 'This source does not support the selected ratings.'
  String get unsupportedRatings =>
      'This source does not support the selected ratings.';

  /// en: 'No matching images'
  String get noFilteredPosts => 'No matching images';

  /// en: 'No posts match this search.'
  String get noSearchResults => 'No posts match this search.';

  /// en: 'This source currently has no posts to display.'
  String get noFeedPosts => 'This source currently has no posts to display.';

  /// en: 'Popular by date'
  String get historicalPopular => 'Popular by date';

  /// en: 'Day'
  String get calendarDay => 'Day';

  /// en: 'Week'
  String get calendarWeek => 'Week';

  /// en: 'Month'
  String get calendarMonth => 'Month';

  /// en: 'Latest'
  String get latest => 'Latest';

  /// en: 'Popular'
  String get popular => 'Popular';

  /// en: 'Today'
  String get today => 'Today';

  /// en: 'This week'
  String get thisWeek => 'This week';

  /// en: 'This month'
  String get thisMonth => 'This month';

  /// en: 'Last 24 hours'
  String get lastDay => 'Last 24 hours';

  /// en: 'Last 3 days'
  String get lastThreeDays => 'Last 3 days';

  /// en: 'Last week'
  String get lastWeek => 'Last week';

  /// en: 'Last month'
  String get lastMonth => 'Last month';

  /// en: 'Last 3 months'
  String get lastThreeMonths => 'Last 3 months';

  /// en: 'Last 6 months'
  String get lastSixMonths => 'Last 6 months';

  /// en: 'Last year'
  String get lastYear => 'Last year';

  /// en: 'All ranked posts loaded'
  String get rankingComplete => 'All ranked posts loaded';

  /// en: 'This source supports latest posts only.'
  String get latestFallback => 'This source supports latest posts only.';

  /// en: 'Filters'
  String get filters => 'Filters';

  /// en: 'Load more'
  String get loadMore => 'Load more';

  /// en: 'Clear'
  String get clearHistory => 'Clear';

  /// en: 'Recent searches'
  String get recentSearches => 'Recent searches';

  /// en: 'No recent searches'
  String get noRecentSearches => 'No recent searches';

  /// en: 'My tags'
  String get myTags => 'My tags';

  /// en: 'Common tags'
  String get commonTags => 'Common tags';

  /// en: 'Show more'
  String get moreTags => 'Show more';

  /// en: 'Source'
  String get tagSource => 'Source';

  /// en: 'All sources'
  String get allTagSources => 'All sources';

  /// en: 'Custom tags'
  String get manageTags => 'Custom tags';

  /// en: 'Manage'
  String get manageTagsAction => 'Manage';

  /// en: 'Add'
  String get addTagAction => 'Add';

  /// en: 'Delete'
  String get deleteTag => 'Delete';

  /// en: 'Add tag'
  String get addTag => 'Add tag';

  /// en: 'No custom tags yet'
  String get noCustomTags => 'No custom tags yet';

  /// en: 'Give frequently used tags a memorable name to find them more easily in search.'
  String get customTagsHint =>
      'Give frequently used tags a memorable name to find them more easily in search.';

  /// en: 'Add as a custom tag'
  String get addCustomTag => 'Add as a custom tag';

  /// en: 'Edit custom tag'
  String get editTag => 'Edit custom tag';

  /// en: 'Source tag'
  String get canonicalTag => 'Source tag';

  /// en: 'Display name (optional)'
  String get displayName => 'Display name (optional)';

  /// en: 'Enter one nonempty tag without spaces.'
  String get invalidTag => 'Enter one nonempty tag without spaces.';

  /// en: 'Search tags'
  String get queryHint => 'Search tags';

  /// en: 'Some tags are not verified for this source. You can still search.'
  String get unverifiedTag =>
      'Some tags are not verified for this source. You can still search.';

  /// en: 'Verified for this source'
  String get verifiedTag => 'Verified for this source';

  /// en: 'No suggestions'
  String get noSuggestions => 'No suggestions';

  /// en: 'Online suggestions unavailable; local suggestions are still available.'
  String get localFallback =>
      'Online suggestions unavailable; local suggestions are still available.';

  /// en: 'Retry common tags'
  String get retryTags => 'Retry common tags';

  /// en: 'Artist'
  String get artist => 'Artist';

  /// en: 'Character'
  String get character => 'Character';

  /// en: 'Series'
  String get copyright => 'Series';

  /// en: 'Meta'
  String get meta => 'Meta';

  /// en: 'General'
  String get general => 'General';

  /// en: 'Random'
  String get random => 'Random';

  /// en: 'Lifetime views'
  String get lifetimeViews => 'Lifetime views';

  /// en: 'Lifetime favorites'
  String get lifetimeFavorites => 'Lifetime favorites';
}

// Path: mediaError
class Translations$mediaError$en {
  Translations$mediaError$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'The selected SOCKS proxy is not supported for video; this playback attempted a direct connection.'
  String get videoProxyBypassed =>
      'The selected SOCKS proxy is not supported for video; this playback attempted a direct connection.';

  /// en: 'Video playback failed'
  String get videoFailed => 'Video playback failed';

  /// en: 'Download original file'
  String get downloadOriginal => 'Download original file';

  /// en: 'Preview unavailable'
  String get previewUnsupported => 'Preview unavailable';

  /// en: 'Image failed to load'
  String get title => 'Image failed to load';

  /// en: 'Error details'
  String get details => 'Error details';

  /// en: 'Copy details'
  String get copyDetails => 'Copy details';

  /// en: 'The downloaded image could not be decoded. Retry will clear this image’s cache and download it again.'
  String get decodeFailed =>
      'The downloaded image could not be decoded. Retry will clear this image’s cache and download it again.';
}

// Path: webChallenge
class Translations$webChallenge$en {
  Translations$webChallenge$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Web verification'
  String get title => 'Web verification';

  /// en: 'Open web verification'
  String get open => 'Open web verification';

  /// en: '$source · Close this window after verification'
  String windowTitle({required Object source}) =>
      '${source} · Close this window after verification';

  /// en: 'Complete the page's verification manually, then go back or close the window. The app will save the verification data and reload the source.'
  String get instructions =>
      'Complete the page\'s verification manually, then go back or close the window. The app will save the verification data and reload the source.';

  /// en: 'Finish and return'
  String get finish => 'Finish and return';

  /// en: 'Reading and verifying the web session'
  String get saving => 'Reading and verifying the web session';

  /// en: 'Web verification in progress'
  String get waiting => 'Web verification in progress';

  /// en: 'Clear'
  String get clear => 'Clear';

  /// en: 'Clear all web verification data'
  String get clearAll => 'Clear all web verification data';

  /// en: 'Remove cookies, browser identity and web cache.'
  String get clearDescription =>
      'Remove cookies, browser identity and web cache.';

  /// en: 'Web verification data cleared'
  String get cleared => 'Web verification data cleared';

  /// en: 'Verified and accessible'
  String get verified => 'Verified and accessible';

  /// en: 'Saved; awaiting verification'
  String get saved => 'Saved; awaiting verification';

  /// en: 'No saved verification data'
  String get empty => 'No saved verification data';

  /// en: 'Web verification did not complete. Please retry.'
  String get failed => 'Web verification did not complete. Please retry.';

  /// en: 'The page failed to load. Reopen verification or check network settings.'
  String get pageLoadFailed =>
      'The page failed to load. Reopen verification or check network settings.';

  /// en: 'The web component is unavailable on this platform.'
  String get webViewUnavailable =>
      'The web component is unavailable on this platform.';

  /// en: 'Could not open web verification.'
  String get windowFailed => 'Could not open web verification.';

  /// en: 'Microsoft Edge WebView2 Runtime was not found. Install or update it and try again.'
  String get runtimeMissing =>
      'Microsoft Edge WebView2 Runtime was not found. Install or update it and try again.';

  /// en: 'The web component does not support the current proxy settings. Change them and retry.'
  String get proxyUnsupported =>
      'The web component does not support the current proxy settings. Change them and retry.';

  /// en: 'Another web verification or cleanup is in progress.'
  String get busy => 'Another web verification or cleanup is in progress.';

  /// en: 'Web verification cancelled.'
  String get cancelled => 'Web verification cancelled.';

  /// en: 'Web verification timed out. Open the page again.'
  String get timedOut => 'Web verification timed out. Open the page again.';

  /// en: 'Verification data could not be saved or cleared. The previous session was retained.'
  String get storageFailed =>
      'Verification data could not be saved or cleared. The previous session was retained.';

  /// en: 'The web session could not be read. Open verification again.'
  String get captureFailed =>
      'The web session could not be read. Open verification again.';

  /// en: 'Web data cleanup is incomplete. Try clearing it again shortly.'
  String get cleanupFailed =>
      'Web data cleanup is incomplete. Try clearing it again shortly.';

  /// en: 'Verification was cancelled by a data clear or network settings change.'
  String get operationSuperseded =>
      'Verification was cancelled by a data clear or network settings change.';

  /// en: 'The page has not provided usable verification data. Complete verification before returning.'
  String get noCookies =>
      'The page has not provided usable verification data. Complete verification before returning.';
}

// Path: nativeWindow
class Translations$nativeWindow$en {
  Translations$nativeWindow$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Minimize'
  String get minimize => 'Minimize';

  /// en: 'Maximize'
  String get maximize => 'Maximize';

  /// en: 'Restore'
  String get restore => 'Restore';

  /// en: 'Close'
  String get close => 'Close';
}

// Path: batchDownload
class Translations$batchDownload$en {
  Translations$batchDownload$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Batch download'
  String get title => 'Batch download';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'How many images should we look for?'
  String get limitTitle => 'How many images should we look for?';

  /// en: 'Fetch matching results page by page until this limit is reached.'
  String get limitHint =>
      'Fetch matching results page by page until this limit is reached.';

  /// en: 'Maximum images to fetch'
  String get limitLabel => 'Maximum images to fetch';

  /// en: 'Enter a positive whole number.'
  String get positiveInteger => 'Enter a positive whole number.';

  /// en: 'Fetch images'
  String get start => 'Fetch images';

  /// en: '/ up to $count images'
  String fetchLimit({required Object count}) => '/ up to ${count} images';

  /// en: 'Images found so far'
  String get fetching => 'Images found so far';

  /// en: '$current / $total'
  String progress({required Object current, required Object total}) =>
      '${current} / ${total}';

  /// en: 'Fetched $current of at most $limit images'
  String fetchProgress({required Object current, required Object limit}) =>
      'Fetched ${current} of at most ${limit} images';

  /// en: 'Stop at any time and use the images already found.'
  String get stopHint => 'Stop at any time and use the images already found.';

  /// en: 'Stop fetching'
  String get stop => 'Stop fetching';

  /// en: 'images available to download'
  String get found => 'images available to download';

  /// en: 'Fetch limit reached. More matching images may be available.'
  String get limitReached =>
      'Fetch limit reached. More matching images may be available.';

  /// en: 'All matching results have been fetched.'
  String get exhausted => 'All matching results have been fetched.';

  /// en: 'Download permission is unavailable. Check the app's permissions in system settings and retry.'
  String get permissionDenied =>
      'Download permission is unavailable. Check the app\'s permissions in system settings and retry.';

  /// en: 'Could not add tasks. Check the save location and available storage, then retry.'
  String get enqueueFailed =>
      'Could not add tasks. Check the save location and available storage, then retry.';

  /// en: 'Fetching stopped. You can download the images already found.'
  String get stopped =>
      'Fetching stopped. You can download the images already found.';

  /// en: 'No matching images were found.'
  String get empty => 'No matching images were found.';

  /// en: 'The source stopped making progress. Results have been kept; retry or use them below.'
  String get stalled =>
      'The source stopped making progress. Results have been kept; retry or use them below.';

  /// en: 'Source settings changed. Close this window and start again, or use the results already found.'
  String get sessionChanged =>
      'Source settings changed. Close this window and start again, or use the results already found.';

  /// en: 'Could not finish fetching. Results have been kept; retry or use them below.'
  String get fetchFailed =>
      'Could not finish fetching. Results have been kept; retry or use them below.';

  /// en: 'Images to download'
  String get countLabel => 'Images to download';

  /// en: 'All'
  String get all => 'All';

  /// en: 'Enter 1–$max'
  String countRange({required Object max}) => 'Enter 1–${max}';

  /// en: 'Downloads the first N images in the current search order.'
  String get orderHint =>
      'Downloads the first N images in the current search order.';

  /// en: 'Folder name'
  String get folderLabel => 'Folder name';

  /// en: 'e.g. September collection'
  String get folderHint => 'e.g. September collection';

  /// en: 'Your folder'
  String get folderPlaceholder => 'Your folder';

  /// en: 'Use 1–100 characters without path separators, reserved names, leading/trailing spaces or trailing dots.'
  String get invalidFolder =>
      'Use 1–100 characters without path separators, reserved names, leading/trailing spaces or trailing dots.';

  /// en: 'Existing folders are reused; existing files are never overwritten.'
  String get folderHelp =>
      'Existing folders are reused; existing files are never overwritten.';

  /// en: 'Could not resolve the save location.'
  String get locationFailed => 'Could not resolve the save location.';

  /// en: 'Photos'
  String get photos => 'Photos';

  /// en: 'On iOS, the batch is saved in an album inside the source folder. Full Photos access is needed to reuse albums.'
  String get photosHint =>
      'On iOS, the batch is saved in an album inside the source folder. Full Photos access is needed to reuse albums.';

  /// en: 'Add to queue · $count'
  String enqueue({required Object count}) => 'Add to queue · ${count}';

  /// en: 'Adding download tasks'
  String get enqueueing => 'Adding download tasks';

  /// en: 'Preparing $current / $total images'
  String preparing({required Object current, required Object total}) =>
      'Preparing ${current} / ${total} images';

  /// en: 'Tasks added to the download queue'
  String get added => 'Tasks added to the download queue';

  /// en: 'You can close this window. Submission continues while the app is running; reopen here to see its result.'
  String get backgroundHint =>
      'You can close this window. Submission continues while the app is running; reopen here to see its result.';

  /// en: 'Follow download progress in the download list.'
  String get queueHint => 'Follow download progress in the download list.';

  /// en: '$count images could not be added.'
  String failedHint({required Object count}) =>
      '${count} images could not be added.';

  /// en: 'Retry failed items'
  String get retryFailed => 'Retry failed items';

  /// en: 'Batch: $added added to queue, $failed failed to add.'
  String queued({required Object added, required Object failed}) =>
      'Batch: ${added} added to queue, ${failed} failed to add.';

  /// en: 'Batch finished: $saved saved, $failed failed or cancelled.'
  String completed({required Object saved, required Object failed}) =>
      'Batch finished: ${saved} saved, ${failed} failed or cancelled.';

  /// en: 'Done'
  String get done => 'Done';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'First N'
  String get first => 'First N';

  /// en: '$count images added'
  String addedCount({required Object count}) => '${count} images added';

  /// en: 'Save to “$folder”'
  String savedTo({required Object folder}) => 'Save to “${folder}”';

  /// en: 'View downloads'
  String get viewDownloads => 'View downloads';
}

// Path: frost
class Translations$frost$en {
  Translations$frost$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Retry'
  String get retry => 'Retry';

  /// en: 'Error'
  String get error => 'Error';

  /// en: 'Error details'
  String get errorDetails => 'Error details';

  /// en: 'Copy details'
  String get copyDetails => 'Copy details';

  /// en: 'Copied'
  String get copied => 'Copied';

  /// en: 'Loading'
  String get loading => 'Loading';

  /// en: 'Action succeeded'
  String get actionSucceeded => 'Action succeeded';

  /// en: 'Action failed'
  String get actionFailed => 'Action failed';

  /// en: 'Couldn't load'
  String get loadFailed => 'Couldn\'t load';

  /// en: 'No items'
  String get noItems => 'No items';

  /// en: 'No more items'
  String get noMoreItems => 'No more items';

  /// en: 'Pull to refresh'
  String get pullToRefresh => 'Pull to refresh';

  /// en: 'Release to refresh'
  String get releaseToRefresh => 'Release to refresh';

  /// en: 'Refreshing'
  String get refreshing => 'Refreshing';

  /// en: 'Refresh complete'
  String get refreshComplete => 'Refresh complete';

  /// en: 'Refresh failed'
  String get refreshFailed => 'Refresh failed';

  /// en: 'Previous'
  String get previous => 'Previous';

  /// en: 'Next'
  String get next => 'Next';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'More'
  String get more => 'More';

  /// en: 'Expand sidebar'
  String get expandNavigation => 'Expand sidebar';

  /// en: 'Collapse sidebar'
  String get collapseNavigation => 'Collapse sidebar';

  /// en: 'Clear text'
  String get clearText => 'Clear text';

  /// en: 'Search'
  String get search => 'Search';

  /// en: 'No results for “$query”'
  String noResults({required Object query}) => 'No results for “${query}”';

  /// en: 'Clear search'
  String get clearSearch => 'Clear search';

  /// en: 'Dismiss'
  String get dismiss => 'Dismiss';

  /// en: 'Show more'
  String get expandText => 'Show more';

  /// en: 'Show less'
  String get collapseText => 'Show less';

  /// en: 'Show all'
  String get showAll => 'Show all';

  /// en: 'Copy'
  String get copy => 'Copy';

  /// en: 'Clear all'
  String get clearAll => 'Clear all';

  /// en: 'Show password'
  String get showPassword => 'Show password';

  /// en: 'Hide password'
  String get hidePassword => 'Hide password';

  /// en: 'Choose date'
  String get chooseDate => 'Choose date';

  /// en: 'Choose time'
  String get chooseTime => 'Choose time';

  /// en: 'Increase'
  String get increment => 'Increase';

  /// en: 'Decrease'
  String get decrement => 'Decrease';

  /// en: 'Reorder'
  String get reorderHandle => 'Reorder';

  /// en: 'Ascending'
  String get sortAscending => 'Ascending';

  /// en: 'Descending'
  String get sortDescending => 'Descending';

  /// en: 'Play'
  String get play => 'Play';

  /// en: 'Pause'
  String get pause => 'Pause';

  /// en: 'Loop'
  String get loop => 'Loop';

  /// en: 'Mute'
  String get mute => 'Mute';

  /// en: 'Unmute'
  String get unmute => 'Unmute';

  /// en: 'Full screen'
  String get fullscreen => 'Full screen';

  /// en: 'Exit full screen'
  String get exitFullscreen => 'Exit full screen';

  /// en: 'Reload'
  String get reload => 'Reload';

  /// en: 'Open in browser'
  String get openInBrowser => 'Open in browser';

  /// en: 'Minimize'
  String get minimize => 'Minimize';

  /// en: 'Maximize'
  String get maximize => 'Maximize';

  /// en: 'Restore'
  String get restore => 'Restore';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Apply'
  String get apply => 'Apply';

  /// en: 'Clear'
  String get clear => 'Clear';

  /// en: 'Choose'
  String get choose => 'Choose';

  /// en: 'Show in folder'
  String get showInFolder => 'Show in folder';

  /// en: '$count selected'
  String selectedCount({required Object count}) => '${count} selected';

  /// en: 'Page $page of $total'
  String pageOf({required Object page, required Object total}) =>
      'Page ${page} of ${total}';

  /// en: 'Select all'
  String get selectAll => 'Select all';

  /// en: 'Done'
  String get done => 'Done';

  /// en: '$position of $total'
  String itemPosition({required Object position, required Object total}) =>
      '${position} of ${total}';

  /// en: '$rows rows, $columns columns'
  String tableDimensions({required Object rows, required Object columns}) =>
      '${rows} rows, ${columns} columns';

  /// en: 'Queued'
  String get taskQueued => 'Queued';

  /// en: 'Downloading'
  String get taskRunning => 'Downloading';

  /// en: 'Paused'
  String get taskPaused => 'Paused';

  /// en: 'Completed'
  String get taskCompleted => 'Completed';

  /// en: 'Failed'
  String get taskFailed => 'Failed';

  /// en: 'Cancelled'
  String get taskCancelled => 'Cancelled';

  /// en: 'Remove'
  String get remove => 'Remove';

  /// en: 'Forward'
  String get forward => 'Forward';

  /// en: 'Stop'
  String get stop => 'Stop';

  /// en: 'Playback position'
  String get seek => 'Playback position';

  /// en: 'Send'
  String get send => 'Send';

  /// en: 'Attach'
  String get attach => 'Attach';

  /// en: 'Reading settings'
  String get readerSettings => 'Reading settings';

  /// en: 'Text size'
  String get textSize => 'Text size';

  /// en: 'Line spacing'
  String get lineSpacing => 'Line spacing';

  /// en: 'Reading progress'
  String get readingProgress => 'Reading progress';

  /// en: 'Show $count replies'
  String showReplies({required Object count}) => 'Show ${count} replies';

  /// en: '$count of $limit characters'
  String characterCount({required Object count, required Object limit}) =>
      '${count} of ${limit} characters';

  /// en: '$count more images'
  String moreMedia({required Object count}) => '${count} more images';

  /// en: '$count items'
  String navigationCount({required Object count}) => '${count} items';

  /// en: '$progress% complete'
  String navigationProgress({required Object progress}) =>
      '${progress}% complete';

  /// en: ', '
  String get listSeparator => ', ';
}

// Path: navigation
class Translations$navigation$en {
  Translations$navigation$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Browse'
  String get browse => 'Browse';

  /// en: 'Search'
  String get search => 'Search';

  /// en: 'Downloads'
  String get downloads => 'Downloads';

  /// en: 'Settings'
  String get settings => 'Settings';

  /// en: 'Browse your favorite sources'
  String get browseEmpty => 'Browse your favorite sources';

  /// en: 'Find posts by tags'
  String get searchEmpty => 'Find posts by tags';

  /// en: 'Your downloads appear here'
  String get downloadsEmpty => 'Your downloads appear here';

  /// en: 'Make BooruFlow yours'
  String get settingsEmpty => 'Make BooruFlow yours';
}

// Path: settingsV2
class Translations$settingsV2$en {
  Translations$settingsV2$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Predictive back'
  String get predictiveBack => 'Predictive back';

  /// en: 'Previews returns within the app. Returning to the home screen uses the system animation.'
  String get predictiveBackScope =>
      'Previews returns within the app. Returning to the home screen uses the system animation.';

  /// en: 'Background'
  String get background => 'Background';

  /// en: 'Blur'
  String get ambientBlur => 'Blur';

  /// en: 'Mica'
  String get mica => 'Mica';

  /// en: 'Off'
  String get backgroundOff => 'Off';

  /// en: 'Intensity'
  String get backgroundIntensity => 'Intensity';

  /// en: 'System transparency is reduced'
  String get systemTransparencyReduced => 'System transparency is reduced';

  /// en: 'Custom colour'
  String get customColour => 'Custom colour';

  /// en: 'Appearance'
  String get appearance => 'Appearance';

  /// en: 'Browsing'
  String get browsing => 'Browsing';

  /// en: 'Tone'
  String get tone => 'Tone';

  /// en: 'Neutral'
  String get neutral => 'Neutral';

  /// en: 'Cool'
  String get cool => 'Cool';

  /// en: 'Warm'
  String get warm => 'Warm';

  /// en: 'Accent colour'
  String get accent => 'Accent colour';

  /// en: 'Custom accent'
  String get customAccent => 'Custom accent';

  /// en: 'Accent HEX'
  String get customHex => 'Accent HEX';

  /// en: 'Enter a six-digit HEX colour.'
  String get invalidHex => 'Enter a six-digit HEX colour.';

  /// en: 'This accent is not readable on the current surfaces.'
  String get accentRejected =>
      'This accent is not readable on the current surfaces.';

  /// en: 'This accent has low contrast. Apply it anyway?'
  String get accentWarning => 'This accent has low contrast. Apply it anyway?';

  /// en: 'Edit account'
  String get editAccount => 'Edit account';

  /// en: 'Remove the saved credentials for this source?'
  String get signOutConfirm => 'Remove the saved credentials for this source?';

  /// en: 'Open-source licences'
  String get licenses => 'Open-source licences';

  /// en: 'Check for updates'
  String get checkUpdates => 'Check for updates';

  /// en: 'Help'
  String get help => 'Help';
}

// Path: settingsDetails
class Translations$settingsDetails$en {
  Translations$settingsDetails$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Mode'
  String get mode => 'Mode';

  /// en: 'Custom'
  String get custom => 'Custom';

  /// en: 'Change'
  String get change => 'Change';

  /// en: 'Route cache'
  String get routeCache => 'Route cache';

  /// en: '$count hosts'
  String hostCount({required Object count}) => '${count} hosts';

  /// en: 'Updated $time'
  String updatedAt({required Object time}) => 'Updated ${time}';

  /// en: 'Source status'
  String get sourceStatus => 'Source status';

  /// en: 'API and images available'
  String get apiAndImages => 'API and images available';

  /// en: 'API available · images failed'
  String get apiOnly => 'API available · images failed';

  /// en: 'Status'
  String get status => 'Status';

  /// en: 'Content'
  String get content => 'Content';

  /// en: 'Edit $source account'
  String editSourceAccount({required Object source}) =>
      'Edit ${source} account';

  /// en: 'Applies to sources, images and new downloads.'
  String get proxyApplies => 'Applies to sources, images and new downloads.';

  /// en: 'Version $version ($build)'
  String version({required Object version, required Object build}) =>
      'Version ${version} (${build})';

  /// en: 'Telegram group'
  String get communityTelegram => 'Telegram group';

  /// en: 'Discord server'
  String get communityDiscord => 'Discord server';

  /// en: 'Saved verifications'
  String get savedVerifications => 'Saved verifications';

  /// en: 'System DNS'
  String get systemDnsShort => 'System DNS';

  /// en: 'Refresh'
  String get refresh => 'Refresh';

  /// en: 'New version $version is available'
  String updateAvailable({required Object version}) =>
      'New version ${version} is available';
}

// Path: verificationPage
class Translations$verificationPage$en {
  Translations$verificationPage$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Complete the verification below, then choose Finish and return.'
  String get instructions =>
      'Complete the verification below, then choose Finish and return.';

  /// en: 'Opening webpage'
  String get opening => 'Opening webpage';

  /// en: 'Webpage failed to load'
  String get failed => 'Webpage failed to load';

  /// en: 'Verification window closed'
  String get closed => 'Verification window closed';

  /// en: 'Reopen it, or check network settings.'
  String get failureHelp => 'Reopen it, or check network settings.';

  /// en: 'Reopen'
  String get reopen => 'Reopen';

  /// en: 'Sign out of $source?'
  String signOut({required Object source}) => 'Sign out of ${source}?';

  /// en: 'Account information will be removed from this device.'
  String get signOutHelp =>
      'Account information will be removed from this device.';

  /// en: 'Added to downloads'
  String get downloadAdded => 'Added to downloads';

  /// en: 'Download failed'
  String get downloadFailed => 'Download failed';

  /// en: 'Copied link'
  String get linkCopied => 'Copied link';

  /// en: 'View'
  String get view => 'View';

  /// en: 'Network settings'
  String get networkSettings => 'Network settings';
}

// Path: ugoira
class Translations$ugoira$en {
  Translations$ugoira$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Other formats: Files › BooruFlow'
  String get iosFilesDestination => 'Other formats: Files › BooruFlow';

  /// en: 'Animated WebP and ZIP are saved to Files.'
  String get iosFormatHelp => 'Animated WebP and ZIP are saved to Files.';

  /// en: 'Album name'
  String get albumName => 'Album name';

  /// en: 'Open settings'
  String get openSettings => 'Open settings';

  /// en: 'Albums and Downloads'
  String get androidDestination => 'Albums and Downloads';

  /// en: 'Save to Photos'
  String get iosDestination => 'Save to Photos';

  /// en: 'Ugoira export'
  String get format => 'Ugoira export';

  /// en: 'Lossless animated WebP'
  String get losslessWebp => 'Lossless animated WebP';

  /// en: 'Original ZIP'
  String get originalZip => 'Original ZIP';

  /// en: 'WebP · animation'
  String get webpRecord => 'WebP · animation';

  /// en: 'ZIP · original frames'
  String get zipRecord => 'ZIP · original frames';

  /// en: 'The animation archive is invalid.'
  String get ugoiraInvalidArchive => 'The animation archive is invalid.';

  /// en: 'The animation has no frame timing metadata.'
  String get ugoiraMetadataMissing =>
      'The animation has no frame timing metadata.';

  /// en: 'The animation timing metadata is invalid.'
  String get ugoiraInvalidMetadata =>
      'The animation timing metadata is invalid.';

  /// en: 'An animation frame is missing.'
  String get ugoiraFrameMissing => 'An animation frame is missing.';

  /// en: 'An animation frame is damaged.'
  String get ugoiraFrameCorrupt => 'An animation frame is damaged.';

  /// en: 'Animation frame dimensions do not match.'
  String get ugoiraFrameSizeMismatch =>
      'Animation frame dimensions do not match.';

  /// en: 'An animation frame exceeds the size limit.'
  String get ugoiraFrameTooLarge =>
      'An animation frame exceeds the size limit.';

  /// en: 'The animation could not be encoded.'
  String get ugoiraEncodeFailed => 'The animation could not be encoded.';

  /// en: 'The encoded animation exceeds the size limit.'
  String get ugoiraOutputTooLarge =>
      'The encoded animation exceeds the size limit.';
}

// Path: downloads.messages
class Translations$downloads$messages$en {
  Translations$downloads$messages$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'You have permanently denied storage permissions.\nPlease manually enable storage permissions in settings.'
  String get storagePermanentlyDenied =>
      'You have permanently denied storage permissions.\nPlease manually enable storage permissions in settings.';

  /// en: 'You have denied storage permissions.'
  String get storageDenied => 'You have denied storage permissions.';

  /// en: 'Unable to parse device information.'
  String get deviceInfoError => 'Unable to parse device information.';

  /// en: 'You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings.'
  String get photosPermanentlyDenied =>
      'You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings.';

  /// en: 'You have denied photos permissions.'
  String get photosDenied => 'You have denied photos permissions.';

  /// en: 'The download task already exists.'
  String get downloadTaskExists => 'The download task already exists.';

  /// en: 'The image file already exists.'
  String get imageFileExists => 'The image file already exists.';

  /// en: 'Retry download task $name'
  String downloadRetryWith({required Object name}) =>
      'Retry download task ${name}';

  /// en: 'Start download task $name'
  String downloadStartWith({required Object name}) =>
      'Start download task ${name}';

  /// en: 'Download completed for task $name'
  String downloadCompletedWith({required Object name}) =>
      'Download completed for task ${name}';

  /// en: 'Download failed for task $name'
  String downloadFailedWith({required Object name}) =>
      'Download failed for task ${name}';

  /// en: 'Saving failed for task $name'
  String saveFailedWith({required Object name}) =>
      'Saving failed for task ${name}';
}

// Path: settings.sections
class Translations$settings$sections$en {
  Translations$settings$sections$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Sources & accounts'
  String get sourcesAndAccounts => 'Sources & accounts';

  /// en: 'Accounts'
  String get accounts => 'Accounts';

  /// en: 'Network'
  String get network => 'Network';

  /// en: 'General'
  String get general => 'General';

  /// en: 'Downloads'
  String get downloads => 'Downloads';
}

// Path: settings.source
class Translations$settings$source$en {
  Translations$settings$source$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Default source'
  String get defaultSource => 'Default source';

  /// en: 'Supported ratings'
  String get supportedRatings => 'Supported ratings';

  /// en: 'Content rating'
  String get safetyRating => 'Content rating';
}

// Path: settings.account
class Translations$settings$account$en {
  Translations$settings$account$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Source ratings and account settings'
  String get manageAllSubtitle => 'Source ratings and account settings';

  /// en: 'No account needed'
  String get noAccountRequired => 'No account needed';

  /// en: 'Open sign-in page'
  String get openSignInPage => 'Open sign-in page';

  /// en: 'Cookie header'
  String get cookieHeader => 'Cookie header';

  /// en: 'Stored locally on this device'
  String get storedLocally => 'Stored locally on this device';

  /// en: 'Browser User-Agent'
  String get browserUserAgent => 'Browser User-Agent';

  /// en: 'Use the same User-Agent as the signed-in browser'
  String get browserUserAgentHint =>
      'Use the same User-Agent as the signed-in browser';

  /// en: 'Required'
  String get required => 'Required';

  /// en: 'Optional'
  String get optional => 'Optional';

  /// en: 'Account actions'
  String get actions => 'Account actions';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'Verify'
  String get verify => 'Verify';

  /// en: 'Sign out'
  String get signOut => 'Sign out';

  /// en: 'Account saved'
  String get saved => 'Account saved';

  /// en: 'Could not save account'
  String get saveFailed => 'Could not save account';

  /// en: 'Account verified'
  String get verified => 'Account verified';

  /// en: 'Verification failed'
  String get verificationFailed => 'Verification failed';

  /// en: 'Username'
  String get username => 'Username';

  /// en: 'User ID'
  String get userId => 'User ID';

  /// en: 'API key'
  String get apiKey => 'API key';

  /// en: 'Status · $status'
  String statusValue({required Object status}) => 'Status · ${status}';

  late final Translations$settings$account$statuses$en statuses =
      Translations$settings$account$statuses$en.internal(_root);
}

// Path: settings.network
class Translations$settings$network$en {
  Translations$settings$network$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Custom proxy'
  String get proxyCompact => 'Custom proxy';

  /// en: 'Test'
  String get checkCompact => 'Test';

  /// en: 'Details'
  String get detailsCompact => 'Details';

  /// en: 'Advanced'
  String get advancedCompact => 'Advanced';

  /// en: 'Not tested'
  String get uncheckedCompact => 'Not tested';

  /// en: 'Testing'
  String get checkingCompact => 'Testing';

  /// en: 'API'
  String get apiShort => 'API';

  /// en: 'Images'
  String get imagesShort => 'Images';

  /// en: 'Save'
  String get saveCompact => 'Save';

  /// en: 'Protocol'
  String get proxyProtocol => 'Protocol';

  /// en: 'Host'
  String get proxyHost => 'Host';

  /// en: 'Port'
  String get proxyPort => 'Port';

  /// en: 'Reachable'
  String get proxyReachable => 'Reachable';

  /// en: 'Unreachable'
  String get proxyUnreachable => 'Unreachable';

  /// en: 'Test proxy connectivity'
  String get proxyProbe => 'Test proxy connectivity';

  /// en: 'Tests the entered proxy without saving it. Each source is checked independently.'
  String get proxyProbeHint =>
      'Tests the entered proxy without saving it. Each source is checked independently.';

  /// en: 'Available'
  String get sourceAvailable => 'Available';

  /// en: 'Partially available'
  String get sourcePartial => 'Partially available';

  /// en: 'Unavailable'
  String get sourceUnavailable => 'Unavailable';

  /// en: 'Check all'
  String get checkAllSources => 'Check all';

  /// en: 'Images: available'
  String get mediaAvailable => 'Images: available';

  /// en: 'Images: failed or no test image'
  String get mediaUnavailable => 'Images: failed or no test image';

  /// en: 'DNS route details (separate from availability)'
  String get dnsDetails => 'DNS route details (separate from availability)';

  /// en: 'Green: API and image checks passed; yellow: partially passed; red: failed. Sources run concurrently with a 26-second limit.'
  String get sourceProbeHelp =>
      'Green: API and image checks passed; yellow: partially passed; red: failed. Sources run concurrently with a 26-second limit.';

  /// en: 'DNS service'
  String get dnsProvider => 'DNS service';

  /// en: '$available available · $issues issues'
  String sourceSummary({required Object available, required Object issues}) =>
      '${available} available · ${issues} issues';

  /// en: 'Services status'
  String get servicesTitle => 'Services status';

  /// en: 'IP resolution and API availability are checked separately. API results do not guarantee every image can be downloaded.'
  String get servicesHint =>
      'IP resolution and API availability are checked separately. API results do not guarantee every image can be downloaded.';

  /// en: 'The DNS provider is used for route refresh below. System DNS mode does not use cached IPs. SNI bypass uses cached IPs without automatic fallback.'
  String get noFallback =>
      'The DNS provider is used for route refresh below. System DNS mode does not use cached IPs. SNI bypass uses cached IPs without automatic fallback.';

  /// en: 'DNS $done/$total · API $checked/$sources'
  String checkProgress({
    required Object done,
    required Object total,
    required Object checked,
    required Object sources,
  }) => 'DNS ${done}/${total} · API ${checked}/${sources}';

  /// en: 'API available: $available/$total · DNS failures: $failed'
  String checkSummary({
    required Object available,
    required Object total,
    required Object failed,
  }) => 'API available: ${available}/${total} · DNS failures: ${failed}';

  /// en: 'Reading saved status'
  String get loadingStatus => 'Reading saved status';

  /// en: 'API: checking'
  String get apiChecking => 'API: checking';

  /// en: 'API: available'
  String get apiAvailable => 'API: available';

  /// en: 'API: unavailable'
  String get apiFailed => 'API: unavailable';

  /// en: 'API: not checked'
  String get apiUnchecked => 'API: not checked';

  /// en: 'Not resolved · refresh routes to obtain IPs'
  String get dnsPending => 'Not resolved · refresh routes to obtain IPs';

  /// en: 'Resolving'
  String get dnsResolving => 'Resolving';

  /// en: 'Resolved'
  String get dnsResolved => 'Resolved';

  /// en: 'Using cached IPs · not rechecked'
  String get dnsCached => 'Using cached IPs · not rechecked';

  /// en: 'Resolution failed · no active route'
  String get dnsFailed => 'Resolution failed · no active route';

  /// en: 'Waiting to resolve'
  String get dnsQueued => 'Waiting to resolve';

  /// en: 'IP cached · updated at $time'
  String ipCachedAt({required Object time}) => 'IP cached · updated at ${time}';

  /// en: 'IP resolved · not yet saved'
  String get ipNotCached => 'IP resolved · not yet saved';

  /// en: 'Connection mode'
  String get connectionMode => 'Connection mode';

  /// en: 'Proxy URL'
  String get proxyUrl => 'Proxy URL';

  /// en: 'Custom proxy'
  String get proxyTitle => 'Custom proxy';

  /// en: 'The custom proxy takes priority and keeps normal SNI and certificate verification. SNI bypass is not combined with a proxy. The connection mode takes effect after disabling the custom proxy.'
  String get proxyModeOverride =>
      'The custom proxy takes priority and keeps normal SNI and certificate verification. SNI bypass is not combined with a proxy. The connection mode takes effect after disabling the custom proxy.';

  /// en: 'Apply'
  String get proxyApply => 'Apply';

  /// en: 'Disable proxy'
  String get proxyDisable => 'Disable proxy';

  /// en: 'Applied: $endpoint (connection not confirmed)'
  String proxyActive({required Object endpoint}) =>
      'Applied: ${endpoint} (connection not confirmed)';

  /// en: 'Not in use'
  String get proxyInactive => 'Not in use';

  /// en: 'Changes are not applied. Choose Apply to save them.'
  String get proxyPending =>
      'Changes are not applied. Choose Apply to save them.';

  /// en: 'Enter a proxy address and click the button below. Start the proxy service first. Applies to source lists, images and new download requests.'
  String get proxyHelp =>
      'Enter a proxy address and click the button below. Start the proxy service first. Applies to source lists, images and new download requests.';

  /// en: 'A custom proxy takes priority over cached IP routes. Use the source API checks below to confirm connectivity; successful DNS resolution does not test the proxy.'
  String get proxyCheckHelp =>
      'A custom proxy takes priority over cached IP routes. Use the source API checks below to confirm connectivity; successful DNS resolution does not test the proxy.';

  /// en: 'Enter a valid IP or hostname and a port from 1–65535 in separate fields. Omit the protocol and path from the address.'
  String get proxyInvalid =>
      'Enter a valid IP or hostname and a port from 1–65535 in separate fields. Omit the protocol and path from the address.';

  /// en: 'Optional · for example http://127.0.0.1:7890'
  String get proxyHint => 'Optional · for example http://127.0.0.1:7890';

  /// en: 'Apply and route cache'
  String get applyAndRouteCache => 'Apply and route cache';

  /// en: 'Apply network'
  String get apply => 'Apply network';

  /// en: 'Refresh routes'
  String get refreshRoutes => 'Refresh routes';

  /// en: 'Route cache unavailable'
  String get routeCacheUnavailable => 'Route cache unavailable';

  /// en: '$hosts hosts · revision $revision'
  String routeCacheStatus({required Object hosts, required Object revision}) =>
      '${hosts} hosts · revision ${revision}';

  /// en: 'Network settings applied'
  String get applied => 'Network settings applied';

  /// en: 'Invalid network settings'
  String get invalidSettings => 'Invalid network settings';

  /// en: 'Route refresh failed'
  String get routeRefreshFailed => 'Route refresh failed';

  /// en: 'Use system DNS'
  String get systemDns => 'Use system DNS';

  /// en: 'SNI bypass'
  String get sniBypass => 'SNI bypass';
}

// Path: settings.languageDialog
class Translations$settings$languageDialog$en {
  Translations$settings$languageDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Language'
  String get title => 'Language';
}

// Path: settings.themeModeDialog
class Translations$settings$themeModeDialog$en {
  Translations$settings$themeModeDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Theme mode'
  String get title => 'Theme mode';
}

// Path: settings.downloadDirectoryDialog
class Translations$settings$downloadDirectoryDialog$en {
  Translations$settings$downloadDirectoryDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Download directory'
  String get title => 'Download directory';

  /// en: 'Choose directory'
  String get pickerTitle => 'Choose directory';

  /// en: 'Choose directory'
  String get pick => 'Choose directory';

  late final Translations$settings$downloadDirectoryDialog$messages$en
  messages = Translations$settings$downloadDirectoryDialog$messages$en.internal(
    _root,
  );
}

// Path: settings.bypassSniDialog
class Translations$settings$bypassSniDialog$en {
  Translations$settings$bypassSniDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Bypass SNI'
  String get title => 'Bypass SNI';
}

// Path: settings.columnsPerRowDialog
class Translations$settings$columnsPerRowDialog$en {
  Translations$settings$columnsPerRowDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Images per row'
  String get title => 'Images per row';
}

// Path: settings.maxSegmentsPerTaskDialog
class Translations$settings$maxSegmentsPerTaskDialog$en {
  Translations$settings$maxSegmentsPerTaskDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Max segments per download task'
  String get title => 'Max segments per download task';
}

// Path: settings.account.statuses
class Translations$settings$account$statuses$en {
  Translations$settings$account$statuses$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Not configured'
  String get notConfigured => 'Not configured';

  /// en: 'Configured, not verified'
  String get configuredUnverified => 'Configured, not verified';

  /// en: 'Verified'
  String get verified => 'Verified';

  /// en: 'Rejected'
  String get rejected => 'Rejected';
}

// Path: settings.downloadDirectoryDialog.messages
class Translations$settings$downloadDirectoryDialog$messages$en {
  Translations$settings$downloadDirectoryDialog$messages$en.internal(
    this._root,
  );

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Directory set to platform default.'
  String get setToPlatformDefault => 'Directory set to platform default.';

  /// en: 'Directory path must be absolute.'
  String get pathNotAbsolute => 'Directory path must be absolute.';

  /// en: 'Directory path is not writable.'
  String get pathNotWritable => 'Directory path is not writable.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
          'generic.ok' => 'OK',
          'generic.cancel' => 'Cancel',
          'generic.clear' => 'Clear',
          'generic.confirm' => 'Confirm',
          'generic.enabled' => 'Enabled',
          'generic.disabled' => 'Disabled',
          'generic.copiedWithValue' =>
            ({required Object value}) => 'Copied to clipboard: ${value}',
          'generic.errorWithValue' =>
            ({required Object value}) => 'An error occurred: ${value}',
          'generic.loading' => 'Loading',
          'generic.loadFailed' => 'Load failed',
          'generic.retry' => 'Retry',
          'generic.noMoreData' => 'No more items',
          'generic.notFound' => 'Not found',
          'booruError.invalidRequest' => 'The request is invalid.',
          'booruError.unsupportedCapability' =>
            'This source does not support the requested operation.',
          'booruError.authenticationRequired' =>
            'Sign in to this source and try again.',
          'booruError.authenticationRejected' =>
            'The source rejected the account credentials.',
          'booruError.permissionDenied' =>
            'The source denied access to this resource.',
          'booruError.rateLimited' =>
            'The source is limiting requests. Access will resume shortly.',
          'booruError.challengeRequired' =>
            'The source requires browser verification. Try opening it in a browser to complete verification, or choose another source.',
          'booruError.routeUnavailable' =>
            'No route is available for this domain. Refresh routes in Network settings; system DNS fallback is disabled.',
          'booruError.sourceUnavailable' =>
            'The source is currently unavailable.',
          'booruError.network' =>
            'Network request failed. Check your connection and retry.',
          'booruError.timeout' =>
            'The request timed out. Check your internet connection or try again later.',
          'booruError.invalidResponse' =>
            'The source returned an invalid response.',
          'booruError.unsafeRedirect' =>
            'The source returned an unsafe redirect.',
          'booruError.mediaValidationFailed' =>
            'The media response could not be validated or decoded.',
          'booruError.cancelled' => 'The request was cancelled.',
          'booruError.internal' => 'An internal booru engine error occurred.',
          'update.checkUpdateStart' => 'Checking for updates',
          'update.checkUpdateFailed' =>
            'Failed to check for updates. Please check your internet connection.',
          'update.selectDownloadUrlFailed' =>
            'Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project issue page.',
          'update.newVersionFound' =>
            ({required Object version}) =>
                'Version ${version} is available. Open About to download the update.',
          'update.noNewVersionFound' => 'No new version found.',
          'postList.short' => 'Home',
          'postList.title' => 'Home',
          'postList.titleWithTags' =>
            ({required Object tags}) => 'Posts with tags: ${tags}',
          'postDetail.fullscreen' => 'View fullscreen',
          'postDetail.notFound' => 'Post not found',
          'postDetail.parentCount' =>
            ({required Object count}) => '${count} parent',
          'postDetail.childCount' =>
            ({required Object count}) => '${count} children',
          'postDetail.zoomIn' => 'Zoom in',
          'postDetail.zoomOut' => 'Zoom out',
          'postDetail.originalFailed' => 'Original image failed to load',
          'postDetail.previewShown' => 'Showing the preview image.',
          'postDetail.uploadedAt' =>
            ({required Object date}) => 'Uploaded ${date}',
          'postDetail.pixels' => 'pixels',
          'postDetail.dimensions' => 'Dimensions',
          'postDetail.searchTag' => 'Search this tag',
          'postDetail.addToSearch' => 'Add to search',
          'postDetail.excludeTag' => 'Exclude this tag',
          'postDetail.openSource' => 'Open source',
          'postDetail.resetZoom' => 'Reset zoom',
          'postDetail.ratingGeneral' => 'General',
          'postDetail.ratingSensitive' => 'Sensitive',
          'postDetail.ratingQuestionable' => 'Questionable',
          'postDetail.ratingExplicit' => 'Explicit',
          'postDetail.ratingUnknown' => 'Unknown',
          'postDetail.titleWithId' => ({required Object id}) => 'Post: ${id}',
          'postDetail.tags' => 'Tags',
          'postDetail.details' => 'Details',
          'postDetail.actions' => 'Actions',
          'postDetail.rating' => 'Rating',
          'postDetail.fileType' => 'File type',
          'postDetail.viewOriginal' => 'View original',
          'postDetail.download' => 'Download',
          'postDetail.relatedLoadFailed' =>
            'Failed to load related images. You can retry.',
          'postDetail.createdAt' => 'Created at',
          'postDetail.author' => 'Author',
          'postDetail.unknownAuthor' => 'Unknown',
          'postDetail.imageSource' => 'Image source',
          'postDetail.source' => 'Source',
          'postDetail.width' => 'Width',
          'postDetail.height' => 'Height',
          'postDetail.score' => 'Score',
          'postDetail.size' => 'Size',
          'postDetail.parent' => 'Parent ID',
          'postDetail.hasChildren' => 'Has child posts',
          'postDetail.similarPosts' => 'Related images',
          'postDetail.parentPost' => 'Parent post',
          'postDetail.childPost' => 'Child post',
          'postSearch.title' => 'Search',
          'imageZoom.title' => 'Zoom image',
          'downloads.fileMissing' =>
            'File is no longer in its original location',
          'downloads.locationMissing' => 'File or folder not found',
          'downloads.redownload' => 'Download again',
          'downloads.remove' => 'Delete',
          'downloads.activeTasks' =>
            ({required Object count}) => 'Downloading ${count} items',
          'downloads.failedTasks' =>
            ({required Object count}) => '${count} downloads failed',
          'downloads.retryAll' => 'Retry all',
          'downloads.today' => 'Today',
          'downloads.yesterday' => 'Yesterday',
          'downloads.transferRate' => ({required Object value}) => '${value}/s',
          'downloads.remainingSeconds' =>
            ({required Object count}) => 'About ${count} s',
          'downloads.remainingMinutes' =>
            ({required Object count}) => 'About ${count} min',
          'downloads.remainingHours' =>
            ({required Object count}) => 'About ${count} h',
          'downloads.format' => 'Format',
          'downloads.startedAt' => 'Started',
          'downloads.browse' => 'Browse',
          'downloads.all' => 'All',
          'downloads.pause' => 'Pause',
          'downloads.resume' => 'Resume',
          'downloads.pauseAll' => 'Pause all',
          'downloads.resumeAll' => 'Resume all',
          'downloads.retryFailed' => 'Retry failed tasks',
          'downloads.clearCompleted' => 'Clear completed',
          'downloads.openDirectory' => 'Open download directory',
          'downloads.openPost' => 'Open post',
          'downloads.batch' => 'Batch download',
          'downloads.batchProgress' =>
            ({required Object completed, required Object total}) =>
                '${completed} / ${total}',
          'downloads.path' => 'Save path',
          'downloads.taskDetails' => 'Task details',
          'downloads.viewLog' => 'Logs',
          'downloads.title' => 'Downloads',
          'downloads.tasksTitle' => 'Download tasks',
          'downloads.noTasks' => 'No download tasks',
          'downloads.noTasksMessage' => 'Downloaded images will appear here.',
          'downloads.total' => 'Total',
          'downloads.active' => 'Active',
          'downloads.saved' => 'Saved',
          'downloads.completed' => 'Completed',
          'downloads.failed' => 'Failed',
          'downloads.waiting' => 'Waiting',
          'downloads.downloading' => 'Downloading',
          'downloads.needsAttention' => 'Needs attention',
          'downloads.queued' => 'Queued',
          'downloads.running' => 'Downloading',
          'downloads.paused' => 'Paused',
          'downloads.downloaded' => 'Downloaded',
          'downloads.cancelled' => 'Cancelled',
          'downloads.savePending' => 'Waiting to save',
          'downloads.saving' => 'Saving',
          'downloads.saveFailed' => 'Save failed',
          'downloads.retrySave' => 'Retry save',
          'downloads.cancel' => 'Cancel',
          'downloads.deleteTask' => 'Delete task',
          'downloads.sync' => 'Sync',
          'downloads.syncFailed' => 'Download sync failed',
          'downloads.actionFailed' => 'Download action failed',
          'downloads.expand' => 'Expand',
          'downloads.collapse' => 'Collapse',
          'downloads.messages.storagePermanentlyDenied' =>
            'You have permanently denied storage permissions.\nPlease manually enable storage permissions in settings.',
          'downloads.messages.storageDenied' =>
            'You have denied storage permissions.',
          'downloads.messages.deviceInfoError' =>
            'Unable to parse device information.',
          'downloads.messages.photosPermanentlyDenied' =>
            'You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings.',
          'downloads.messages.photosDenied' =>
            'You have denied photos permissions.',
          'downloads.messages.downloadTaskExists' =>
            'The download task already exists.',
          'downloads.messages.imageFileExists' =>
            'The image file already exists.',
          'downloads.messages.downloadRetryWith' =>
            ({required Object name}) => 'Retry download task ${name}',
          'downloads.messages.downloadStartWith' =>
            ({required Object name}) => 'Start download task ${name}',
          'downloads.messages.downloadCompletedWith' =>
            ({required Object name}) => 'Download completed for task ${name}',
          'downloads.messages.downloadFailedWith' =>
            ({required Object name}) => 'Download failed for task ${name}',
          'downloads.messages.saveFailedWith' =>
            ({required Object name}) => 'Saving failed for task ${name}',
          'about.title' => 'About',
          'about.projectUrl' => 'Project URL',
          'about.publishPage' => 'Publish page',
          'about.appVersion' => 'App version',
          'about.freepivPromotionTitle' => 'Discover freepiv',
          'about.freepivPromotionSubtitle' =>
            'A modern, smooth, cross-platform third-party Pixiv client.',
          'about.discussion' => 'Community',
          'about.downloadUpdate' => 'Download update',
          'about.downloadUpdateHint' =>
            'Download the latest version for your device via your browser.',
          'settings.title' => 'Settings',
          'settings.theme' => 'Theme',
          'settings.language' => 'Language',
          'settings.bypassSni' => 'Bypass SNI',
          'settings.downloadDirectory' => 'Download directory',
          'settings.defaultToPlatformSettings' =>
            'Default to platform settings',
          'settings.columnsPerRow' => 'Images per row',
          'settings.maxConcurrentDownloads' => 'Concurrent downloads',
          'settings.maxSegmentsPerTask' => 'Segments per task',
          'settings.platformDefault' => 'Platform default',
          'settings.system' => 'System',
          'settings.light' => 'Light',
          'settings.dark' => 'Dark',
          'settings.auto' => 'Auto',
          'settings.downloadsOverview' =>
            'Save location and download concurrency',
          'settings.sections.sourcesAndAccounts' => 'Sources & accounts',
          'settings.sections.accounts' => 'Accounts',
          'settings.sections.network' => 'Network',
          'settings.sections.general' => 'General',
          'settings.sections.downloads' => 'Downloads',
          'settings.source.defaultSource' => 'Default source',
          'settings.source.supportedRatings' => 'Supported ratings',
          'settings.source.safetyRating' => 'Content rating',
          'settings.account.manageAllSubtitle' =>
            'Source ratings and account settings',
          'settings.account.noAccountRequired' => 'No account needed',
          'settings.account.openSignInPage' => 'Open sign-in page',
          'settings.account.cookieHeader' => 'Cookie header',
          'settings.account.storedLocally' => 'Stored locally on this device',
          'settings.account.browserUserAgent' => 'Browser User-Agent',
          'settings.account.browserUserAgentHint' =>
            'Use the same User-Agent as the signed-in browser',
          'settings.account.required' => 'Required',
          'settings.account.optional' => 'Optional',
          'settings.account.actions' => 'Account actions',
          'settings.account.save' => 'Save',
          'settings.account.verify' => 'Verify',
          'settings.account.signOut' => 'Sign out',
          'settings.account.saved' => 'Account saved',
          'settings.account.saveFailed' => 'Could not save account',
          'settings.account.verified' => 'Account verified',
          'settings.account.verificationFailed' => 'Verification failed',
          'settings.account.username' => 'Username',
          'settings.account.userId' => 'User ID',
          'settings.account.apiKey' => 'API key',
          'settings.account.statusValue' =>
            ({required Object status}) => 'Status · ${status}',
          'settings.account.statuses.notConfigured' => 'Not configured',
          'settings.account.statuses.configuredUnverified' =>
            'Configured, not verified',
          'settings.account.statuses.verified' => 'Verified',
          'settings.account.statuses.rejected' => 'Rejected',
          'settings.network.proxyCompact' => 'Custom proxy',
          'settings.network.checkCompact' => 'Test',
          'settings.network.detailsCompact' => 'Details',
          'settings.network.advancedCompact' => 'Advanced',
          'settings.network.uncheckedCompact' => 'Not tested',
          'settings.network.checkingCompact' => 'Testing',
          'settings.network.apiShort' => 'API',
          'settings.network.imagesShort' => 'Images',
          'settings.network.saveCompact' => 'Save',
          'settings.network.proxyProtocol' => 'Protocol',
          'settings.network.proxyHost' => 'Host',
          'settings.network.proxyPort' => 'Port',
          'settings.network.proxyReachable' => 'Reachable',
          'settings.network.proxyUnreachable' => 'Unreachable',
          'settings.network.proxyProbe' => 'Test proxy connectivity',
          'settings.network.proxyProbeHint' =>
            'Tests the entered proxy without saving it. Each source is checked independently.',
          'settings.network.sourceAvailable' => 'Available',
          'settings.network.sourcePartial' => 'Partially available',
          'settings.network.sourceUnavailable' => 'Unavailable',
          'settings.network.checkAllSources' => 'Check all',
          'settings.network.mediaAvailable' => 'Images: available',
          'settings.network.mediaUnavailable' =>
            'Images: failed or no test image',
          'settings.network.dnsDetails' =>
            'DNS route details (separate from availability)',
          'settings.network.sourceProbeHelp' =>
            'Green: API and image checks passed; yellow: partially passed; red: failed. Sources run concurrently with a 26-second limit.',
          'settings.network.dnsProvider' => 'DNS service',
          'settings.network.sourceSummary' =>
            ({required Object available, required Object issues}) =>
                '${available} available · ${issues} issues',
          'settings.network.servicesTitle' => 'Services status',
          'settings.network.servicesHint' =>
            'IP resolution and API availability are checked separately. API results do not guarantee every image can be downloaded.',
          'settings.network.noFallback' =>
            'The DNS provider is used for route refresh below. System DNS mode does not use cached IPs. SNI bypass uses cached IPs without automatic fallback.',
          'settings.network.checkProgress' =>
            ({
              required Object done,
              required Object total,
              required Object checked,
              required Object sources,
            }) => 'DNS ${done}/${total} · API ${checked}/${sources}',
          'settings.network.checkSummary' =>
            ({
              required Object available,
              required Object total,
              required Object failed,
            }) =>
                'API available: ${available}/${total} · DNS failures: ${failed}',
          'settings.network.loadingStatus' => 'Reading saved status',
          'settings.network.apiChecking' => 'API: checking',
          'settings.network.apiAvailable' => 'API: available',
          'settings.network.apiFailed' => 'API: unavailable',
          'settings.network.apiUnchecked' => 'API: not checked',
          'settings.network.dnsPending' =>
            'Not resolved · refresh routes to obtain IPs',
          'settings.network.dnsResolving' => 'Resolving',
          'settings.network.dnsResolved' => 'Resolved',
          'settings.network.dnsCached' => 'Using cached IPs · not rechecked',
          'settings.network.dnsFailed' => 'Resolution failed · no active route',
          'settings.network.dnsQueued' => 'Waiting to resolve',
          'settings.network.ipCachedAt' =>
            ({required Object time}) => 'IP cached · updated at ${time}',
          'settings.network.ipNotCached' => 'IP resolved · not yet saved',
          'settings.network.connectionMode' => 'Connection mode',
          'settings.network.proxyUrl' => 'Proxy URL',
          'settings.network.proxyTitle' => 'Custom proxy',
          'settings.network.proxyModeOverride' =>
            'The custom proxy takes priority and keeps normal SNI and certificate verification. SNI bypass is not combined with a proxy. The connection mode takes effect after disabling the custom proxy.',
          'settings.network.proxyApply' => 'Apply',
          'settings.network.proxyDisable' => 'Disable proxy',
          'settings.network.proxyActive' =>
            ({required Object endpoint}) =>
                'Applied: ${endpoint} (connection not confirmed)',
          'settings.network.proxyInactive' => 'Not in use',
          'settings.network.proxyPending' =>
            'Changes are not applied. Choose Apply to save them.',
          'settings.network.proxyHelp' =>
            'Enter a proxy address and click the button below. Start the proxy service first. Applies to source lists, images and new download requests.',
          'settings.network.proxyCheckHelp' =>
            'A custom proxy takes priority over cached IP routes. Use the source API checks below to confirm connectivity; successful DNS resolution does not test the proxy.',
          'settings.network.proxyInvalid' =>
            'Enter a valid IP or hostname and a port from 1–65535 in separate fields. Omit the protocol and path from the address.',
          'settings.network.proxyHint' =>
            'Optional · for example http://127.0.0.1:7890',
          'settings.network.applyAndRouteCache' => 'Apply and route cache',
          'settings.network.apply' => 'Apply network',
          'settings.network.refreshRoutes' => 'Refresh routes',
          'settings.network.routeCacheUnavailable' => 'Route cache unavailable',
          'settings.network.routeCacheStatus' =>
            ({required Object hosts, required Object revision}) =>
                '${hosts} hosts · revision ${revision}',
          'settings.network.applied' => 'Network settings applied',
          'settings.network.invalidSettings' => 'Invalid network settings',
          'settings.network.routeRefreshFailed' => 'Route refresh failed',
          'settings.network.systemDns' => 'Use system DNS',
          'settings.network.sniBypass' => 'SNI bypass',
          'settings.languageDialog.title' => 'Language',
          'settings.themeModeDialog.title' => 'Theme mode',
          'settings.downloadDirectoryDialog.title' => 'Download directory',
          'settings.downloadDirectoryDialog.pickerTitle' => 'Choose directory',
          'settings.downloadDirectoryDialog.pick' => 'Choose directory',
          'settings.downloadDirectoryDialog.messages.setToPlatformDefault' =>
            'Directory set to platform default.',
          'settings.downloadDirectoryDialog.messages.pathNotAbsolute' =>
            'Directory path must be absolute.',
          'settings.downloadDirectoryDialog.messages.pathNotWritable' =>
            'Directory path is not writable.',
          'settings.bypassSniDialog.title' => 'Bypass SNI',
          'settings.columnsPerRowDialog.title' => 'Images per row',
          'settings.maxSegmentsPerTaskDialog.title' =>
            'Max segments per download task',
          'discovery.mode' => 'Mode',
          'discovery.timeRange' => 'Time range',
          'discovery.chooseDate' => 'Choose date',
          'discovery.menuWeek' => 'Week',
          'discovery.menuMonth' => 'Month',
          'discovery.ratingsTitle' => 'Content rating',
          'discovery.ratingLabel' => 'Rating',
          'discovery.ratingSeparator' => ', ',
          'discovery.calendarRanges' => 'Calendar periods',
          'discovery.rollingRanges' => 'Rolling periods',
          'discovery.tooManyRequests' => 'Too many requests',
          'discovery.copyLink' => 'Copy link',
          'discovery.copyQueryLink' => 'Copy query link',
          'discovery.copyImage' => 'Copy image',
          'discovery.searchAuthor' => 'Search this artist',
          'discovery.mediaAnimation' => 'Animated',
          'discovery.mediaVideo' => 'Video',
          'discovery.mediaCollection' => 'Related images',
          'discovery.retryIn' =>
            ({required Object seconds}) => 'Retry in ${seconds} s',
          'discovery.searchResults' => 'Search results',
          'discovery.searchTermsTitle' =>
            ({required Object count}) => 'Search ${count} terms',
          'discovery.allAvailable' => 'All available',
          'discovery.defaultRatingsHint' =>
            'Leave all unchecked to show all content available from the current source.',
          'discovery.resetFilters' => 'Restore defaults',
          'discovery.unsupportedRatings' =>
            'This source does not support the selected ratings.',
          'discovery.noFilteredPosts' => 'No matching images',
          'discovery.noSearchResults' => 'No posts match this search.',
          'discovery.noFeedPosts' =>
            'This source currently has no posts to display.',
          'discovery.historicalPopular' => 'Popular by date',
          'discovery.calendarDay' => 'Day',
          'discovery.calendarWeek' => 'Week',
          'discovery.calendarMonth' => 'Month',
          'discovery.latest' => 'Latest',
          'discovery.popular' => 'Popular',
          'discovery.today' => 'Today',
          'discovery.thisWeek' => 'This week',
          'discovery.thisMonth' => 'This month',
          'discovery.lastDay' => 'Last 24 hours',
          'discovery.lastThreeDays' => 'Last 3 days',
          'discovery.lastWeek' => 'Last week',
          'discovery.lastMonth' => 'Last month',
          'discovery.lastThreeMonths' => 'Last 3 months',
          'discovery.lastSixMonths' => 'Last 6 months',
          'discovery.lastYear' => 'Last year',
          'discovery.rankingComplete' => 'All ranked posts loaded',
          'discovery.latestFallback' =>
            'This source supports latest posts only.',
          'discovery.filters' => 'Filters',
          'discovery.loadMore' => 'Load more',
          'discovery.clearHistory' => 'Clear',
          'discovery.recentSearches' => 'Recent searches',
          'discovery.noRecentSearches' => 'No recent searches',
          'discovery.myTags' => 'My tags',
          'discovery.commonTags' => 'Common tags',
          'discovery.moreTags' => 'Show more',
          'discovery.tagSource' => 'Source',
          'discovery.allTagSources' => 'All sources',
          'discovery.manageTags' => 'Custom tags',
          'discovery.manageTagsAction' => 'Manage',
          'discovery.addTagAction' => 'Add',
          'discovery.deleteTag' => 'Delete',
          'discovery.addTag' => 'Add tag',
          'discovery.noCustomTags' => 'No custom tags yet',
          'discovery.customTagsHint' =>
            'Give frequently used tags a memorable name to find them more easily in search.',
          'discovery.addCustomTag' => 'Add as a custom tag',
          'discovery.editTag' => 'Edit custom tag',
          'discovery.canonicalTag' => 'Source tag',
          'discovery.displayName' => 'Display name (optional)',
          'discovery.invalidTag' => 'Enter one nonempty tag without spaces.',
          'discovery.queryHint' => 'Search tags',
          'discovery.unverifiedTag' =>
            'Some tags are not verified for this source. You can still search.',
          'discovery.verifiedTag' => 'Verified for this source',
          'discovery.noSuggestions' => 'No suggestions',
          'discovery.localFallback' =>
            'Online suggestions unavailable; local suggestions are still available.',
          'discovery.retryTags' => 'Retry common tags',
          'discovery.artist' => 'Artist',
          'discovery.character' => 'Character',
          'discovery.copyright' => 'Series',
          'discovery.meta' => 'Meta',
          'discovery.general' => 'General',
          'discovery.random' => 'Random',
          'discovery.lifetimeViews' => 'Lifetime views',
          'discovery.lifetimeFavorites' => 'Lifetime favorites',
          'mediaError.videoProxyBypassed' =>
            'The selected SOCKS proxy is not supported for video; this playback attempted a direct connection.',
          'mediaError.videoFailed' => 'Video playback failed',
          'mediaError.downloadOriginal' => 'Download original file',
          'mediaError.previewUnsupported' => 'Preview unavailable',
          'mediaError.title' => 'Image failed to load',
          'mediaError.details' => 'Error details',
          'mediaError.copyDetails' => 'Copy details',
          'mediaError.decodeFailed' =>
            'The downloaded image could not be decoded. Retry will clear this image’s cache and download it again.',
          'webChallenge.title' => 'Web verification',
          'webChallenge.open' => 'Open web verification',
          'webChallenge.windowTitle' =>
            ({required Object source}) =>
                '${source} · Close this window after verification',
          'webChallenge.instructions' =>
            'Complete the page\'s verification manually, then go back or close the window. The app will save the verification data and reload the source.',
          'webChallenge.finish' => 'Finish and return',
          'webChallenge.saving' => 'Reading and verifying the web session',
          'webChallenge.waiting' => 'Web verification in progress',
          'webChallenge.clear' => 'Clear',
          'webChallenge.clearAll' => 'Clear all web verification data',
          'webChallenge.clearDescription' =>
            'Remove cookies, browser identity and web cache.',
          'webChallenge.cleared' => 'Web verification data cleared',
          'webChallenge.verified' => 'Verified and accessible',
          'webChallenge.saved' => 'Saved; awaiting verification',
          'webChallenge.empty' => 'No saved verification data',
          'webChallenge.failed' =>
            'Web verification did not complete. Please retry.',
          'webChallenge.pageLoadFailed' =>
            'The page failed to load. Reopen verification or check network settings.',
          'webChallenge.webViewUnavailable' =>
            'The web component is unavailable on this platform.',
          'webChallenge.windowFailed' => 'Could not open web verification.',
          'webChallenge.runtimeMissing' =>
            'Microsoft Edge WebView2 Runtime was not found. Install or update it and try again.',
          'webChallenge.proxyUnsupported' =>
            'The web component does not support the current proxy settings. Change them and retry.',
          'webChallenge.busy' =>
            'Another web verification or cleanup is in progress.',
          'webChallenge.cancelled' => 'Web verification cancelled.',
          'webChallenge.timedOut' =>
            'Web verification timed out. Open the page again.',
          'webChallenge.storageFailed' =>
            'Verification data could not be saved or cleared. The previous session was retained.',
          'webChallenge.captureFailed' =>
            'The web session could not be read. Open verification again.',
          'webChallenge.cleanupFailed' =>
            'Web data cleanup is incomplete. Try clearing it again shortly.',
          'webChallenge.operationSuperseded' =>
            'Verification was cancelled by a data clear or network settings change.',
          'webChallenge.noCookies' =>
            'The page has not provided usable verification data. Complete verification before returning.',
          'nativeWindow.minimize' => 'Minimize',
          'nativeWindow.maximize' => 'Maximize',
          'nativeWindow.restore' => 'Restore',
          'nativeWindow.close' => 'Close',
          'batchDownload.title' => 'Batch download',
          'batchDownload.close' => 'Close',
          'batchDownload.limitTitle' => 'How many images should we look for?',
          'batchDownload.limitHint' =>
            'Fetch matching results page by page until this limit is reached.',
          'batchDownload.limitLabel' => 'Maximum images to fetch',
          'batchDownload.positiveInteger' => 'Enter a positive whole number.',
          'batchDownload.start' => 'Fetch images',
          'batchDownload.fetchLimit' =>
            ({required Object count}) => '/ up to ${count} images',
          'batchDownload.fetching' => 'Images found so far',
          'batchDownload.progress' =>
            ({required Object current, required Object total}) =>
                '${current} / ${total}',
          'batchDownload.fetchProgress' =>
            ({required Object current, required Object limit}) =>
                'Fetched ${current} of at most ${limit} images',
          'batchDownload.stopHint' =>
            'Stop at any time and use the images already found.',
          'batchDownload.stop' => 'Stop fetching',
          'batchDownload.found' => 'images available to download',
          'batchDownload.limitReached' =>
            'Fetch limit reached. More matching images may be available.',
          'batchDownload.exhausted' =>
            'All matching results have been fetched.',
          'batchDownload.permissionDenied' =>
            'Download permission is unavailable. Check the app\'s permissions in system settings and retry.',
          'batchDownload.enqueueFailed' =>
            'Could not add tasks. Check the save location and available storage, then retry.',
          'batchDownload.stopped' =>
            'Fetching stopped. You can download the images already found.',
          'batchDownload.empty' => 'No matching images were found.',
          'batchDownload.stalled' =>
            'The source stopped making progress. Results have been kept; retry or use them below.',
          'batchDownload.sessionChanged' =>
            'Source settings changed. Close this window and start again, or use the results already found.',
          'batchDownload.fetchFailed' =>
            'Could not finish fetching. Results have been kept; retry or use them below.',
          'batchDownload.countLabel' => 'Images to download',
          'batchDownload.all' => 'All',
          'batchDownload.countRange' =>
            ({required Object max}) => 'Enter 1–${max}',
          'batchDownload.orderHint' =>
            'Downloads the first N images in the current search order.',
          'batchDownload.folderLabel' => 'Folder name',
          'batchDownload.folderHint' => 'e.g. September collection',
          'batchDownload.folderPlaceholder' => 'Your folder',
          'batchDownload.invalidFolder' =>
            'Use 1–100 characters without path separators, reserved names, leading/trailing spaces or trailing dots.',
          'batchDownload.folderHelp' =>
            'Existing folders are reused; existing files are never overwritten.',
          'batchDownload.locationFailed' =>
            'Could not resolve the save location.',
          'batchDownload.photos' => 'Photos',
          'batchDownload.photosHint' =>
            'On iOS, the batch is saved in an album inside the source folder. Full Photos access is needed to reuse albums.',
          'batchDownload.enqueue' =>
            ({required Object count}) => 'Add to queue · ${count}',
          'batchDownload.enqueueing' => 'Adding download tasks',
          'batchDownload.preparing' =>
            ({required Object current, required Object total}) =>
                'Preparing ${current} / ${total} images',
          'batchDownload.added' => 'Tasks added to the download queue',
          'batchDownload.backgroundHint' =>
            'You can close this window. Submission continues while the app is running; reopen here to see its result.',
          'batchDownload.queueHint' =>
            'Follow download progress in the download list.',
          'batchDownload.failedHint' =>
            ({required Object count}) => '${count} images could not be added.',
          'batchDownload.retryFailed' => 'Retry failed items',
          'batchDownload.queued' =>
            ({required Object added, required Object failed}) =>
                'Batch: ${added} added to queue, ${failed} failed to add.',
          'batchDownload.completed' =>
            ({required Object saved, required Object failed}) =>
                'Batch finished: ${saved} saved, ${failed} failed or cancelled.',
          'batchDownload.done' => 'Done',
          'batchDownload.back' => 'Back',
          'batchDownload.first' => 'First N',
          'batchDownload.addedCount' =>
            ({required Object count}) => '${count} images added',
          'batchDownload.savedTo' =>
            ({required Object folder}) => 'Save to “${folder}”',
          'batchDownload.viewDownloads' => 'View downloads',
          'frost.retry' => 'Retry',
          'frost.error' => 'Error',
          'frost.errorDetails' => 'Error details',
          'frost.copyDetails' => 'Copy details',
          'frost.copied' => 'Copied',
          'frost.loading' => 'Loading',
          'frost.actionSucceeded' => 'Action succeeded',
          'frost.actionFailed' => 'Action failed',
          'frost.loadFailed' => 'Couldn\'t load',
          'frost.noItems' => 'No items',
          'frost.noMoreItems' => 'No more items',
          'frost.pullToRefresh' => 'Pull to refresh',
          'frost.releaseToRefresh' => 'Release to refresh',
          'frost.refreshing' => 'Refreshing',
          'frost.refreshComplete' => 'Refresh complete',
          'frost.refreshFailed' => 'Refresh failed',
          'frost.previous' => 'Previous',
          'frost.next' => 'Next',
          'frost.back' => 'Back',
          'frost.more' => 'More',
          'frost.expandNavigation' => 'Expand sidebar',
          'frost.collapseNavigation' => 'Collapse sidebar',
          'frost.clearText' => 'Clear text',
          'frost.search' => 'Search',
          'frost.noResults' =>
            ({required Object query}) => 'No results for “${query}”',
          'frost.clearSearch' => 'Clear search',
          'frost.dismiss' => 'Dismiss',
          'frost.expandText' => 'Show more',
          'frost.collapseText' => 'Show less',
          'frost.showAll' => 'Show all',
          'frost.copy' => 'Copy',
          'frost.clearAll' => 'Clear all',
          'frost.showPassword' => 'Show password',
          'frost.hidePassword' => 'Hide password',
          'frost.chooseDate' => 'Choose date',
          'frost.chooseTime' => 'Choose time',
          'frost.increment' => 'Increase',
          'frost.decrement' => 'Decrease',
          'frost.reorderHandle' => 'Reorder',
          'frost.sortAscending' => 'Ascending',
          'frost.sortDescending' => 'Descending',
          'frost.play' => 'Play',
          'frost.pause' => 'Pause',
          'frost.loop' => 'Loop',
          'frost.mute' => 'Mute',
          'frost.unmute' => 'Unmute',
          'frost.fullscreen' => 'Full screen',
          'frost.exitFullscreen' => 'Exit full screen',
          'frost.reload' => 'Reload',
          'frost.openInBrowser' => 'Open in browser',
          'frost.minimize' => 'Minimize',
          _ => null,
        } ??
        switch (path) {
          'frost.maximize' => 'Maximize',
          'frost.restore' => 'Restore',
          'frost.close' => 'Close',
          'frost.cancel' => 'Cancel',
          'frost.apply' => 'Apply',
          'frost.clear' => 'Clear',
          'frost.choose' => 'Choose',
          'frost.showInFolder' => 'Show in folder',
          'frost.selectedCount' =>
            ({required Object count}) => '${count} selected',
          'frost.pageOf' =>
            ({required Object page, required Object total}) =>
                'Page ${page} of ${total}',
          'frost.selectAll' => 'Select all',
          'frost.done' => 'Done',
          'frost.itemPosition' =>
            ({required Object position, required Object total}) =>
                '${position} of ${total}',
          'frost.tableDimensions' =>
            ({required Object rows, required Object columns}) =>
                '${rows} rows, ${columns} columns',
          'frost.taskQueued' => 'Queued',
          'frost.taskRunning' => 'Downloading',
          'frost.taskPaused' => 'Paused',
          'frost.taskCompleted' => 'Completed',
          'frost.taskFailed' => 'Failed',
          'frost.taskCancelled' => 'Cancelled',
          'frost.remove' => 'Remove',
          'frost.forward' => 'Forward',
          'frost.stop' => 'Stop',
          'frost.seek' => 'Playback position',
          'frost.send' => 'Send',
          'frost.attach' => 'Attach',
          'frost.readerSettings' => 'Reading settings',
          'frost.textSize' => 'Text size',
          'frost.lineSpacing' => 'Line spacing',
          'frost.readingProgress' => 'Reading progress',
          'frost.showReplies' =>
            ({required Object count}) => 'Show ${count} replies',
          'frost.characterCount' =>
            ({required Object count, required Object limit}) =>
                '${count} of ${limit} characters',
          'frost.moreMedia' =>
            ({required Object count}) => '${count} more images',
          'frost.navigationCount' =>
            ({required Object count}) => '${count} items',
          'frost.navigationProgress' =>
            ({required Object progress}) => '${progress}% complete',
          'frost.listSeparator' => ', ',
          'navigation.browse' => 'Browse',
          'navigation.search' => 'Search',
          'navigation.downloads' => 'Downloads',
          'navigation.settings' => 'Settings',
          'navigation.browseEmpty' => 'Browse your favorite sources',
          'navigation.searchEmpty' => 'Find posts by tags',
          'navigation.downloadsEmpty' => 'Your downloads appear here',
          'navigation.settingsEmpty' => 'Make BooruFlow yours',
          'settingsV2.predictiveBack' => 'Predictive back',
          'settingsV2.predictiveBackScope' =>
            'Previews returns within the app. Returning to the home screen uses the system animation.',
          'settingsV2.background' => 'Background',
          'settingsV2.ambientBlur' => 'Blur',
          'settingsV2.mica' => 'Mica',
          'settingsV2.backgroundOff' => 'Off',
          'settingsV2.backgroundIntensity' => 'Intensity',
          'settingsV2.systemTransparencyReduced' =>
            'System transparency is reduced',
          'settingsV2.customColour' => 'Custom colour',
          'settingsV2.appearance' => 'Appearance',
          'settingsV2.browsing' => 'Browsing',
          'settingsV2.tone' => 'Tone',
          'settingsV2.neutral' => 'Neutral',
          'settingsV2.cool' => 'Cool',
          'settingsV2.warm' => 'Warm',
          'settingsV2.accent' => 'Accent colour',
          'settingsV2.customAccent' => 'Custom accent',
          'settingsV2.customHex' => 'Accent HEX',
          'settingsV2.invalidHex' => 'Enter a six-digit HEX colour.',
          'settingsV2.accentRejected' =>
            'This accent is not readable on the current surfaces.',
          'settingsV2.accentWarning' =>
            'This accent has low contrast. Apply it anyway?',
          'settingsV2.editAccount' => 'Edit account',
          'settingsV2.signOutConfirm' =>
            'Remove the saved credentials for this source?',
          'settingsV2.licenses' => 'Open-source licences',
          'settingsV2.checkUpdates' => 'Check for updates',
          'settingsV2.help' => 'Help',
          'settingsDetails.mode' => 'Mode',
          'settingsDetails.custom' => 'Custom',
          'settingsDetails.change' => 'Change',
          'settingsDetails.routeCache' => 'Route cache',
          'settingsDetails.hostCount' =>
            ({required Object count}) => '${count} hosts',
          'settingsDetails.updatedAt' =>
            ({required Object time}) => 'Updated ${time}',
          'settingsDetails.sourceStatus' => 'Source status',
          'settingsDetails.apiAndImages' => 'API and images available',
          'settingsDetails.apiOnly' => 'API available · images failed',
          'settingsDetails.status' => 'Status',
          'settingsDetails.content' => 'Content',
          'settingsDetails.editSourceAccount' =>
            ({required Object source}) => 'Edit ${source} account',
          'settingsDetails.proxyApplies' =>
            'Applies to sources, images and new downloads.',
          'settingsDetails.version' =>
            ({required Object version, required Object build}) =>
                'Version ${version} (${build})',
          'settingsDetails.communityTelegram' => 'Telegram group',
          'settingsDetails.communityDiscord' => 'Discord server',
          'settingsDetails.savedVerifications' => 'Saved verifications',
          'settingsDetails.systemDnsShort' => 'System DNS',
          'settingsDetails.refresh' => 'Refresh',
          'settingsDetails.updateAvailable' =>
            ({required Object version}) =>
                'New version ${version} is available',
          'verificationPage.instructions' =>
            'Complete the verification below, then choose Finish and return.',
          'verificationPage.opening' => 'Opening webpage',
          'verificationPage.failed' => 'Webpage failed to load',
          'verificationPage.closed' => 'Verification window closed',
          'verificationPage.failureHelp' =>
            'Reopen it, or check network settings.',
          'verificationPage.reopen' => 'Reopen',
          'verificationPage.signOut' =>
            ({required Object source}) => 'Sign out of ${source}?',
          'verificationPage.signOutHelp' =>
            'Account information will be removed from this device.',
          'verificationPage.downloadAdded' => 'Added to downloads',
          'verificationPage.downloadFailed' => 'Download failed',
          'verificationPage.linkCopied' => 'Copied link',
          'verificationPage.view' => 'View',
          'verificationPage.networkSettings' => 'Network settings',
          'ugoira.iosFilesDestination' => 'Other formats: Files › BooruFlow',
          'ugoira.iosFormatHelp' => 'Animated WebP and ZIP are saved to Files.',
          'ugoira.albumName' => 'Album name',
          'ugoira.openSettings' => 'Open settings',
          'ugoira.androidDestination' => 'Albums and Downloads',
          'ugoira.iosDestination' => 'Save to Photos',
          'ugoira.format' => 'Ugoira export',
          'ugoira.losslessWebp' => 'Lossless animated WebP',
          'ugoira.originalZip' => 'Original ZIP',
          'ugoira.webpRecord' => 'WebP · animation',
          'ugoira.zipRecord' => 'ZIP · original frames',
          'ugoira.ugoiraInvalidArchive' => 'The animation archive is invalid.',
          'ugoira.ugoiraMetadataMissing' =>
            'The animation has no frame timing metadata.',
          'ugoira.ugoiraInvalidMetadata' =>
            'The animation timing metadata is invalid.',
          'ugoira.ugoiraFrameMissing' => 'An animation frame is missing.',
          'ugoira.ugoiraFrameCorrupt' => 'An animation frame is damaged.',
          'ugoira.ugoiraFrameSizeMismatch' =>
            'Animation frame dimensions do not match.',
          'ugoira.ugoiraFrameTooLarge' =>
            'An animation frame exceeds the size limit.',
          'ugoira.ugoiraEncodeFailed' => 'The animation could not be encoded.',
          'ugoira.ugoiraOutputTooLarge' =>
            'The encoded animation exceeds the size limit.',
          _ => null,
        };
  }
}
