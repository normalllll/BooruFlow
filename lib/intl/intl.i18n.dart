// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field
import 'package:i18n/i18n.dart' as i18n;

String get _languageCode => 'en';

String _plural(int count, {String? zero, String? one, String? two, String? few, String? many, String? other}) =>
    i18n.plural(count, _languageCode, zero: zero, one: one, two: two, few: few, many: many, other: other);

String _ordinal(int count, {String? zero, String? one, String? two, String? few, String? many, String? other}) =>
    i18n.ordinal(count, _languageCode, zero: zero, one: one, two: two, few: few, many: many, other: other);

String _cardinal(int count, {String? zero, String? one, String? two, String? few, String? many, String? other}) =>
    i18n.cardinal(count, _languageCode, zero: zero, one: one, two: two, few: few, many: many, other: other);

class Intl {
  const Intl();

  String get locale => "en";

  String get languageCode => "en";

  GenericIntl get generic => GenericIntl(this);

  UpdateIntl get update => UpdateIntl(this);

  PostListIntl get postList => PostListIntl(this);

  PostDetailIntl get postDetail => PostDetailIntl(this);

  PostSearchIntl get postSearch => PostSearchIntl(this);

  ImageZoomIntl get imageZoom => ImageZoomIntl(this);

  DownloadsIntl get downloads => DownloadsIntl(this);

  AboutIntl get about => AboutIntl(this);

  SettingsIntl get settings => SettingsIntl(this);
}

class GenericIntl {
  final Intl _parent;

  const GenericIntl(this._parent);

  /// ```dart
  /// "OK"
  /// ```
  String get ok => """OK""";

  /// ```dart
  /// "Cancel"
  /// ```
  String get cancel => """Cancel""";

  /// ```dart
  /// "Clear"
  /// ```
  String get clear => """Clear""";

  /// ```dart
  /// "Confirm"
  /// ```
  String get confirm => """Confirm""";

  /// ```dart
  /// "Enabled"
  /// ```
  String get enabled => """Enabled""";

  /// ```dart
  /// "Disabled"
  /// ```
  String get disabled => """Disabled""";

  /// ```dart
  /// "Copied to clipboard: $value"
  /// ```
  String copiedWithValue(String value) => """Copied to clipboard: $value""";

  /// ```dart
  /// "An error occurred: $value"
  /// ```
  String errorWithValue(String value) => """An error occurred: $value""";
}

class UpdateIntl {
  final Intl _parent;

  const UpdateIntl(this._parent);

  /// ```dart
  /// "Checking for updates..."
  /// ```
  String get checkUpdateStart => """Checking for updates...""";

  /// ```dart
  /// "Failed to check for updates. Please check your Internet connection."
  /// ```
  String get checkUpdateFailed => """Failed to check for updates. Please check your Internet connection.""";

  /// ```dart
  /// "Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project Issue page."
  /// ```
  String get selectDownloadUrlFailed =>
      """Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project Issue page.""";

  /// ```dart
  /// """
  /// New version found: $version.
  /// Please go to the About page and click Download update.
  /// """
  /// ```
  String newVersionFound(String version) => """New version found: $version.
Please go to the About page and click Download update.""";

  /// ```dart
  /// "No new version found."
  /// ```
  String get noNewVersionFound => """No new version found.""";
}

class PostListIntl {
  final Intl _parent;

  const PostListIntl(this._parent);

  /// ```dart
  /// "Post"
  /// ```
  String get short => """Post""";

  /// ```dart
  /// "Post List"
  /// ```
  String get title => """Post List""";

  /// ```dart
  /// "Posts with tags: $tags"
  /// ```
  String titleWithTags(String tags) => """Posts with tags: $tags""";
}

class PostDetailIntl {
  final Intl _parent;

  const PostDetailIntl(this._parent);

  /// ```dart
  /// "Post: $id"
  /// ```
  String titleWithId(int id) => """Post: $id""";

  /// ```dart
  /// "Created at"
  /// ```
  String get createdAt => """Created at""";

  /// ```dart
  /// "Author"
  /// ```
  String get author => """Author""";

  /// ```dart
  /// "Source"
  /// ```
  String get source => """Source""";

  /// ```dart
  /// "Width"
  /// ```
  String get width => """Width""";

  /// ```dart
  /// "Height"
  /// ```
  String get height => """Height""";

  /// ```dart
  /// "Score"
  /// ```
  String get score => """Score""";

  /// ```dart
  /// "Size"
  /// ```
  String get size => """Size""";

  /// ```dart
  /// "Parent ID"
  /// ```
  String get parent => """Parent ID""";

  /// ```dart
  /// "Has child posts"
  /// ```
  String get hasChildren => """Has child posts""";

  /// ```dart
  /// "Similar posts"
  /// ```
  String get similarPosts => """Similar posts""";

  /// ```dart
  /// "Parent post"
  /// ```
  String get parentPost => """Parent post""";

  /// ```dart
  /// "Child post"
  /// ```
  String get childPost => """Child post""";
}

class PostSearchIntl {
  final Intl _parent;

  const PostSearchIntl(this._parent);

  /// ```dart
  /// "Search"
  /// ```
  String get title => """Search""";
}

class ImageZoomIntl {
  final Intl _parent;

  const ImageZoomIntl(this._parent);

  /// ```dart
  /// "Zoom Image"
  /// ```
  String get title => """Zoom Image""";
}

class DownloadsIntl {
  final Intl _parent;

  const DownloadsIntl(this._parent);

  /// ```dart
  /// "Downloads"
  /// ```
  String get title => """Downloads""";

  MessagesDownloadsIntl get messages => MessagesDownloadsIntl(this);
}

class MessagesDownloadsIntl {
  final DownloadsIntl _parent;

  const MessagesDownloadsIntl(this._parent);

  /// ```dart
  /// "You have permanently denied storage permissions.\nPlease manually enable storage permissions in settings."
  /// ```
  String get storagePermanentlyDenied =>
      """You have permanently denied storage permissions.\nPlease manually enable storage permissions in settings.""";

  /// ```dart
  /// "You have denied storage permissions."
  /// ```
  String get storageDenied => """You have denied storage permissions.""";

  /// ```dart
  /// "Unable to parse device information."
  /// ```
  String get deviceInfoError => """Unable to parse device information.""";

  /// ```dart
  /// "You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings."
  /// ```
  String get photosPermanentlyDenied =>
      """You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings.""";

  /// ```dart
  /// "You have denied photos permissions."
  /// ```
  String get photosDenied => """You have denied photos permissions.""";

  /// ```dart
  /// "The download task already exists."
  /// ```
  String get downloadTaskExists => """The download task already exists.""";

  /// ```dart
  /// "The image file already exists."
  /// ```
  String get imageFileExists => """The image file already exists.""";

  /// ```dart
  /// "Retry download task $name"
  /// ```
  String downloadRetryWith(String name) => """Retry download task $name""";

  /// ```dart
  /// "Start download task $name"
  /// ```
  String downloadStartWith(String name) => """Start download task $name""";

  /// ```dart
  /// "Download completed for task $name"
  /// ```
  String downloadCompletedWith(String name) => """Download completed for task $name""";

  /// ```dart
  /// "Download failed for task $name"
  /// ```
  String downloadFailedWith(String name) => """Download failed for task $name""";

  /// ```dart
  /// "Saving failed for task $name"
  /// ```
  String saveFailedWith(String name) => """Saving failed for task $name""";
}

class AboutIntl {
  final Intl _parent;

  const AboutIntl(this._parent);

  /// ```dart
  /// "About"
  /// ```
  String get title => """About""";

  /// ```dart
  /// "Project URL"
  /// ```
  String get projectUrl => """Project URL""";

  /// ```dart
  /// "Publish page"
  /// ```
  String get publishPage => """Publish page""";

  /// ```dart
  /// "App version"
  /// ```
  String get appVersion => """App version""";

  /// ```dart
  /// "Dart version"
  /// ```
  String get dartVersion => """Dart version""";

  /// ```dart
  /// "Rust version"
  /// ```
  String get rustVersion => """Rust version""";

  /// ```dart
  /// "Discussion"
  /// ```
  String get discussion => """Discussion""";

  /// ```dart
  /// "Download update"
  /// ```
  String get downloadUpdate => """Download update""";

  /// ```dart
  /// "Download the latest version for your device via your browser."
  /// ```
  String get downloadUpdateHint => """Download the latest version for your device via your browser.""";
}

class SettingsIntl {
  final Intl _parent;

  const SettingsIntl(this._parent);

  /// ```dart
  /// "Settings"
  /// ```
  String get title => """Settings""";

  /// ```dart
  /// "Theme"
  /// ```
  String get theme => """Theme""";

  /// ```dart
  /// "Language"
  /// ```
  String get language => """Language""";

  /// ```dart
  /// "Prefetch DNS"
  /// ```
  String get prefetchDns => """Prefetch DNS""";

  /// ```dart
  /// "Download Directory"
  /// ```
  String get downloadDirectory => """Download Directory""";

  /// ```dart
  /// "Default to Platform Settings"
  /// ```
  String get defaultToPlatformSettings => """Default to Platform Settings""";

  /// ```dart
  /// "Columns per Row"
  /// ```
  String get columnsPerRow => """Columns per Row""";

  /// ```dart
  /// "Max Concurrent Download Tasks"
  /// ```
  String get maxConcurrentDownloads => """Max Concurrent Download Tasks""";

  /// ```dart
  /// "Max Segments per Download Task"
  /// ```
  String get maxSegmentsPerTask => """Max Segments per Download Task""";

  /// ```dart
  /// "Platform default"
  /// ```
  String get platformDefault => """Platform default""";

  /// ```dart
  /// "System"
  /// ```
  String get system => """System""";

  /// ```dart
  /// "Light"
  /// ```
  String get light => """Light""";

  /// ```dart
  /// "Dark"
  /// ```
  String get dark => """Dark""";

  LanguageDialogSettingsIntl get languageDialog => LanguageDialogSettingsIntl(this);

  ThemeModeDialogSettingsIntl get themeModeDialog => ThemeModeDialogSettingsIntl(this);

  DownloadDirectoryDialogSettingsIntl get downloadDirectoryDialog => DownloadDirectoryDialogSettingsIntl(this);

  DnsPrefetchDialogSettingsIntl get dnsPrefetchDialog => DnsPrefetchDialogSettingsIntl(this);

  ColumnsPerRowDialogSettingsIntl get columnsPerRowDialog => ColumnsPerRowDialogSettingsIntl(this);

  MaxConcurrentDownloadsDialogSettingsIntl get maxConcurrentDownloadsDialog => MaxConcurrentDownloadsDialogSettingsIntl(this);

  MaxSegmentsPerTaskDialogSettingsIntl get maxSegmentsPerTaskDialog => MaxSegmentsPerTaskDialogSettingsIntl(this);
}

class LanguageDialogSettingsIntl {
  final SettingsIntl _parent;

  const LanguageDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Language"
  /// ```
  String get title => """Language""";
}

class ThemeModeDialogSettingsIntl {
  final SettingsIntl _parent;

  const ThemeModeDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Theme Mode"
  /// ```
  String get title => """Theme Mode""";
}

class DownloadDirectoryDialogSettingsIntl {
  final SettingsIntl _parent;

  const DownloadDirectoryDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Download Directory"
  /// ```
  String get title => """Download Directory""";

  /// ```dart
  /// "Choose Directory"
  /// ```
  String get pickerTitle => """Choose Directory""";

  /// ```dart
  /// "Choose Directory"
  /// ```
  String get pick => """Choose Directory""";

  MessagesDownloadDirectoryDialogSettingsIntl get messages => MessagesDownloadDirectoryDialogSettingsIntl(this);
}

class MessagesDownloadDirectoryDialogSettingsIntl {
  final DownloadDirectoryDialogSettingsIntl _parent;

  const MessagesDownloadDirectoryDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Directory set to platform default."
  /// ```
  String get setToPlatformDefault => """Directory set to platform default.""";

  /// ```dart
  /// "Directory path must be absolute."
  /// ```
  String get pathNotAbsolute => """Directory path must be absolute.""";

  /// ```dart
  /// "Directory path is not writable."
  /// ```
  String get pathNotWritable => """Directory path is not writable.""";
}

class DnsPrefetchDialogSettingsIntl {
  final SettingsIntl _parent;

  const DnsPrefetchDialogSettingsIntl(this._parent);

  /// ```dart
  /// "DNS Prefetch"
  /// ```
  String get title => """DNS Prefetch""";
}

class ColumnsPerRowDialogSettingsIntl {
  final SettingsIntl _parent;

  const ColumnsPerRowDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Columns per Row"
  /// ```
  String get title => """Columns per Row""";
}

class MaxConcurrentDownloadsDialogSettingsIntl {
  final SettingsIntl _parent;

  const MaxConcurrentDownloadsDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Max Concurrent Download Tasks"
  /// ```
  String get title => """Max Concurrent Download Tasks""";
}

class MaxSegmentsPerTaskDialogSettingsIntl {
  final SettingsIntl _parent;

  const MaxSegmentsPerTaskDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Max Segments per Download Task"
  /// ```
  String get title => """Max Segments per Download Task""";
}

Map<String, String> get intlMap => {
  """generic.ok""": """OK""",
  """generic.cancel""": """Cancel""",
  """generic.clear""": """Clear""",
  """generic.confirm""": """Confirm""",
  """generic.enabled""": """Enabled""",
  """generic.disabled""": """Disabled""",
  """update.checkUpdateStart""": """Checking for updates...""",
  """update.checkUpdateFailed""": """Failed to check for updates. Please check your Internet connection.""",
  """update.selectDownloadUrlFailed""":
      """Unable to find download URL.\nPlease visit the project page to manually update or seek help on the project Issue page.""",
  """update.noNewVersionFound""": """No new version found.""",
  """postList.short""": """Post""",
  """postList.title""": """Post List""",
  """postDetail.createdAt""": """Created at""",
  """postDetail.author""": """Author""",
  """postDetail.source""": """Source""",
  """postDetail.width""": """Width""",
  """postDetail.height""": """Height""",
  """postDetail.score""": """Score""",
  """postDetail.size""": """Size""",
  """postDetail.parent""": """Parent ID""",
  """postDetail.hasChildren""": """Has child posts""",
  """postDetail.similarPosts""": """Similar posts""",
  """postDetail.parentPost""": """Parent post""",
  """postDetail.childPost""": """Child post""",
  """postSearch.title""": """Search""",
  """imageZoom.title""": """Zoom Image""",
  """downloads.title""": """Downloads""",
  """downloads.messages.storagePermanentlyDenied""":
      """You have permanently denied storage permissions.\nPlease manually enable storage permissions in settings.""",
  """downloads.messages.storageDenied""": """You have denied storage permissions.""",
  """downloads.messages.deviceInfoError""": """Unable to parse device information.""",
  """downloads.messages.photosPermanentlyDenied""":
      """You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings.""",
  """downloads.messages.photosDenied""": """You have denied photos permissions.""",
  """downloads.messages.downloadTaskExists""": """The download task already exists.""",
  """downloads.messages.imageFileExists""": """The image file already exists.""",
  """about.title""": """About""",
  """about.projectUrl""": """Project URL""",
  """about.publishPage""": """Publish page""",
  """about.appVersion""": """App version""",
  """about.dartVersion""": """Dart version""",
  """about.rustVersion""": """Rust version""",
  """about.discussion""": """Discussion""",
  """about.downloadUpdate""": """Download update""",
  """about.downloadUpdateHint""": """Download the latest version for your device via your browser.""",
  """settings.title""": """Settings""",
  """settings.theme""": """Theme""",
  """settings.language""": """Language""",
  """settings.prefetchDns""": """Prefetch DNS""",
  """settings.downloadDirectory""": """Download Directory""",
  """settings.defaultToPlatformSettings""": """Default to Platform Settings""",
  """settings.columnsPerRow""": """Columns per Row""",
  """settings.maxConcurrentDownloads""": """Max Concurrent Download Tasks""",
  """settings.maxSegmentsPerTask""": """Max Segments per Download Task""",
  """settings.platformDefault""": """Platform default""",
  """settings.system""": """System""",
  """settings.light""": """Light""",
  """settings.dark""": """Dark""",
  """settings.languageDialog.title""": """Language""",
  """settings.themeModeDialog.title""": """Theme Mode""",
  """settings.downloadDirectoryDialog.title""": """Download Directory""",
  """settings.downloadDirectoryDialog.pickerTitle""": """Choose Directory""",
  """settings.downloadDirectoryDialog.pick""": """Choose Directory""",
  """settings.downloadDirectoryDialog.messages.setToPlatformDefault""": """Directory set to platform default.""",
  """settings.downloadDirectoryDialog.messages.pathNotAbsolute""": """Directory path must be absolute.""",
  """settings.downloadDirectoryDialog.messages.pathNotWritable""": """Directory path is not writable.""",
  """settings.dnsPrefetchDialog.title""": """DNS Prefetch""",
  """settings.columnsPerRowDialog.title""": """Columns per Row""",
  """settings.maxConcurrentDownloadsDialog.title""": """Max Concurrent Download Tasks""",
  """settings.maxSegmentsPerTaskDialog.title""": """Max Segments per Download Task""",
};
