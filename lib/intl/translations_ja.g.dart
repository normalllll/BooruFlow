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
class TranslationsJa extends Translations
    with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsJa({
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
             locale: AppLocale.ja,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ),
       super(
         cardinalResolver: cardinalResolver,
         ordinalResolver: ordinalResolver,
       ) {
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
  TranslationsJa $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => TranslationsJa(meta: meta ?? this.$meta);

  // Translations
  @override
  late final _Translations$generic$ja generic = _Translations$generic$ja._(
    _root,
  );
  @override
  late final _Translations$booruError$ja booruError =
      _Translations$booruError$ja._(_root);
  @override
  late final _Translations$update$ja update = _Translations$update$ja._(_root);
  @override
  late final _Translations$postList$ja postList = _Translations$postList$ja._(
    _root,
  );
  @override
  late final _Translations$postDetail$ja postDetail =
      _Translations$postDetail$ja._(_root);
  @override
  late final _Translations$postSearch$ja postSearch =
      _Translations$postSearch$ja._(_root);
  @override
  late final _Translations$imageZoom$ja imageZoom =
      _Translations$imageZoom$ja._(_root);
  @override
  late final _Translations$downloads$ja downloads =
      _Translations$downloads$ja._(_root);
  @override
  late final _Translations$about$ja about = _Translations$about$ja._(_root);
  @override
  late final _Translations$settings$ja settings = _Translations$settings$ja._(
    _root,
  );
  @override
  late final _Translations$discovery$ja discovery =
      _Translations$discovery$ja._(_root);
  @override
  late final _Translations$mediaError$ja mediaError =
      _Translations$mediaError$ja._(_root);
  @override
  late final _Translations$webChallenge$ja webChallenge =
      _Translations$webChallenge$ja._(_root);
  @override
  late final _Translations$nativeWindow$ja nativeWindow =
      _Translations$nativeWindow$ja._(_root);
  @override
  late final _Translations$batchDownload$ja batchDownload =
      _Translations$batchDownload$ja._(_root);
  @override
  late final _Translations$frost$ja frost = _Translations$frost$ja._(_root);
  @override
  late final _Translations$navigation$ja navigation =
      _Translations$navigation$ja._(_root);
  @override
  late final _Translations$settingsV2$ja settingsV2 =
      _Translations$settingsV2$ja._(_root);
  @override
  late final _Translations$settingsDetails$ja settingsDetails =
      _Translations$settingsDetails$ja._(_root);
  @override
  late final _Translations$verificationPage$ja verificationPage =
      _Translations$verificationPage$ja._(_root);
  @override
  late final _Translations$ugoira$ja ugoira = _Translations$ugoira$ja._(_root);
}

// Path: generic
class _Translations$generic$ja extends Translations$generic$en {
  _Translations$generic$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

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
  String copiedWithValue({required Object value}) =>
      '${value} をクリップボードにコピーしました';
  @override
  String errorWithValue({required Object value}) => 'エラーが発生しました: ${value}';
  @override
  String get loading => '読み込み中';
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
  _Translations$booruError$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

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
  String get rateLimited => '画像ソースが一時的にリクエストを制限しています。しばらくお待ちください。';
  @override
  String get challengeRequired =>
      '画像ソースでブラウザによる確認が必要です。ブラウザで開いて確認を完了するか、別の画像ソースを選択してください。';
  @override
  String get routeUnavailable =>
      'このドメインのルートがありません。ネットワーク設定で更新してください。システム DNS には切り替えません。';
  @override
  String get sourceUnavailable => '画像ソースは現在利用できません。';
  @override
  String get network => '通信に失敗しました。接続を確認して再試行してください。';
  @override
  String get timeout => 'リクエストがタイムアウトしました。インターネット接続を確認するか、しばらくしてから再試行してください。';
  @override
  String get invalidResponse => '画像ソースから無効なレスポンスが返されました。';
  @override
  String get unsafeRedirect => '画像ソースから安全でないリダイレクトが返されました。';
  @override
  String get mediaValidationFailed => 'メディアの検証またはデコードに失敗しました。';
  @override
  String get cancelled => 'リクエストはキャンセルされました。';
  @override
  String get internal => 'Booru エンジンの内部エラーが発生しました。';
}

// Path: update
class _Translations$update$ja extends Translations$update$en {
  _Translations$update$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get checkUpdateStart => 'アップデートを確認中';
  @override
  String get checkUpdateFailed => 'アップデートの確認に失敗しました。インターネット接続を確認してください。';
  @override
  String get selectDownloadUrlFailed =>
      'ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。';
  @override
  String newVersionFound({required Object version}) =>
      '新しいバージョン ${version} があります。「このアプリについて」から更新できます。';
  @override
  String get noNewVersionFound => '新しいバージョンが見つかりません。';
}

// Path: postList
class _Translations$postList$ja extends Translations$postList$en {
  _Translations$postList$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

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
  _Translations$postDetail$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get fullscreen => '全画面で表示';
  @override
  String get notFound => '作品が見つかりません';
  @override
  String parentCount({required Object count}) => '${count} 親作品';
  @override
  String childCount({required Object count}) => '${count} 子作品';
  @override
  String get zoomIn => '拡大';
  @override
  String get zoomOut => '縮小';
  @override
  String get originalFailed => '元画像を読み込めませんでした';
  @override
  String get previewShown => 'プレビュー画像を表示しています。';
  @override
  String uploadedAt({required Object date}) => '${date} に投稿';
  @override
  String get pixels => 'ピクセル';
  @override
  String get dimensions => '解像度';
  @override
  String get searchTag => 'このタグで検索';
  @override
  String get addToSearch => '検索に追加';
  @override
  String get excludeTag => 'このタグを除外';
  @override
  String get openSource => '出典を開く';
  @override
  String get resetZoom => 'ズームをリセット';
  @override
  String get ratingGeneral => '一般';
  @override
  String get ratingSensitive => 'センシティブ';
  @override
  String get ratingQuestionable => '疑わしい';
  @override
  String get ratingExplicit => '成人向け';
  @override
  String get ratingUnknown => '不明';
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
  String get viewOriginal => 'オリジナル';
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
  String get similarPosts => '関連画像';
  @override
  String get parentPost => '親投稿';
  @override
  String get childPost => '子投稿';
}

// Path: postSearch
class _Translations$postSearch$ja extends Translations$postSearch$en {
  _Translations$postSearch$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '検索';
}

// Path: imageZoom
class _Translations$imageZoom$ja extends Translations$imageZoom$en {
  _Translations$imageZoom$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '画像をズーム';
}

// Path: downloads
class _Translations$downloads$ja extends Translations$downloads$en {
  _Translations$downloads$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get fileMissing => 'ファイルは元の場所にありません';
  @override
  String get locationMissing => 'ファイルまたはフォルダーが見つかりません';
  @override
  String get redownload => '再ダウンロード';
  @override
  String get remove => '削除';
  @override
  String activeTasks({required Object count}) => '${count} 件をダウンロード中';
  @override
  String failedTasks({required Object count}) => '${count} 件のダウンロードに失敗';
  @override
  String get retryAll => 'すべて再試行';
  @override
  String get today => '今日';
  @override
  String get yesterday => '昨日';
  @override
  String transferRate({required Object value}) => '${value}/秒';
  @override
  String remainingSeconds({required Object count}) => '約 ${count} 秒';
  @override
  String remainingMinutes({required Object count}) => '約 ${count} 分';
  @override
  String remainingHours({required Object count}) => '約 ${count} 時間';
  @override
  String get format => '形式';
  @override
  String get startedAt => '開始日時';
  @override
  String get browse => '閲覧する';
  @override
  String get all => 'すべて';
  @override
  String get pause => '一時停止';
  @override
  String get resume => '再開';
  @override
  String get pauseAll => 'すべて一時停止';
  @override
  String get resumeAll => 'すべて再開';
  @override
  String get retryFailed => '失敗したタスクを再試行';
  @override
  String get clearCompleted => '完了済みを削除';
  @override
  String get openDirectory => 'ダウンロード先を開く';
  @override
  String get openPost => '作品を開く';
  @override
  String get batch => '一括ダウンロード';
  @override
  String batchProgress({required Object completed, required Object total}) =>
      '${completed} / ${total}';
  @override
  String get path => '保存先';
  @override
  String get taskDetails => 'タスクの詳細';
  @override
  String get viewLog => 'ログ';
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
  late final _Translations$downloads$messages$ja messages =
      _Translations$downloads$messages$ja._(_root);
}

// Path: about
class _Translations$about$ja extends Translations$about$en {
  _Translations$about$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'このアプリについて';
  @override
  String get projectUrl => 'プロジェクトURL';
  @override
  String get publishPage => '公開ページ';
  @override
  String get appVersion => 'アプリバージョン';
  @override
  String get freepivPromotionTitle => 'freepiv をチェック';
  @override
  String get freepivPromotionSubtitle => '快適に使えるクロスプラットフォームの Pixiv 非公式クライアント。';
  @override
  String get discussion => 'コミュニティ';
  @override
  String get downloadUpdate => 'アップデートをダウンロード';
  @override
  String get downloadUpdateHint => 'お使いのデバイス用に最新バージョンをブラウザでダウンロードしてください。';
}

// Path: settings
class _Translations$settings$ja extends Translations$settings$en {
  _Translations$settings$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

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
  String get downloadDirectory => 'ダウンロード先';
  @override
  String get defaultToPlatformSettings => 'システムの既定値を使用';
  @override
  String get columnsPerRow => '1 行の画像数';
  @override
  String get maxConcurrentDownloads => '同時ダウンロード';
  @override
  String get maxSegmentsPerTask => 'タスクごとの分割数';
  @override
  String get platformDefault => 'システムの既定値';
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
  late final _Translations$settings$sections$ja sections =
      _Translations$settings$sections$ja._(_root);
  @override
  late final _Translations$settings$source$ja source =
      _Translations$settings$source$ja._(_root);
  @override
  late final _Translations$settings$account$ja account =
      _Translations$settings$account$ja._(_root);
  @override
  late final _Translations$settings$network$ja network =
      _Translations$settings$network$ja._(_root);
  @override
  late final _Translations$settings$languageDialog$ja languageDialog =
      _Translations$settings$languageDialog$ja._(_root);
  @override
  late final _Translations$settings$themeModeDialog$ja themeModeDialog =
      _Translations$settings$themeModeDialog$ja._(_root);
  @override
  late final _Translations$settings$downloadDirectoryDialog$ja
  downloadDirectoryDialog = _Translations$settings$downloadDirectoryDialog$ja._(
    _root,
  );
  @override
  late final _Translations$settings$bypassSniDialog$ja bypassSniDialog =
      _Translations$settings$bypassSniDialog$ja._(_root);
  @override
  late final _Translations$settings$columnsPerRowDialog$ja columnsPerRowDialog =
      _Translations$settings$columnsPerRowDialog$ja._(_root);
  @override
  late final _Translations$settings$maxSegmentsPerTaskDialog$ja
  maxSegmentsPerTaskDialog =
      _Translations$settings$maxSegmentsPerTaskDialog$ja._(_root);
}

// Path: discovery
class _Translations$discovery$ja extends Translations$discovery$en {
  _Translations$discovery$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get mode => '表示';
  @override
  String get timeRange => '期間';
  @override
  String get chooseDate => '日付を指定';
  @override
  String get menuWeek => '今週';
  @override
  String get menuMonth => '今月';
  @override
  String get ratingsTitle => 'レーティング';
  @override
  String get ratingLabel => 'レーティング';
  @override
  String get ratingSeparator => '、';
  @override
  String get calendarRanges => '暦の期間';
  @override
  String get rollingRanges => '直近の期間';
  @override
  String get tooManyRequests => 'リクエストが多すぎます';
  @override
  String get copyLink => 'リンクをコピー';
  @override
  String get copyQueryLink => '検索リンクをコピー';
  @override
  String get copyImage => '画像をコピー';
  @override
  String get searchAuthor => 'この絵師を検索';
  @override
  String get mediaAnimation => 'アニメ';
  @override
  String get mediaVideo => '動画';
  @override
  String get mediaCollection => '関連画像';
  @override
  String retryIn({required Object seconds}) => '${seconds} 秒後に再試行';
  @override
  String get searchResults => '検索結果';
  @override
  String searchTermsTitle({required Object count}) => '${count}個のキーワードを検索';
  @override
  String get allAvailable => '表示可能なすべてのコンテンツ';
  @override
  String get defaultRatingsHint => '未選択なら現在の画像ソースで閲覧できるすべてのコンテンツを表示します。';
  @override
  String get resetFilters => '初期設定に戻す';
  @override
  String get unsupportedRatings => 'この画像ソースは選択したレーティングに対応していません。';
  @override
  String get noFilteredPosts => '条件に一致する画像がありません';
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
  String get clearHistory => '消去';
  @override
  String get recentSearches => '最近の検索';
  @override
  String get noRecentSearches => '検索履歴はありません';
  @override
  String get myTags => '自分のタグ';
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
  String get manageTagsAction => '管理';
  @override
  String get addTagAction => '追加';
  @override
  String get deleteTag => '削除';
  @override
  String get addTag => 'タグを追加';
  @override
  String get noCustomTags => 'カスタムタグはまだありません';
  @override
  String get customTagsHint => 'よく使うタグに覚えやすい名前を付けると、検索で見つけやすくなります。';
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
  String get queryHint => 'タグを検索';
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
  _Translations$mediaError$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get videoProxyBypassed => '動画では SOCKS プロキシを利用できないため、今回は直接接続しました。';
  @override
  String get videoFailed => '動画の再生に失敗しました';
  @override
  String get downloadOriginal => '元のファイルをダウンロード';
  @override
  String get previewUnsupported => 'プレビューできません';
  @override
  String get title => '画像の読み込みに失敗しました';
  @override
  String get details => 'エラーの詳細';
  @override
  String get copyDetails => '詳細をコピー';
  @override
  String get decodeFailed =>
      'ダウンロードした画像をデコードできませんでした。再試行すると、この画像のキャッシュを削除して再ダウンロードします。';
}

// Path: webChallenge
class _Translations$webChallenge$ja extends Translations$webChallenge$en {
  _Translations$webChallenge$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'ウェブ認証';
  @override
  String get open => 'ウェブ認証を開く';
  @override
  String windowTitle({required Object source}) =>
      '${source} · 認証後にウィンドウを閉じてください';
  @override
  String get instructions =>
      'ページの人間確認を手動で完了してから、戻るかウィンドウを閉じてください。認証データを保存し、画像ソースを再読み込みします。';
  @override
  String get finish => '完了して戻る';
  @override
  String get saving => 'ウェブセッションを読み取り、確認しています';
  @override
  String get waiting => 'ウェブ認証を実行中';
  @override
  String get clear => '消去';
  @override
  String get clearAll => 'すべてのウェブ認証データを消去';
  @override
  String get clearDescription => 'Cookie、ブラウザー識別情報、ウェブキャッシュを消去します。';
  @override
  String get cleared => 'ウェブ認証データを消去しました';
  @override
  String get verified => '確認済み・アクセス可能';
  @override
  String get saved => '保存済み・再確認待ち';
  @override
  String get empty => '保存された認証データはありません';
  @override
  String get failed => 'ウェブ認証が完了しませんでした。再試行してください。';
  @override
  String get pageLoadFailed => 'ページを読み込めませんでした。認証ページを開き直すか、ネットワーク設定を確認してください。';
  @override
  String get webViewUnavailable => 'この環境ではウェブコンポーネントを使用できません。';
  @override
  String get windowFailed => 'ウェブ認証を開けませんでした。';
  @override
  String get runtimeMissing =>
      'Microsoft Edge WebView2 Runtime が見つかりません。インストールまたは更新してから再試行してください。';
  @override
  String get proxyUnsupported => '現在のプロキシ設定には対応していません。設定を変更して再試行してください。';
  @override
  String get busy => '別のウェブ認証またはデータ消去を実行中です。';
  @override
  String get cancelled => 'ウェブ認証をキャンセルしました。';
  @override
  String get timedOut => 'ウェブ認証がタイムアウトしました。ページを開き直してください。';
  @override
  String get storageFailed => '認証データを保存または消去できませんでした。以前のセッションは保持されています。';
  @override
  String get captureFailed => 'ウェブセッションを読み取れませんでした。認証ページを開き直してください。';
  @override
  String get cleanupFailed => 'ウェブデータの消去が完了していません。しばらくしてから再試行してください。';
  @override
  String get operationSuperseded => 'データの消去またはネットワーク設定の変更により、認証をキャンセルしました。';
  @override
  String get noCookies => '使用可能な認証データがありません。人間確認を完了してから戻ってください。';
}

// Path: nativeWindow
class _Translations$nativeWindow$ja extends Translations$nativeWindow$en {
  _Translations$nativeWindow$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get minimize => '最小化';
  @override
  String get maximize => '最大化';
  @override
  String get restore => '元に戻す';
  @override
  String get close => '閉じる';
}

// Path: batchDownload
class _Translations$batchDownload$ja extends Translations$batchDownload$en {
  _Translations$batchDownload$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '一括ダウンロード';
  @override
  String get close => '閉じる';
  @override
  String get limitTitle => '画像を何枚まで取得しますか？';
  @override
  String get limitHint => '現在の検索条件でページごとに取得し、上限に達したら停止します。';
  @override
  String get limitLabel => '取得する画像の上限';
  @override
  String get positiveInteger => '1 以上の整数を入力してください。';
  @override
  String get start => '画像を取得';
  @override
  String fetchLimit({required Object count}) => '/ 最大 ${count} 枚';
  @override
  String get fetching => '見つかった画像';
  @override
  String progress({required Object current, required Object total}) =>
      '${current} / ${total}';
  @override
  String fetchProgress({required Object limit, required Object current}) =>
      '最大 ${limit} 枚のうち ${current} 枚を取得';
  @override
  String get stopHint => 'いつでも停止して、取得済みの画像を使用できます。';
  @override
  String get stop => '取得を停止';
  @override
  String get found => '枚の画像をダウンロードできます';
  @override
  String get limitReached => '取得上限に達しました。検索結果がまだ残っている可能性があります。';
  @override
  String get exhausted => '条件に一致するすべての結果を取得しました。';
  @override
  String get permissionDenied =>
      'ダウンロード権限がありません。システム設定でアプリの権限を確認してから再試行してください。';
  @override
  String get enqueueFailed => 'タスクを追加できませんでした。保存先と空き容量を確認してから再試行してください。';
  @override
  String get stopped => '取得を停止しました。見つかった画像をダウンロードできます。';
  @override
  String get empty => '条件に一致する画像が見つかりませんでした。';
  @override
  String get stalled => 'ページの取得が進まなくなりました。結果は保持されています。再試行するか取得済みの画像を使用してください。';
  @override
  String get sessionChanged => '配信元の設定が変更されました。閉じてから再度取得するか、取得済みの画像を使用してください。';
  @override
  String get fetchFailed => '取得を完了できませんでした。結果は保持されています。再試行するか取得済みの画像を使用してください。';
  @override
  String get countLabel => 'ダウンロード枚数';
  @override
  String get all => 'すべて';
  @override
  String countRange({required Object max}) => '1～${max} を入力';
  @override
  String get orderHint => '現在の検索順で先頭から N 枚をダウンロードします。';
  @override
  String get folderLabel => 'フォルダー名';
  @override
  String get folderHint => '例：9月のコレクション';
  @override
  String get folderPlaceholder => '保存フォルダー';
  @override
  String get invalidFolder =>
      '1～100 文字で入力してください。パス区切り、予約名、前後の空白、末尾のピリオドは使用できません。';
  @override
  String get folderHelp => '同名フォルダーを再利用し、既存のファイルは上書きしません。';
  @override
  String get locationFailed => '保存先を取得できませんでした。';
  @override
  String get photos => '写真ライブラリ';
  @override
  String get photosHint =>
      'iOS では配信元フォルダー内のアルバムに保存します。アルバムの再利用には写真へのフルアクセスが必要です。';
  @override
  String enqueue({required Object count}) => 'キューに追加 · ${count} 枚';
  @override
  String get enqueueing => 'ダウンロードキューに追加中';
  @override
  String preparing({required Object current, required Object total}) =>
      '${current} / ${total} 枚を準備中';
  @override
  String get added => 'ダウンロードキューに追加したタスク';
  @override
  String get backgroundHint => 'この画面を閉じてもアプリの実行中は追加を続けます。同じボタンから結果を確認できます。';
  @override
  String get queueHint => 'ダウンロードの進捗はダウンロード一覧で確認できます。';
  @override
  String failedHint({required Object count}) => '${count} 枚を追加できませんでした。';
  @override
  String get retryFailed => '失敗した画像を再試行';
  @override
  String queued({required Object added, required Object failed}) =>
      '一括処理：${added} 枚をキューに追加、${failed} 枚の追加に失敗。';
  @override
  String completed({required Object saved, required Object failed}) =>
      '一括ダウンロード終了：${saved} 枚を保存、${failed} 枚が失敗またはキャンセル。';
  @override
  String get done => '完了';
  @override
  String get back => '戻る';
  @override
  String get first => '先頭 N 枚';
  @override
  String addedCount({required Object count}) => '${count} 枚を追加しました';
  @override
  String savedTo({required Object folder}) => '保存先「${folder}」';
  @override
  String get viewDownloads => 'ダウンロードを表示';
}

// Path: frost
class _Translations$frost$ja extends Translations$frost$en {
  _Translations$frost$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get retry => '再試行';
  @override
  String get error => 'エラー';
  @override
  String get errorDetails => 'エラーの詳細';
  @override
  String get copyDetails => '詳細をコピー';
  @override
  String get copied => 'コピーしました';
  @override
  String get loading => '読み込み中';
  @override
  String get actionSucceeded => '完了しました';
  @override
  String get actionFailed => '失敗しました';
  @override
  String get loadFailed => '読み込めませんでした';
  @override
  String get noItems => 'まだ項目がありません';
  @override
  String get noMoreItems => 'すべて表示しました';
  @override
  String get pullToRefresh => '引っ張って更新';
  @override
  String get releaseToRefresh => '離して更新';
  @override
  String get refreshing => '更新中';
  @override
  String get refreshComplete => '更新しました';
  @override
  String get refreshFailed => '更新できませんでした';
  @override
  String get previous => '前へ';
  @override
  String get next => '次へ';
  @override
  String get back => '戻る';
  @override
  String get more => 'その他';
  @override
  String get expandNavigation => 'サイドバーを開く';
  @override
  String get collapseNavigation => 'サイドバーを閉じる';
  @override
  String get clearText => '入力を消去';
  @override
  String get search => '検索';
  @override
  String noResults({required Object query}) => '「${query}」の結果はありません';
  @override
  String get clearSearch => '検索を消去';
  @override
  String get dismiss => '閉じる';
  @override
  String get expandText => 'もっと見る';
  @override
  String get collapseText => '折りたたむ';
  @override
  String get showAll => 'すべて表示';
  @override
  String get copy => 'コピー';
  @override
  String get clearAll => 'すべて消去';
  @override
  String get showPassword => 'パスワードを表示';
  @override
  String get hidePassword => 'パスワードを隠す';
  @override
  String get chooseDate => '日付を選択';
  @override
  String get chooseTime => '時刻を選択';
  @override
  String get increment => '増やす';
  @override
  String get decrement => '減らす';
  @override
  String get reorderHandle => '並べ替え';
  @override
  String get sortAscending => '昇順';
  @override
  String get sortDescending => '降順';
  @override
  String get play => '再生';
  @override
  String get pause => '一時停止';
  @override
  String get loop => 'ループ再生';
  @override
  String get mute => 'ミュート';
  @override
  String get unmute => 'ミュートを解除';
  @override
  String get fullscreen => '全画面表示';
  @override
  String get exitFullscreen => '全画面表示を終了';
  @override
  String get reload => '再読み込み';
  @override
  String get openInBrowser => 'ブラウザーで開く';
  @override
  String get minimize => '最小化';
  @override
  String get maximize => '最大化';
  @override
  String get restore => '元のサイズに戻す';
  @override
  String get close => '閉じる';
  @override
  String get cancel => 'キャンセル';
  @override
  String get apply => '適用';
  @override
  String get clear => '消去';
  @override
  String get choose => '選択';
  @override
  String get showInFolder => 'フォルダーで表示';
  @override
  String selectedCount({required Object count}) => '${count}件を選択中';
  @override
  String pageOf({required Object total, required Object page}) =>
      '${total}ページ中${page}ページ';
  @override
  String get selectAll => 'すべて選択';
  @override
  String get done => '完了';
  @override
  String itemPosition({required Object total, required Object position}) =>
      '${total}件中${position}件目';
  @override
  String tableDimensions({required Object rows, required Object columns}) =>
      '${rows}行、${columns}列';
  @override
  String get taskQueued => '待機中';
  @override
  String get taskRunning => 'ダウンロード中';
  @override
  String get taskPaused => '一時停止中';
  @override
  String get taskCompleted => '完了';
  @override
  String get taskFailed => '失敗';
  @override
  String get taskCancelled => 'キャンセル済み';
  @override
  String get remove => '削除';
  @override
  String get forward => '進む';
  @override
  String get stop => '停止';
  @override
  String get seek => '再生位置';
  @override
  String get send => '送信';
  @override
  String get attach => '添付';
  @override
  String get readerSettings => '表示設定';
  @override
  String get textSize => '文字サイズ';
  @override
  String get lineSpacing => '行間';
  @override
  String get readingProgress => '読書の進捗';
  @override
  String showReplies({required Object count}) => '${count}件の返信を表示';
  @override
  String characterCount({required Object limit, required Object count}) =>
      '${limit}文字中${count}文字';
  @override
  String moreMedia({required Object count}) => 'ほか${count}枚';
  @override
  String navigationCount({required Object count}) => '${count}件';
  @override
  String navigationProgress({required Object progress}) => '進捗${progress}%';
  @override
  String get listSeparator => '、';
}

// Path: navigation
class _Translations$navigation$ja extends Translations$navigation$en {
  _Translations$navigation$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get browse => '閲覧';
  @override
  String get search => '検索';
  @override
  String get downloads => 'ダウンロード';
  @override
  String get settings => '設定';
  @override
  String get browseEmpty => 'お気に入りのサイトを閲覧';
  @override
  String get searchEmpty => 'タグで作品を検索';
  @override
  String get downloadsEmpty => 'ダウンロードはここに表示されます';
  @override
  String get settingsEmpty => 'BooruFlowを使いやすく';
}

// Path: settingsV2
class _Translations$settingsV2$ja extends Translations$settingsV2$en {
  _Translations$settingsV2$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get predictiveBack => '予測型「戻る」';
  @override
  String get predictiveBackScope =>
      'アプリ内の戻る動作をプレビューします。ホーム画面に戻るアニメーションはシステムが制御します。';
  @override
  String get background => '背景';
  @override
  String get ambientBlur => '環境ぼかし';
  @override
  String get mica => 'マイカ';
  @override
  String get backgroundOff => 'オフ';
  @override
  String get backgroundIntensity => '強さ';
  @override
  String get systemTransparencyReduced => 'システムで透明度を下げています';
  @override
  String get customColour => 'カスタムカラー';
  @override
  String get appearance => '外観';
  @override
  String get browsing => '閲覧';
  @override
  String get tone => '色調';
  @override
  String get neutral => '標準';
  @override
  String get cool => '寒色';
  @override
  String get warm => '暖色';
  @override
  String get accent => 'アクセントカラー';
  @override
  String get customAccent => 'カスタムカラー';
  @override
  String get customHex => 'アクセントのHEX';
  @override
  String get invalidHex => '6桁のHEXカラーを入力してください。';
  @override
  String get accentRejected => 'この色は現在の背景で読みづらいため使用できません。';
  @override
  String get accentWarning => 'この色はコントラストが低くなります。適用しますか？';
  @override
  String get editAccount => 'アカウントを編集';
  @override
  String get signOutConfirm => 'このソースの保存済み認証情報を削除しますか？';
  @override
  String get licenses => 'オープンソースライセンス';
  @override
  String get checkUpdates => '更新を確認';
  @override
  String get help => 'ヘルプ';
}

// Path: settingsDetails
class _Translations$settingsDetails$ja extends Translations$settingsDetails$en {
  _Translations$settingsDetails$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get mode => 'モード';
  @override
  String get custom => 'カスタム';
  @override
  String get change => '変更';
  @override
  String get routeCache => 'ルートキャッシュ';
  @override
  String hostCount({required Object count}) => '${count} ホスト';
  @override
  String updatedAt({required Object time}) => '更新 ${time}';
  @override
  String get sourceStatus => '画像ソースの状態';
  @override
  String get apiAndImages => 'API と画像を利用可能';
  @override
  String get apiOnly => 'API 利用可能 · 画像に接続不可';
  @override
  String get status => '状態';
  @override
  String get content => 'コンテンツ';
  @override
  String editSourceAccount({required Object source}) => '${source} のアカウントを編集';
  @override
  String get proxyApplies => '画像ソース、画像、新しいダウンロードに適用します。';
  @override
  String version({required Object version, required Object build}) =>
      'バージョン ${version} (${build})';
  @override
  String get communityTelegram => 'Telegram グループ';
  @override
  String get communityDiscord => 'Discord サーバー';
  @override
  String get savedVerifications => '保存した認証';
  @override
  String get systemDnsShort => 'システム DNS';
  @override
  String get refresh => '更新';
  @override
  String updateAvailable({required Object version}) =>
      '新しいバージョン ${version} があります';
}

// Path: verificationPage
class _Translations$verificationPage$ja
    extends Translations$verificationPage$en {
  _Translations$verificationPage$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get instructions => '下のページで認証し、完了して戻るを選んでください。';
  @override
  String get opening => 'ページを開いています';
  @override
  String get failed => 'ページを読み込めませんでした';
  @override
  String get closed => '認証ウィンドウを閉じました';
  @override
  String get failureHelp => 'もう一度開くか、ネットワーク設定を確認してください。';
  @override
  String get reopen => 'もう一度開く';
  @override
  String signOut({required Object source}) => '${source} からログアウトしますか？';
  @override
  String get signOutHelp => 'この端末からアカウント情報を削除します。';
  @override
  String get downloadAdded => 'ダウンロードに追加しました';
  @override
  String get downloadFailed => 'ダウンロード失敗';
  @override
  String get linkCopied => 'リンクをコピーしました';
  @override
  String get view => '表示';
  @override
  String get networkSettings => 'ネットワーク設定';
}

// Path: ugoira
class _Translations$ugoira$ja extends Translations$ugoira$en {
  _Translations$ugoira$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get iosFilesDestination => 'その他の形式：ファイル › BooruFlow';
  @override
  String get iosFormatHelp => 'アニメーション WebP と ZIP は「ファイル」に保存します。';
  @override
  String get albumName => 'アルバム名';
  @override
  String get openSettings => '設定を開く';
  @override
  String get androidDestination => 'アルバムとダウンロード';
  @override
  String get iosDestination => '写真に保存';
  @override
  String get format => 'うごイラの保存形式';
  @override
  String get losslessWebp => '可逆圧縮のアニメーション WebP';
  @override
  String get originalZip => '元の ZIP';
  @override
  String get webpRecord => 'WebP · アニメーション';
  @override
  String get zipRecord => 'ZIP · 元のフレーム';
  @override
  String get ugoiraInvalidArchive => 'アニメーションの ZIP ファイルが無効です。';
  @override
  String get ugoiraMetadataMissing => 'フレームの表示時間がありません。';
  @override
  String get ugoiraInvalidMetadata => 'フレームの表示時間が無効です。';
  @override
  String get ugoiraFrameMissing => 'アニメーションのフレームが見つかりません。';
  @override
  String get ugoiraFrameCorrupt => 'アニメーションのフレームが破損しています。';
  @override
  String get ugoiraFrameSizeMismatch => 'フレームのサイズが一致しません。';
  @override
  String get ugoiraFrameTooLarge => 'フレームがサイズの上限を超えています。';
  @override
  String get ugoiraEncodeFailed => 'アニメーションをエンコードできませんでした。';
  @override
  String get ugoiraOutputTooLarge => '出力ファイルがサイズの上限を超えています。';
}

// Path: downloads.messages
class _Translations$downloads$messages$ja
    extends Translations$downloads$messages$en {
  _Translations$downloads$messages$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get storagePermanentlyDenied =>
      'ストレージのアクセス許可が永久に拒否されました。\n設定で手動でストレージのアクセス許可を有効にしてください。';
  @override
  String get storageDenied => 'ストレージのアクセス許可が拒否されました。';
  @override
  String get deviceInfoError => 'デバイス情報を解析できません。';
  @override
  String get photosPermanentlyDenied =>
      '写真のアクセス許可が永久に拒否されました。\n設定で手動で写真のアクセス許可を有効にしてください。';
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
  String downloadCompletedWith({required Object name}) =>
      'ダウンロード完了: タスク ${name}';
  @override
  String downloadFailedWith({required Object name}) => 'ダウンロード失敗: タスク ${name}';
  @override
  String saveFailedWith({required Object name}) => '保存失敗: タスク ${name}';
}

// Path: settings.sections
class _Translations$settings$sections$ja
    extends Translations$settings$sections$en {
  _Translations$settings$sections$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

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
  _Translations$settings$source$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get defaultSource => '既定のサイト';
  @override
  String get supportedRatings => '対応するレーティング';
  @override
  String get safetyRating => 'レーティング';
}

// Path: settings.account
class _Translations$settings$account$ja
    extends Translations$settings$account$en {
  _Translations$settings$account$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get manageAllSubtitle => 'サイトのレーティングとアカウント設定';
  @override
  String get noAccountRequired => 'アカウント不要';
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
  late final _Translations$settings$account$statuses$ja statuses =
      _Translations$settings$account$statuses$ja._(_root);
}

// Path: settings.network
class _Translations$settings$network$ja
    extends Translations$settings$network$en {
  _Translations$settings$network$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get proxyCompact => 'カスタムプロキシ';
  @override
  String get checkCompact => 'テスト';
  @override
  String get detailsCompact => '詳細';
  @override
  String get advancedCompact => '詳細設定';
  @override
  String get uncheckedCompact => '未確認';
  @override
  String get checkingCompact => '確認中';
  @override
  String get apiShort => 'API';
  @override
  String get imagesShort => '画像';
  @override
  String get saveCompact => '保存';
  @override
  String get proxyProtocol => '方式';
  @override
  String get proxyHost => 'ホスト';
  @override
  String get proxyPort => 'ポート';
  @override
  String get proxyReachable => '接続可能';
  @override
  String get proxyUnreachable => '接続できません';
  @override
  String get proxyProbe => 'プロキシ接続をテスト';
  @override
  String get proxyProbeHint => '入力中のプロキシを保存せずにテストします。各サイトの結果を個別に表示します。';
  @override
  String get sourceAvailable => '利用可能';
  @override
  String get sourcePartial => '一部利用可能';
  @override
  String get sourceUnavailable => '利用不可';
  @override
  String get checkAllSources => 'すべて確認';
  @override
  String get mediaAvailable => '画像：利用可能';
  @override
  String get mediaUnavailable => '画像：失敗またはテスト画像なし';
  @override
  String get dnsDetails => 'DNS ルート詳細（可用性とは別）';
  @override
  String get sourceProbeHelp =>
      '緑：API と画像が成功、黄：一部成功、赤：失敗。各サイトを並列にテストし、約26秒でタイムアウトします。';
  @override
  String get dnsProvider => 'DNS サービス';
  @override
  String sourceSummary({required Object available, required Object issues}) =>
      '利用可能 ${available} · 問題あり ${issues}';
  @override
  String get servicesTitle => '全画像サイトの状態';
  @override
  String get servicesHint =>
      'IP 解決と API の接続を個別に確認します。API が利用可能でも、すべての画像を取得できるとは限りません。';
  @override
  String get noFallback =>
      'DNS プロバイダーは下のルート更新に使用します。システム DNS モードはキャッシュ IP を使用しません。SNI 回避はキャッシュ IP を使用し、失敗時に自動で切り替えません。';
  @override
  String checkProgress({
    required Object done,
    required Object total,
    required Object checked,
    required Object sources,
  }) => 'DNS ${done}/${total} · API ${checked}/${sources}';
  @override
  String checkSummary({
    required Object available,
    required Object total,
    required Object failed,
  }) => 'API 利用可能 ${available}/${total} · DNS 失敗 ${failed} 件';
  @override
  String get loadingStatus => 'キャッシュの状態を読み込み中';
  @override
  String get apiChecking => 'API：確認中';
  @override
  String get apiAvailable => 'API：利用可能';
  @override
  String get apiFailed => 'API：利用不可';
  @override
  String get apiUnchecked => 'API：未確認';
  @override
  String get dnsPending => '未解決 · ルートを更新して IP を取得';
  @override
  String get dnsResolving => '名前解決中';
  @override
  String get dnsResolved => '名前解決成功';
  @override
  String get dnsCached => 'キャッシュ済み IP を使用 · 再確認していません';
  @override
  String get dnsFailed => '名前解決失敗 · 利用可能なルートなし';
  @override
  String get dnsQueued => '名前解決を待機中';
  @override
  String ipCachedAt({required Object time}) => 'IP をキャッシュ済み · 更新日時 ${time}';
  @override
  String get ipNotCached => 'IP 解決済み · まだ保存されていません';
  @override
  String get connectionMode => '接続モード';
  @override
  String get proxyUrl => 'プロキシ URL';
  @override
  String get proxyTitle => 'カスタムプロキシ';
  @override
  String get proxyModeOverride =>
      'カスタムプロキシを優先し、通常の SNI と証明書検証を維持します。SNI 回避は併用しません。接続モードはカスタムプロキシを無効にした後に適用されます。';
  @override
  String get proxyApply => '適用';
  @override
  String get proxyDisable => 'プロキシを無効にする';
  @override
  String proxyActive({required Object endpoint}) => '適用済み：${endpoint}（接続は未確認）';
  @override
  String get proxyInactive => '未使用';
  @override
  String get proxyPending => '変更は未適用です。「適用」を押してください。';
  @override
  String get proxyHelp =>
      'アドレスを入力して下のボタンを押してください。プロキシサービスの起動が必要です。画像一覧、画像、新しいダウンロード要求に適用されます。';
  @override
  String get proxyCheckHelp =>
      'カスタムプロキシはキャッシュ IP ルートより優先されます。適用後は下の API チェックで接続を確認してください。DNS の成功はプロキシの動作確認にはなりません。';
  @override
  String get proxyInvalid =>
      '有効な IP またはホスト名とポート（1–65535）を別々に入力してください。アドレスに方式やパスを含めないでください。';
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
  String routeCacheStatus({required Object hosts, required Object revision}) =>
      '${hosts} ホスト · リビジョン ${revision}';
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
}

// Path: settings.languageDialog
class _Translations$settings$languageDialog$ja
    extends Translations$settings$languageDialog$en {
  _Translations$settings$languageDialog$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '言語';
}

// Path: settings.themeModeDialog
class _Translations$settings$themeModeDialog$ja
    extends Translations$settings$themeModeDialog$en {
  _Translations$settings$themeModeDialog$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'テーマモード';
}

// Path: settings.downloadDirectoryDialog
class _Translations$settings$downloadDirectoryDialog$ja
    extends Translations$settings$downloadDirectoryDialog$en {
  _Translations$settings$downloadDirectoryDialog$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'ダウンロード先';
  @override
  String get pickerTitle => 'フォルダーを選択';
  @override
  String get pick => 'フォルダーを選択';
  @override
  late final _Translations$settings$downloadDirectoryDialog$messages$ja
  messages = _Translations$settings$downloadDirectoryDialog$messages$ja._(
    _root,
  );
}

// Path: settings.bypassSniDialog
class _Translations$settings$bypassSniDialog$ja
    extends Translations$settings$bypassSniDialog$en {
  _Translations$settings$bypassSniDialog$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'SNI をバイパス';
}

// Path: settings.columnsPerRowDialog
class _Translations$settings$columnsPerRowDialog$ja
    extends Translations$settings$columnsPerRowDialog$en {
  _Translations$settings$columnsPerRowDialog$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '1 行の画像数';
}

// Path: settings.maxSegmentsPerTaskDialog
class _Translations$settings$maxSegmentsPerTaskDialog$ja
    extends Translations$settings$maxSegmentsPerTaskDialog$en {
  _Translations$settings$maxSegmentsPerTaskDialog$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'タスクごとの最大分割数';
}

// Path: settings.account.statuses
class _Translations$settings$account$statuses$ja
    extends Translations$settings$account$statuses$en {
  _Translations$settings$account$statuses$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

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
  _Translations$settings$downloadDirectoryDialog$messages$ja._(
    TranslationsJa root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get setToPlatformDefault => 'ダウンロード先をシステムの既定値に戻しました。';
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
          'generic.copiedWithValue' =>
            ({required Object value}) => '${value} をクリップボードにコピーしました',
          'generic.errorWithValue' =>
            ({required Object value}) => 'エラーが発生しました: ${value}',
          'generic.loading' => '読み込み中',
          'generic.loadFailed' => '読み込みに失敗しました',
          'generic.retry' => '再試行',
          'generic.noMoreData' => 'これ以上データはありません',
          'generic.notFound' => '見つかりませんでした',
          'booruError.invalidRequest' => 'リクエストが無効です。',
          'booruError.unsupportedCapability' => 'この画像ソースは要求された操作に対応していません。',
          'booruError.authenticationRequired' => 'この画像ソースにログインしてから再試行してください。',
          'booruError.authenticationRejected' => '画像ソースがアカウント認証情報を拒否しました。',
          'booruError.permissionDenied' => '画像ソースがこのリソースへのアクセスを拒否しました。',
          'booruError.rateLimited' => '画像ソースが一時的にリクエストを制限しています。しばらくお待ちください。',
          'booruError.challengeRequired' =>
            '画像ソースでブラウザによる確認が必要です。ブラウザで開いて確認を完了するか、別の画像ソースを選択してください。',
          'booruError.routeUnavailable' =>
            'このドメインのルートがありません。ネットワーク設定で更新してください。システム DNS には切り替えません。',
          'booruError.sourceUnavailable' => '画像ソースは現在利用できません。',
          'booruError.network' => '通信に失敗しました。接続を確認して再試行してください。',
          'booruError.timeout' =>
            'リクエストがタイムアウトしました。インターネット接続を確認するか、しばらくしてから再試行してください。',
          'booruError.invalidResponse' => '画像ソースから無効なレスポンスが返されました。',
          'booruError.unsafeRedirect' => '画像ソースから安全でないリダイレクトが返されました。',
          'booruError.mediaValidationFailed' => 'メディアの検証またはデコードに失敗しました。',
          'booruError.cancelled' => 'リクエストはキャンセルされました。',
          'booruError.internal' => 'Booru エンジンの内部エラーが発生しました。',
          'update.checkUpdateStart' => 'アップデートを確認中',
          'update.checkUpdateFailed' => 'アップデートの確認に失敗しました。インターネット接続を確認してください。',
          'update.selectDownloadUrlFailed' =>
            'ダウンロードURLが見つかりません。\nプロジェクトページにアクセスし、手動で更新するか、プロジェクトのIssueページでヘルプを求めてください。',
          'update.newVersionFound' =>
            ({required Object version}) =>
                '新しいバージョン ${version} があります。「このアプリについて」から更新できます。',
          'update.noNewVersionFound' => '新しいバージョンが見つかりません。',
          'postList.short' => 'ホーム',
          'postList.title' => 'ホーム',
          'postList.titleWithTags' =>
            ({required Object tags}) => 'タグ付き投稿: ${tags}',
          'postDetail.fullscreen' => '全画面で表示',
          'postDetail.notFound' => '作品が見つかりません',
          'postDetail.parentCount' =>
            ({required Object count}) => '${count} 親作品',
          'postDetail.childCount' =>
            ({required Object count}) => '${count} 子作品',
          'postDetail.zoomIn' => '拡大',
          'postDetail.zoomOut' => '縮小',
          'postDetail.originalFailed' => '元画像を読み込めませんでした',
          'postDetail.previewShown' => 'プレビュー画像を表示しています。',
          'postDetail.uploadedAt' => ({required Object date}) => '${date} に投稿',
          'postDetail.pixels' => 'ピクセル',
          'postDetail.dimensions' => '解像度',
          'postDetail.searchTag' => 'このタグで検索',
          'postDetail.addToSearch' => '検索に追加',
          'postDetail.excludeTag' => 'このタグを除外',
          'postDetail.openSource' => '出典を開く',
          'postDetail.resetZoom' => 'ズームをリセット',
          'postDetail.ratingGeneral' => '一般',
          'postDetail.ratingSensitive' => 'センシティブ',
          'postDetail.ratingQuestionable' => '疑わしい',
          'postDetail.ratingExplicit' => '成人向け',
          'postDetail.ratingUnknown' => '不明',
          'postDetail.titleWithId' => ({required Object id}) => '投稿: ${id}',
          'postDetail.tags' => 'タグ',
          'postDetail.details' => '詳細',
          'postDetail.actions' => '操作',
          'postDetail.rating' => 'レーティング',
          'postDetail.fileType' => 'ファイル形式',
          'postDetail.viewOriginal' => 'オリジナル',
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
          'postDetail.similarPosts' => '関連画像',
          'postDetail.parentPost' => '親投稿',
          'postDetail.childPost' => '子投稿',
          'postSearch.title' => '検索',
          'imageZoom.title' => '画像をズーム',
          'downloads.fileMissing' => 'ファイルは元の場所にありません',
          'downloads.locationMissing' => 'ファイルまたはフォルダーが見つかりません',
          'downloads.redownload' => '再ダウンロード',
          'downloads.remove' => '削除',
          'downloads.activeTasks' =>
            ({required Object count}) => '${count} 件をダウンロード中',
          'downloads.failedTasks' =>
            ({required Object count}) => '${count} 件のダウンロードに失敗',
          'downloads.retryAll' => 'すべて再試行',
          'downloads.today' => '今日',
          'downloads.yesterday' => '昨日',
          'downloads.transferRate' => ({required Object value}) => '${value}/秒',
          'downloads.remainingSeconds' =>
            ({required Object count}) => '約 ${count} 秒',
          'downloads.remainingMinutes' =>
            ({required Object count}) => '約 ${count} 分',
          'downloads.remainingHours' =>
            ({required Object count}) => '約 ${count} 時間',
          'downloads.format' => '形式',
          'downloads.startedAt' => '開始日時',
          'downloads.browse' => '閲覧する',
          'downloads.all' => 'すべて',
          'downloads.pause' => '一時停止',
          'downloads.resume' => '再開',
          'downloads.pauseAll' => 'すべて一時停止',
          'downloads.resumeAll' => 'すべて再開',
          'downloads.retryFailed' => '失敗したタスクを再試行',
          'downloads.clearCompleted' => '完了済みを削除',
          'downloads.openDirectory' => 'ダウンロード先を開く',
          'downloads.openPost' => '作品を開く',
          'downloads.batch' => '一括ダウンロード',
          'downloads.batchProgress' =>
            ({required Object completed, required Object total}) =>
                '${completed} / ${total}',
          'downloads.path' => '保存先',
          'downloads.taskDetails' => 'タスクの詳細',
          'downloads.viewLog' => 'ログ',
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
          'downloads.messages.storagePermanentlyDenied' =>
            'ストレージのアクセス許可が永久に拒否されました。\n設定で手動でストレージのアクセス許可を有効にしてください。',
          'downloads.messages.storageDenied' => 'ストレージのアクセス許可が拒否されました。',
          'downloads.messages.deviceInfoError' => 'デバイス情報を解析できません。',
          'downloads.messages.photosPermanentlyDenied' =>
            '写真のアクセス許可が永久に拒否されました。\n設定で手動で写真のアクセス許可を有効にしてください。',
          'downloads.messages.photosDenied' => '写真のアクセス許可が拒否されました。',
          'downloads.messages.downloadTaskExists' => 'ダウンロードタスクは既に存在しています。',
          'downloads.messages.imageFileExists' => '画像ファイルは既に存在しています。',
          'downloads.messages.downloadRetryWith' =>
            ({required Object name}) => 'ダウンロードタスクを再試行: ${name}',
          'downloads.messages.downloadStartWith' =>
            ({required Object name}) => 'ダウンロードタスクを開始: ${name}',
          'downloads.messages.downloadCompletedWith' =>
            ({required Object name}) => 'ダウンロード完了: タスク ${name}',
          'downloads.messages.downloadFailedWith' =>
            ({required Object name}) => 'ダウンロード失敗: タスク ${name}',
          'downloads.messages.saveFailedWith' =>
            ({required Object name}) => '保存失敗: タスク ${name}',
          'about.title' => 'このアプリについて',
          'about.projectUrl' => 'プロジェクトURL',
          'about.publishPage' => '公開ページ',
          'about.appVersion' => 'アプリバージョン',
          'about.freepivPromotionTitle' => 'freepiv をチェック',
          'about.freepivPromotionSubtitle' =>
            '快適に使えるクロスプラットフォームの Pixiv 非公式クライアント。',
          'about.discussion' => 'コミュニティ',
          'about.downloadUpdate' => 'アップデートをダウンロード',
          'about.downloadUpdateHint' => 'お使いのデバイス用に最新バージョンをブラウザでダウンロードしてください。',
          'settings.title' => '設定',
          'settings.theme' => 'テーマ',
          'settings.language' => '言語',
          'settings.bypassSni' => 'SNI をバイパス',
          'settings.downloadDirectory' => 'ダウンロード先',
          'settings.defaultToPlatformSettings' => 'システムの既定値を使用',
          'settings.columnsPerRow' => '1 行の画像数',
          'settings.maxConcurrentDownloads' => '同時ダウンロード',
          'settings.maxSegmentsPerTask' => 'タスクごとの分割数',
          'settings.platformDefault' => 'システムの既定値',
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
          'settings.source.safetyRating' => 'レーティング',
          'settings.account.manageAllSubtitle' => 'サイトのレーティングとアカウント設定',
          'settings.account.noAccountRequired' => 'アカウント不要',
          'settings.account.openSignInPage' => 'ログインページを開く',
          'settings.account.cookieHeader' => 'Cookie ヘッダー',
          'settings.account.storedLocally' => 'このデバイス内に保存',
          'settings.account.browserUserAgent' => 'ブラウザーの User-Agent',
          'settings.account.browserUserAgentHint' =>
            'ログインしたブラウザーと同じ User-Agent を使用',
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
          'settings.account.statusValue' =>
            ({required Object status}) => '状態 · ${status}',
          'settings.account.statuses.notConfigured' => '未設定',
          'settings.account.statuses.configuredUnverified' => '設定済み・未検証',
          'settings.account.statuses.verified' => '検証済み',
          'settings.account.statuses.rejected' => '拒否されました',
          'settings.network.proxyCompact' => 'カスタムプロキシ',
          'settings.network.checkCompact' => 'テスト',
          'settings.network.detailsCompact' => '詳細',
          'settings.network.advancedCompact' => '詳細設定',
          'settings.network.uncheckedCompact' => '未確認',
          'settings.network.checkingCompact' => '確認中',
          'settings.network.apiShort' => 'API',
          'settings.network.imagesShort' => '画像',
          'settings.network.saveCompact' => '保存',
          'settings.network.proxyProtocol' => '方式',
          'settings.network.proxyHost' => 'ホスト',
          'settings.network.proxyPort' => 'ポート',
          'settings.network.proxyReachable' => '接続可能',
          'settings.network.proxyUnreachable' => '接続できません',
          'settings.network.proxyProbe' => 'プロキシ接続をテスト',
          'settings.network.proxyProbeHint' =>
            '入力中のプロキシを保存せずにテストします。各サイトの結果を個別に表示します。',
          'settings.network.sourceAvailable' => '利用可能',
          'settings.network.sourcePartial' => '一部利用可能',
          'settings.network.sourceUnavailable' => '利用不可',
          'settings.network.checkAllSources' => 'すべて確認',
          'settings.network.mediaAvailable' => '画像：利用可能',
          'settings.network.mediaUnavailable' => '画像：失敗またはテスト画像なし',
          'settings.network.dnsDetails' => 'DNS ルート詳細（可用性とは別）',
          'settings.network.sourceProbeHelp' =>
            '緑：API と画像が成功、黄：一部成功、赤：失敗。各サイトを並列にテストし、約26秒でタイムアウトします。',
          'settings.network.dnsProvider' => 'DNS サービス',
          'settings.network.sourceSummary' =>
            ({required Object available, required Object issues}) =>
                '利用可能 ${available} · 問題あり ${issues}',
          'settings.network.servicesTitle' => '全画像サイトの状態',
          'settings.network.servicesHint' =>
            'IP 解決と API の接続を個別に確認します。API が利用可能でも、すべての画像を取得できるとは限りません。',
          'settings.network.noFallback' =>
            'DNS プロバイダーは下のルート更新に使用します。システム DNS モードはキャッシュ IP を使用しません。SNI 回避はキャッシュ IP を使用し、失敗時に自動で切り替えません。',
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
            }) => 'API 利用可能 ${available}/${total} · DNS 失敗 ${failed} 件',
          'settings.network.loadingStatus' => 'キャッシュの状態を読み込み中',
          'settings.network.apiChecking' => 'API：確認中',
          'settings.network.apiAvailable' => 'API：利用可能',
          'settings.network.apiFailed' => 'API：利用不可',
          'settings.network.apiUnchecked' => 'API：未確認',
          'settings.network.dnsPending' => '未解決 · ルートを更新して IP を取得',
          'settings.network.dnsResolving' => '名前解決中',
          'settings.network.dnsResolved' => '名前解決成功',
          'settings.network.dnsCached' => 'キャッシュ済み IP を使用 · 再確認していません',
          'settings.network.dnsFailed' => '名前解決失敗 · 利用可能なルートなし',
          'settings.network.dnsQueued' => '名前解決を待機中',
          'settings.network.ipCachedAt' =>
            ({required Object time}) => 'IP をキャッシュ済み · 更新日時 ${time}',
          'settings.network.ipNotCached' => 'IP 解決済み · まだ保存されていません',
          'settings.network.connectionMode' => '接続モード',
          'settings.network.proxyUrl' => 'プロキシ URL',
          'settings.network.proxyTitle' => 'カスタムプロキシ',
          'settings.network.proxyModeOverride' =>
            'カスタムプロキシを優先し、通常の SNI と証明書検証を維持します。SNI 回避は併用しません。接続モードはカスタムプロキシを無効にした後に適用されます。',
          'settings.network.proxyApply' => '適用',
          'settings.network.proxyDisable' => 'プロキシを無効にする',
          'settings.network.proxyActive' =>
            ({required Object endpoint}) => '適用済み：${endpoint}（接続は未確認）',
          'settings.network.proxyInactive' => '未使用',
          'settings.network.proxyPending' => '変更は未適用です。「適用」を押してください。',
          'settings.network.proxyHelp' =>
            'アドレスを入力して下のボタンを押してください。プロキシサービスの起動が必要です。画像一覧、画像、新しいダウンロード要求に適用されます。',
          'settings.network.proxyCheckHelp' =>
            'カスタムプロキシはキャッシュ IP ルートより優先されます。適用後は下の API チェックで接続を確認してください。DNS の成功はプロキシの動作確認にはなりません。',
          'settings.network.proxyInvalid' =>
            '有効な IP またはホスト名とポート（1–65535）を別々に入力してください。アドレスに方式やパスを含めないでください。',
          'settings.network.proxyHint' => '任意 · 例 http://127.0.0.1:7890',
          'settings.network.applyAndRouteCache' => '適用とルートキャッシュ',
          'settings.network.apply' => 'ネットワーク設定を適用',
          'settings.network.refreshRoutes' => 'ルートを更新',
          'settings.network.routeCacheUnavailable' => 'ルートキャッシュを利用できません',
          'settings.network.routeCacheStatus' =>
            ({required Object hosts, required Object revision}) =>
                '${hosts} ホスト · リビジョン ${revision}',
          'settings.network.applied' => 'ネットワーク設定を適用しました',
          'settings.network.invalidSettings' => 'ネットワーク設定が無効です',
          'settings.network.routeRefreshFailed' => 'ルートの更新に失敗しました',
          'settings.network.systemDns' => 'システム DNS',
          'settings.network.sniBypass' => 'SNI バイパス',
          'settings.languageDialog.title' => '言語',
          'settings.themeModeDialog.title' => 'テーマモード',
          'settings.downloadDirectoryDialog.title' => 'ダウンロード先',
          'settings.downloadDirectoryDialog.pickerTitle' => 'フォルダーを選択',
          'settings.downloadDirectoryDialog.pick' => 'フォルダーを選択',
          'settings.downloadDirectoryDialog.messages.setToPlatformDefault' =>
            'ダウンロード先をシステムの既定値に戻しました。',
          'settings.downloadDirectoryDialog.messages.pathNotAbsolute' =>
            'パスは絶対パスである必要があります。',
          'settings.downloadDirectoryDialog.messages.pathNotWritable' =>
            'パスに書き込みできません。',
          'settings.bypassSniDialog.title' => 'SNI をバイパス',
          'settings.columnsPerRowDialog.title' => '1 行の画像数',
          'settings.maxSegmentsPerTaskDialog.title' => 'タスクごとの最大分割数',
          'discovery.mode' => '表示',
          'discovery.timeRange' => '期間',
          'discovery.chooseDate' => '日付を指定',
          'discovery.menuWeek' => '今週',
          'discovery.menuMonth' => '今月',
          'discovery.ratingsTitle' => 'レーティング',
          'discovery.ratingLabel' => 'レーティング',
          'discovery.ratingSeparator' => '、',
          'discovery.calendarRanges' => '暦の期間',
          'discovery.rollingRanges' => '直近の期間',
          'discovery.tooManyRequests' => 'リクエストが多すぎます',
          'discovery.copyLink' => 'リンクをコピー',
          'discovery.copyQueryLink' => '検索リンクをコピー',
          'discovery.copyImage' => '画像をコピー',
          'discovery.searchAuthor' => 'この絵師を検索',
          'discovery.mediaAnimation' => 'アニメ',
          'discovery.mediaVideo' => '動画',
          'discovery.mediaCollection' => '関連画像',
          'discovery.retryIn' =>
            ({required Object seconds}) => '${seconds} 秒後に再試行',
          'discovery.searchResults' => '検索結果',
          'discovery.searchTermsTitle' =>
            ({required Object count}) => '${count}個のキーワードを検索',
          'discovery.allAvailable' => '表示可能なすべてのコンテンツ',
          'discovery.defaultRatingsHint' =>
            '未選択なら現在の画像ソースで閲覧できるすべてのコンテンツを表示します。',
          'discovery.resetFilters' => '初期設定に戻す',
          'discovery.unsupportedRatings' => 'この画像ソースは選択したレーティングに対応していません。',
          'discovery.noFilteredPosts' => '条件に一致する画像がありません',
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
          'discovery.clearHistory' => '消去',
          'discovery.recentSearches' => '最近の検索',
          'discovery.noRecentSearches' => '検索履歴はありません',
          'discovery.myTags' => '自分のタグ',
          'discovery.commonTags' => 'よく使われるタグ',
          'discovery.moreTags' => 'もっと見る',
          'discovery.tagSource' => '対象サイト',
          'discovery.allTagSources' => 'すべてのサイト',
          'discovery.manageTags' => 'カスタムタグ',
          'discovery.manageTagsAction' => '管理',
          'discovery.addTagAction' => '追加',
          'discovery.deleteTag' => '削除',
          'discovery.addTag' => 'タグを追加',
          'discovery.noCustomTags' => 'カスタムタグはまだありません',
          'discovery.customTagsHint' => 'よく使うタグに覚えやすい名前を付けると、検索で見つけやすくなります。',
          'discovery.addCustomTag' => 'カスタムタグとして追加',
          'discovery.editTag' => 'カスタムタグを編集',
          'discovery.canonicalTag' => 'サイトのタグ',
          'discovery.displayName' => '表示名（任意）',
          'discovery.invalidTag' => '空白を含まないタグを1つ入力してください。',
          'discovery.queryHint' => 'タグを検索',
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
          'mediaError.videoProxyBypassed' =>
            '動画では SOCKS プロキシを利用できないため、今回は直接接続しました。',
          'mediaError.videoFailed' => '動画の再生に失敗しました',
          'mediaError.downloadOriginal' => '元のファイルをダウンロード',
          'mediaError.previewUnsupported' => 'プレビューできません',
          'mediaError.title' => '画像の読み込みに失敗しました',
          'mediaError.details' => 'エラーの詳細',
          'mediaError.copyDetails' => '詳細をコピー',
          'mediaError.decodeFailed' =>
            'ダウンロードした画像をデコードできませんでした。再試行すると、この画像のキャッシュを削除して再ダウンロードします。',
          'webChallenge.title' => 'ウェブ認証',
          'webChallenge.open' => 'ウェブ認証を開く',
          'webChallenge.windowTitle' =>
            ({required Object source}) => '${source} · 認証後にウィンドウを閉じてください',
          'webChallenge.instructions' =>
            'ページの人間確認を手動で完了してから、戻るかウィンドウを閉じてください。認証データを保存し、画像ソースを再読み込みします。',
          'webChallenge.finish' => '完了して戻る',
          'webChallenge.saving' => 'ウェブセッションを読み取り、確認しています',
          'webChallenge.waiting' => 'ウェブ認証を実行中',
          'webChallenge.clear' => '消去',
          'webChallenge.clearAll' => 'すべてのウェブ認証データを消去',
          'webChallenge.clearDescription' => 'Cookie、ブラウザー識別情報、ウェブキャッシュを消去します。',
          'webChallenge.cleared' => 'ウェブ認証データを消去しました',
          'webChallenge.verified' => '確認済み・アクセス可能',
          'webChallenge.saved' => '保存済み・再確認待ち',
          'webChallenge.empty' => '保存された認証データはありません',
          'webChallenge.failed' => 'ウェブ認証が完了しませんでした。再試行してください。',
          'webChallenge.pageLoadFailed' =>
            'ページを読み込めませんでした。認証ページを開き直すか、ネットワーク設定を確認してください。',
          'webChallenge.webViewUnavailable' => 'この環境ではウェブコンポーネントを使用できません。',
          'webChallenge.windowFailed' => 'ウェブ認証を開けませんでした。',
          'webChallenge.runtimeMissing' =>
            'Microsoft Edge WebView2 Runtime が見つかりません。インストールまたは更新してから再試行してください。',
          'webChallenge.proxyUnsupported' =>
            '現在のプロキシ設定には対応していません。設定を変更して再試行してください。',
          'webChallenge.busy' => '別のウェブ認証またはデータ消去を実行中です。',
          'webChallenge.cancelled' => 'ウェブ認証をキャンセルしました。',
          'webChallenge.timedOut' => 'ウェブ認証がタイムアウトしました。ページを開き直してください。',
          'webChallenge.storageFailed' =>
            '認証データを保存または消去できませんでした。以前のセッションは保持されています。',
          'webChallenge.captureFailed' =>
            'ウェブセッションを読み取れませんでした。認証ページを開き直してください。',
          'webChallenge.cleanupFailed' =>
            'ウェブデータの消去が完了していません。しばらくしてから再試行してください。',
          'webChallenge.operationSuperseded' =>
            'データの消去またはネットワーク設定の変更により、認証をキャンセルしました。',
          'webChallenge.noCookies' => '使用可能な認証データがありません。人間確認を完了してから戻ってください。',
          'nativeWindow.minimize' => '最小化',
          'nativeWindow.maximize' => '最大化',
          'nativeWindow.restore' => '元に戻す',
          'nativeWindow.close' => '閉じる',
          'batchDownload.title' => '一括ダウンロード',
          'batchDownload.close' => '閉じる',
          'batchDownload.limitTitle' => '画像を何枚まで取得しますか？',
          'batchDownload.limitHint' => '現在の検索条件でページごとに取得し、上限に達したら停止します。',
          'batchDownload.limitLabel' => '取得する画像の上限',
          'batchDownload.positiveInteger' => '1 以上の整数を入力してください。',
          'batchDownload.start' => '画像を取得',
          'batchDownload.fetchLimit' =>
            ({required Object count}) => '/ 最大 ${count} 枚',
          'batchDownload.fetching' => '見つかった画像',
          'batchDownload.progress' =>
            ({required Object current, required Object total}) =>
                '${current} / ${total}',
          'batchDownload.fetchProgress' =>
            ({required Object limit, required Object current}) =>
                '最大 ${limit} 枚のうち ${current} 枚を取得',
          'batchDownload.stopHint' => 'いつでも停止して、取得済みの画像を使用できます。',
          'batchDownload.stop' => '取得を停止',
          'batchDownload.found' => '枚の画像をダウンロードできます',
          'batchDownload.limitReached' => '取得上限に達しました。検索結果がまだ残っている可能性があります。',
          'batchDownload.exhausted' => '条件に一致するすべての結果を取得しました。',
          'batchDownload.permissionDenied' =>
            'ダウンロード権限がありません。システム設定でアプリの権限を確認してから再試行してください。',
          'batchDownload.enqueueFailed' =>
            'タスクを追加できませんでした。保存先と空き容量を確認してから再試行してください。',
          'batchDownload.stopped' => '取得を停止しました。見つかった画像をダウンロードできます。',
          'batchDownload.empty' => '条件に一致する画像が見つかりませんでした。',
          'batchDownload.stalled' =>
            'ページの取得が進まなくなりました。結果は保持されています。再試行するか取得済みの画像を使用してください。',
          'batchDownload.sessionChanged' =>
            '配信元の設定が変更されました。閉じてから再度取得するか、取得済みの画像を使用してください。',
          'batchDownload.fetchFailed' =>
            '取得を完了できませんでした。結果は保持されています。再試行するか取得済みの画像を使用してください。',
          'batchDownload.countLabel' => 'ダウンロード枚数',
          'batchDownload.all' => 'すべて',
          'batchDownload.countRange' =>
            ({required Object max}) => '1～${max} を入力',
          'batchDownload.orderHint' => '現在の検索順で先頭から N 枚をダウンロードします。',
          'batchDownload.folderLabel' => 'フォルダー名',
          'batchDownload.folderHint' => '例：9月のコレクション',
          'batchDownload.folderPlaceholder' => '保存フォルダー',
          'batchDownload.invalidFolder' =>
            '1～100 文字で入力してください。パス区切り、予約名、前後の空白、末尾のピリオドは使用できません。',
          'batchDownload.folderHelp' => '同名フォルダーを再利用し、既存のファイルは上書きしません。',
          'batchDownload.locationFailed' => '保存先を取得できませんでした。',
          'batchDownload.photos' => '写真ライブラリ',
          'batchDownload.photosHint' =>
            'iOS では配信元フォルダー内のアルバムに保存します。アルバムの再利用には写真へのフルアクセスが必要です。',
          'batchDownload.enqueue' =>
            ({required Object count}) => 'キューに追加 · ${count} 枚',
          'batchDownload.enqueueing' => 'ダウンロードキューに追加中',
          'batchDownload.preparing' =>
            ({required Object current, required Object total}) =>
                '${current} / ${total} 枚を準備中',
          'batchDownload.added' => 'ダウンロードキューに追加したタスク',
          'batchDownload.backgroundHint' =>
            'この画面を閉じてもアプリの実行中は追加を続けます。同じボタンから結果を確認できます。',
          'batchDownload.queueHint' => 'ダウンロードの進捗はダウンロード一覧で確認できます。',
          'batchDownload.failedHint' =>
            ({required Object count}) => '${count} 枚を追加できませんでした。',
          'batchDownload.retryFailed' => '失敗した画像を再試行',
          'batchDownload.queued' =>
            ({required Object added, required Object failed}) =>
                '一括処理：${added} 枚をキューに追加、${failed} 枚の追加に失敗。',
          'batchDownload.completed' =>
            ({required Object saved, required Object failed}) =>
                '一括ダウンロード終了：${saved} 枚を保存、${failed} 枚が失敗またはキャンセル。',
          'batchDownload.done' => '完了',
          'batchDownload.back' => '戻る',
          'batchDownload.first' => '先頭 N 枚',
          'batchDownload.addedCount' =>
            ({required Object count}) => '${count} 枚を追加しました',
          'batchDownload.savedTo' =>
            ({required Object folder}) => '保存先「${folder}」',
          'batchDownload.viewDownloads' => 'ダウンロードを表示',
          'frost.retry' => '再試行',
          'frost.error' => 'エラー',
          'frost.errorDetails' => 'エラーの詳細',
          'frost.copyDetails' => '詳細をコピー',
          'frost.copied' => 'コピーしました',
          'frost.loading' => '読み込み中',
          'frost.actionSucceeded' => '完了しました',
          'frost.actionFailed' => '失敗しました',
          'frost.loadFailed' => '読み込めませんでした',
          'frost.noItems' => 'まだ項目がありません',
          'frost.noMoreItems' => 'すべて表示しました',
          'frost.pullToRefresh' => '引っ張って更新',
          'frost.releaseToRefresh' => '離して更新',
          'frost.refreshing' => '更新中',
          'frost.refreshComplete' => '更新しました',
          'frost.refreshFailed' => '更新できませんでした',
          'frost.previous' => '前へ',
          'frost.next' => '次へ',
          'frost.back' => '戻る',
          'frost.more' => 'その他',
          'frost.expandNavigation' => 'サイドバーを開く',
          'frost.collapseNavigation' => 'サイドバーを閉じる',
          'frost.clearText' => '入力を消去',
          'frost.search' => '検索',
          'frost.noResults' =>
            ({required Object query}) => '「${query}」の結果はありません',
          'frost.clearSearch' => '検索を消去',
          'frost.dismiss' => '閉じる',
          'frost.expandText' => 'もっと見る',
          'frost.collapseText' => '折りたたむ',
          'frost.showAll' => 'すべて表示',
          'frost.copy' => 'コピー',
          'frost.clearAll' => 'すべて消去',
          'frost.showPassword' => 'パスワードを表示',
          'frost.hidePassword' => 'パスワードを隠す',
          'frost.chooseDate' => '日付を選択',
          'frost.chooseTime' => '時刻を選択',
          'frost.increment' => '増やす',
          'frost.decrement' => '減らす',
          'frost.reorderHandle' => '並べ替え',
          'frost.sortAscending' => '昇順',
          'frost.sortDescending' => '降順',
          'frost.play' => '再生',
          'frost.pause' => '一時停止',
          'frost.loop' => 'ループ再生',
          'frost.mute' => 'ミュート',
          'frost.unmute' => 'ミュートを解除',
          'frost.fullscreen' => '全画面表示',
          'frost.exitFullscreen' => '全画面表示を終了',
          'frost.reload' => '再読み込み',
          'frost.openInBrowser' => 'ブラウザーで開く',
          'frost.minimize' => '最小化',
          _ => null,
        } ??
        switch (path) {
          'frost.maximize' => '最大化',
          'frost.restore' => '元のサイズに戻す',
          'frost.close' => '閉じる',
          'frost.cancel' => 'キャンセル',
          'frost.apply' => '適用',
          'frost.clear' => '消去',
          'frost.choose' => '選択',
          'frost.showInFolder' => 'フォルダーで表示',
          'frost.selectedCount' => ({required Object count}) => '${count}件を選択中',
          'frost.pageOf' =>
            ({required Object total, required Object page}) =>
                '${total}ページ中${page}ページ',
          'frost.selectAll' => 'すべて選択',
          'frost.done' => '完了',
          'frost.itemPosition' =>
            ({required Object total, required Object position}) =>
                '${total}件中${position}件目',
          'frost.tableDimensions' =>
            ({required Object rows, required Object columns}) =>
                '${rows}行、${columns}列',
          'frost.taskQueued' => '待機中',
          'frost.taskRunning' => 'ダウンロード中',
          'frost.taskPaused' => '一時停止中',
          'frost.taskCompleted' => '完了',
          'frost.taskFailed' => '失敗',
          'frost.taskCancelled' => 'キャンセル済み',
          'frost.remove' => '削除',
          'frost.forward' => '進む',
          'frost.stop' => '停止',
          'frost.seek' => '再生位置',
          'frost.send' => '送信',
          'frost.attach' => '添付',
          'frost.readerSettings' => '表示設定',
          'frost.textSize' => '文字サイズ',
          'frost.lineSpacing' => '行間',
          'frost.readingProgress' => '読書の進捗',
          'frost.showReplies' => ({required Object count}) => '${count}件の返信を表示',
          'frost.characterCount' =>
            ({required Object limit, required Object count}) =>
                '${limit}文字中${count}文字',
          'frost.moreMedia' => ({required Object count}) => 'ほか${count}枚',
          'frost.navigationCount' => ({required Object count}) => '${count}件',
          'frost.navigationProgress' =>
            ({required Object progress}) => '進捗${progress}%',
          'frost.listSeparator' => '、',
          'navigation.browse' => '閲覧',
          'navigation.search' => '検索',
          'navigation.downloads' => 'ダウンロード',
          'navigation.settings' => '設定',
          'navigation.browseEmpty' => 'お気に入りのサイトを閲覧',
          'navigation.searchEmpty' => 'タグで作品を検索',
          'navigation.downloadsEmpty' => 'ダウンロードはここに表示されます',
          'navigation.settingsEmpty' => 'BooruFlowを使いやすく',
          'settingsV2.predictiveBack' => '予測型「戻る」',
          'settingsV2.predictiveBackScope' =>
            'アプリ内の戻る動作をプレビューします。ホーム画面に戻るアニメーションはシステムが制御します。',
          'settingsV2.background' => '背景',
          'settingsV2.ambientBlur' => '環境ぼかし',
          'settingsV2.mica' => 'マイカ',
          'settingsV2.backgroundOff' => 'オフ',
          'settingsV2.backgroundIntensity' => '強さ',
          'settingsV2.systemTransparencyReduced' => 'システムで透明度を下げています',
          'settingsV2.customColour' => 'カスタムカラー',
          'settingsV2.appearance' => '外観',
          'settingsV2.browsing' => '閲覧',
          'settingsV2.tone' => '色調',
          'settingsV2.neutral' => '標準',
          'settingsV2.cool' => '寒色',
          'settingsV2.warm' => '暖色',
          'settingsV2.accent' => 'アクセントカラー',
          'settingsV2.customAccent' => 'カスタムカラー',
          'settingsV2.customHex' => 'アクセントのHEX',
          'settingsV2.invalidHex' => '6桁のHEXカラーを入力してください。',
          'settingsV2.accentRejected' => 'この色は現在の背景で読みづらいため使用できません。',
          'settingsV2.accentWarning' => 'この色はコントラストが低くなります。適用しますか？',
          'settingsV2.editAccount' => 'アカウントを編集',
          'settingsV2.signOutConfirm' => 'このソースの保存済み認証情報を削除しますか？',
          'settingsV2.licenses' => 'オープンソースライセンス',
          'settingsV2.checkUpdates' => '更新を確認',
          'settingsV2.help' => 'ヘルプ',
          'settingsDetails.mode' => 'モード',
          'settingsDetails.custom' => 'カスタム',
          'settingsDetails.change' => '変更',
          'settingsDetails.routeCache' => 'ルートキャッシュ',
          'settingsDetails.hostCount' =>
            ({required Object count}) => '${count} ホスト',
          'settingsDetails.updatedAt' =>
            ({required Object time}) => '更新 ${time}',
          'settingsDetails.sourceStatus' => '画像ソースの状態',
          'settingsDetails.apiAndImages' => 'API と画像を利用可能',
          'settingsDetails.apiOnly' => 'API 利用可能 · 画像に接続不可',
          'settingsDetails.status' => '状態',
          'settingsDetails.content' => 'コンテンツ',
          'settingsDetails.editSourceAccount' =>
            ({required Object source}) => '${source} のアカウントを編集',
          'settingsDetails.proxyApplies' => '画像ソース、画像、新しいダウンロードに適用します。',
          'settingsDetails.version' =>
            ({required Object version, required Object build}) =>
                'バージョン ${version} (${build})',
          'settingsDetails.communityTelegram' => 'Telegram グループ',
          'settingsDetails.communityDiscord' => 'Discord サーバー',
          'settingsDetails.savedVerifications' => '保存した認証',
          'settingsDetails.systemDnsShort' => 'システム DNS',
          'settingsDetails.refresh' => '更新',
          'settingsDetails.updateAvailable' =>
            ({required Object version}) => '新しいバージョン ${version} があります',
          'verificationPage.instructions' => '下のページで認証し、完了して戻るを選んでください。',
          'verificationPage.opening' => 'ページを開いています',
          'verificationPage.failed' => 'ページを読み込めませんでした',
          'verificationPage.closed' => '認証ウィンドウを閉じました',
          'verificationPage.failureHelp' => 'もう一度開くか、ネットワーク設定を確認してください。',
          'verificationPage.reopen' => 'もう一度開く',
          'verificationPage.signOut' =>
            ({required Object source}) => '${source} からログアウトしますか？',
          'verificationPage.signOutHelp' => 'この端末からアカウント情報を削除します。',
          'verificationPage.downloadAdded' => 'ダウンロードに追加しました',
          'verificationPage.downloadFailed' => 'ダウンロード失敗',
          'verificationPage.linkCopied' => 'リンクをコピーしました',
          'verificationPage.view' => '表示',
          'verificationPage.networkSettings' => 'ネットワーク設定',
          'ugoira.iosFilesDestination' => 'その他の形式：ファイル › BooruFlow',
          'ugoira.iosFormatHelp' => 'アニメーション WebP と ZIP は「ファイル」に保存します。',
          'ugoira.albumName' => 'アルバム名',
          'ugoira.openSettings' => '設定を開く',
          'ugoira.androidDestination' => 'アルバムとダウンロード',
          'ugoira.iosDestination' => '写真に保存',
          'ugoira.format' => 'うごイラの保存形式',
          'ugoira.losslessWebp' => '可逆圧縮のアニメーション WebP',
          'ugoira.originalZip' => '元の ZIP',
          'ugoira.webpRecord' => 'WebP · アニメーション',
          'ugoira.zipRecord' => 'ZIP · 元のフレーム',
          'ugoira.ugoiraInvalidArchive' => 'アニメーションの ZIP ファイルが無効です。',
          'ugoira.ugoiraMetadataMissing' => 'フレームの表示時間がありません。',
          'ugoira.ugoiraInvalidMetadata' => 'フレームの表示時間が無効です。',
          'ugoira.ugoiraFrameMissing' => 'アニメーションのフレームが見つかりません。',
          'ugoira.ugoiraFrameCorrupt' => 'アニメーションのフレームが破損しています。',
          'ugoira.ugoiraFrameSizeMismatch' => 'フレームのサイズが一致しません。',
          'ugoira.ugoiraFrameTooLarge' => 'フレームがサイズの上限を超えています。',
          'ugoira.ugoiraEncodeFailed' => 'アニメーションをエンコードできませんでした。',
          'ugoira.ugoiraOutputTooLarge' => '出力ファイルがサイズの上限を超えています。',
          _ => null,
        };
  }
}
