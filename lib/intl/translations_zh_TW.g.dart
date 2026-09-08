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
class TranslationsZhTw extends Translations with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsZhTw({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.zhTw,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ),
       super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <zh-TW>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key) ?? super[key];

  late final TranslationsZhTw _root = this; // ignore: unused_field

  @override
  TranslationsZhTw $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) =>
      TranslationsZhTw(meta: meta ?? this.$meta);

  // Translations
  @override
  late final Translations$generic$zh_TW generic = Translations$generic$zh_TW.internal(_root);
  @override
  late final Translations$booruError$zh_TW booruError = Translations$booruError$zh_TW.internal(_root);
  @override
  late final Translations$update$zh_TW update = Translations$update$zh_TW.internal(_root);
  @override
  late final Translations$postList$zh_TW postList = Translations$postList$zh_TW.internal(_root);
  @override
  late final Translations$postDetail$zh_TW postDetail = Translations$postDetail$zh_TW.internal(_root);
  @override
  late final Translations$postSearch$zh_TW postSearch = Translations$postSearch$zh_TW.internal(_root);
  @override
  late final Translations$imageZoom$zh_TW imageZoom = Translations$imageZoom$zh_TW.internal(_root);
  @override
  late final Translations$downloads$zh_TW downloads = Translations$downloads$zh_TW.internal(_root);
  @override
  late final Translations$about$zh_TW about = Translations$about$zh_TW.internal(_root);
  @override
  late final Translations$settings$zh_TW settings = Translations$settings$zh_TW.internal(_root);
  @override
  late final Translations$discovery$zh_TW discovery = Translations$discovery$zh_TW.internal(_root);
  @override
  late final Translations$mediaError$zh_TW mediaError = Translations$mediaError$zh_TW.internal(_root);
}

// Path: generic
class Translations$generic$zh_TW extends Translations$generic$en {
  Translations$generic$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get ok => '確定';
  @override
  String get cancel => '取消';
  @override
  String get clear => '清除';
  @override
  String get confirm => '確認';
  @override
  String get enabled => '啟用';
  @override
  String get disabled => '停用';
  @override
  String copiedWithValue({required Object value}) => '已複製到剪貼簿: ${value}';
  @override
  String errorWithValue({required Object value}) => '發生錯誤: ${value}';
  @override
  String errorWithCause({required Object message, required Object cause}) => '${message}：${cause}';
  @override
  String get loading => '載入中...';
  @override
  String get loadFailed => '載入失敗';
  @override
  String get retry => '重試';
  @override
  String get noMoreData => '沒有更多資料';
  @override
  String get notFound => '找不到內容';
}

// Path: booruError
class Translations$booruError$zh_TW extends Translations$booruError$en {
  Translations$booruError$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get invalidRequest => '請求參數無效。';
  @override
  String get unsupportedCapability => '目前圖源不支援此操作。';
  @override
  String get authenticationRequired => '請登入目前圖源後重試。';
  @override
  String get authenticationRejected => '圖源拒絕了帳號憑證。';
  @override
  String get permissionDenied => '圖源拒絕存取此資源。';
  @override
  String get rateLimited => '請求受到圖源限流，請稍後重試。';
  @override
  String get challengeRequired => '圖源要求瀏覽器驗證。可嘗試在瀏覽器中開啟圖源完成驗證，或選擇其他圖源。';
  @override
  String get routeUnavailable => '目前網域沒有可用路由。請在網路設定中重新整理路由；不會改用系統 DNS。';
  @override
  String get sourceUnavailable => '目前圖源暫時無法使用。';
  @override
  String get network => '網路請求失敗。請檢查網路連線並重試。如果問題持續，可嘗試使用代理伺服器。';
  @override
  String get timeout => '請求逾時。請檢查網路連線，或稍後重試。';
  @override
  String get invalidResponse => '圖源回傳了無法解析的回應。';
  @override
  String get unsafeRedirect => '圖源回傳了不安全的重新導向。';
  @override
  String get mediaValidationFailed => '圖片回應驗證或解碼失敗。';
  @override
  String get cancelled => '請求已取消。';
  @override
  String get internal => '圖源引擎發生內部錯誤。';
}

// Path: update
class Translations$update$zh_TW extends Translations$update$en {
  Translations$update$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get checkUpdateStart => '正在檢查更新...';
  @override
  String get checkUpdateFailed => '檢查更新失敗，請檢查您的網路連線。';
  @override
  String get selectDownloadUrlFailed => '找不到下載連結。\n請訪問專案頁面以手動更新或在專案Issue頁尋求幫助。';
  @override
  String newVersionFound({required Object version}) => '發現新版本: ${version}。請轉到「關於」頁面並點擊「下載更新」。';
  @override
  String get noNewVersionFound => '沒有新版本。';
}

// Path: postList
class Translations$postList$zh_TW extends Translations$postList$en {
  Translations$postList$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get short => '首頁';
  @override
  String get title => '首頁';
  @override
  String titleWithTags({required Object tags}) => '帶有標籤的帖子: ${tags}';
}

// Path: postDetail
class Translations$postDetail$zh_TW extends Translations$postDetail$en {
  Translations$postDetail$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String titleWithId({required Object id}) => '帖子: ${id}';
  @override
  String get tags => '標籤';
  @override
  String get details => '詳細資訊';
  @override
  String get actions => '操作';
  @override
  String get rating => '安全評級';
  @override
  String get fileType => '檔案類型';
  @override
  String get viewOriginal => '查看原圖';
  @override
  String get download => '下載';
  @override
  String get relatedLoadFailed => '關聯圖片載入失敗，可以重試。';
  @override
  String get createdAt => '建立時間';
  @override
  String get author => '作者';
  @override
  String get unknownAuthor => '未知';
  @override
  String get imageSource => '圖源';
  @override
  String get source => '來源';
  @override
  String get width => '寬度';
  @override
  String get height => '高度';
  @override
  String get score => '評分';
  @override
  String get size => '大小';
  @override
  String get parent => '父ID';
  @override
  String get hasChildren => '有子帖子';
  @override
  String get similarPosts => '相似帖子';
  @override
  String get parentPost => '父帖子';
  @override
  String get childPost => '子帖子';
}

// Path: postSearch
class Translations$postSearch$zh_TW extends Translations$postSearch$en {
  Translations$postSearch$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '搜尋';
}

// Path: imageZoom
class Translations$imageZoom$zh_TW extends Translations$imageZoom$en {
  Translations$imageZoom$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '縮放圖片';
}

// Path: downloads
class Translations$downloads$zh_TW extends Translations$downloads$en {
  Translations$downloads$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '下載項';
  @override
  String get tasksTitle => '下載任務';
  @override
  String get noTasks => '尚無下載任務';
  @override
  String get noTasksMessage => '下載的圖片會顯示在這裡。';
  @override
  String get total => '總數';
  @override
  String get active => '進行中';
  @override
  String get saved => '已儲存';
  @override
  String get completed => '已完成';
  @override
  String get failed => '失敗';
  @override
  String get waiting => '等待中';
  @override
  String get downloading => '下載中';
  @override
  String get needsAttention => '需要處理';
  @override
  String get queued => '佇列中';
  @override
  String get running => '正在下載';
  @override
  String get paused => '已暫停';
  @override
  String get downloaded => '已下載';
  @override
  String get cancelled => '已取消';
  @override
  String get savePending => '等待儲存';
  @override
  String get saving => '正在儲存';
  @override
  String get saveFailed => '儲存失敗';
  @override
  String get retrySave => '重試儲存';
  @override
  String get cancel => '取消';
  @override
  String get deleteTask => '刪除任務';
  @override
  String get sync => '同步';
  @override
  String get syncFailed => '下載狀態同步失敗';
  @override
  String get actionFailed => '下載操作失敗';
  @override
  String get expand => '展開';
  @override
  String get collapse => '收合';
  @override
  late final Translations$downloads$messages$zh_TW messages = Translations$downloads$messages$zh_TW.internal(_root);
}

// Path: about
class Translations$about$zh_TW extends Translations$about$en {
  Translations$about$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '關於';
  @override
  String get projectUrl => '專案網址';
  @override
  String get publishPage => '發佈頁面';
  @override
  String get appVersion => '應用程式版本';
  @override
  String get freepivPromotionTitle => '試試 freepiv';
  @override
  String get freepivPromotionSubtitle => '現代、流暢的跨平台 Pixiv 第三方用戶端。';
  @override
  String get discussion => '討論';
  @override
  String get downloadUpdate => '下載更新';
  @override
  String get downloadUpdateHint => '透過瀏覽器下載適合您裝置的最新版本。';
}

// Path: settings
class Translations$settings$zh_TW extends Translations$settings$en {
  Translations$settings$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '設定';
  @override
  String get theme => '主題';
  @override
  String get language => '語言';
  @override
  String get bypassSni => '略過 SNI';
  @override
  String get downloadDirectory => '下載目錄';
  @override
  String get defaultToPlatformSettings => '使用系統預設';
  @override
  String get columnsPerRow => '每行列數';
  @override
  String get maxConcurrentDownloads => '最大同時下載任務數';
  @override
  String get maxSegmentsPerTask => '每個下載任務的最大分段數';
  @override
  String get platformDefault => '平台預設';
  @override
  String get system => '系統';
  @override
  String get light => '淺色模式';
  @override
  String get dark => '深色模式';
  @override
  String get auto => '自動';
  @override
  String get downloadsOverview => '儲存位置與同時下載數';
  @override
  late final Translations$settings$sections$zh_TW sections = Translations$settings$sections$zh_TW.internal(_root);
  @override
  late final Translations$settings$source$zh_TW source = Translations$settings$source$zh_TW.internal(_root);
  @override
  late final Translations$settings$account$zh_TW account = Translations$settings$account$zh_TW.internal(_root);
  @override
  late final Translations$settings$network$zh_TW network = Translations$settings$network$zh_TW.internal(_root);
  @override
  late final Translations$settings$languageDialog$zh_TW languageDialog =
      Translations$settings$languageDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$themeModeDialog$zh_TW themeModeDialog =
      Translations$settings$themeModeDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$downloadDirectoryDialog$zh_TW downloadDirectoryDialog =
      Translations$settings$downloadDirectoryDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$bypassSniDialog$zh_TW bypassSniDialog =
      Translations$settings$bypassSniDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$columnsPerRowDialog$zh_TW columnsPerRowDialog =
      Translations$settings$columnsPerRowDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$maxConcurrentDownloadsDialog$zh_TW maxConcurrentDownloadsDialog =
      Translations$settings$maxConcurrentDownloadsDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$maxSegmentsPerTaskDialog$zh_TW maxSegmentsPerTaskDialog =
      Translations$settings$maxSegmentsPerTaskDialog$zh_TW.internal(_root);
}

// Path: discovery
class Translations$discovery$zh_TW extends Translations$discovery$en {
  Translations$discovery$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get searchResults => '搜尋結果';
  @override
  String get allAvailable => '全部可用內容';
  @override
  String get defaultRatingsHint => '分級偏好適用於所有圖源。未選擇分級時，顯示目前圖源和帳號能存取的所有內容。';
  @override
  String get resetFilters => '恢復預設';
  @override
  String get unsupportedRatings => '目前圖源不支援所選分級，請恢復預設以瀏覽可用內容。';
  @override
  String get noFilteredPosts => '沒有符合目前篩選條件的內容。';
  @override
  String get noSearchResults => '沒有找到符合此查詢的內容。';
  @override
  String get noFeedPosts => '目前圖源暫時沒有可展示的內容。';
  @override
  String get historicalPopular => '歷史熱門';
  @override
  String get calendarDay => '自然日';
  @override
  String get calendarWeek => '自然週';
  @override
  String get calendarMonth => '自然月';
  @override
  String get latest => '最新';
  @override
  String get popular => '熱門';
  @override
  String get today => '今日';
  @override
  String get thisWeek => '本週';
  @override
  String get thisMonth => '本月';
  @override
  String get lastDay => '最近 24 小時';
  @override
  String get lastThreeDays => '最近 3 天';
  @override
  String get lastWeek => '最近一週';
  @override
  String get lastMonth => '最近一個月';
  @override
  String get lastThreeMonths => '最近三個月';
  @override
  String get lastSixMonths => '最近六個月';
  @override
  String get lastYear => '最近一年';
  @override
  String get rankingComplete => '榜單已全部載入';
  @override
  String get latestFallback => '此圖源僅支援最新貼文。';
  @override
  String get filters => '篩選';
  @override
  String get loadMore => '載入更多';
  @override
  String get filteredContinue => '目前幾頁沒有符合篩選的貼文，繼續瀏覽';
  @override
  String get commonTags => '常用標籤';
  @override
  String get moreTags => '查看更多';
  @override
  String get tagSource => '適用圖源';
  @override
  String get allTagSources => '通用';
  @override
  String get manageTags => '標籤管理';
  @override
  String get addTag => '新增標籤';
  @override
  String get noCustomTags => '還沒有自訂標籤';
  @override
  String get customTagsHint => '為常用標籤設定好記的名稱，搜尋時更容易找到。';
  @override
  String get addCustomTag => '新增為自訂標籤';
  @override
  String get editTag => '編輯自訂標籤';
  @override
  String get canonicalTag => '圖源標籤';
  @override
  String get displayName => '顯示名稱（選填）';
  @override
  String get invalidTag => '請輸入一個非空且不含空格的標籤。';
  @override
  String get queryHint => '輸入標籤或圖源查詢語句…';
  @override
  String get unverifiedTag => '部分標籤尚未在目前圖源驗證，仍可提交搜尋。';
  @override
  String get verifiedTag => '已在目前圖源驗證';
  @override
  String get noSuggestions => '沒有建議';
  @override
  String get localFallback => '線上補全暫時無法使用，仍可使用本機建議。';
  @override
  String get retryTags => '重試常用標籤';
  @override
  String get artist => '繪師';
  @override
  String get character => '角色';
  @override
  String get copyright => '作品';
  @override
  String get meta => '中繼標籤';
  @override
  String get general => '一般';
  @override
  String get random => '隨機';
  @override
  String get lifetimeViews => '累計瀏覽量';
  @override
  String get lifetimeFavorites => '累計收藏數';
}

// Path: mediaError
class Translations$mediaError$zh_TW extends Translations$mediaError$en {
  Translations$mediaError$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '圖片載入失敗';
  @override
  String get details => '錯誤詳情';
  @override
  String get copyDetails => '複製詳情';
  @override
  String get decodeFailed => '下載的圖片無法解碼。重試會清除這張圖片的快取並重新下載。';
}

// Path: downloads.messages
class Translations$downloads$messages$zh_TW extends Translations$downloads$messages$en {
  Translations$downloads$messages$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get storagePermanentlyDenied => '您已永久拒絕存儲權限。\n請在設定中手動啟用存儲權限。';
  @override
  String get storageDenied => '您已拒絕存儲權限。';
  @override
  String get deviceInfoError => '無法解析設備資訊。';
  @override
  String get photosPermanentlyDenied => '您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。';
  @override
  String get photosDenied => '您已拒絕照片權限。';
  @override
  String get downloadTaskExists => '下載任務已經存在。';
  @override
  String get imageFileExists => '圖片檔案已經存在。';
  @override
  String downloadRetryWith({required Object name}) => '重試下載任務: ${name}';
  @override
  String downloadStartWith({required Object name}) => '開始下載任務: ${name}';
  @override
  String downloadCompletedWith({required Object name}) => '下載任務完成: ${name}';
  @override
  String downloadFailedWith({required Object name}) => '下載任務失敗: ${name}';
  @override
  String saveFailedWith({required Object name}) => '儲存失敗: 任務 ${name}';
}

// Path: settings.sections
class Translations$settings$sections$zh_TW extends Translations$settings$sections$en {
  Translations$settings$sections$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get sourcesAndAccounts => '圖源與帳號';
  @override
  String get accounts => '帳號';
  @override
  String get network => '網路';
  @override
  String get general => '一般';
  @override
  String get downloads => '下載';
}

// Path: settings.source
class Translations$settings$source$zh_TW extends Translations$settings$source$en {
  Translations$settings$source$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get defaultSource => '預設圖源';
  @override
  String get supportedRatings => '支援的分級';
  @override
  String get safetyRating => '全域內容分級';
}

// Path: settings.account
class Translations$settings$account$zh_TW extends Translations$settings$account$en {
  Translations$settings$account$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get manageAllSubtitle => '圖源分級與帳號設定';
  @override
  String get noAccountRequired => '此圖源無需設定帳號';
  @override
  String get openSignInPage => '開啟登入頁面';
  @override
  String get cookieHeader => 'Cookie 標頭';
  @override
  String get storedLocally => '僅儲存在此裝置';
  @override
  String get browserUserAgent => '瀏覽器 User-Agent';
  @override
  String get browserUserAgentHint => '使用與已登入瀏覽器相同的 User-Agent';
  @override
  String get required => '必填';
  @override
  String get optional => '選填';
  @override
  String get actions => '帳號操作';
  @override
  String get save => '儲存';
  @override
  String get verify => '驗證';
  @override
  String get signOut => '登出';
  @override
  String get saved => '帳號已儲存';
  @override
  String get saveFailed => '無法儲存帳號';
  @override
  String get verified => '帳號已驗證';
  @override
  String get verificationFailed => '驗證失敗';
  @override
  String get username => '使用者名稱';
  @override
  String get userId => '使用者 ID';
  @override
  String get apiKey => 'API 金鑰';
  @override
  String statusValue({required Object status}) => '狀態 · ${status}';
  @override
  late final Translations$settings$account$statuses$zh_TW statuses =
      Translations$settings$account$statuses$zh_TW.internal(_root);
}

// Path: settings.network
class Translations$settings$network$zh_TW extends Translations$settings$network$en {
  Translations$settings$network$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get dnsProvider => 'DNS 服務';
  @override
  String get servicesTitle => '全部圖源狀態';
  @override
  String get servicesHint => 'IP 解析與 API 可用性分別檢測；API 可用不代表所有圖片均可下載。';
  @override
  String get noFallback => '僅使用所選 DNS，失敗直接報錯；不會改用系統 DNS 或自動切換服務。';
  @override
  String checkProgress({
    required Object done,
    required Object total,
    required Object checked,
    required Object sources,
  }) => 'DNS 已完成 ${done}/${total} · API 已檢測 ${checked}/${sources}';
  @override
  String checkSummary({required Object available, required Object total, required Object failed}) =>
      'API 可用 ${available}/${total} · DNS 失敗 ${failed} 項';
  @override
  String get loadingStatus => '正在讀取快取狀態…';
  @override
  String get apiChecking => 'API：檢測中…';
  @override
  String get apiAvailable => 'API：可用';
  @override
  String get apiFailed => 'API：無法使用';
  @override
  String get apiUnchecked => 'API：尚未檢測';
  @override
  String get dnsPending => '尚未解析 · 點選重新整理路由取得 IP';
  @override
  String get dnsResolving => '正在解析…';
  @override
  String get dnsResolved => '解析成功';
  @override
  String get dnsCached => '使用已快取 IP · 尚未重新檢測';
  @override
  String get dnsFailed => '解析失敗 · 目前無可用路由';
  @override
  String get dnsQueued => '等待解析…';
  @override
  String ipCachedAt({required Object time}) => 'IP 已快取 · 更新於 ${time}';
  @override
  String get ipNotCached => 'IP 已解析 · 尚未寫入快取';
  @override
  String get connectionMode => '連線模式';
  @override
  String get proxyUrl => 'Proxy URL';
  @override
  String get proxyHint => '選填 · 例如 http://127.0.0.1:7890';
  @override
  String get applyAndRouteCache => '套用與路由快取';
  @override
  String get apply => '套用網路設定';
  @override
  String get refreshRoutes => '重新整理路由';
  @override
  String get routeCacheUnavailable => '無法取得路由快取';
  @override
  String routeCacheStatus({required Object hosts, required Object revision}) => '${hosts} 個主機 · 修訂 ${revision}';
  @override
  String get applied => '網路設定已套用';
  @override
  String get invalidSettings => '網路設定無效';
  @override
  String get routeRefreshFailed => '路由重新整理失敗';
  @override
  String get systemDns => '系統 DNS';
  @override
  String get sniBypass => '略過 SNI';
  @override
  String get legacyIpUrl => '舊版 IP URL';
}

// Path: settings.languageDialog
class Translations$settings$languageDialog$zh_TW extends Translations$settings$languageDialog$en {
  Translations$settings$languageDialog$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '語言';
}

// Path: settings.themeModeDialog
class Translations$settings$themeModeDialog$zh_TW extends Translations$settings$themeModeDialog$en {
  Translations$settings$themeModeDialog$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '主題模式';
}

// Path: settings.downloadDirectoryDialog
class Translations$settings$downloadDirectoryDialog$zh_TW extends Translations$settings$downloadDirectoryDialog$en {
  Translations$settings$downloadDirectoryDialog$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '下載目錄';
  @override
  String get pickerTitle => '選擇目錄';
  @override
  String get pick => '選擇目錄';
  @override
  late final Translations$settings$downloadDirectoryDialog$messages$zh_TW messages =
      Translations$settings$downloadDirectoryDialog$messages$zh_TW.internal(_root);
}

// Path: settings.bypassSniDialog
class Translations$settings$bypassSniDialog$zh_TW extends Translations$settings$bypassSniDialog$en {
  Translations$settings$bypassSniDialog$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '略過 SNI';
}

// Path: settings.columnsPerRowDialog
class Translations$settings$columnsPerRowDialog$zh_TW extends Translations$settings$columnsPerRowDialog$en {
  Translations$settings$columnsPerRowDialog$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每行列數';
}

// Path: settings.maxConcurrentDownloadsDialog
class Translations$settings$maxConcurrentDownloadsDialog$zh_TW
    extends Translations$settings$maxConcurrentDownloadsDialog$en {
  Translations$settings$maxConcurrentDownloadsDialog$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '最大同時下載任務數';
}

// Path: settings.maxSegmentsPerTaskDialog
class Translations$settings$maxSegmentsPerTaskDialog$zh_TW extends Translations$settings$maxSegmentsPerTaskDialog$en {
  Translations$settings$maxSegmentsPerTaskDialog$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每個下載任務的最大分段數';
}

// Path: settings.account.statuses
class Translations$settings$account$statuses$zh_TW extends Translations$settings$account$statuses$en {
  Translations$settings$account$statuses$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get notConfigured => '尚未設定';
  @override
  String get configuredUnverified => '已設定，尚未驗證';
  @override
  String get verified => '已驗證';
  @override
  String get rejected => '已被拒絕';
}

// Path: settings.downloadDirectoryDialog.messages
class Translations$settings$downloadDirectoryDialog$messages$zh_TW
    extends Translations$settings$downloadDirectoryDialog$messages$en {
  Translations$settings$downloadDirectoryDialog$messages$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get setToPlatformDefault => '下載目錄已設為系統預設。';
  @override
  String get pathNotAbsolute => '路徑必須是絕對路徑。';
  @override
  String get pathNotWritable => '路徑不可寫入。';
}

/// The flat map containing all translations for locale <zh-TW>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhTw {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'generic.ok' => '確定',
      'generic.cancel' => '取消',
      'generic.clear' => '清除',
      'generic.confirm' => '確認',
      'generic.enabled' => '啟用',
      'generic.disabled' => '停用',
      'generic.copiedWithValue' => ({required Object value}) => '已複製到剪貼簿: ${value}',
      'generic.errorWithValue' => ({required Object value}) => '發生錯誤: ${value}',
      'generic.errorWithCause' => ({required Object message, required Object cause}) => '${message}：${cause}',
      'generic.loading' => '載入中...',
      'generic.loadFailed' => '載入失敗',
      'generic.retry' => '重試',
      'generic.noMoreData' => '沒有更多資料',
      'generic.notFound' => '找不到內容',
      'booruError.invalidRequest' => '請求參數無效。',
      'booruError.unsupportedCapability' => '目前圖源不支援此操作。',
      'booruError.authenticationRequired' => '請登入目前圖源後重試。',
      'booruError.authenticationRejected' => '圖源拒絕了帳號憑證。',
      'booruError.permissionDenied' => '圖源拒絕存取此資源。',
      'booruError.rateLimited' => '請求受到圖源限流，請稍後重試。',
      'booruError.challengeRequired' => '圖源要求瀏覽器驗證。可嘗試在瀏覽器中開啟圖源完成驗證，或選擇其他圖源。',
      'booruError.routeUnavailable' => '目前網域沒有可用路由。請在網路設定中重新整理路由；不會改用系統 DNS。',
      'booruError.sourceUnavailable' => '目前圖源暫時無法使用。',
      'booruError.network' => '網路請求失敗。請檢查網路連線並重試。如果問題持續，可嘗試使用代理伺服器。',
      'booruError.timeout' => '請求逾時。請檢查網路連線，或稍後重試。',
      'booruError.invalidResponse' => '圖源回傳了無法解析的回應。',
      'booruError.unsafeRedirect' => '圖源回傳了不安全的重新導向。',
      'booruError.mediaValidationFailed' => '圖片回應驗證或解碼失敗。',
      'booruError.cancelled' => '請求已取消。',
      'booruError.internal' => '圖源引擎發生內部錯誤。',
      'update.checkUpdateStart' => '正在檢查更新...',
      'update.checkUpdateFailed' => '檢查更新失敗，請檢查您的網路連線。',
      'update.selectDownloadUrlFailed' => '找不到下載連結。\n請訪問專案頁面以手動更新或在專案Issue頁尋求幫助。',
      'update.newVersionFound' => ({required Object version}) => '發現新版本: ${version}。請轉到「關於」頁面並點擊「下載更新」。',
      'update.noNewVersionFound' => '沒有新版本。',
      'postList.short' => '首頁',
      'postList.title' => '首頁',
      'postList.titleWithTags' => ({required Object tags}) => '帶有標籤的帖子: ${tags}',
      'postDetail.titleWithId' => ({required Object id}) => '帖子: ${id}',
      'postDetail.tags' => '標籤',
      'postDetail.details' => '詳細資訊',
      'postDetail.actions' => '操作',
      'postDetail.rating' => '安全評級',
      'postDetail.fileType' => '檔案類型',
      'postDetail.viewOriginal' => '查看原圖',
      'postDetail.download' => '下載',
      'postDetail.relatedLoadFailed' => '關聯圖片載入失敗，可以重試。',
      'postDetail.createdAt' => '建立時間',
      'postDetail.author' => '作者',
      'postDetail.unknownAuthor' => '未知',
      'postDetail.imageSource' => '圖源',
      'postDetail.source' => '來源',
      'postDetail.width' => '寬度',
      'postDetail.height' => '高度',
      'postDetail.score' => '評分',
      'postDetail.size' => '大小',
      'postDetail.parent' => '父ID',
      'postDetail.hasChildren' => '有子帖子',
      'postDetail.similarPosts' => '相似帖子',
      'postDetail.parentPost' => '父帖子',
      'postDetail.childPost' => '子帖子',
      'postSearch.title' => '搜尋',
      'imageZoom.title' => '縮放圖片',
      'downloads.title' => '下載項',
      'downloads.tasksTitle' => '下載任務',
      'downloads.noTasks' => '尚無下載任務',
      'downloads.noTasksMessage' => '下載的圖片會顯示在這裡。',
      'downloads.total' => '總數',
      'downloads.active' => '進行中',
      'downloads.saved' => '已儲存',
      'downloads.completed' => '已完成',
      'downloads.failed' => '失敗',
      'downloads.waiting' => '等待中',
      'downloads.downloading' => '下載中',
      'downloads.needsAttention' => '需要處理',
      'downloads.queued' => '佇列中',
      'downloads.running' => '正在下載',
      'downloads.paused' => '已暫停',
      'downloads.downloaded' => '已下載',
      'downloads.cancelled' => '已取消',
      'downloads.savePending' => '等待儲存',
      'downloads.saving' => '正在儲存',
      'downloads.saveFailed' => '儲存失敗',
      'downloads.retrySave' => '重試儲存',
      'downloads.cancel' => '取消',
      'downloads.deleteTask' => '刪除任務',
      'downloads.sync' => '同步',
      'downloads.syncFailed' => '下載狀態同步失敗',
      'downloads.actionFailed' => '下載操作失敗',
      'downloads.expand' => '展開',
      'downloads.collapse' => '收合',
      'downloads.messages.storagePermanentlyDenied' => '您已永久拒絕存儲權限。\n請在設定中手動啟用存儲權限。',
      'downloads.messages.storageDenied' => '您已拒絕存儲權限。',
      'downloads.messages.deviceInfoError' => '無法解析設備資訊。',
      'downloads.messages.photosPermanentlyDenied' => '您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。',
      'downloads.messages.photosDenied' => '您已拒絕照片權限。',
      'downloads.messages.downloadTaskExists' => '下載任務已經存在。',
      'downloads.messages.imageFileExists' => '圖片檔案已經存在。',
      'downloads.messages.downloadRetryWith' => ({required Object name}) => '重試下載任務: ${name}',
      'downloads.messages.downloadStartWith' => ({required Object name}) => '開始下載任務: ${name}',
      'downloads.messages.downloadCompletedWith' => ({required Object name}) => '下載任務完成: ${name}',
      'downloads.messages.downloadFailedWith' => ({required Object name}) => '下載任務失敗: ${name}',
      'downloads.messages.saveFailedWith' => ({required Object name}) => '儲存失敗: 任務 ${name}',
      'about.title' => '關於',
      'about.projectUrl' => '專案網址',
      'about.publishPage' => '發佈頁面',
      'about.appVersion' => '應用程式版本',
      'about.freepivPromotionTitle' => '試試 freepiv',
      'about.freepivPromotionSubtitle' => '現代、流暢的跨平台 Pixiv 第三方用戶端。',
      'about.discussion' => '討論',
      'about.downloadUpdate' => '下載更新',
      'about.downloadUpdateHint' => '透過瀏覽器下載適合您裝置的最新版本。',
      'settings.title' => '設定',
      'settings.theme' => '主題',
      'settings.language' => '語言',
      'settings.bypassSni' => '略過 SNI',
      'settings.downloadDirectory' => '下載目錄',
      'settings.defaultToPlatformSettings' => '使用系統預設',
      'settings.columnsPerRow' => '每行列數',
      'settings.maxConcurrentDownloads' => '最大同時下載任務數',
      'settings.maxSegmentsPerTask' => '每個下載任務的最大分段數',
      'settings.platformDefault' => '平台預設',
      'settings.system' => '系統',
      'settings.light' => '淺色模式',
      'settings.dark' => '深色模式',
      'settings.auto' => '自動',
      'settings.downloadsOverview' => '儲存位置與同時下載數',
      'settings.sections.sourcesAndAccounts' => '圖源與帳號',
      'settings.sections.accounts' => '帳號',
      'settings.sections.network' => '網路',
      'settings.sections.general' => '一般',
      'settings.sections.downloads' => '下載',
      'settings.source.defaultSource' => '預設圖源',
      'settings.source.supportedRatings' => '支援的分級',
      'settings.source.safetyRating' => '全域內容分級',
      'settings.account.manageAllSubtitle' => '圖源分級與帳號設定',
      'settings.account.noAccountRequired' => '此圖源無需設定帳號',
      'settings.account.openSignInPage' => '開啟登入頁面',
      'settings.account.cookieHeader' => 'Cookie 標頭',
      'settings.account.storedLocally' => '僅儲存在此裝置',
      'settings.account.browserUserAgent' => '瀏覽器 User-Agent',
      'settings.account.browserUserAgentHint' => '使用與已登入瀏覽器相同的 User-Agent',
      'settings.account.required' => '必填',
      'settings.account.optional' => '選填',
      'settings.account.actions' => '帳號操作',
      'settings.account.save' => '儲存',
      'settings.account.verify' => '驗證',
      'settings.account.signOut' => '登出',
      'settings.account.saved' => '帳號已儲存',
      'settings.account.saveFailed' => '無法儲存帳號',
      'settings.account.verified' => '帳號已驗證',
      'settings.account.verificationFailed' => '驗證失敗',
      'settings.account.username' => '使用者名稱',
      'settings.account.userId' => '使用者 ID',
      'settings.account.apiKey' => 'API 金鑰',
      'settings.account.statusValue' => ({required Object status}) => '狀態 · ${status}',
      'settings.account.statuses.notConfigured' => '尚未設定',
      'settings.account.statuses.configuredUnverified' => '已設定，尚未驗證',
      'settings.account.statuses.verified' => '已驗證',
      'settings.account.statuses.rejected' => '已被拒絕',
      'settings.network.dnsProvider' => 'DNS 服務',
      'settings.network.servicesTitle' => '全部圖源狀態',
      'settings.network.servicesHint' => 'IP 解析與 API 可用性分別檢測；API 可用不代表所有圖片均可下載。',
      'settings.network.noFallback' => '僅使用所選 DNS，失敗直接報錯；不會改用系統 DNS 或自動切換服務。',
      'settings.network.checkProgress' =>
        ({required Object done, required Object total, required Object checked, required Object sources}) =>
            'DNS 已完成 ${done}/${total} · API 已檢測 ${checked}/${sources}',
      'settings.network.checkSummary' =>
        ({required Object available, required Object total, required Object failed}) =>
            'API 可用 ${available}/${total} · DNS 失敗 ${failed} 項',
      'settings.network.loadingStatus' => '正在讀取快取狀態…',
      'settings.network.apiChecking' => 'API：檢測中…',
      'settings.network.apiAvailable' => 'API：可用',
      'settings.network.apiFailed' => 'API：無法使用',
      'settings.network.apiUnchecked' => 'API：尚未檢測',
      'settings.network.dnsPending' => '尚未解析 · 點選重新整理路由取得 IP',
      'settings.network.dnsResolving' => '正在解析…',
      'settings.network.dnsResolved' => '解析成功',
      'settings.network.dnsCached' => '使用已快取 IP · 尚未重新檢測',
      'settings.network.dnsFailed' => '解析失敗 · 目前無可用路由',
      'settings.network.dnsQueued' => '等待解析…',
      'settings.network.ipCachedAt' => ({required Object time}) => 'IP 已快取 · 更新於 ${time}',
      'settings.network.ipNotCached' => 'IP 已解析 · 尚未寫入快取',
      'settings.network.connectionMode' => '連線模式',
      'settings.network.proxyUrl' => 'Proxy URL',
      'settings.network.proxyHint' => '選填 · 例如 http://127.0.0.1:7890',
      'settings.network.applyAndRouteCache' => '套用與路由快取',
      'settings.network.apply' => '套用網路設定',
      'settings.network.refreshRoutes' => '重新整理路由',
      'settings.network.routeCacheUnavailable' => '無法取得路由快取',
      'settings.network.routeCacheStatus' =>
        ({required Object hosts, required Object revision}) => '${hosts} 個主機 · 修訂 ${revision}',
      'settings.network.applied' => '網路設定已套用',
      'settings.network.invalidSettings' => '網路設定無效',
      'settings.network.routeRefreshFailed' => '路由重新整理失敗',
      'settings.network.systemDns' => '系統 DNS',
      'settings.network.sniBypass' => '略過 SNI',
      'settings.network.legacyIpUrl' => '舊版 IP URL',
      'settings.languageDialog.title' => '語言',
      'settings.themeModeDialog.title' => '主題模式',
      'settings.downloadDirectoryDialog.title' => '下載目錄',
      'settings.downloadDirectoryDialog.pickerTitle' => '選擇目錄',
      'settings.downloadDirectoryDialog.pick' => '選擇目錄',
      'settings.downloadDirectoryDialog.messages.setToPlatformDefault' => '下載目錄已設為系統預設。',
      'settings.downloadDirectoryDialog.messages.pathNotAbsolute' => '路徑必須是絕對路徑。',
      'settings.downloadDirectoryDialog.messages.pathNotWritable' => '路徑不可寫入。',
      'settings.bypassSniDialog.title' => '略過 SNI',
      'settings.columnsPerRowDialog.title' => '每行列數',
      'settings.maxConcurrentDownloadsDialog.title' => '最大同時下載任務數',
      'settings.maxSegmentsPerTaskDialog.title' => '每個下載任務的最大分段數',
      'discovery.searchResults' => '搜尋結果',
      'discovery.allAvailable' => '全部可用內容',
      'discovery.defaultRatingsHint' => '分級偏好適用於所有圖源。未選擇分級時，顯示目前圖源和帳號能存取的所有內容。',
      'discovery.resetFilters' => '恢復預設',
      'discovery.unsupportedRatings' => '目前圖源不支援所選分級，請恢復預設以瀏覽可用內容。',
      'discovery.noFilteredPosts' => '沒有符合目前篩選條件的內容。',
      'discovery.noSearchResults' => '沒有找到符合此查詢的內容。',
      'discovery.noFeedPosts' => '目前圖源暫時沒有可展示的內容。',
      'discovery.historicalPopular' => '歷史熱門',
      'discovery.calendarDay' => '自然日',
      'discovery.calendarWeek' => '自然週',
      'discovery.calendarMonth' => '自然月',
      'discovery.latest' => '最新',
      'discovery.popular' => '熱門',
      'discovery.today' => '今日',
      'discovery.thisWeek' => '本週',
      'discovery.thisMonth' => '本月',
      'discovery.lastDay' => '最近 24 小時',
      'discovery.lastThreeDays' => '最近 3 天',
      'discovery.lastWeek' => '最近一週',
      'discovery.lastMonth' => '最近一個月',
      'discovery.lastThreeMonths' => '最近三個月',
      'discovery.lastSixMonths' => '最近六個月',
      'discovery.lastYear' => '最近一年',
      'discovery.rankingComplete' => '榜單已全部載入',
      'discovery.latestFallback' => '此圖源僅支援最新貼文。',
      'discovery.filters' => '篩選',
      'discovery.loadMore' => '載入更多',
      'discovery.filteredContinue' => '目前幾頁沒有符合篩選的貼文，繼續瀏覽',
      'discovery.commonTags' => '常用標籤',
      'discovery.moreTags' => '查看更多',
      'discovery.tagSource' => '適用圖源',
      'discovery.allTagSources' => '通用',
      'discovery.manageTags' => '標籤管理',
      'discovery.addTag' => '新增標籤',
      'discovery.noCustomTags' => '還沒有自訂標籤',
      'discovery.customTagsHint' => '為常用標籤設定好記的名稱，搜尋時更容易找到。',
      'discovery.addCustomTag' => '新增為自訂標籤',
      'discovery.editTag' => '編輯自訂標籤',
      'discovery.canonicalTag' => '圖源標籤',
      'discovery.displayName' => '顯示名稱（選填）',
      'discovery.invalidTag' => '請輸入一個非空且不含空格的標籤。',
      'discovery.queryHint' => '輸入標籤或圖源查詢語句…',
      'discovery.unverifiedTag' => '部分標籤尚未在目前圖源驗證，仍可提交搜尋。',
      'discovery.verifiedTag' => '已在目前圖源驗證',
      'discovery.noSuggestions' => '沒有建議',
      'discovery.localFallback' => '線上補全暫時無法使用，仍可使用本機建議。',
      'discovery.retryTags' => '重試常用標籤',
      'discovery.artist' => '繪師',
      'discovery.character' => '角色',
      'discovery.copyright' => '作品',
      'discovery.meta' => '中繼標籤',
      'discovery.general' => '一般',
      'discovery.random' => '隨機',
      'discovery.lifetimeViews' => '累計瀏覽量',
      'discovery.lifetimeFavorites' => '累計收藏數',
      'mediaError.title' => '圖片載入失敗',
      'mediaError.details' => '錯誤詳情',
      'mediaError.copyDetails' => '複製詳情',
      'mediaError.decodeFailed' => '下載的圖片無法解碼。重試會清除這張圖片的快取並重新下載。',
      _ => null,
    };
  }
}
