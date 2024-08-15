// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field
import 'package:i18n/i18n.dart' as i18n;

String get _languageCode => 'en';
String _plural(
  int count, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) =>
    i18n.plural(
      count,
      _languageCode,
      zero: zero,
      one: one,
      two: two,
      few: few,
      many: many,
      other: other,
    );
String _ordinal(
  int count, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) =>
    i18n.ordinal(
      count,
      _languageCode,
      zero: zero,
      one: one,
      two: two,
      few: few,
      many: many,
      other: other,
    );
String _cardinal(
  int count, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) =>
    i18n.cardinal(
      count,
      _languageCode,
      zero: zero,
      one: one,
      two: two,
      few: few,
      many: many,
      other: other,
    );

class Intl {
  const Intl();
  String get locale => "en";
  String get languageCode => "en";
  GenericIntl get generic => GenericIntl(this);
  UpdateIntl get update => UpdateIntl(this);
  PostListIntl get postList => PostListIntl(this);
  PostDetailIntl get postDetail => PostDetailIntl(this);
  ImageZoomIntl get imageZoom => ImageZoomIntl(this);
  DownloaderIntl get downloader => DownloaderIntl(this);
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
  String get checkUpdateFailed =>
      """Failed to check for updates. Please check your Internet connection.""";

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

class ImageZoomIntl {
  final Intl _parent;
  const ImageZoomIntl(this._parent);

  /// ```dart
  /// "Zoom Image"
  /// ```
  String get title => """Zoom Image""";
}

class DownloaderIntl {
  final Intl _parent;
  const DownloaderIntl(this._parent);

  /// ```dart
  /// "Downloader"
  /// ```
  String get title => """Downloader""";
  MessagesDownloaderIntl get messages => MessagesDownloaderIntl(this);
}

class MessagesDownloaderIntl {
  final DownloaderIntl _parent;
  const MessagesDownloaderIntl(this._parent);

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
  /// "Retry download task $id"
  /// ```
  String downloadRetryWithId(int id) => """Retry download task $id""";

  /// ```dart
  /// "Start download task $id"
  /// ```
  String downloadStartWithId(int id) => """Start download task $id""";

  /// ```dart
  /// "Download completed for task $id"
  /// ```
  String downloadCompletedWithId(int id) =>
      """Download completed for task $id""";

  /// ```dart
  /// "Download failed for task $id"
  /// ```
  String downloadFailedWithId(int id) => """Download failed for task $id""";

  /// ```dart
  /// "Saving failed for task $id"
  /// ```
  String saveFailedWith(int id) => """Saving failed for task $id""";
}

class AboutIntl {
  final Intl _parent;
  const AboutIntl(this._parent);

  /// ```dart
  /// "Title"
  /// ```
  String get title => """Title""";

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
  /// "Flutter version"
  /// ```
  String get flutterVersion => """Flutter version""";

  /// ```dart
  /// "Rust version"
  /// ```
  String get rustVersion => """Rust version""";

  /// ```dart
  /// "Download update"
  /// ```
  String get downloadUpdate => """Download update""";

  /// ```dart
  /// "Download the latest version for your device via your browser."
  /// ```
  String get downloadUpdateHint =>
      """Download the latest version for your device via your browser.""";
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
  /// "Download path"
  /// ```
  String get downloadPath => """Download path""";

  /// ```dart
  /// "Platform Default"
  /// ```
  String get platformDefault => """Platform Default""";

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
  LanguageDialogSettingsIntl get languageDialog =>
      LanguageDialogSettingsIntl(this);
  ThemeModeDialogSettingsIntl get themeModeDialog =>
      ThemeModeDialogSettingsIntl(this);
  SelectDownloadPathDialogSettingsIntl get selectDownloadPathDialog =>
      SelectDownloadPathDialogSettingsIntl(this);
}

class LanguageDialogSettingsIntl {
  final SettingsIntl _parent;
  const LanguageDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Select Language"
  /// ```
  String get title => """Select Language""";
}

class ThemeModeDialogSettingsIntl {
  final SettingsIntl _parent;
  const ThemeModeDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Select Theme Mode"
  /// ```
  String get title => """Select Theme Mode""";
}

class SelectDownloadPathDialogSettingsIntl {
  final SettingsIntl _parent;
  const SelectDownloadPathDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Select download path"
  /// ```
  String get title => """Select download path""";

  /// ```dart
  /// "Select a directory"
  /// ```
  String get pickerTitle => """Select a directory""";

  /// ```dart
  /// "Pick a directory"
  /// ```
  String get pick => """Pick a directory""";
  MessagesSelectDownloadPathDialogSettingsIntl get messages =>
      MessagesSelectDownloadPathDialogSettingsIntl(this);
}

class MessagesSelectDownloadPathDialogSettingsIntl {
  final SelectDownloadPathDialogSettingsIntl _parent;
  const MessagesSelectDownloadPathDialogSettingsIntl(this._parent);

  /// ```dart
  /// "Download path set to platform default."
  /// ```
  String get setToPlatformDefault =>
      """Download path set to platform default.""";

  /// ```dart
  /// "Path must be absolute."
  /// ```
  String get pathNotAbsolute => """Path must be absolute.""";

  /// ```dart
  /// "Path is not writable"
  /// ```
  String get pathNotWritable => """Path is not writable""";
}

Map<String, String> get intlMap => {
      """generic.ok""": """OK""",
      """generic.cancel""": """Cancel""",
      """generic.clear""": """Clear""",
      """generic.confirm""": """Confirm""",
      """update.checkUpdateStart""": """Checking for updates...""",
      """update.checkUpdateFailed""":
          """Failed to check for updates. Please check your Internet connection.""",
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
      """imageZoom.title""": """Zoom Image""",
      """downloader.title""": """Downloader""",
      """downloader.messages.storagePermanentlyDenied""":
          """You have permanently denied storage permissions.\nPlease manually enable storage permissions in settings.""",
      """downloader.messages.storageDenied""":
          """You have denied storage permissions.""",
      """downloader.messages.deviceInfoError""":
          """Unable to parse device information.""",
      """downloader.messages.photosPermanentlyDenied""":
          """You have permanently denied photos permissions.\nPlease manually enable photos permissions in settings.""",
      """downloader.messages.photosDenied""":
          """You have denied photos permissions.""",
      """downloader.messages.downloadTaskExists""":
          """The download task already exists.""",
      """downloader.messages.imageFileExists""":
          """The image file already exists.""",
      """about.title""": """Title""",
      """about.projectUrl""": """Project URL""",
      """about.publishPage""": """Publish page""",
      """about.appVersion""": """App version""",
      """about.flutterVersion""": """Flutter version""",
      """about.rustVersion""": """Rust version""",
      """about.downloadUpdate""": """Download update""",
      """about.downloadUpdateHint""":
          """Download the latest version for your device via your browser.""",
      """settings.title""": """Settings""",
      """settings.theme""": """Theme""",
      """settings.language""": """Language""",
      """settings.downloadPath""": """Download path""",
      """settings.platformDefault""": """Platform Default""",
      """settings.system""": """System""",
      """settings.light""": """Light""",
      """settings.dark""": """Dark""",
      """settings.languageDialog.title""": """Select Language""",
      """settings.themeModeDialog.title""": """Select Theme Mode""",
      """settings.selectDownloadPathDialog.title""": """Select download path""",
      """settings.selectDownloadPathDialog.pickerTitle""":
          """Select a directory""",
      """settings.selectDownloadPathDialog.pick""": """Pick a directory""",
      """settings.selectDownloadPathDialog.messages.setToPlatformDefault""":
          """Download path set to platform default.""",
      """settings.selectDownloadPathDialog.messages.pathNotAbsolute""":
          """Path must be absolute.""",
      """settings.selectDownloadPathDialog.messages.pathNotWritable""":
          """Path is not writable""",
    };
