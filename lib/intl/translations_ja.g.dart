///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsJa({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
       $meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.ja,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ),
       super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
    super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <ja>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

  late final TranslationsJa _root = this; // ignore: unused_field

  @override
  TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) =>
      TranslationsJa(meta: meta ?? this.$meta);

  // Translations
  @override
  late final _Translations$generic$ja generic = _Translations$generic$ja._(_root);
  @override
  late final _Translations$update$ja update = _Translations$update$ja._(_root);
  @override
  late final _Translations$postList$ja postList = _Translations$postList$ja._(_root);
  @override
  late final _Translations$postDetail$ja postDetail = _Translations$postDetail$ja._(_root);
  @override
  late final _Translations$postSearch$ja postSearch = _Translations$postSearch$ja._(_root);
  @override
  late final _Translations$imageZoom$ja imageZoom = _Translations$imageZoom$ja._(_root);
  @override
  late final _Translations$downloads$ja downloads = _Translations$downloads$ja._(_root);
  @override
  late final _Translations$about$ja about = _Translations$about$ja._(_root);
  @override
  late final _Translations$settings$ja settings = _Translations$settings$ja._(_root);
}

// Path: generic
class _Translations$generic$ja extends Translations$generic$en {
  _Translations$generic$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'キャンセル';
  @override
  String get clear => 'クリア';
  @override
  String get confirm => '確認';
  @override
  String get enabled => '有効';
  @override
  String get disabled => '無効';
  @override
  String copiedWithValue({required Object value}) => '${value} をクリップボードにコピーしました';
  @override
  String errorWithValue({required Object value}) => 'エラーが発生しました: ${value}';
  @override
  String errorWithCause({required Object message, required Object cause}) => '${message}: ${cause}';
  @override
  String get loading => '読み込み中...';
  @override
  String get loadFailed => '読み込みに失敗しました';
  @override
  String get retry => '再試行';
  @override
  String get noMoreData => 'これ以上データはありません';
  @override
  String get notFound => '見つかりませんでした';
}

// Path: update
class _Translations$update$ja extends Translations$update$en {
  _Translations$update$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get checkUpdateStart => 'アップデートを確認中…';
  @override
  String get checkUpdateFailed => 'アップデートの確認に失敗しました。インターネット接続を確認してください。';
  @override
  String get selectDownloadUrlFailed => 'ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。';
  @override
  String newVersionFound({required Object version}) =>
      '新しいバージョンが見つかりました: ${version}。\n「ページについて」ページに移動し、「アップデートをダウンロード」をクリックしてください。';
  @override
  String get noNewVersionFound => '新しいバージョンが見つかりません。';
}

// Path: postList
class _Translations$postList$ja extends Translations$postList$en {
  _Translations$postList$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get short => '投稿';
  @override
  String get title => '投稿リスト';
  @override
  String titleWithTags({required Object tags}) => 'タグ付き投稿: ${tags}';
  @override
  String get freepivPromotionTitle => 'freepiv をチェック';
  @override
  String get freepivPromotionSubtitle => 'モダンで快適なクロスプラットフォーム対応の Pixiv 非公式クライアントです。';
  @override
  String get freepivPromotionAction => 'プロジェクトを見る';
}

// Path: postDetail
class _Translations$postDetail$ja extends Translations$postDetail$en {
  _Translations$postDetail$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String titleWithId({required Object id}) => '投稿: ${id}';
  @override
  String get tags => 'タグ';
  @override
  String get details => '詳細';
  @override
  String get actions => '操作';
  @override
  String get rating => 'レーティング';
  @override
  String get fileType => 'ファイル形式';
  @override
  String get viewOriginal => 'オリジナルを表示';
  @override
  String get download => 'ダウンロード';
  @override
  String get relatedLoadFailed => '関連画像の読み込みに失敗しました。再試行できます。';
  @override
  String get createdAt => '作成日時';
  @override
  String get author => '作者';
  @override
  String get source => 'ソース';
  @override
  String get width => '幅';
  @override
  String get height => '高さ';
  @override
  String get score => 'スコア';
  @override
  String get size => 'サイズ';
  @override
  String get parent => '親ID';
  @override
  String get hasChildren => '子投稿があります';
  @override
  String get similarPosts => '類似投稿';
  @override
  String get parentPost => '親投稿';
  @override
  String get childPost => '子投稿';
}

// Path: postSearch
class _Translations$postSearch$ja extends Translations$postSearch$en {
  _Translations$postSearch$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '検索';
}

// Path: imageZoom
class _Translations$imageZoom$ja extends Translations$imageZoom$en {
  _Translations$imageZoom$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '画像をズーム';
}

// Path: downloads
class _Translations$downloads$ja extends Translations$downloads$en {
  _Translations$downloads$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'ダウンロード';
  @override
  String get tasksTitle => 'ダウンロードタスク';
  @override
  String get noTasks => 'ダウンロードタスクはありません';
  @override
  String get noTasksMessage => 'ダウンロードした画像がここに表示されます。';
  @override
  String get total => '合計';
  @override
  String get active => '実行中';
  @override
  String get saved => '保存済み';
  @override
  String get completed => '完了';
  @override
  String get failed => '失敗';
  @override
  String get waiting => '待機中';
  @override
  String get downloading => 'ダウンロード中';
  @override
  String get needsAttention => '確認が必要';
  @override
  String get queued => '待機中';
  @override
  String get running => 'ダウンロード中';
  @override
  String get paused => '一時停止';
  @override
  String get downloaded => 'ダウンロード済み';
  @override
  String get cancelled => 'キャンセル済み';
  @override
  String get savePending => '保存待ち';
  @override
  String get saving => '保存中';
  @override
  String get saveFailed => '保存失敗';
  @override
  String get retrySave => '保存を再試行';
  @override
  String get cancel => 'キャンセル';
  @override
  String get deleteTask => 'タスクを削除';
  @override
  String get sync => '同期';
  @override
  String get syncFailed => 'ダウンロード状態の同期に失敗しました';
  @override
  String get actionFailed => 'ダウンロード操作に失敗しました';
  @override
  String get expand => '展開';
  @override
  String get collapse => '折りたたむ';
  @override
  late final _Translations$downloads$messages$ja messages = _Translations$downloads$messages$ja._(_root);
}

// Path: about
class _Translations$about$ja extends Translations$about$en {
  _Translations$about$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'について';
  @override
  String get projectUrl => 'プロジェクトURL';
  @override
  String get publishPage => '公開ページ';
  @override
  String get appVersion => 'アプリバージョン';
  @override
  String get dartVersion => 'Dartバージョン';
  @override
  String get rustVersion => 'Rustバージョン';
  @override
  String get discussion => '議論';
  @override
  String get downloadUpdate => 'アップデートをダウンロード';
  @override
  String get downloadUpdateHint => 'お使いのデバイス用に最新バージョンをブラウザでダウンロードしてください。';
}

// Path: settings
class _Translations$settings$ja extends Translations$settings$en {
  _Translations$settings$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '設定';
  @override
  String get theme => 'テーマ';
  @override
  String get language => '言語';
  @override
  String get bypassSni => 'SNI をバイパス';
  @override
  String get downloadDirectory => 'ダウンロードディレクトリ';
  @override
  String get defaultToPlatformSettings => 'プラットフォームのデフォルトを使用';
  @override
  String get columnsPerRow => '各行の列数';
  @override
  String get maxConcurrentDownloads => '最大同時ダウンロードタスク数';
  @override
  String get maxSegmentsPerTask => '各ダウンロードタスクの最大セグメント数';
  @override
  String get platformDefault => 'プラットフォームのデフォルト';
  @override
  String get system => 'システム';
  @override
  String get light => 'ライト';
  @override
  String get dark => 'ダーク';
  @override
  late final _Translations$settings$languageDialog$ja languageDialog = _Translations$settings$languageDialog$ja._(
    _root,
  );
  @override
  late final _Translations$settings$themeModeDialog$ja themeModeDialog = _Translations$settings$themeModeDialog$ja._(
    _root,
  );
  @override
  late final _Translations$settings$downloadDirectoryDialog$ja downloadDirectoryDialog =
      _Translations$settings$downloadDirectoryDialog$ja._(_root);
  @override
  late final _Translations$settings$bypassSniDialog$ja bypassSniDialog = _Translations$settings$bypassSniDialog$ja._(
    _root,
  );
  @override
  late final _Translations$settings$columnsPerRowDialog$ja columnsPerRowDialog =
      _Translations$settings$columnsPerRowDialog$ja._(_root);
  @override
  late final _Translations$settings$maxConcurrentDownloadsDialog$ja maxConcurrentDownloadsDialog =
      _Translations$settings$maxConcurrentDownloadsDialog$ja._(_root);
  @override
  late final _Translations$settings$maxSegmentsPerTaskDialog$ja maxSegmentsPerTaskDialog =
      _Translations$settings$maxSegmentsPerTaskDialog$ja._(_root);
}

// Path: downloads.messages
class _Translations$downloads$messages$ja extends Translations$downloads$messages$en {
  _Translations$downloads$messages$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get storagePermanentlyDenied => 'ストレージのアクセス許可が永久に拒否されました。\n設定で手動でストレージのアクセス許可を有効にしてください。';
  @override
  String get storageDenied => 'ストレージのアクセス許可が拒否されました。';
  @override
  String get deviceInfoError => 'デバイス情報を解析できません。';
  @override
  String get photosPermanentlyDenied => '写真のアクセス許可が永久に拒否されました。\n設定で手動で写真のアクセス許可を有効にしてください。';
  @override
  String get photosDenied => '写真のアクセス許可が拒否されました。';
  @override
  String get downloadTaskExists => 'ダウンロードタスクは既に存在しています。';
  @override
  String get imageFileExists => '画像ファイルは既に存在しています。';
  @override
  String downloadRetryWith({required Object name}) => 'ダウンロードタスクを再試行: ${name}';
  @override
  String downloadStartWith({required Object name}) => 'ダウンロードタスクを開始: ${name}';
  @override
  String downloadCompletedWith({required Object name}) => 'ダウンロード完了: タスク ${name}';
  @override
  String downloadFailedWith({required Object name}) => 'ダウンロード失敗: タスク ${name}';
  @override
  String saveFailedWith({required Object name}) => '保存失敗: タスク ${name}';
}

// Path: settings.languageDialog
class _Translations$settings$languageDialog$ja extends Translations$settings$languageDialog$en {
  _Translations$settings$languageDialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '言語';
}

// Path: settings.themeModeDialog
class _Translations$settings$themeModeDialog$ja extends Translations$settings$themeModeDialog$en {
  _Translations$settings$themeModeDialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'テーマモード';
}

// Path: settings.downloadDirectoryDialog
class _Translations$settings$downloadDirectoryDialog$ja extends Translations$settings$downloadDirectoryDialog$en {
  _Translations$settings$downloadDirectoryDialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'ダウンロードディレクトリ';
  @override
  String get pickerTitle => 'ディレクトリを選択';
  @override
  String get pick => 'ディレクトリを選択';
  @override
  late final _Translations$settings$downloadDirectoryDialog$messages$ja messages =
      _Translations$settings$downloadDirectoryDialog$messages$ja._(_root);
}

// Path: settings.bypassSniDialog
class _Translations$settings$bypassSniDialog$ja extends Translations$settings$bypassSniDialog$en {
  _Translations$settings$bypassSniDialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'SNI をバイパス';
}

// Path: settings.columnsPerRowDialog
class _Translations$settings$columnsPerRowDialog$ja extends Translations$settings$columnsPerRowDialog$en {
  _Translations$settings$columnsPerRowDialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '各行の列数';
}

// Path: settings.maxConcurrentDownloadsDialog
class _Translations$settings$maxConcurrentDownloadsDialog$ja
    extends Translations$settings$maxConcurrentDownloadsDialog$en {
  _Translations$settings$maxConcurrentDownloadsDialog$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '最大同時ダウンロードタスク数';
}

// Path: settings.maxSegmentsPerTaskDialog
class _Translations$settings$maxSegmentsPerTaskDialog$ja extends Translations$settings$maxSegmentsPerTaskDialog$en {
  _Translations$settings$maxSegmentsPerTaskDialog$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '各ダウンロードタスクの最大セグメント数';
}

// Path: settings.downloadDirectoryDialog.messages
class _Translations$settings$downloadDirectoryDialog$messages$ja
    extends Translations$settings$downloadDirectoryDialog$messages$en {
  _Translations$settings$downloadDirectoryDialog$messages$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get setToPlatformDefault => 'ダウンロードディレクトリはプラットフォームのデフォルトに設定されています。';
  @override
  String get pathNotAbsolute => 'パスは絶対パスである必要があります。';
  @override
  String get pathNotWritable => 'パスに書き込みできません。';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'generic.ok' => 'OK',
      'generic.cancel' => 'キャンセル',
      'generic.clear' => 'クリア',
      'generic.confirm' => '確認',
      'generic.enabled' => '有効',
      'generic.disabled' => '無効',
      'generic.copiedWithValue' => ({required Object value}) => '${value} をクリップボードにコピーしました',
      'generic.errorWithValue' => ({required Object value}) => 'エラーが発生しました: ${value}',
      'generic.errorWithCause' => ({required Object message, required Object cause}) => '${message}: ${cause}',
      'generic.loading' => '読み込み中...',
      'generic.loadFailed' => '読み込みに失敗しました',
      'generic.retry' => '再試行',
      'generic.noMoreData' => 'これ以上データはありません',
      'generic.notFound' => '見つかりませんでした',
      'update.checkUpdateStart' => 'アップデートを確認中…',
      'update.checkUpdateFailed' => 'アップデートの確認に失敗しました。インターネット接続を確認してください。',
      'update.selectDownloadUrlFailed' => 'ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。',
      'update.newVersionFound' =>
        ({required Object version}) => '新しいバージョンが見つかりました: ${version}。\n「ページについて」ページに移動し、「アップデートをダウンロード」をクリックしてください。',
      'update.noNewVersionFound' => '新しいバージョンが見つかりません。',
      'postList.short' => '投稿',
      'postList.title' => '投稿リスト',
      'postList.titleWithTags' => ({required Object tags}) => 'タグ付き投稿: ${tags}',
      'postList.freepivPromotionTitle' => 'freepiv をチェック',
      'postList.freepivPromotionSubtitle' => 'モダンで快適なクロスプラットフォーム対応の Pixiv 非公式クライアントです。',
      'postList.freepivPromotionAction' => 'プロジェクトを見る',
      'postDetail.titleWithId' => ({required Object id}) => '投稿: ${id}',
      'postDetail.tags' => 'タグ',
      'postDetail.details' => '詳細',
      'postDetail.actions' => '操作',
      'postDetail.rating' => 'レーティング',
      'postDetail.fileType' => 'ファイル形式',
      'postDetail.viewOriginal' => 'オリジナルを表示',
      'postDetail.download' => 'ダウンロード',
      'postDetail.relatedLoadFailed' => '関連画像の読み込みに失敗しました。再試行できます。',
      'postDetail.createdAt' => '作成日時',
      'postDetail.author' => '作者',
      'postDetail.source' => 'ソース',
      'postDetail.width' => '幅',
      'postDetail.height' => '高さ',
      'postDetail.score' => 'スコア',
      'postDetail.size' => 'サイズ',
      'postDetail.parent' => '親ID',
      'postDetail.hasChildren' => '子投稿があります',
      'postDetail.similarPosts' => '類似投稿',
      'postDetail.parentPost' => '親投稿',
      'postDetail.childPost' => '子投稿',
      'postSearch.title' => '検索',
      'imageZoom.title' => '画像をズーム',
      'downloads.title' => 'ダウンロード',
      'downloads.tasksTitle' => 'ダウンロードタスク',
      'downloads.noTasks' => 'ダウンロードタスクはありません',
      'downloads.noTasksMessage' => 'ダウンロードした画像がここに表示されます。',
      'downloads.total' => '合計',
      'downloads.active' => '実行中',
      'downloads.saved' => '保存済み',
      'downloads.completed' => '完了',
      'downloads.failed' => '失敗',
      'downloads.waiting' => '待機中',
      'downloads.downloading' => 'ダウンロード中',
      'downloads.needsAttention' => '確認が必要',
      'downloads.queued' => '待機中',
      'downloads.running' => 'ダウンロード中',
      'downloads.paused' => '一時停止',
      'downloads.downloaded' => 'ダウンロード済み',
      'downloads.cancelled' => 'キャンセル済み',
      'downloads.savePending' => '保存待ち',
      'downloads.saving' => '保存中',
      'downloads.saveFailed' => '保存失敗',
      'downloads.retrySave' => '保存を再試行',
      'downloads.cancel' => 'キャンセル',
      'downloads.deleteTask' => 'タスクを削除',
      'downloads.sync' => '同期',
      'downloads.syncFailed' => 'ダウンロード状態の同期に失敗しました',
      'downloads.actionFailed' => 'ダウンロード操作に失敗しました',
      'downloads.expand' => '展開',
      'downloads.collapse' => '折りたたむ',
      'downloads.messages.storagePermanentlyDenied' => 'ストレージのアクセス許可が永久に拒否されました。\n設定で手動でストレージのアクセス許可を有効にしてください。',
      'downloads.messages.storageDenied' => 'ストレージのアクセス許可が拒否されました。',
      'downloads.messages.deviceInfoError' => 'デバイス情報を解析できません。',
      'downloads.messages.photosPermanentlyDenied' => '写真のアクセス許可が永久に拒否されました。\n設定で手動で写真のアクセス許可を有効にしてください。',
      'downloads.messages.photosDenied' => '写真のアクセス許可が拒否されました。',
      'downloads.messages.downloadTaskExists' => 'ダウンロードタスクは既に存在しています。',
      'downloads.messages.imageFileExists' => '画像ファイルは既に存在しています。',
      'downloads.messages.downloadRetryWith' => ({required Object name}) => 'ダウンロードタスクを再試行: ${name}',
      'downloads.messages.downloadStartWith' => ({required Object name}) => 'ダウンロードタスクを開始: ${name}',
      'downloads.messages.downloadCompletedWith' => ({required Object name}) => 'ダウンロード完了: タスク ${name}',
      'downloads.messages.downloadFailedWith' => ({required Object name}) => 'ダウンロード失敗: タスク ${name}',
      'downloads.messages.saveFailedWith' => ({required Object name}) => '保存失敗: タスク ${name}',
      'about.title' => 'について',
      'about.projectUrl' => 'プロジェクトURL',
      'about.publishPage' => '公開ページ',
      'about.appVersion' => 'アプリバージョン',
      'about.dartVersion' => 'Dartバージョン',
      'about.rustVersion' => 'Rustバージョン',
      'about.discussion' => '議論',
      'about.downloadUpdate' => 'アップデートをダウンロード',
      'about.downloadUpdateHint' => 'お使いのデバイス用に最新バージョンをブラウザでダウンロードしてください。',
      'settings.title' => '設定',
      'settings.theme' => 'テーマ',
      'settings.language' => '言語',
      'settings.bypassSni' => 'SNI をバイパス',
      'settings.downloadDirectory' => 'ダウンロードディレクトリ',
      'settings.defaultToPlatformSettings' => 'プラットフォームのデフォルトを使用',
      'settings.columnsPerRow' => '各行の列数',
      'settings.maxConcurrentDownloads' => '最大同時ダウンロードタスク数',
      'settings.maxSegmentsPerTask' => '各ダウンロードタスクの最大セグメント数',
      'settings.platformDefault' => 'プラットフォームのデフォルト',
      'settings.system' => 'システム',
      'settings.light' => 'ライト',
      'settings.dark' => 'ダーク',
      'settings.languageDialog.title' => '言語',
      'settings.themeModeDialog.title' => 'テーマモード',
      'settings.downloadDirectoryDialog.title' => 'ダウンロードディレクトリ',
      'settings.downloadDirectoryDialog.pickerTitle' => 'ディレクトリを選択',
      'settings.downloadDirectoryDialog.pick' => 'ディレクトリを選択',
      'settings.downloadDirectoryDialog.messages.setToPlatformDefault' => 'ダウンロードディレクトリはプラットフォームのデフォルトに設定されています。',
      'settings.downloadDirectoryDialog.messages.pathNotAbsolute' => 'パスは絶対パスである必要があります。',
      'settings.downloadDirectoryDialog.messages.pathNotWritable' => 'パスに書き込みできません。',
      'settings.bypassSniDialog.title' => 'SNI をバイパス',
      'settings.columnsPerRowDialog.title' => '各行の列数',
      'settings.maxConcurrentDownloadsDialog.title' => '最大同時ダウンロードタスク数',
      'settings.maxSegmentsPerTaskDialog.title' => '各ダウンロードタスクの最大セグメント数',
      _ => null,
    };
  }
}
