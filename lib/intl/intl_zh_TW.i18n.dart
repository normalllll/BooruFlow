// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field
import 'package:i18n/i18n.dart' as i18n;
import 'intl.i18n.dart';

String get _languageCode => 'zh';

String _plural(int count, {String? zero, String? one, String? two, String? few, String? many, String? other}) =>
    i18n.plural(count, _languageCode, zero: zero, one: one, two: two, few: few, many: many, other: other);

String _ordinal(int count, {String? zero, String? one, String? two, String? few, String? many, String? other}) =>
    i18n.ordinal(count, _languageCode, zero: zero, one: one, two: two, few: few, many: many, other: other);

String _cardinal(int count, {String? zero, String? one, String? two, String? few, String? many, String? other}) =>
    i18n.cardinal(count, _languageCode, zero: zero, one: one, two: two, few: few, many: many, other: other);

class IntlZhTW extends Intl {
  const IntlZhTW();

  String get locale => "zh_TW";

  String get languageCode => "zh";

  GenericIntlZhTW get generic => GenericIntlZhTW(this);

  UpdateIntlZhTW get update => UpdateIntlZhTW(this);

  PostListIntlZhTW get postList => PostListIntlZhTW(this);

  PostDetailIntlZhTW get postDetail => PostDetailIntlZhTW(this);

  PostSearchIntlZhTW get postSearch => PostSearchIntlZhTW(this);

  ImageZoomIntlZhTW get imageZoom => ImageZoomIntlZhTW(this);

  DownloadsIntlZhTW get downloads => DownloadsIntlZhTW(this);

  AboutIntlZhTW get about => AboutIntlZhTW(this);

  SettingsIntlZhTW get settings => SettingsIntlZhTW(this);
}

class GenericIntlZhTW extends GenericIntl {
  final IntlZhTW _parent;

  const GenericIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "確定"
  /// ```
  String get ok => """確定""";

  /// ```dart
  /// "取消"
  /// ```
  String get cancel => """取消""";

  /// ```dart
  /// "清除"
  /// ```
  String get clear => """清除""";

  /// ```dart
  /// "確認"
  /// ```
  String get confirm => """確認""";

  /// ```dart
  /// "啟用"
  /// ```
  String get enabled => """啟用""";

  /// ```dart
  /// "停用"
  /// ```
  String get disabled => """停用""";

  /// ```dart
  /// "已複製到剪貼簿: $value"
  /// ```
  String copiedWithValue(String value) => """已複製到剪貼簿: $value""";

  /// ```dart
  /// "發生錯誤: $value"
  /// ```
  String errorWithValue(String value) => """發生錯誤: $value""";
}

class UpdateIntlZhTW extends UpdateIntl {
  final IntlZhTW _parent;

  const UpdateIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "正在檢查更新..."
  /// ```
  String get checkUpdateStart => """正在檢查更新...""";

  /// ```dart
  /// "檢查更新失敗，請檢查您的網路連線。"
  /// ```
  String get checkUpdateFailed => """檢查更新失敗，請檢查您的網路連線。""";

  /// ```dart
  /// "找不到下載連結。\n請訪問專案頁面以手動更新或在專案Issue頁尋求幫助。"
  /// ```
  String get selectDownloadUrlFailed => """找不到下載連結。\n請訪問專案頁面以手動更新或在專案Issue頁尋求幫助。""";

  /// ```dart
  /// "發現新版本: $version。請轉到「關於」頁面並點擊「下載更新」。"
  /// ```
  String newVersionFound(String version) => """發現新版本: $version。請轉到「關於」頁面並點擊「下載更新」。""";

  /// ```dart
  /// "沒有新版本。"
  /// ```
  String get noNewVersionFound => """沒有新版本。""";
}

class PostListIntlZhTW extends PostListIntl {
  final IntlZhTW _parent;

  const PostListIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "帖子"
  /// ```
  String get short => """帖子""";

  /// ```dart
  /// "帖子列表"
  /// ```
  String get title => """帖子列表""";

  /// ```dart
  /// "帶有標籤的帖子: $tags"
  /// ```
  String titleWithTags(String tags) => """帶有標籤的帖子: $tags""";
}

class PostDetailIntlZhTW extends PostDetailIntl {
  final IntlZhTW _parent;

  const PostDetailIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "帖子: $id"
  /// ```
  String titleWithId(int id) => """帖子: $id""";

  /// ```dart
  /// "建立時間"
  /// ```
  String get createdAt => """建立時間""";

  /// ```dart
  /// "作者"
  /// ```
  String get author => """作者""";

  /// ```dart
  /// "來源"
  /// ```
  String get source => """來源""";

  /// ```dart
  /// "寬度"
  /// ```
  String get width => """寬度""";

  /// ```dart
  /// "高度"
  /// ```
  String get height => """高度""";

  /// ```dart
  /// "評分"
  /// ```
  String get score => """評分""";

  /// ```dart
  /// "大小"
  /// ```
  String get size => """大小""";

  /// ```dart
  /// "父ID"
  /// ```
  String get parent => """父ID""";

  /// ```dart
  /// "有子帖子"
  /// ```
  String get hasChildren => """有子帖子""";

  /// ```dart
  /// "相似帖子"
  /// ```
  String get similarPosts => """相似帖子""";

  /// ```dart
  /// "父帖子"
  /// ```
  String get parentPost => """父帖子""";

  /// ```dart
  /// "子帖子"
  /// ```
  String get childPost => """子帖子""";
}

class PostSearchIntlZhTW extends PostSearchIntl {
  final IntlZhTW _parent;

  const PostSearchIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "搜尋"
  /// ```
  String get title => """搜尋""";
}

class ImageZoomIntlZhTW extends ImageZoomIntl {
  final IntlZhTW _parent;

  const ImageZoomIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "縮放圖片"
  /// ```
  String get title => """縮放圖片""";
}

class DownloadsIntlZhTW extends DownloadsIntl {
  final IntlZhTW _parent;

  const DownloadsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "下載項"
  /// ```
  String get title => """下載項""";

  MessagesDownloadsIntlZhTW get messages => MessagesDownloadsIntlZhTW(this);
}

class MessagesDownloadsIntlZhTW extends MessagesDownloadsIntl {
  final DownloadsIntlZhTW _parent;

  const MessagesDownloadsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "您已永久拒絕存儲權限。\n請在設定中手動啟用存儲權限。"
  /// ```
  String get storagePermanentlyDenied => """您已永久拒絕存儲權限。\n請在設定中手動啟用存儲權限。""";

  /// ```dart
  /// "您已拒絕存儲權限。"
  /// ```
  String get storageDenied => """您已拒絕存儲權限。""";

  /// ```dart
  /// "無法解析設備資訊。"
  /// ```
  String get deviceInfoError => """無法解析設備資訊。""";

  /// ```dart
  /// "您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。"
  /// ```
  String get photosPermanentlyDenied => """您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。""";

  /// ```dart
  /// "您已拒絕照片權限。"
  /// ```
  String get photosDenied => """您已拒絕照片權限。""";

  /// ```dart
  /// "下載任務已經存在。"
  /// ```
  String get downloadTaskExists => """下載任務已經存在。""";

  /// ```dart
  /// "圖片檔案已經存在。"
  /// ```
  String get imageFileExists => """圖片檔案已經存在。""";

  /// ```dart
  /// "重試下載任務: $name"
  /// ```
  String downloadRetryWith(String name) => """重試下載任務: $name""";

  /// ```dart
  /// "開始下載任務: $name"
  /// ```
  String downloadStartWith(String name) => """開始下載任務: $name""";

  /// ```dart
  /// "下載任務完成: $name"
  /// ```
  String downloadCompletedWith(String name) => """下載任務完成: $name""";

  /// ```dart
  /// "下載任務失敗: $name"
  /// ```
  String downloadFailedWith(String name) => """下載任務失敗: $name""";

  /// ```dart
  /// "儲存失敗: 任務 $name"
  /// ```
  String saveFailedWith(String name) => """儲存失敗: 任務 $name""";
}

class AboutIntlZhTW extends AboutIntl {
  final IntlZhTW _parent;

  const AboutIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "關於"
  /// ```
  String get title => """關於""";

  /// ```dart
  /// "專案網址"
  /// ```
  String get projectUrl => """專案網址""";

  /// ```dart
  /// "發佈頁面"
  /// ```
  String get publishPage => """發佈頁面""";

  /// ```dart
  /// "應用程式版本"
  /// ```
  String get appVersion => """應用程式版本""";

  /// ```dart
  /// "Dart 版本"
  /// ```
  String get dartVersion => """Dart 版本""";

  /// ```dart
  /// "Rust 版本"
  /// ```
  String get rustVersion => """Rust 版本""";

  /// ```dart
  /// "討論"
  /// ```
  String get discussion => """討論""";

  /// ```dart
  /// "下載更新"
  /// ```
  String get downloadUpdate => """下載更新""";

  /// ```dart
  /// "透過瀏覽器下載適合您裝置的最新版本。"
  /// ```
  String get downloadUpdateHint => """透過瀏覽器下載適合您裝置的最新版本。""";
}

class SettingsIntlZhTW extends SettingsIntl {
  final IntlZhTW _parent;

  const SettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "設定"
  /// ```
  String get title => """設定""";

  /// ```dart
  /// "主題"
  /// ```
  String get theme => """主題""";

  /// ```dart
  /// "語言"
  /// ```
  String get language => """語言""";

  /// ```dart
  /// "預抓取 DNS"
  /// ```
  String get prefetchDns => """預抓取 DNS""";

  /// ```dart
  /// "下載目錄"
  /// ```
  String get downloadDirectory => """下載目錄""";

  /// ```dart
  /// "使用系統預設"
  /// ```
  String get defaultToPlatformSettings => """使用系統預設""";

  /// ```dart
  /// "每行列數"
  /// ```
  String get columnsPerRow => """每行列數""";

  /// ```dart
  /// "最大同時下載任務數"
  /// ```
  String get maxConcurrentDownloads => """最大同時下載任務數""";

  /// ```dart
  /// "每個下載任務的最大分段數"
  /// ```
  String get maxSegmentsPerTask => """每個下載任務的最大分段數""";

  /// ```dart
  /// "平台預設"
  /// ```
  String get platformDefault => """平台預設""";

  /// ```dart
  /// "系統"
  /// ```
  String get system => """系統""";

  /// ```dart
  /// "淺色模式"
  /// ```
  String get light => """淺色模式""";

  /// ```dart
  /// "深色模式"
  /// ```
  String get dark => """深色模式""";

  LanguageDialogSettingsIntlZhTW get languageDialog => LanguageDialogSettingsIntlZhTW(this);

  ThemeModeDialogSettingsIntlZhTW get themeModeDialog => ThemeModeDialogSettingsIntlZhTW(this);

  DownloadDirectoryDialogSettingsIntlZhTW get downloadDirectoryDialog => DownloadDirectoryDialogSettingsIntlZhTW(this);

  DnsPrefetchDialogSettingsIntlZhTW get dnsPrefetchDialog => DnsPrefetchDialogSettingsIntlZhTW(this);

  ColumnsPerRowDialogSettingsIntlZhTW get columnsPerRowDialog => ColumnsPerRowDialogSettingsIntlZhTW(this);

  MaxConcurrentDownloadsDialogSettingsIntlZhTW get maxConcurrentDownloadsDialog => MaxConcurrentDownloadsDialogSettingsIntlZhTW(this);

  MaxSegmentsPerTaskDialogSettingsIntlZhTW get maxSegmentsPerTaskDialog => MaxSegmentsPerTaskDialogSettingsIntlZhTW(this);
}

class LanguageDialogSettingsIntlZhTW extends LanguageDialogSettingsIntl {
  final SettingsIntlZhTW _parent;

  const LanguageDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "語言"
  /// ```
  String get title => """語言""";
}

class ThemeModeDialogSettingsIntlZhTW extends ThemeModeDialogSettingsIntl {
  final SettingsIntlZhTW _parent;

  const ThemeModeDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "主題模式"
  /// ```
  String get title => """主題模式""";
}

class DownloadDirectoryDialogSettingsIntlZhTW extends DownloadDirectoryDialogSettingsIntl {
  final SettingsIntlZhTW _parent;

  const DownloadDirectoryDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "下載目錄"
  /// ```
  String get title => """下載目錄""";

  /// ```dart
  /// "選擇目錄"
  /// ```
  String get pickerTitle => """選擇目錄""";

  /// ```dart
  /// "選擇目錄"
  /// ```
  String get pick => """選擇目錄""";

  MessagesDownloadDirectoryDialogSettingsIntlZhTW get messages => MessagesDownloadDirectoryDialogSettingsIntlZhTW(this);
}

class MessagesDownloadDirectoryDialogSettingsIntlZhTW extends MessagesDownloadDirectoryDialogSettingsIntl {
  final DownloadDirectoryDialogSettingsIntlZhTW _parent;

  const MessagesDownloadDirectoryDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "下載目錄已設為系統預設。"
  /// ```
  String get setToPlatformDefault => """下載目錄已設為系統預設。""";

  /// ```dart
  /// "路徑必須是絕對路徑。"
  /// ```
  String get pathNotAbsolute => """路徑必須是絕對路徑。""";

  /// ```dart
  /// "路徑不可寫入。"
  /// ```
  String get pathNotWritable => """路徑不可寫入。""";
}

class DnsPrefetchDialogSettingsIntlZhTW extends DnsPrefetchDialogSettingsIntl {
  final SettingsIntlZhTW _parent;

  const DnsPrefetchDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "DNS 預抓取"
  /// ```
  String get title => """DNS 預抓取""";
}

class ColumnsPerRowDialogSettingsIntlZhTW extends ColumnsPerRowDialogSettingsIntl {
  final SettingsIntlZhTW _parent;

  const ColumnsPerRowDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "每行列數"
  /// ```
  String get title => """每行列數""";
}

class MaxConcurrentDownloadsDialogSettingsIntlZhTW extends MaxConcurrentDownloadsDialogSettingsIntl {
  final SettingsIntlZhTW _parent;

  const MaxConcurrentDownloadsDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "最大同時下載任務數"
  /// ```
  String get title => """最大同時下載任務數""";
}

class MaxSegmentsPerTaskDialogSettingsIntlZhTW extends MaxSegmentsPerTaskDialogSettingsIntl {
  final SettingsIntlZhTW _parent;

  const MaxSegmentsPerTaskDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "每個下載任務的最大分段數"
  /// ```
  String get title => """每個下載任務的最大分段數""";
}

Map<String, String> get intlZhTWMap => {
  """generic.ok""": """確定""",
  """generic.cancel""": """取消""",
  """generic.clear""": """清除""",
  """generic.confirm""": """確認""",
  """generic.enabled""": """啟用""",
  """generic.disabled""": """停用""",
  """update.checkUpdateStart""": """正在檢查更新...""",
  """update.checkUpdateFailed""": """檢查更新失敗，請檢查您的網路連線。""",
  """update.selectDownloadUrlFailed""": """找不到下載連結。\n請訪問專案頁面以手動更新或在專案Issue頁尋求幫助。""",
  """update.noNewVersionFound""": """沒有新版本。""",
  """postList.short""": """帖子""",
  """postList.title""": """帖子列表""",
  """postDetail.createdAt""": """建立時間""",
  """postDetail.author""": """作者""",
  """postDetail.source""": """來源""",
  """postDetail.width""": """寬度""",
  """postDetail.height""": """高度""",
  """postDetail.score""": """評分""",
  """postDetail.size""": """大小""",
  """postDetail.parent""": """父ID""",
  """postDetail.hasChildren""": """有子帖子""",
  """postDetail.similarPosts""": """相似帖子""",
  """postDetail.parentPost""": """父帖子""",
  """postDetail.childPost""": """子帖子""",
  """postSearch.title""": """搜尋""",
  """imageZoom.title""": """縮放圖片""",
  """downloads.title""": """下載項""",
  """downloads.messages.storagePermanentlyDenied""": """您已永久拒絕存儲權限。\n請在設定中手動啟用存儲權限。""",
  """downloads.messages.storageDenied""": """您已拒絕存儲權限。""",
  """downloads.messages.deviceInfoError""": """無法解析設備資訊。""",
  """downloads.messages.photosPermanentlyDenied""": """您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。""",
  """downloads.messages.photosDenied""": """您已拒絕照片權限。""",
  """downloads.messages.downloadTaskExists""": """下載任務已經存在。""",
  """downloads.messages.imageFileExists""": """圖片檔案已經存在。""",
  """about.title""": """關於""",
  """about.projectUrl""": """專案網址""",
  """about.publishPage""": """發佈頁面""",
  """about.appVersion""": """應用程式版本""",
  """about.dartVersion""": """Dart 版本""",
  """about.rustVersion""": """Rust 版本""",
  """about.discussion""": """討論""",
  """about.downloadUpdate""": """下載更新""",
  """about.downloadUpdateHint""": """透過瀏覽器下載適合您裝置的最新版本。""",
  """settings.title""": """設定""",
  """settings.theme""": """主題""",
  """settings.language""": """語言""",
  """settings.prefetchDns""": """預抓取 DNS""",
  """settings.downloadDirectory""": """下載目錄""",
  """settings.defaultToPlatformSettings""": """使用系統預設""",
  """settings.columnsPerRow""": """每行列數""",
  """settings.maxConcurrentDownloads""": """最大同時下載任務數""",
  """settings.maxSegmentsPerTask""": """每個下載任務的最大分段數""",
  """settings.platformDefault""": """平台預設""",
  """settings.system""": """系統""",
  """settings.light""": """淺色模式""",
  """settings.dark""": """深色模式""",
  """settings.languageDialog.title""": """語言""",
  """settings.themeModeDialog.title""": """主題模式""",
  """settings.downloadDirectoryDialog.title""": """下載目錄""",
  """settings.downloadDirectoryDialog.pickerTitle""": """選擇目錄""",
  """settings.downloadDirectoryDialog.pick""": """選擇目錄""",
  """settings.downloadDirectoryDialog.messages.setToPlatformDefault""": """下載目錄已設為系統預設。""",
  """settings.downloadDirectoryDialog.messages.pathNotAbsolute""": """路徑必須是絕對路徑。""",
  """settings.downloadDirectoryDialog.messages.pathNotWritable""": """路徑不可寫入。""",
  """settings.dnsPrefetchDialog.title""": """DNS 預抓取""",
  """settings.columnsPerRowDialog.title""": """每行列數""",
  """settings.maxConcurrentDownloadsDialog.title""": """最大同時下載任務數""",
  """settings.maxSegmentsPerTaskDialog.title""": """每個下載任務的最大分段數""",
};
