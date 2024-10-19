// GENERATED FILE, do not edit!
// ignore_for_file: annotate_overrides, non_constant_identifier_names, prefer_single_quotes, unused_element, unused_field
import 'package:i18n/i18n.dart' as i18n;
import 'intl.i18n.dart';

String get _languageCode => 'ja';
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

class IntlJa extends Intl {
  const IntlJa();
  String get locale => "ja";
  String get languageCode => "ja";
  GenericIntlJa get generic => GenericIntlJa(this);
  UpdateIntlJa get update => UpdateIntlJa(this);
  PostListIntlJa get postList => PostListIntlJa(this);
  PostDetailIntlJa get postDetail => PostDetailIntlJa(this);
  PostSearchIntlJa get postSearch => PostSearchIntlJa(this);
  ImageZoomIntlJa get imageZoom => ImageZoomIntlJa(this);
  DownloadsIntlJa get downloads => DownloadsIntlJa(this);
  AboutIntlJa get about => AboutIntlJa(this);
  SettingsIntlJa get settings => SettingsIntlJa(this);
}

class GenericIntlJa extends GenericIntl {
  final IntlJa _parent;
  const GenericIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "OK"
  /// ```
  String get ok => """OK""";

  /// ```dart
  /// "キャンセル"
  /// ```
  String get cancel => """キャンセル""";

  /// ```dart
  /// "クリア"
  /// ```
  String get clear => """クリア""";

  /// ```dart
  /// "確認"
  /// ```
  String get confirm => """確認""";

  /// ```dart
  /// "$value をクリップボードにコピーしました"
  /// ```
  String copiedWithValue(String value) => """$value をクリップボードにコピーしました""";

  /// ```dart
  /// "エラーが発生しました: $value"
  /// ```
  String errorWithValue(String value) => """エラーが発生しました: $value""";
}

class UpdateIntlJa extends UpdateIntl {
  final IntlJa _parent;
  const UpdateIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "アップデートを確認中…"
  /// ```
  String get checkUpdateStart => """アップデートを確認中…""";

  /// ```dart
  /// "アップデートの確認に失敗しました。インターネット接続を確認してください。"
  /// ```
  String get checkUpdateFailed => """アップデートの確認に失敗しました。インターネット接続を確認してください。""";

  /// ```dart
  /// "ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。"
  /// ```
  String get selectDownloadUrlFailed =>
      """ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。""";

  /// ```dart
  /// """
  /// 新しいバージョンが見つかりました: $version。
  /// 「ページについて」ページに移動し、「アップデートをダウンロード」をクリックしてください。
  /// """
  /// ```
  String newVersionFound(String version) => """新しいバージョンが見つかりました: $version。
「ページについて」ページに移動し、「アップデートをダウンロード」をクリックしてください。""";

  /// ```dart
  /// "新しいバージョンが見つかりません。"
  /// ```
  String get noNewVersionFound => """新しいバージョンが見つかりません。""";
}

class PostListIntlJa extends PostListIntl {
  final IntlJa _parent;
  const PostListIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "投稿"
  /// ```
  String get short => """投稿""";

  /// ```dart
  /// "投稿リスト"
  /// ```
  String get title => """投稿リスト""";

  /// ```dart
  /// "タグ付き投稿: $tags"
  /// ```
  String titleWithTags(String tags) => """タグ付き投稿: $tags""";
}

class PostDetailIntlJa extends PostDetailIntl {
  final IntlJa _parent;
  const PostDetailIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "投稿: $id"
  /// ```
  String titleWithId(int id) => """投稿: $id""";

  /// ```dart
  /// "作成日時"
  /// ```
  String get createdAt => """作成日時""";

  /// ```dart
  /// "作者"
  /// ```
  String get author => """作者""";

  /// ```dart
  /// "ソース"
  /// ```
  String get source => """ソース""";

  /// ```dart
  /// "幅"
  /// ```
  String get width => """幅""";

  /// ```dart
  /// "高さ"
  /// ```
  String get height => """高さ""";

  /// ```dart
  /// "スコア"
  /// ```
  String get score => """スコア""";

  /// ```dart
  /// "サイズ"
  /// ```
  String get size => """サイズ""";

  /// ```dart
  /// "親ID"
  /// ```
  String get parent => """親ID""";

  /// ```dart
  /// "子投稿があります"
  /// ```
  String get hasChildren => """子投稿があります""";

  /// ```dart
  /// "類似投稿"
  /// ```
  String get similarPosts => """類似投稿""";

  /// ```dart
  /// "親投稿"
  /// ```
  String get parentPost => """親投稿""";

  /// ```dart
  /// "子投稿"
  /// ```
  String get childPost => """子投稿""";
}

class PostSearchIntlJa extends PostSearchIntl {
  final IntlJa _parent;
  const PostSearchIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "検索"
  /// ```
  String get title => """検索""";
}

class ImageZoomIntlJa extends ImageZoomIntl {
  final IntlJa _parent;
  const ImageZoomIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "画像をズーム"
  /// ```
  String get title => """画像をズーム""";
}

class DownloadsIntlJa extends DownloadsIntl {
  final IntlJa _parent;
  const DownloadsIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "ダウンロード"
  /// ```
  String get title => """ダウンロード""";
  MessagesDownloadsIntlJa get messages => MessagesDownloadsIntlJa(this);
}

class MessagesDownloadsIntlJa extends MessagesDownloadsIntl {
  final DownloadsIntlJa _parent;
  const MessagesDownloadsIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "ストレージのアクセス許可が永久に拒否されました。\n設定で手動でストレージのアクセス許可を有効にしてください。"
  /// ```
  String get storagePermanentlyDenied =>
      """ストレージのアクセス許可が永久に拒否されました。\n設定で手動でストレージのアクセス許可を有効にしてください。""";

  /// ```dart
  /// "ストレージのアクセス許可が拒否されました。"
  /// ```
  String get storageDenied => """ストレージのアクセス許可が拒否されました。""";

  /// ```dart
  /// "デバイス情報を解析できません。"
  /// ```
  String get deviceInfoError => """デバイス情報を解析できません。""";

  /// ```dart
  /// "写真のアクセス許可が永久に拒否されました。\n設定で手動で写真のアクセス許可を有効にしてください。"
  /// ```
  String get photosPermanentlyDenied =>
      """写真のアクセス許可が永久に拒否されました。\n設定で手動で写真のアクセス許可を有効にしてください。""";

  /// ```dart
  /// "写真のアクセス許可が拒否されました。"
  /// ```
  String get photosDenied => """写真のアクセス許可が拒否されました。""";

  /// ```dart
  /// "ダウンロードタスクは既に存在しています。"
  /// ```
  String get downloadTaskExists => """ダウンロードタスクは既に存在しています。""";

  /// ```dart
  /// "画像ファイルは既に存在しています。"
  /// ```
  String get imageFileExists => """画像ファイルは既に存在しています。""";

  /// ```dart
  /// "ダウンロードタスクを再試行: $id"
  /// ```
  String downloadRetryWithId(int id) => """ダウンロードタスクを再試行: $id""";

  /// ```dart
  /// "ダウンロードタスクを開始: $id"
  /// ```
  String downloadStartWithId(int id) => """ダウンロードタスクを開始: $id""";

  /// ```dart
  /// "ダウンロード完了: タスク $id"
  /// ```
  String downloadCompletedWithId(int id) => """ダウンロード完了: タスク $id""";

  /// ```dart
  /// "ダウンロード失敗: タスク $id"
  /// ```
  String downloadFailedWithId(int id) => """ダウンロード失敗: タスク $id""";

  /// ```dart
  /// "保存失敗: タスク $id"
  /// ```
  String saveFailedWith(int id) => """保存失敗: タスク $id""";
}

class AboutIntlJa extends AboutIntl {
  final IntlJa _parent;
  const AboutIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "について"
  /// ```
  String get title => """について""";

  /// ```dart
  /// "プロジェクトURL"
  /// ```
  String get projectUrl => """プロジェクトURL""";

  /// ```dart
  /// "公開ページ"
  /// ```
  String get publishPage => """公開ページ""";

  /// ```dart
  /// "アプリバージョン"
  /// ```
  String get appVersion => """アプリバージョン""";

  /// ```dart
  /// "Dartバージョン"
  /// ```
  String get dartVersion => """Dartバージョン""";

  /// ```dart
  /// "Rustバージョン"
  /// ```
  String get rustVersion => """Rustバージョン""";

  /// ```dart
  /// "議論"
  /// ```
  String get discussion => """議論""";

  /// ```dart
  /// "アップデートをダウンロード"
  /// ```
  String get downloadUpdate => """アップデートをダウンロード""";

  /// ```dart
  /// "お使いのデバイス用に最新バージョンをブラウザでダウンロードしてください。"
  /// ```
  String get downloadUpdateHint => """お使いのデバイス用に最新バージョンをブラウザでダウンロードしてください。""";
}

class SettingsIntlJa extends SettingsIntl {
  final IntlJa _parent;
  const SettingsIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "設定"
  /// ```
  String get title => """設定""";

  /// ```dart
  /// "テーマ"
  /// ```
  String get theme => """テーマ""";

  /// ```dart
  /// "言語"
  /// ```
  String get language => """言語""";

  /// ```dart
  /// "ダウンロードパス"
  /// ```
  String get downloadPath => """ダウンロードパス""";

  /// ```dart
  /// "プラットフォームのデフォルト"
  /// ```
  String get platformDefault => """プラットフォームのデフォルト""";

  /// ```dart
  /// "行あたりの列数"
  /// ```
  String get waterfallColumns => """行あたりの列数""";

  /// ```dart
  /// "システム"
  /// ```
  String get system => """システム""";

  /// ```dart
  /// "ライト"
  /// ```
  String get light => """ライト""";

  /// ```dart
  /// "ダーク"
  /// ```
  String get dark => """ダーク""";
  LanguageDialogSettingsIntlJa get languageDialog =>
      LanguageDialogSettingsIntlJa(this);
  ThemeModeDialogSettingsIntlJa get themeModeDialog =>
      ThemeModeDialogSettingsIntlJa(this);
  SelectDownloadPathDialogSettingsIntlJa get selectDownloadPathDialog =>
      SelectDownloadPathDialogSettingsIntlJa(this);
  SetWaterfallColumnsDialogSettingsIntlJa get setWaterfallColumnsDialog =>
      SetWaterfallColumnsDialogSettingsIntlJa(this);
}

class LanguageDialogSettingsIntlJa extends LanguageDialogSettingsIntl {
  final SettingsIntlJa _parent;
  const LanguageDialogSettingsIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "言語を選択"
  /// ```
  String get title => """言語を選択""";
}

class ThemeModeDialogSettingsIntlJa extends ThemeModeDialogSettingsIntl {
  final SettingsIntlJa _parent;
  const ThemeModeDialogSettingsIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "テーマモードを選択"
  /// ```
  String get title => """テーマモードを選択""";
}

class SelectDownloadPathDialogSettingsIntlJa
    extends SelectDownloadPathDialogSettingsIntl {
  final SettingsIntlJa _parent;
  const SelectDownloadPathDialogSettingsIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "ダウンロードパスを選択"
  /// ```
  String get title => """ダウンロードパスを選択""";

  /// ```dart
  /// "ディレクトリを選択"
  /// ```
  String get pickerTitle => """ディレクトリを選択""";

  /// ```dart
  /// "ディレクトリを選択"
  /// ```
  String get pick => """ディレクトリを選択""";
  MessagesSelectDownloadPathDialogSettingsIntlJa get messages =>
      MessagesSelectDownloadPathDialogSettingsIntlJa(this);
}

class MessagesSelectDownloadPathDialogSettingsIntlJa
    extends MessagesSelectDownloadPathDialogSettingsIntl {
  final SelectDownloadPathDialogSettingsIntlJa _parent;
  const MessagesSelectDownloadPathDialogSettingsIntlJa(this._parent)
      : super(_parent);

  /// ```dart
  /// "ダウンロードパスがプラットフォームのデフォルトに設定されました。"
  /// ```
  String get setToPlatformDefault => """ダウンロードパスがプラットフォームのデフォルトに設定されました。""";

  /// ```dart
  /// "パスは絶対パスである必要があります。"
  /// ```
  String get pathNotAbsolute => """パスは絶対パスである必要があります。""";

  /// ```dart
  /// "パスに書き込みできません"
  /// ```
  String get pathNotWritable => """パスに書き込みできません""";
}

class SetWaterfallColumnsDialogSettingsIntlJa
    extends SetWaterfallColumnsDialogSettingsIntl {
  final SettingsIntlJa _parent;
  const SetWaterfallColumnsDialogSettingsIntlJa(this._parent) : super(_parent);

  /// ```dart
  /// "行あたりの列数を設定する"
  /// ```
  String get title => """行あたりの列数を設定する""";

  /// ```dart
  /// "現在 $value"
  /// ```
  String current(String value) => """現在 $value""";
}

Map<String, String> get intlJaMap => {
      """generic.ok""": """OK""",
      """generic.cancel""": """キャンセル""",
      """generic.clear""": """クリア""",
      """generic.confirm""": """確認""",
      """update.checkUpdateStart""": """アップデートを確認中…""",
      """update.checkUpdateFailed""":
          """アップデートの確認に失敗しました。インターネット接続を確認してください。""",
      """update.selectDownloadUrlFailed""":
          """ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。""",
      """update.noNewVersionFound""": """新しいバージョンが見つかりません。""",
      """postList.short""": """投稿""",
      """postList.title""": """投稿リスト""",
      """postDetail.createdAt""": """作成日時""",
      """postDetail.author""": """作者""",
      """postDetail.source""": """ソース""",
      """postDetail.width""": """幅""",
      """postDetail.height""": """高さ""",
      """postDetail.score""": """スコア""",
      """postDetail.size""": """サイズ""",
      """postDetail.parent""": """親ID""",
      """postDetail.hasChildren""": """子投稿があります""",
      """postDetail.similarPosts""": """類似投稿""",
      """postDetail.parentPost""": """親投稿""",
      """postDetail.childPost""": """子投稿""",
      """postSearch.title""": """検索""",
      """imageZoom.title""": """画像をズーム""",
      """downloads.title""": """ダウンロード""",
      """downloads.messages.storagePermanentlyDenied""":
          """ストレージのアクセス許可が永久に拒否されました。\n設定で手動でストレージのアクセス許可を有効にしてください。""",
      """downloads.messages.storageDenied""": """ストレージのアクセス許可が拒否されました。""",
      """downloads.messages.deviceInfoError""": """デバイス情報を解析できません。""",
      """downloads.messages.photosPermanentlyDenied""":
          """写真のアクセス許可が永久に拒否されました。\n設定で手動で写真のアクセス許可を有効にしてください。""",
      """downloads.messages.photosDenied""": """写真のアクセス許可が拒否されました。""",
      """downloads.messages.downloadTaskExists""": """ダウンロードタスクは既に存在しています。""",
      """downloads.messages.imageFileExists""": """画像ファイルは既に存在しています。""",
      """about.title""": """について""",
      """about.projectUrl""": """プロジェクトURL""",
      """about.publishPage""": """公開ページ""",
      """about.appVersion""": """アプリバージョン""",
      """about.dartVersion""": """Dartバージョン""",
      """about.rustVersion""": """Rustバージョン""",
      """about.discussion""": """議論""",
      """about.downloadUpdate""": """アップデートをダウンロード""",
      """about.downloadUpdateHint""":
          """お使いのデバイス用に最新バージョンをブラウザでダウンロードしてください。""",
      """settings.title""": """設定""",
      """settings.theme""": """テーマ""",
      """settings.language""": """言語""",
      """settings.downloadPath""": """ダウンロードパス""",
      """settings.platformDefault""": """プラットフォームのデフォルト""",
      """settings.waterfallColumns""": """行あたりの列数""",
      """settings.system""": """システム""",
      """settings.light""": """ライト""",
      """settings.dark""": """ダーク""",
      """settings.languageDialog.title""": """言語を選択""",
      """settings.themeModeDialog.title""": """テーマモードを選択""",
      """settings.selectDownloadPathDialog.title""": """ダウンロードパスを選択""",
      """settings.selectDownloadPathDialog.pickerTitle""": """ディレクトリを選択""",
      """settings.selectDownloadPathDialog.pick""": """ディレクトリを選択""",
      """settings.selectDownloadPathDialog.messages.setToPlatformDefault""":
          """ダウンロードパスがプラットフォームのデフォルトに設定されました。""",
      """settings.selectDownloadPathDialog.messages.pathNotAbsolute""":
          """パスは絶対パスである必要があります。""",
      """settings.selectDownloadPathDialog.messages.pathNotWritable""":
          """パスに書き込みできません""",
      """settings.setWaterfallColumnsDialog.title""": """行あたりの列数を設定する""",
    };
