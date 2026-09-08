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
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.ja,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ),
       super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <ja>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key) ?? super[key];

  late final TranslationsJa _root = this; // ignore: unused_field

  @override
  TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) =>
      TranslationsJa(meta: meta ?? this.$meta);

  // Translations
  @override
  late final _Translations$generic$ja generic = _Translations$generic$ja._(_root);
  @override
  late final _Translations$booruError$ja booruError = _Translations$booruError$ja._(_root);
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
  @override
  late final _Translations$discovery$ja discovery = _Translations$discovery$ja._(_root);
  @override
  late final _Translations$mediaError$ja mediaError = _Translations$mediaError$ja._(_root);
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

// Path: booruError
class _Translations$booruError$ja extends Translations$booruError$en {
  _Translations$booruError$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get invalidRequest => 'リクエストが無効です。';
  @override
  String get unsupportedCapability => 'この画像ソースは要求された操作に対応していません。';
  @override
  String get authenticationRequired => 'この画像ソースにログインしてから再試行してください。';
  @override
  String get authenticationRejected => '画像ソースがアカウント認証情報を拒否しました。';
  @override
  String get permissionDenied => '画像ソースがこのリソースへのアクセスを拒否しました。';
  @override
  String get rateLimited => '画像ソースのレート制限中です。しばらくしてから再試行してください。';
  @override
  String get challengeRequired => '画像ソースでブラウザによる確認が必要です。ブラウザで開いて確認を完了するか、別の画像ソースを選択してください。';
  @override
  String get routeUnavailable => 'このドメインのルートがありません。ネットワーク設定で更新してください。システム DNS には切り替えません。';
  @override
  String get sourceUnavailable => '画像ソースは現在利用できません。';
  @override
  String get network => 'ネットワークリクエストに失敗しました。インターネット接続を確認して再試行してください。問題が続く場合は、プロキシサーバーの利用を試すこともできます。';
  @override
  String get timeout => 'リクエストがタイムアウトしました。インターネット接続を確認するか、しばらくしてから再試行してください。';
  @override
  String get invalidResponse => '画像ソースから無効なレスポンスが返されました。';
  @override
  String get unsafeRedirect => '画像ソースから安全でないリダイレクトが返されました。';
  @override
  String get mediaValidationFailed => '画像レスポンスを検証またはデコードできませんでした。';
  @override
  String get cancelled => 'リクエストはキャンセルされました。';
  @override
  String get internal => 'Booru エンジンの内部エラーが発生しました。';
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
  String get short => 'ホーム';
  @override
  String get title => 'ホーム';
  @override
  String titleWithTags({required Object tags}) => 'タグ付き投稿: ${tags}';
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
  String get unknownAuthor => '不明';
  @override
  String get imageSource => '画像サイト';
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
  String get freepivPromotionTitle => 'freepiv をチェック';
  @override
  String get freepivPromotionSubtitle => 'モダンで快適なクロスプラットフォーム対応の Pixiv 非公式クライアントです。';
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
  String get auto => '自動';
  @override
  String get downloadsOverview => '保存先と同時ダウンロード数';
  @override
  late final _Translations$settings$sections$ja sections = _Translations$settings$sections$ja._(_root);
  @override
  late final _Translations$settings$source$ja source = _Translations$settings$source$ja._(_root);
  @override
  late final _Translations$settings$account$ja account = _Translations$settings$account$ja._(_root);
  @override
  late final _Translations$settings$network$ja network = _Translations$settings$network$ja._(_root);
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

// Path: discovery
class _Translations$discovery$ja extends Translations$discovery$en {
  _Translations$discovery$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get searchResults => '検索結果';
  @override
  String get allAvailable => '表示可能なすべてのコンテンツ';
  @override
  String get defaultRatingsHint => 'レーティング設定はすべての画像ソースに共通です。未選択時は、現在の画像ソースとアカウントで閲覧できるすべてのコンテンツを表示します。';
  @override
  String get resetFilters => '初期設定に戻す';
  @override
  String get unsupportedRatings => '選択したレーティングはこの画像ソースで利用できません。初期設定に戻してください。';
  @override
  String get noFilteredPosts => '現在の絞り込み条件に一致する投稿はありません。';
  @override
  String get noSearchResults => '検索条件に一致する投稿はありません。';
  @override
  String get noFeedPosts => 'この画像ソースには現在表示できる投稿がありません。';
  @override
  String get historicalPopular => '過去の人気';
  @override
  String get calendarDay => '日別';
  @override
  String get calendarWeek => '週別';
  @override
  String get calendarMonth => '月別';
  @override
  String get latest => '最新';
  @override
  String get popular => '人気';
  @override
  String get today => '今日';
  @override
  String get thisWeek => '今週';
  @override
  String get thisMonth => '今月';
  @override
  String get lastDay => '過去24時間';
  @override
  String get lastThreeDays => '過去3日間';
  @override
  String get lastWeek => '過去1週間';
  @override
  String get lastMonth => '過去1か月';
  @override
  String get lastThreeMonths => '過去3か月';
  @override
  String get lastSixMonths => '過去6か月';
  @override
  String get lastYear => '過去1年';
  @override
  String get rankingComplete => 'ランキングをすべて読み込みました';
  @override
  String get latestFallback => 'このサイトでは最新の投稿のみ利用できます。';
  @override
  String get filters => '絞り込み';
  @override
  String get loadMore => 'さらに読み込む';
  @override
  String get filteredContinue => 'この範囲に該当する投稿はありません。続きを表示';
  @override
  String get commonTags => 'よく使われるタグ';
  @override
  String get moreTags => 'もっと見る';
  @override
  String get tagSource => '対象サイト';
  @override
  String get allTagSources => 'すべてのサイト';
  @override
  String get manageTags => 'カスタムタグ';
  @override
  String get addTag => 'タグを追加';
  @override
  String get noCustomTags => 'カスタムタグはまだありません';
  @override
  String get customTagsHint => 'タグに覚えやすい名前を付けると、検索で見つけやすくなります。';
  @override
  String get addCustomTag => 'カスタムタグとして追加';
  @override
  String get editTag => 'カスタムタグを編集';
  @override
  String get canonicalTag => 'サイトのタグ';
  @override
  String get displayName => '表示名（任意）';
  @override
  String get invalidTag => '空白を含まないタグを1つ入力してください。';
  @override
  String get queryHint => 'タグやサイトの検索式を入力…';
  @override
  String get unverifiedTag => 'このサイトで未確認のタグがあります。そのまま検索できます。';
  @override
  String get verifiedTag => 'このサイトで確認済み';
  @override
  String get noSuggestions => '候補がありません';
  @override
  String get localFallback => 'オンライン候補を取得できません。ローカル候補を利用できます。';
  @override
  String get retryTags => 'よく使われるタグを再取得';
  @override
  String get artist => '作者';
  @override
  String get character => 'キャラクター';
  @override
  String get copyright => '作品';
  @override
  String get meta => 'メタ';
  @override
  String get general => '一般';
  @override
  String get random => 'ランダム';
  @override
  String get lifetimeViews => '累計閲覧数';
  @override
  String get lifetimeFavorites => '累計お気に入り数';
}

// Path: mediaError
class _Translations$mediaError$ja extends Translations$mediaError$en {
  _Translations$mediaError$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '画像の読み込みに失敗しました';
  @override
  String get details => 'エラーの詳細';
  @override
  String get copyDetails => '詳細をコピー';
  @override
  String get decodeFailed => 'ダウンロードした画像をデコードできませんでした。再試行すると、この画像のキャッシュを削除して再ダウンロードします。';
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

// Path: settings.sections
class _Translations$settings$sections$ja extends Translations$settings$sections$en {
  _Translations$settings$sections$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get sourcesAndAccounts => 'サイトとアカウント';
  @override
  String get accounts => 'アカウント';
  @override
  String get network => 'ネットワーク';
  @override
  String get general => '一般';
  @override
  String get downloads => 'ダウンロード';
}

// Path: settings.source
class _Translations$settings$source$ja extends Translations$settings$source$en {
  _Translations$settings$source$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get defaultSource => '既定のサイト';
  @override
  String get supportedRatings => '対応するレーティング';
  @override
  String get safetyRating => '全画像ソースのレーティング';
}

// Path: settings.account
class _Translations$settings$account$ja extends Translations$settings$account$en {
  _Translations$settings$account$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get manageAllSubtitle => 'サイトのレーティングとアカウント設定';
  @override
  String get noAccountRequired => 'アカウント設定は不要です';
  @override
  String get openSignInPage => 'ログインページを開く';
  @override
  String get cookieHeader => 'Cookie ヘッダー';
  @override
  String get storedLocally => 'このデバイス内に保存';
  @override
  String get browserUserAgent => 'ブラウザーの User-Agent';
  @override
  String get browserUserAgentHint => 'ログインしたブラウザーと同じ User-Agent を使用';
  @override
  String get required => '必須';
  @override
  String get optional => '任意';
  @override
  String get actions => 'アカウント操作';
  @override
  String get save => '保存';
  @override
  String get verify => '検証';
  @override
  String get signOut => 'サインアウト';
  @override
  String get saved => 'アカウントを保存しました';
  @override
  String get saveFailed => 'アカウントを保存できませんでした';
  @override
  String get verified => 'アカウントを検証しました';
  @override
  String get verificationFailed => '検証に失敗しました';
  @override
  String get username => 'ユーザー名';
  @override
  String get userId => 'ユーザー ID';
  @override
  String get apiKey => 'API キー';
  @override
  String statusValue({required Object status}) => '状態 · ${status}';
  @override
  late final _Translations$settings$account$statuses$ja statuses = _Translations$settings$account$statuses$ja._(_root);
}

// Path: settings.network
class _Translations$settings$network$ja extends Translations$settings$network$en {
  _Translations$settings$network$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get dnsProvider => 'DNS サービス';
  @override
  String get servicesTitle => '全画像サイトの状態';
  @override
  String get servicesHint => 'IP 解決と API の接続を個別に確認します。API が利用可能でも、すべての画像を取得できるとは限りません。';
  @override
  String get noFallback => '選択した DNS のみを使用します。失敗時はエラーを表示し、システム DNS や別のサービスには切り替えません。';
  @override
  String checkProgress({
    required Object done,
    required Object total,
    required Object checked,
    required Object sources,
  }) => 'DNS ${done}/${total} · API ${checked}/${sources}';
  @override
  String checkSummary({required Object available, required Object total, required Object failed}) =>
      'API 利用可能 ${available}/${total} · DNS 失敗 ${failed} 件';
  @override
  String get loadingStatus => 'キャッシュの状態を読み込み中…';
  @override
  String get apiChecking => 'API：確認中…';
  @override
  String get apiAvailable => 'API：利用可能';
  @override
  String get apiFailed => 'API：利用不可';
  @override
  String get apiUnchecked => 'API：未確認';
  @override
  String get dnsPending => '未解決 · ルートを更新して IP を取得';
  @override
  String get dnsResolving => '名前解決中…';
  @override
  String get dnsResolved => '名前解決成功';
  @override
  String get dnsCached => 'キャッシュ済み IP を使用 · 再確認していません';
  @override
  String get dnsFailed => '名前解決失敗 · 利用可能なルートなし';
  @override
  String get dnsQueued => '名前解決を待機中…';
  @override
  String ipCachedAt({required Object time}) => 'IP をキャッシュ済み · 更新日時 ${time}';
  @override
  String get ipNotCached => 'IP 解決済み · まだ保存されていません';
  @override
  String get connectionMode => '接続モード';
  @override
  String get proxyUrl => 'プロキシ URL';
  @override
  String get proxyHint => '任意 · 例 http://127.0.0.1:7890';
  @override
  String get applyAndRouteCache => '適用とルートキャッシュ';
  @override
  String get apply => 'ネットワーク設定を適用';
  @override
  String get refreshRoutes => 'ルートを更新';
  @override
  String get routeCacheUnavailable => 'ルートキャッシュを利用できません';
  @override
  String routeCacheStatus({required Object hosts, required Object revision}) => '${hosts} ホスト · リビジョン ${revision}';
  @override
  String get applied => 'ネットワーク設定を適用しました';
  @override
  String get invalidSettings => 'ネットワーク設定が無効です';
  @override
  String get routeRefreshFailed => 'ルートの更新に失敗しました';
  @override
  String get systemDns => 'システム DNS';
  @override
  String get sniBypass => 'SNI バイパス';
  @override
  String get legacyIpUrl => '従来の IP URL';
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

// Path: settings.account.statuses
class _Translations$settings$account$statuses$ja extends Translations$settings$account$statuses$en {
  _Translations$settings$account$statuses$ja._(TranslationsJa root) : this._root = root, super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get notConfigured => '未設定';
  @override
  String get configuredUnverified => '設定済み・未検証';
  @override
  String get verified => '検証済み';
  @override
  String get rejected => '拒否されました';
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
      'booruError.invalidRequest' => 'リクエストが無効です。',
      'booruError.unsupportedCapability' => 'この画像ソースは要求された操作に対応していません。',
      'booruError.authenticationRequired' => 'この画像ソースにログインしてから再試行してください。',
      'booruError.authenticationRejected' => '画像ソースがアカウント認証情報を拒否しました。',
      'booruError.permissionDenied' => '画像ソースがこのリソースへのアクセスを拒否しました。',
      'booruError.rateLimited' => '画像ソースのレート制限中です。しばらくしてから再試行してください。',
      'booruError.challengeRequired' => '画像ソースでブラウザによる確認が必要です。ブラウザで開いて確認を完了するか、別の画像ソースを選択してください。',
      'booruError.routeUnavailable' => 'このドメインのルートがありません。ネットワーク設定で更新してください。システム DNS には切り替えません。',
      'booruError.sourceUnavailable' => '画像ソースは現在利用できません。',
      'booruError.network' => 'ネットワークリクエストに失敗しました。インターネット接続を確認して再試行してください。問題が続く場合は、プロキシサーバーの利用を試すこともできます。',
      'booruError.timeout' => 'リクエストがタイムアウトしました。インターネット接続を確認するか、しばらくしてから再試行してください。',
      'booruError.invalidResponse' => '画像ソースから無効なレスポンスが返されました。',
      'booruError.unsafeRedirect' => '画像ソースから安全でないリダイレクトが返されました。',
      'booruError.mediaValidationFailed' => '画像レスポンスを検証またはデコードできませんでした。',
      'booruError.cancelled' => 'リクエストはキャンセルされました。',
      'booruError.internal' => 'Booru エンジンの内部エラーが発生しました。',
      'update.checkUpdateStart' => 'アップデートを確認中…',
      'update.checkUpdateFailed' => 'アップデートの確認に失敗しました。インターネット接続を確認してください。',
      'update.selectDownloadUrlFailed' => 'ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。',
      'update.newVersionFound' =>
        ({required Object version}) => '新しいバージョンが見つかりました: ${version}。\n「ページについて」ページに移動し、「アップデートをダウンロード」をクリックしてください。',
      'update.noNewVersionFound' => '新しいバージョンが見つかりません。',
      'postList.short' => 'ホーム',
      'postList.title' => 'ホーム',
      'postList.titleWithTags' => ({required Object tags}) => 'タグ付き投稿: ${tags}',
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
      'postDetail.unknownAuthor' => '不明',
      'postDetail.imageSource' => '画像サイト',
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
      'about.freepivPromotionTitle' => 'freepiv をチェック',
      'about.freepivPromotionSubtitle' => 'モダンで快適なクロスプラットフォーム対応の Pixiv 非公式クライアントです。',
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
      'settings.auto' => '自動',
      'settings.downloadsOverview' => '保存先と同時ダウンロード数',
      'settings.sections.sourcesAndAccounts' => 'サイトとアカウント',
      'settings.sections.accounts' => 'アカウント',
      'settings.sections.network' => 'ネットワーク',
      'settings.sections.general' => '一般',
      'settings.sections.downloads' => 'ダウンロード',
      'settings.source.defaultSource' => '既定のサイト',
      'settings.source.supportedRatings' => '対応するレーティング',
      'settings.source.safetyRating' => '全画像ソースのレーティング',
      'settings.account.manageAllSubtitle' => 'サイトのレーティングとアカウント設定',
      'settings.account.noAccountRequired' => 'アカウント設定は不要です',
      'settings.account.openSignInPage' => 'ログインページを開く',
      'settings.account.cookieHeader' => 'Cookie ヘッダー',
      'settings.account.storedLocally' => 'このデバイス内に保存',
      'settings.account.browserUserAgent' => 'ブラウザーの User-Agent',
      'settings.account.browserUserAgentHint' => 'ログインしたブラウザーと同じ User-Agent を使用',
      'settings.account.required' => '必須',
      'settings.account.optional' => '任意',
      'settings.account.actions' => 'アカウント操作',
      'settings.account.save' => '保存',
      'settings.account.verify' => '検証',
      'settings.account.signOut' => 'サインアウト',
      'settings.account.saved' => 'アカウントを保存しました',
      'settings.account.saveFailed' => 'アカウントを保存できませんでした',
      'settings.account.verified' => 'アカウントを検証しました',
      'settings.account.verificationFailed' => '検証に失敗しました',
      'settings.account.username' => 'ユーザー名',
      'settings.account.userId' => 'ユーザー ID',
      'settings.account.apiKey' => 'API キー',
      'settings.account.statusValue' => ({required Object status}) => '状態 · ${status}',
      'settings.account.statuses.notConfigured' => '未設定',
      'settings.account.statuses.configuredUnverified' => '設定済み・未検証',
      'settings.account.statuses.verified' => '検証済み',
      'settings.account.statuses.rejected' => '拒否されました',
      'settings.network.dnsProvider' => 'DNS サービス',
      'settings.network.servicesTitle' => '全画像サイトの状態',
      'settings.network.servicesHint' => 'IP 解決と API の接続を個別に確認します。API が利用可能でも、すべての画像を取得できるとは限りません。',
      'settings.network.noFallback' => '選択した DNS のみを使用します。失敗時はエラーを表示し、システム DNS や別のサービスには切り替えません。',
      'settings.network.checkProgress' =>
        ({required Object done, required Object total, required Object checked, required Object sources}) =>
            'DNS ${done}/${total} · API ${checked}/${sources}',
      'settings.network.checkSummary' =>
        ({required Object available, required Object total, required Object failed}) =>
            'API 利用可能 ${available}/${total} · DNS 失敗 ${failed} 件',
      'settings.network.loadingStatus' => 'キャッシュの状態を読み込み中…',
      'settings.network.apiChecking' => 'API：確認中…',
      'settings.network.apiAvailable' => 'API：利用可能',
      'settings.network.apiFailed' => 'API：利用不可',
      'settings.network.apiUnchecked' => 'API：未確認',
      'settings.network.dnsPending' => '未解決 · ルートを更新して IP を取得',
      'settings.network.dnsResolving' => '名前解決中…',
      'settings.network.dnsResolved' => '名前解決成功',
      'settings.network.dnsCached' => 'キャッシュ済み IP を使用 · 再確認していません',
      'settings.network.dnsFailed' => '名前解決失敗 · 利用可能なルートなし',
      'settings.network.dnsQueued' => '名前解決を待機中…',
      'settings.network.ipCachedAt' => ({required Object time}) => 'IP をキャッシュ済み · 更新日時 ${time}',
      'settings.network.ipNotCached' => 'IP 解決済み · まだ保存されていません',
      'settings.network.connectionMode' => '接続モード',
      'settings.network.proxyUrl' => 'プロキシ URL',
      'settings.network.proxyHint' => '任意 · 例 http://127.0.0.1:7890',
      'settings.network.applyAndRouteCache' => '適用とルートキャッシュ',
      'settings.network.apply' => 'ネットワーク設定を適用',
      'settings.network.refreshRoutes' => 'ルートを更新',
      'settings.network.routeCacheUnavailable' => 'ルートキャッシュを利用できません',
      'settings.network.routeCacheStatus' =>
        ({required Object hosts, required Object revision}) => '${hosts} ホスト · リビジョン ${revision}',
      'settings.network.applied' => 'ネットワーク設定を適用しました',
      'settings.network.invalidSettings' => 'ネットワーク設定が無効です',
      'settings.network.routeRefreshFailed' => 'ルートの更新に失敗しました',
      'settings.network.systemDns' => 'システム DNS',
      'settings.network.sniBypass' => 'SNI バイパス',
      'settings.network.legacyIpUrl' => '従来の IP URL',
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
      'discovery.searchResults' => '検索結果',
      'discovery.allAvailable' => '表示可能なすべてのコンテンツ',
      'discovery.defaultRatingsHint' => 'レーティング設定はすべての画像ソースに共通です。未選択時は、現在の画像ソースとアカウントで閲覧できるすべてのコンテンツを表示します。',
      'discovery.resetFilters' => '初期設定に戻す',
      'discovery.unsupportedRatings' => '選択したレーティングはこの画像ソースで利用できません。初期設定に戻してください。',
      'discovery.noFilteredPosts' => '現在の絞り込み条件に一致する投稿はありません。',
      'discovery.noSearchResults' => '検索条件に一致する投稿はありません。',
      'discovery.noFeedPosts' => 'この画像ソースには現在表示できる投稿がありません。',
      'discovery.historicalPopular' => '過去の人気',
      'discovery.calendarDay' => '日別',
      'discovery.calendarWeek' => '週別',
      'discovery.calendarMonth' => '月別',
      'discovery.latest' => '最新',
      'discovery.popular' => '人気',
      'discovery.today' => '今日',
      'discovery.thisWeek' => '今週',
      'discovery.thisMonth' => '今月',
      'discovery.lastDay' => '過去24時間',
      'discovery.lastThreeDays' => '過去3日間',
      'discovery.lastWeek' => '過去1週間',
      'discovery.lastMonth' => '過去1か月',
      'discovery.lastThreeMonths' => '過去3か月',
      'discovery.lastSixMonths' => '過去6か月',
      'discovery.lastYear' => '過去1年',
      'discovery.rankingComplete' => 'ランキングをすべて読み込みました',
      'discovery.latestFallback' => 'このサイトでは最新の投稿のみ利用できます。',
      'discovery.filters' => '絞り込み',
      'discovery.loadMore' => 'さらに読み込む',
      'discovery.filteredContinue' => 'この範囲に該当する投稿はありません。続きを表示',
      'discovery.commonTags' => 'よく使われるタグ',
      'discovery.moreTags' => 'もっと見る',
      'discovery.tagSource' => '対象サイト',
      'discovery.allTagSources' => 'すべてのサイト',
      'discovery.manageTags' => 'カスタムタグ',
      'discovery.addTag' => 'タグを追加',
      'discovery.noCustomTags' => 'カスタムタグはまだありません',
      'discovery.customTagsHint' => 'タグに覚えやすい名前を付けると、検索で見つけやすくなります。',
      'discovery.addCustomTag' => 'カスタムタグとして追加',
      'discovery.editTag' => 'カスタムタグを編集',
      'discovery.canonicalTag' => 'サイトのタグ',
      'discovery.displayName' => '表示名（任意）',
      'discovery.invalidTag' => '空白を含まないタグを1つ入力してください。',
      'discovery.queryHint' => 'タグやサイトの検索式を入力…',
      'discovery.unverifiedTag' => 'このサイトで未確認のタグがあります。そのまま検索できます。',
      'discovery.verifiedTag' => 'このサイトで確認済み',
      'discovery.noSuggestions' => '候補がありません',
      'discovery.localFallback' => 'オンライン候補を取得できません。ローカル候補を利用できます。',
      'discovery.retryTags' => 'よく使われるタグを再取得',
      'discovery.artist' => '作者',
      'discovery.character' => 'キャラクター',
      'discovery.copyright' => '作品',
      'discovery.meta' => 'メタ',
      'discovery.general' => '一般',
      'discovery.random' => 'ランダム',
      'discovery.lifetimeViews' => '累計閲覧数',
      'discovery.lifetimeFavorites' => '累計お気に入り数',
      'mediaError.title' => '画像の読み込みに失敗しました',
      'mediaError.details' => 'エラーの詳細',
      'mediaError.copyDetails' => '詳細をコピー',
      'mediaError.decodeFailed' => 'ダウンロードした画像をデコードできませんでした。再試行すると、この画像のキャッシュを削除して再ダウンロードします。',
      _ => null,
    };
  }
}
