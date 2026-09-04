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
  static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
       $meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.en,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) =>
      Translations(meta: meta ?? this.$meta);

  // Translations
  late final Translations$generic$en generic = Translations$generic$en.internal(_root);
  late final Translations$booruError$en booruError = Translations$booruError$en.internal(_root);
  late final Translations$update$en update = Translations$update$en.internal(_root);
  late final Translations$postList$en postList = Translations$postList$en.internal(_root);
  late final Translations$postDetail$en postDetail = Translations$postDetail$en.internal(_root);
  late final Translations$postSearch$en postSearch = Translations$postSearch$en.internal(_root);
  late final Translations$imageZoom$en imageZoom = Translations$imageZoom$en.internal(_root);
  late final Translations$downloads$en downloads = Translations$downloads$en.internal(_root);
  late final Translations$about$en about = Translations$about$en.internal(_root);
  late final Translations$settings$en settings = Translations$settings$en.internal(_root);
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
  String copiedWithValue({required Object value}) => 'Copied to clipboard: ${value}';

  /// en: 'An error occurred: $value'
  String errorWithValue({required Object value}) => 'An error occurred: ${value}';

  /// en: '$message: $cause'
  String errorWithCause({required Object message, required Object cause}) => '${message}: ${cause}';

  /// en: 'Loading...'
  String get loading => 'Loading...';

  /// en: 'Load failed'
  String get loadFailed => 'Load failed';

  /// en: 'Retry'
  String get retry => 'Retry';

  /// en: 'No more data'
  String get noMoreData => 'No more data';

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
  String get unsupportedCapability => 'This source does not support the requested operation.';

  /// en: 'Sign in to this source and try again.'
  String get authenticationRequired => 'Sign in to this source and try again.';

  /// en: 'The source rejected the account credentials.'
  String get authenticationRejected => 'The source rejected the account credentials.';

  /// en: 'The source denied access to this resource.'
  String get permissionDenied => 'The source denied access to this resource.';

  /// en: 'The source is rate limiting requests. Try again later.'
  String get rateLimited => 'The source is rate limiting requests. Try again later.';

  /// en: 'The source requires a browser challenge or a different route.'
  String get challengeRequired => 'The source requires a browser challenge or a different route.';

  /// en: 'The source is currently unavailable.'
  String get sourceUnavailable => 'The source is currently unavailable.';

  /// en: 'The network request failed. Check the proxy or switch nodes.'
  String get network => 'The network request failed. Check the proxy or switch nodes.';

  /// en: 'The request timed out. Check the proxy or switch nodes.'
  String get timeout => 'The request timed out. Check the proxy or switch nodes.';

  /// en: 'The source returned an invalid response.'
  String get invalidResponse => 'The source returned an invalid response.';

  /// en: 'The source returned an unsafe redirect.'
  String get unsafeRedirect => 'The source returned an unsafe redirect.';

  /// en: 'The image response could not be validated or decoded.'
  String get mediaValidationFailed => 'The image response could not be validated or decoded.';

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

  /// en: 'Checking for updates...'
  String get checkUpdateStart => 'Checking for updates...';

  /// en: 'Failed to check for updates. Please check your Internet connection.'
  String get checkUpdateFailed => 'Failed to check for updates. Please check your Internet connection.';

  /// en: 'Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project Issue page.'
  String get selectDownloadUrlFailed =>
      'Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project Issue page.';

  /// en: 'New version found: $version. Please go to the About page and click Download update.'
  String newVersionFound({required Object version}) =>
      'New version found: ${version}.\nPlease go to the About page and click Download update.';

  /// en: 'No new version found.'
  String get noNewVersionFound => 'No new version found.';
}

// Path: postList
class Translations$postList$en {
  Translations$postList$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Post'
  String get short => 'Post';

  /// en: 'Post List'
  String get title => 'Post List';

  /// en: 'Posts with tags: $tags'
  String titleWithTags({required Object tags}) => 'Posts with tags: ${tags}';
}

// Path: postDetail
class Translations$postDetail$en {
  Translations$postDetail$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

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
  String get relatedLoadFailed => 'Failed to load related images. You can retry.';

  /// en: 'Created at'
  String get createdAt => 'Created at';

  /// en: 'Author'
  String get author => 'Author';

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

  /// en: 'Similar posts'
  String get similarPosts => 'Similar posts';

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

  /// en: 'Zoom Image'
  String get title => 'Zoom Image';
}

// Path: downloads
class Translations$downloads$en {
  Translations$downloads$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

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

  late final Translations$downloads$messages$en messages = Translations$downloads$messages$en.internal(_root);
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
  String get freepivPromotionSubtitle => 'A modern, smooth, cross-platform third-party Pixiv client.';

  /// en: 'Discussion'
  String get discussion => 'Discussion';

  /// en: 'Download update'
  String get downloadUpdate => 'Download update';

  /// en: 'Download the latest version for your device via your browser.'
  String get downloadUpdateHint => 'Download the latest version for your device via your browser.';
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

  /// en: 'Download Directory'
  String get downloadDirectory => 'Download Directory';

  /// en: 'Default to Platform Settings'
  String get defaultToPlatformSettings => 'Default to Platform Settings';

  /// en: 'Columns per Row'
  String get columnsPerRow => 'Columns per Row';

  /// en: 'Max Concurrent Download Tasks'
  String get maxConcurrentDownloads => 'Max Concurrent Download Tasks';

  /// en: 'Max Segments per Download Task'
  String get maxSegmentsPerTask => 'Max Segments per Download Task';

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

  /// en: 'Desktop only · one subfolder per source'
  String get downloadsOverview => 'Desktop only · one subfolder per source';

  /// en: 'Source subfolders'
  String get sourceSubfolders => 'Source subfolders';

  /// en: 'Downloads are saved in a separate folder named after each source.'
  String get sourceSubfoldersDescription => 'Downloads are saved in a separate folder named after each source.';

  late final Translations$settings$sections$en sections = Translations$settings$sections$en.internal(_root);
  late final Translations$settings$source$en source = Translations$settings$source$en.internal(_root);
  late final Translations$settings$account$en account = Translations$settings$account$en.internal(_root);
  late final Translations$settings$network$en network = Translations$settings$network$en.internal(_root);
  late final Translations$settings$languageDialog$en languageDialog = Translations$settings$languageDialog$en.internal(
    _root,
  );
  late final Translations$settings$themeModeDialog$en themeModeDialog =
      Translations$settings$themeModeDialog$en.internal(_root);
  late final Translations$settings$downloadDirectoryDialog$en downloadDirectoryDialog =
      Translations$settings$downloadDirectoryDialog$en.internal(_root);
  late final Translations$settings$bypassSniDialog$en bypassSniDialog =
      Translations$settings$bypassSniDialog$en.internal(_root);
  late final Translations$settings$columnsPerRowDialog$en columnsPerRowDialog =
      Translations$settings$columnsPerRowDialog$en.internal(_root);
  late final Translations$settings$maxConcurrentDownloadsDialog$en maxConcurrentDownloadsDialog =
      Translations$settings$maxConcurrentDownloadsDialog$en.internal(_root);
  late final Translations$settings$maxSegmentsPerTaskDialog$en maxSegmentsPerTaskDialog =
      Translations$settings$maxSegmentsPerTaskDialog$en.internal(_root);
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
  String downloadRetryWith({required Object name}) => 'Retry download task ${name}';

  /// en: 'Start download task $name'
  String downloadStartWith({required Object name}) => 'Start download task ${name}';

  /// en: 'Download completed for task $name'
  String downloadCompletedWith({required Object name}) => 'Download completed for task ${name}';

  /// en: 'Download failed for task $name'
  String downloadFailedWith({required Object name}) => 'Download failed for task ${name}';

  /// en: 'Saving failed for task $name'
  String saveFailedWith({required Object name}) => 'Saving failed for task ${name}';
}

// Path: settings.sections
class Translations$settings$sections$en {
  Translations$settings$sections$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Sources & content'
  String get sourcesAndContent => 'Sources & content';

  /// en: 'Accounts'
  String get accounts => 'Accounts';

  /// en: 'Network'
  String get network => 'Network';

  /// en: 'Appearance'
  String get appearance => 'Appearance';

  /// en: 'Downloads'
  String get downloads => 'Downloads';
}

// Path: settings.source
class Translations$settings$source$en {
  Translations$settings$source$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Source'
  String get label => 'Source';

  /// en: 'Content policy'
  String get contentPolicy => 'Content policy';

  /// en: 'Safety rating'
  String get safetyRating => 'Safety rating';

  /// en: 'No hidden default'
  String get noHiddenDefault => 'No hidden default';

  /// en: 'Leave every rating unselected to show all posts, including explicit posts.'
  String get noHiddenDefaultDescription => 'Leave every rating unselected to show all posts, including explicit posts.';

  /// en: 'Unfiltered'
  String get unfiltered => 'Unfiltered';

  /// en: 'Anime focused'
  String get animeFocused => 'Anime focused';
}

// Path: settings.account
class Translations$settings$account$en {
  Translations$settings$account$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Configure every source account independently'
  String get manageAllSubtitle => 'Configure every source account independently';

  /// en: 'Open sign-in page'
  String get openSignInPage => 'Open sign-in page';

  /// en: 'Cookie header'
  String get cookieHeader => 'Cookie header';

  /// en: 'Stored locally on this device'
  String get storedLocally => 'Stored locally on this device';

  /// en: 'Browser User-Agent'
  String get browserUserAgent => 'Browser User-Agent';

  /// en: 'Use the same User-Agent as the signed-in browser'
  String get browserUserAgentHint => 'Use the same User-Agent as the signed-in browser';

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

  late final Translations$settings$account$statuses$en statuses = Translations$settings$account$statuses$en.internal(
    _root,
  );
}

// Path: settings.network
class Translations$settings$network$en {
  Translations$settings$network$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Connection mode'
  String get connectionMode => 'Connection mode';

  /// en: 'Fall back to system DNS'
  String get fallbackToSystemDns => 'Fall back to system DNS';

  /// en: 'Proxy URL'
  String get proxyUrl => 'Proxy URL';

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
  String routeCacheStatus({required Object hosts, required Object revision}) => '${hosts} hosts · revision ${revision}';

  /// en: 'Network settings applied'
  String get applied => 'Network settings applied';

  /// en: 'Invalid network settings'
  String get invalidSettings => 'Invalid network settings';

  /// en: 'Route refresh failed'
  String get routeRefreshFailed => 'Route refresh failed';

  /// en: 'System DNS'
  String get systemDns => 'System DNS';

  /// en: 'SNI bypass'
  String get sniBypass => 'SNI bypass';

  /// en: 'Legacy IP URL'
  String get legacyIpUrl => 'Legacy IP URL';
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

  /// en: 'Theme Mode'
  String get title => 'Theme Mode';
}

// Path: settings.downloadDirectoryDialog
class Translations$settings$downloadDirectoryDialog$en {
  Translations$settings$downloadDirectoryDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Download Directory'
  String get title => 'Download Directory';

  /// en: 'Choose Directory'
  String get pickerTitle => 'Choose Directory';

  /// en: 'Choose Directory'
  String get pick => 'Choose Directory';

  late final Translations$settings$downloadDirectoryDialog$messages$en messages =
      Translations$settings$downloadDirectoryDialog$messages$en.internal(_root);
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

  /// en: 'Columns per Row'
  String get title => 'Columns per Row';
}

// Path: settings.maxConcurrentDownloadsDialog
class Translations$settings$maxConcurrentDownloadsDialog$en {
  Translations$settings$maxConcurrentDownloadsDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Max Concurrent Download Tasks'
  String get title => 'Max Concurrent Download Tasks';
}

// Path: settings.maxSegmentsPerTaskDialog
class Translations$settings$maxSegmentsPerTaskDialog$en {
  Translations$settings$maxSegmentsPerTaskDialog$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Max Segments per Download Task'
  String get title => 'Max Segments per Download Task';
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
  Translations$settings$downloadDirectoryDialog$messages$en.internal(this._root);

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
      'generic.copiedWithValue' => ({required Object value}) => 'Copied to clipboard: ${value}',
      'generic.errorWithValue' => ({required Object value}) => 'An error occurred: ${value}',
      'generic.errorWithCause' => ({required Object message, required Object cause}) => '${message}: ${cause}',
      'generic.loading' => 'Loading...',
      'generic.loadFailed' => 'Load failed',
      'generic.retry' => 'Retry',
      'generic.noMoreData' => 'No more data',
      'generic.notFound' => 'Not found',
      'booruError.invalidRequest' => 'The request is invalid.',
      'booruError.unsupportedCapability' => 'This source does not support the requested operation.',
      'booruError.authenticationRequired' => 'Sign in to this source and try again.',
      'booruError.authenticationRejected' => 'The source rejected the account credentials.',
      'booruError.permissionDenied' => 'The source denied access to this resource.',
      'booruError.rateLimited' => 'The source is rate limiting requests. Try again later.',
      'booruError.challengeRequired' => 'The source requires a browser challenge or a different route.',
      'booruError.sourceUnavailable' => 'The source is currently unavailable.',
      'booruError.network' => 'The network request failed. Check the proxy or switch nodes.',
      'booruError.timeout' => 'The request timed out. Check the proxy or switch nodes.',
      'booruError.invalidResponse' => 'The source returned an invalid response.',
      'booruError.unsafeRedirect' => 'The source returned an unsafe redirect.',
      'booruError.mediaValidationFailed' => 'The image response could not be validated or decoded.',
      'booruError.cancelled' => 'The request was cancelled.',
      'booruError.internal' => 'An internal booru engine error occurred.',
      'update.checkUpdateStart' => 'Checking for updates...',
      'update.checkUpdateFailed' => 'Failed to check for updates. Please check your Internet connection.',
      'update.selectDownloadUrlFailed' =>
        'Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project Issue page.',
      'update.newVersionFound' =>
        ({required Object version}) =>
            'New version found: ${version}.\nPlease go to the About page and click Download update.',
      'update.noNewVersionFound' => 'No new version found.',
      'postList.short' => 'Post',
      'postList.title' => 'Post List',
      'postList.titleWithTags' => ({required Object tags}) => 'Posts with tags: ${tags}',
      'postDetail.titleWithId' => ({required Object id}) => 'Post: ${id}',
      'postDetail.tags' => 'Tags',
      'postDetail.details' => 'Details',
      'postDetail.actions' => 'Actions',
      'postDetail.rating' => 'Rating',
      'postDetail.fileType' => 'File type',
      'postDetail.viewOriginal' => 'View original',
      'postDetail.download' => 'Download',
      'postDetail.relatedLoadFailed' => 'Failed to load related images. You can retry.',
      'postDetail.createdAt' => 'Created at',
      'postDetail.author' => 'Author',
      'postDetail.source' => 'Source',
      'postDetail.width' => 'Width',
      'postDetail.height' => 'Height',
      'postDetail.score' => 'Score',
      'postDetail.size' => 'Size',
      'postDetail.parent' => 'Parent ID',
      'postDetail.hasChildren' => 'Has child posts',
      'postDetail.similarPosts' => 'Similar posts',
      'postDetail.parentPost' => 'Parent post',
      'postDetail.childPost' => 'Child post',
      'postSearch.title' => 'Search',
      'imageZoom.title' => 'Zoom Image',
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
      'downloads.messages.storageDenied' => 'You have denied storage permissions.',
      'downloads.messages.deviceInfoError' => 'Unable to parse device information.',
      'downloads.messages.photosPermanentlyDenied' =>
        'You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings.',
      'downloads.messages.photosDenied' => 'You have denied photos permissions.',
      'downloads.messages.downloadTaskExists' => 'The download task already exists.',
      'downloads.messages.imageFileExists' => 'The image file already exists.',
      'downloads.messages.downloadRetryWith' => ({required Object name}) => 'Retry download task ${name}',
      'downloads.messages.downloadStartWith' => ({required Object name}) => 'Start download task ${name}',
      'downloads.messages.downloadCompletedWith' => ({required Object name}) => 'Download completed for task ${name}',
      'downloads.messages.downloadFailedWith' => ({required Object name}) => 'Download failed for task ${name}',
      'downloads.messages.saveFailedWith' => ({required Object name}) => 'Saving failed for task ${name}',
      'about.title' => 'About',
      'about.projectUrl' => 'Project URL',
      'about.publishPage' => 'Publish page',
      'about.appVersion' => 'App version',
      'about.freepivPromotionTitle' => 'Discover freepiv',
      'about.freepivPromotionSubtitle' => 'A modern, smooth, cross-platform third-party Pixiv client.',
      'about.discussion' => 'Discussion',
      'about.downloadUpdate' => 'Download update',
      'about.downloadUpdateHint' => 'Download the latest version for your device via your browser.',
      'settings.title' => 'Settings',
      'settings.theme' => 'Theme',
      'settings.language' => 'Language',
      'settings.bypassSni' => 'Bypass SNI',
      'settings.downloadDirectory' => 'Download Directory',
      'settings.defaultToPlatformSettings' => 'Default to Platform Settings',
      'settings.columnsPerRow' => 'Columns per Row',
      'settings.maxConcurrentDownloads' => 'Max Concurrent Download Tasks',
      'settings.maxSegmentsPerTask' => 'Max Segments per Download Task',
      'settings.platformDefault' => 'Platform default',
      'settings.system' => 'System',
      'settings.light' => 'Light',
      'settings.dark' => 'Dark',
      'settings.auto' => 'Auto',
      'settings.downloadsOverview' => 'Desktop only · one subfolder per source',
      'settings.sourceSubfolders' => 'Source subfolders',
      'settings.sourceSubfoldersDescription' => 'Downloads are saved in a separate folder named after each source.',
      'settings.sections.sourcesAndContent' => 'Sources & content',
      'settings.sections.accounts' => 'Accounts',
      'settings.sections.network' => 'Network',
      'settings.sections.appearance' => 'Appearance',
      'settings.sections.downloads' => 'Downloads',
      'settings.source.label' => 'Source',
      'settings.source.contentPolicy' => 'Content policy',
      'settings.source.safetyRating' => 'Safety rating',
      'settings.source.noHiddenDefault' => 'No hidden default',
      'settings.source.noHiddenDefaultDescription' =>
        'Leave every rating unselected to show all posts, including explicit posts.',
      'settings.source.unfiltered' => 'Unfiltered',
      'settings.source.animeFocused' => 'Anime focused',
      'settings.account.manageAllSubtitle' => 'Configure every source account independently',
      'settings.account.openSignInPage' => 'Open sign-in page',
      'settings.account.cookieHeader' => 'Cookie header',
      'settings.account.storedLocally' => 'Stored locally on this device',
      'settings.account.browserUserAgent' => 'Browser User-Agent',
      'settings.account.browserUserAgentHint' => 'Use the same User-Agent as the signed-in browser',
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
      'settings.account.statusValue' => ({required Object status}) => 'Status · ${status}',
      'settings.account.statuses.notConfigured' => 'Not configured',
      'settings.account.statuses.configuredUnverified' => 'Configured, not verified',
      'settings.account.statuses.verified' => 'Verified',
      'settings.account.statuses.rejected' => 'Rejected',
      'settings.network.connectionMode' => 'Connection mode',
      'settings.network.fallbackToSystemDns' => 'Fall back to system DNS',
      'settings.network.proxyUrl' => 'Proxy URL',
      'settings.network.proxyHint' => 'Optional · for example http://127.0.0.1:7890',
      'settings.network.applyAndRouteCache' => 'Apply and route cache',
      'settings.network.apply' => 'Apply network',
      'settings.network.refreshRoutes' => 'Refresh routes',
      'settings.network.routeCacheUnavailable' => 'Route cache unavailable',
      'settings.network.routeCacheStatus' =>
        ({required Object hosts, required Object revision}) => '${hosts} hosts · revision ${revision}',
      'settings.network.applied' => 'Network settings applied',
      'settings.network.invalidSettings' => 'Invalid network settings',
      'settings.network.routeRefreshFailed' => 'Route refresh failed',
      'settings.network.systemDns' => 'System DNS',
      'settings.network.sniBypass' => 'SNI bypass',
      'settings.network.legacyIpUrl' => 'Legacy IP URL',
      'settings.languageDialog.title' => 'Language',
      'settings.themeModeDialog.title' => 'Theme Mode',
      'settings.downloadDirectoryDialog.title' => 'Download Directory',
      'settings.downloadDirectoryDialog.pickerTitle' => 'Choose Directory',
      'settings.downloadDirectoryDialog.pick' => 'Choose Directory',
      'settings.downloadDirectoryDialog.messages.setToPlatformDefault' => 'Directory set to platform default.',
      'settings.downloadDirectoryDialog.messages.pathNotAbsolute' => 'Directory path must be absolute.',
      'settings.downloadDirectoryDialog.messages.pathNotWritable' => 'Directory path is not writable.',
      'settings.bypassSniDialog.title' => 'Bypass SNI',
      'settings.columnsPerRowDialog.title' => 'Columns per Row',
      'settings.maxConcurrentDownloadsDialog.title' => 'Max Concurrent Download Tasks',
      'settings.maxSegmentsPerTaskDialog.title' => 'Max Segments per Download Task',
      _ => null,
    };
  }
}
