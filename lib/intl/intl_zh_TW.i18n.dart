// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field
import 'package:i18n/i18n.dart' as i18n;
import 'intl.i18n.dart';

String get _languageCode => 'zh';
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
  DownloaderIntlZhTW get downloader => DownloaderIntlZhTW(this);
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
  String get selectDownloadUrlFailed =>
      """找不到下載連結。\n請訪問專案頁面以手動更新或在專案Issue頁尋求幫助。""";

  /// ```dart
  /// "發現新版本: $version。請轉到「關於」頁面並點擊「下載更新」。"
  /// ```
  String newVersionFound(String version) =>
      """發現新版本: $version。請轉到「關於」頁面並點擊「下載更新」。""";

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

class DownloaderIntlZhTW extends DownloaderIntl {
  final IntlZhTW _parent;
  const DownloaderIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "下載器"
  /// ```
  String get title => """下載器""";
  MessagesDownloaderIntlZhTW get messages => MessagesDownloaderIntlZhTW(this);
}

class MessagesDownloaderIntlZhTW extends MessagesDownloaderIntl {
  final DownloaderIntlZhTW _parent;
  const MessagesDownloaderIntlZhTW(this._parent) : super(_parent);

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
  /// "重試下載任務: $id"
  /// ```
  String downloadRetryWithId(int id) => """重試下載任務: $id""";

  /// ```dart
  /// "開始下載任務: $id"
  /// ```
  String downloadStartWithId(int id) => """開始下載任務: $id""";

  /// ```dart
  /// "下載任務完成: $id"
  /// ```
  String downloadCompletedWithId(int id) => """下載任務完成: $id""";

  /// ```dart
  /// "下載任務失敗: $id"
  /// ```
  String downloadFailedWithId(int id) => """下載任務失敗: $id""";

  /// ```dart
  /// "儲存失敗: 任務 $id"
  /// ```
  String saveFailedWith(int id) => """儲存失敗: 任務 $id""";
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
  /// "Flutter 版本"
  /// ```
  String get flutterVersion => """Flutter 版本""";

  /// ```dart
  /// "Rust 版本"
  /// ```
  String get rustVersion => """Rust 版本""";

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
  /// "下載路徑"
  /// ```
  String get downloadPath => """下載路徑""";

  /// ```dart
  /// "平台預設"
  /// ```
  String get platformDefault => """平台預設""";

  /// ```dart
  /// "每行的列數"
  /// ```
  String get waterfallColumns => """每行的列數""";

  /// ```dart
  /// "系統預設"
  /// ```
  String get system => """系統預設""";

  /// ```dart
  /// "淺色模式"
  /// ```
  String get light => """淺色模式""";

  /// ```dart
  /// "深色模式"
  /// ```
  String get dark => """深色模式""";
  LanguageDialogSettingsIntlZhTW get languageDialog =>
      LanguageDialogSettingsIntlZhTW(this);
  ThemeModeDialogSettingsIntlZhTW get themeModeDialog =>
      ThemeModeDialogSettingsIntlZhTW(this);
  SelectDownloadPathDialogSettingsIntlZhTW get selectDownloadPathDialog =>
      SelectDownloadPathDialogSettingsIntlZhTW(this);
  SetWaterfallColumnsDialogSettingsIntlZhTW get setWaterfallColumnsDialog =>
      SetWaterfallColumnsDialogSettingsIntlZhTW(this);
}

class LanguageDialogSettingsIntlZhTW extends LanguageDialogSettingsIntl {
  final SettingsIntlZhTW _parent;
  const LanguageDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "選擇語言"
  /// ```
  String get title => """選擇語言""";
}

class ThemeModeDialogSettingsIntlZhTW extends ThemeModeDialogSettingsIntl {
  final SettingsIntlZhTW _parent;
  const ThemeModeDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "選擇主題"
  /// ```
  String get title => """選擇主題""";
}

class SelectDownloadPathDialogSettingsIntlZhTW
    extends SelectDownloadPathDialogSettingsIntl {
  final SettingsIntlZhTW _parent;
  const SelectDownloadPathDialogSettingsIntlZhTW(this._parent) : super(_parent);

  /// ```dart
  /// "選擇下載路徑"
  /// ```
  String get title => """選擇下載路徑""";

  /// ```dart
  /// "選擇資料夾"
  /// ```
  String get pickerTitle => """選擇資料夾""";

  /// ```dart
  /// "選擇資料夾"
  /// ```
  String get pick => """選擇資料夾""";
  MessagesSelectDownloadPathDialogSettingsIntlZhTW get messages =>
      MessagesSelectDownloadPathDialogSettingsIntlZhTW(this);
}

class MessagesSelectDownloadPathDialogSettingsIntlZhTW
    extends MessagesSelectDownloadPathDialogSettingsIntl {
  final SelectDownloadPathDialogSettingsIntlZhTW _parent;
  const MessagesSelectDownloadPathDialogSettingsIntlZhTW(this._parent)
      : super(_parent);

  /// ```dart
  /// "下載路徑已設為平台預設值。"
  /// ```
  String get setToPlatformDefault => """下載路徑已設為平台預設值。""";

  /// ```dart
  /// "路徑必須為絕對路徑。"
  /// ```
  String get pathNotAbsolute => """路徑必須為絕對路徑。""";

  /// ```dart
  /// "路徑無法寫入"
  /// ```
  String get pathNotWritable => """路徑無法寫入""";
}

class SetWaterfallColumnsDialogSettingsIntlZhTW
    extends SetWaterfallColumnsDialogSettingsIntl {
  final SettingsIntlZhTW _parent;
  const SetWaterfallColumnsDialogSettingsIntlZhTW(this._parent)
      : super(_parent);

  /// ```dart
  /// "設定每行的列數"
  /// ```
  String get title => """設定每行的列數""";

  /// ```dart
  /// "目前 $value"
  /// ```
  String current(String value) => """目前 $value""";
}

Map<String, String> get intlZhTWMap => {
      """generic.ok""": """確定""",
      """generic.cancel""": """取消""",
      """generic.clear""": """清除""",
      """generic.confirm""": """確認""",
      """update.checkUpdateStart""": """正在檢查更新...""",
      """update.checkUpdateFailed""": """檢查更新失敗，請檢查您的網路連線。""",
      """update.selectDownloadUrlFailed""":
          """找不到下載連結。\n請訪問專案頁面以手動更新或在專案Issue頁尋求幫助。""",
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
      """downloader.title""": """下載器""",
      """downloader.messages.storagePermanentlyDenied""":
          """您已永久拒絕存儲權限。\n請在設定中手動啟用存儲權限。""",
      """downloader.messages.storageDenied""": """您已拒絕存儲權限。""",
      """downloader.messages.deviceInfoError""": """無法解析設備資訊。""",
      """downloader.messages.photosPermanentlyDenied""":
          """您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。""",
      """downloader.messages.photosDenied""": """您已拒絕照片權限。""",
      """downloader.messages.downloadTaskExists""": """下載任務已經存在。""",
      """downloader.messages.imageFileExists""": """圖片檔案已經存在。""",
      """about.title""": """關於""",
      """about.projectUrl""": """專案網址""",
      """about.publishPage""": """發佈頁面""",
      """about.appVersion""": """應用程式版本""",
      """about.flutterVersion""": """Flutter 版本""",
      """about.rustVersion""": """Rust 版本""",
      """about.downloadUpdate""": """下載更新""",
      """about.downloadUpdateHint""": """透過瀏覽器下載適合您裝置的最新版本。""",
      """settings.title""": """設定""",
      """settings.theme""": """主題""",
      """settings.language""": """語言""",
      """settings.downloadPath""": """下載路徑""",
      """settings.platformDefault""": """平台預設""",
      """settings.waterfallColumns""": """每行的列數""",
      """settings.system""": """系統預設""",
      """settings.light""": """淺色模式""",
      """settings.dark""": """深色模式""",
      """settings.languageDialog.title""": """選擇語言""",
      """settings.themeModeDialog.title""": """選擇主題""",
      """settings.selectDownloadPathDialog.title""": """選擇下載路徑""",
      """settings.selectDownloadPathDialog.pickerTitle""": """選擇資料夾""",
      """settings.selectDownloadPathDialog.pick""": """選擇資料夾""",
      """settings.selectDownloadPathDialog.messages.setToPlatformDefault""":
          """下載路徑已設為平台預設值。""",
      """settings.selectDownloadPathDialog.messages.pathNotAbsolute""":
          """路徑必須為絕對路徑。""",
      """settings.selectDownloadPathDialog.messages.pathNotWritable""":
          """路徑無法寫入""",
      """settings.setWaterfallColumnsDialog.title""": """設定每行的列數""",
    };
