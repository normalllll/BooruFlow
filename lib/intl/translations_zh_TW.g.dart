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
class TranslationsZhTw extends Translations
    with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsZhTw({
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
             locale: AppLocale.zhTw,
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

  /// Metadata for the translations of <zh-TW>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key) ?? super[key];

  late final TranslationsZhTw _root = this; // ignore: unused_field

  @override
  TranslationsZhTw $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => TranslationsZhTw(meta: meta ?? this.$meta);

  // Translations
  @override
  late final Translations$generic$zh_TW generic =
      Translations$generic$zh_TW.internal(_root);
  @override
  late final Translations$booruError$zh_TW booruError =
      Translations$booruError$zh_TW.internal(_root);
  @override
  late final Translations$update$zh_TW update =
      Translations$update$zh_TW.internal(_root);
  @override
  late final Translations$postList$zh_TW postList =
      Translations$postList$zh_TW.internal(_root);
  @override
  late final Translations$postDetail$zh_TW postDetail =
      Translations$postDetail$zh_TW.internal(_root);
  @override
  late final Translations$postSearch$zh_TW postSearch =
      Translations$postSearch$zh_TW.internal(_root);
  @override
  late final Translations$imageZoom$zh_TW imageZoom =
      Translations$imageZoom$zh_TW.internal(_root);
  @override
  late final Translations$downloads$zh_TW downloads =
      Translations$downloads$zh_TW.internal(_root);
  @override
  late final Translations$about$zh_TW about = Translations$about$zh_TW.internal(
    _root,
  );
  @override
  late final Translations$settings$zh_TW settings =
      Translations$settings$zh_TW.internal(_root);
  @override
  late final Translations$discovery$zh_TW discovery =
      Translations$discovery$zh_TW.internal(_root);
  @override
  late final Translations$mediaError$zh_TW mediaError =
      Translations$mediaError$zh_TW.internal(_root);
  @override
  late final Translations$webChallenge$zh_TW webChallenge =
      Translations$webChallenge$zh_TW.internal(_root);
  @override
  late final Translations$nativeWindow$zh_TW nativeWindow =
      Translations$nativeWindow$zh_TW.internal(_root);
  @override
  late final Translations$batchDownload$zh_TW batchDownload =
      Translations$batchDownload$zh_TW.internal(_root);
  @override
  late final Translations$frost$zh_TW frost = Translations$frost$zh_TW.internal(
    _root,
  );
  @override
  late final Translations$navigation$zh_TW navigation =
      Translations$navigation$zh_TW.internal(_root);
  @override
  late final Translations$settingsV2$zh_TW settingsV2 =
      Translations$settingsV2$zh_TW.internal(_root);
  @override
  late final Translations$settingsDetails$zh_TW settingsDetails =
      Translations$settingsDetails$zh_TW.internal(_root);
  @override
  late final Translations$verificationPage$zh_TW verificationPage =
      Translations$verificationPage$zh_TW.internal(_root);
  @override
  late final Translations$ugoira$zh_TW ugoira =
      Translations$ugoira$zh_TW.internal(_root);
}

// Path: generic
class Translations$generic$zh_TW extends Translations$generic$en {
  Translations$generic$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

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
  String copiedWithValue({required Object value}) => '已複製到剪貼簿： ${value}';
  @override
  String errorWithValue({required Object value}) => '發生錯誤： ${value}';
  @override
  String get loading => '載入中';
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
  Translations$booruError$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

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
  String get rateLimited => '圖源暫時限制了請求，稍後會自動恢復。';
  @override
  String get challengeRequired => '圖源要求瀏覽器驗證。可嘗試在瀏覽器中開啟圖源完成驗證，或選擇其他圖源。';
  @override
  String get routeUnavailable => '目前網域沒有可用路由。請在網路設定中重新整理路由；不會改用系統 DNS。';
  @override
  String get sourceUnavailable => '目前圖源暫時無法使用。';
  @override
  String get network => '網路請求失敗。請檢查網路連線後重試。';
  @override
  String get timeout => '請求逾時。請檢查網路連線，或稍後重試。';
  @override
  String get invalidResponse => '圖源回傳了無法解析的回應。';
  @override
  String get unsafeRedirect => '圖源回傳了不安全的重新導向。';
  @override
  String get mediaValidationFailed => '媒體回應驗證或解碼失敗。';
  @override
  String get cancelled => '請求已取消。';
  @override
  String get internal => '圖源引擎發生內部錯誤。';
}

// Path: update
class Translations$update$zh_TW extends Translations$update$en {
  Translations$update$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get checkUpdateStart => '正在檢查更新';
  @override
  String get checkUpdateFailed => '檢查更新失敗，請檢查您的網路連線。';
  @override
  String get selectDownloadUrlFailed => '找不到下載連結。請前往專案頁面手動更新，或到 Issue 頁面尋求協助。';
  @override
  String newVersionFound({required Object version}) =>
      '有新版本 ${version}。請前往「關於」下載更新。';
  @override
  String get noNewVersionFound => '沒有新版本。';
}

// Path: postList
class Translations$postList$zh_TW extends Translations$postList$en {
  Translations$postList$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get short => '首頁';
  @override
  String get title => '首頁';
  @override
  String titleWithTags({required Object tags}) => '含有標籤的作品：${tags}';
}

// Path: postDetail
class Translations$postDetail$zh_TW extends Translations$postDetail$en {
  Translations$postDetail$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get fullscreen => '全螢幕檢視';
  @override
  String get notFound => '找不到這個作品';
  @override
  String parentCount({required Object count}) => '${count} 個父作品';
  @override
  String childCount({required Object count}) => '${count} 個子作品';
  @override
  String get zoomIn => '放大';
  @override
  String get zoomOut => '縮小';
  @override
  String get originalFailed => '原圖載入失敗';
  @override
  String get previewShown => '目前顯示的是預覽圖。';
  @override
  String uploadedAt({required Object date}) => '${date} 上傳';
  @override
  String get pixels => '像素';
  @override
  String get dimensions => '尺寸';
  @override
  String get searchTag => '搜尋此標籤';
  @override
  String get addToSearch => '加入搜尋';
  @override
  String get excludeTag => '排除此標籤';
  @override
  String get openSource => '開啟來源';
  @override
  String get resetZoom => '重設縮放';
  @override
  String get ratingGeneral => '一般';
  @override
  String get ratingSensitive => '敏感';
  @override
  String get ratingQuestionable => '存疑';
  @override
  String get ratingExplicit => '成人';
  @override
  String get ratingUnknown => '未知';
  @override
  String titleWithId({required Object id}) => '作品：${id}';
  @override
  String get tags => '標籤';
  @override
  String get details => '詳細資訊';
  @override
  String get actions => '操作';
  @override
  String get rating => '分級';
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
  String get parent => '父作品 ID';
  @override
  String get hasChildren => '有子作品';
  @override
  String get similarPosts => '相關圖片';
  @override
  String get parentPost => '父作品';
  @override
  String get childPost => '子作品';
}

// Path: postSearch
class Translations$postSearch$zh_TW extends Translations$postSearch$en {
  Translations$postSearch$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '搜尋';
}

// Path: imageZoom
class Translations$imageZoom$zh_TW extends Translations$imageZoom$en {
  Translations$imageZoom$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '縮放圖片';
}

// Path: downloads
class Translations$downloads$zh_TW extends Translations$downloads$en {
  Translations$downloads$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get fileMissing => '檔案已不在原來的位置';
  @override
  String get locationMissing => '找不到檔案或資料夾';
  @override
  String get redownload => '重新下載';
  @override
  String get remove => '刪除';
  @override
  String activeTasks({required Object count}) => '正在下載 ${count} 項';
  @override
  String failedTasks({required Object count}) => '${count} 項下載失敗';
  @override
  String get retryAll => '全部重試';
  @override
  String get today => '今天';
  @override
  String get yesterday => '昨天';
  @override
  String transferRate({required Object value}) => '${value}/s';
  @override
  String remainingSeconds({required Object count}) => '約 ${count} 秒';
  @override
  String remainingMinutes({required Object count}) => '約 ${count} 分鐘';
  @override
  String remainingHours({required Object count}) => '約 ${count} 小時';
  @override
  String get format => '格式';
  @override
  String get startedAt => '開始時間';
  @override
  String get browse => '瀏覽';
  @override
  String get all => '全部';
  @override
  String get pause => '暫停';
  @override
  String get resume => '繼續';
  @override
  String get pauseAll => '全部暫停';
  @override
  String get resumeAll => '全部繼續';
  @override
  String get retryFailed => '重試失敗項目';
  @override
  String get clearCompleted => '清除已完成';
  @override
  String get openDirectory => '開啟下載資料夾';
  @override
  String get openPost => '開啟作品';
  @override
  String get batch => '批次下載';
  @override
  String batchProgress({required Object completed, required Object total}) =>
      '${completed} / ${total}';
  @override
  String get path => '儲存路徑';
  @override
  String get taskDetails => '任務詳細資料';
  @override
  String get viewLog => '記錄';
  @override
  String get title => '下載';
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
  late final Translations$downloads$messages$zh_TW messages =
      Translations$downloads$messages$zh_TW.internal(_root);
}

// Path: about
class Translations$about$zh_TW extends Translations$about$en {
  Translations$about$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

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
  String get freepivPromotionSubtitle => '流暢的跨平台 Pixiv 瀏覽工具。';
  @override
  String get discussion => '討論';
  @override
  String get downloadUpdate => '下載更新';
  @override
  String get downloadUpdateHint => '透過瀏覽器下載適合您裝置的最新版本。';
}

// Path: settings
class Translations$settings$zh_TW extends Translations$settings$en {
  Translations$settings$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

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
  String get downloadDirectory => '下載資料夾';
  @override
  String get defaultToPlatformSettings => '使用系統預設';
  @override
  String get columnsPerRow => '每列圖片數';
  @override
  String get maxConcurrentDownloads => '同時下載';
  @override
  String get maxSegmentsPerTask => '每個任務的分段數';
  @override
  String get platformDefault => '系統預設';
  @override
  String get system => '跟隨系統';
  @override
  String get light => '淺色';
  @override
  String get dark => '深色';
  @override
  String get auto => '自動';
  @override
  String get downloadsOverview => '儲存位置與同時下載數';
  @override
  late final Translations$settings$sections$zh_TW sections =
      Translations$settings$sections$zh_TW.internal(_root);
  @override
  late final Translations$settings$source$zh_TW source =
      Translations$settings$source$zh_TW.internal(_root);
  @override
  late final Translations$settings$account$zh_TW account =
      Translations$settings$account$zh_TW.internal(_root);
  @override
  late final Translations$settings$network$zh_TW network =
      Translations$settings$network$zh_TW.internal(_root);
  @override
  late final Translations$settings$languageDialog$zh_TW languageDialog =
      Translations$settings$languageDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$themeModeDialog$zh_TW themeModeDialog =
      Translations$settings$themeModeDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$downloadDirectoryDialog$zh_TW
  downloadDirectoryDialog =
      Translations$settings$downloadDirectoryDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$bypassSniDialog$zh_TW bypassSniDialog =
      Translations$settings$bypassSniDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$columnsPerRowDialog$zh_TW
  columnsPerRowDialog =
      Translations$settings$columnsPerRowDialog$zh_TW.internal(_root);
  @override
  late final Translations$settings$maxSegmentsPerTaskDialog$zh_TW
  maxSegmentsPerTaskDialog =
      Translations$settings$maxSegmentsPerTaskDialog$zh_TW.internal(_root);
}

// Path: discovery
class Translations$discovery$zh_TW extends Translations$discovery$en {
  Translations$discovery$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get mode => '模式';
  @override
  String get timeRange => '時間範圍';
  @override
  String get chooseDate => '指定日期';
  @override
  String get menuWeek => '本週';
  @override
  String get menuMonth => '本月';
  @override
  String get ratingsTitle => '內容分級';
  @override
  String get ratingLabel => '分級';
  @override
  String get ratingSeparator => '、';
  @override
  String get calendarRanges => '日曆週期';
  @override
  String get rollingRanges => '最近期間';
  @override
  String get tooManyRequests => '請求過於頻繁';
  @override
  String get copyLink => '複製連結';
  @override
  String get copyQueryLink => '複製查詢連結';
  @override
  String get copyImage => '複製圖片';
  @override
  String get searchAuthor => '搜尋此繪師';
  @override
  String get mediaAnimation => '動圖';
  @override
  String get mediaVideo => '影片';
  @override
  String get mediaCollection => '相關圖片';
  @override
  String retryIn({required Object seconds}) => '${seconds} 秒後重試';
  @override
  String get searchResults => '搜尋結果';
  @override
  String searchTermsTitle({required Object count}) => '搜尋 ${count} 個關鍵字';
  @override
  String get allAvailable => '全部可用內容';
  @override
  String get defaultRatingsHint => '未選擇時顯示目前圖源能存取的全部內容。';
  @override
  String get resetFilters => '還原預設';
  @override
  String get unsupportedRatings => '目前圖源不支援所選分級。';
  @override
  String get noFilteredPosts => '沒有符合篩選的內容';
  @override
  String get noSearchResults => '沒有找到符合此查詢的內容。';
  @override
  String get noFeedPosts => '目前圖源暫時沒有可展示的內容。';
  @override
  String get historicalPopular => '歷史熱門';
  @override
  String get calendarDay => '每日';
  @override
  String get calendarWeek => '每週';
  @override
  String get calendarMonth => '每月';
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
  String get clearHistory => '清空';
  @override
  String get recentSearches => '最近搜尋';
  @override
  String get noRecentSearches => '尚無最近搜尋';
  @override
  String get myTags => '我的標籤';
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
  String get manageTagsAction => '管理';
  @override
  String get addTagAction => '新增';
  @override
  String get deleteTag => '刪除';
  @override
  String get addTag => '新增標籤';
  @override
  String get noCustomTags => '還沒有自訂標籤';
  @override
  String get customTagsHint => '給常用標籤取個好記的名字，搜尋時更容易找到。';
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
  String get queryHint => '搜尋標籤';
  @override
  String get unverifiedTag => '部分標籤尚未在目前圖源驗證，仍可提交搜尋。';
  @override
  String get verifiedTag => '已在目前圖源驗證';
  @override
  String get noSuggestions => '沒有建議';
  @override
  String get localFallback => '暫時無法取得線上建議，仍可使用本機建議。';
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
  Translations$mediaError$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get videoProxyBypassed => '影片不支援目前的 SOCKS 代理，本次播放使用直接連線。';
  @override
  String get videoFailed => '影片播放失敗';
  @override
  String get downloadOriginal => '下載原檔案';
  @override
  String get previewUnsupported => '無法預覽';
  @override
  String get title => '圖片載入失敗';
  @override
  String get details => '錯誤詳細資料';
  @override
  String get copyDetails => '複製詳細資料';
  @override
  String get decodeFailed => '下載的圖片無法解碼。重試會清除這張圖片的快取並重新下載。';
}

// Path: webChallenge
class Translations$webChallenge$zh_TW extends Translations$webChallenge$en {
  Translations$webChallenge$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '網頁驗證';
  @override
  String get open => '開啟網頁驗證';
  @override
  String windowTitle({required Object source}) => '${source} · 完成驗證後關閉視窗';
  @override
  String get instructions => '請手動完成網頁中的人機驗證，完成後返回或關閉視窗。應用程式會儲存驗證資料並重新載入圖源。';
  @override
  String get finish => '完成驗證並返回';
  @override
  String get saving => '正在讀取並驗證網頁工作階段';
  @override
  String get waiting => '正在進行網頁驗證';
  @override
  String get clear => '清空';
  @override
  String get clearAll => '清空所有網頁驗證資料';
  @override
  String get clearDescription => '清除 Cookie、瀏覽器識別資訊和網頁快取。';
  @override
  String get cleared => '網頁驗證資料已清空';
  @override
  String get verified => '已驗證，可以存取';
  @override
  String get saved => '已儲存，等待重新驗證';
  @override
  String get empty => '沒有已儲存的驗證資料';
  @override
  String get failed => '網頁驗證未完成，請重試。';
  @override
  String get pageLoadFailed => '網頁載入失敗，請重新開啟驗證視窗或檢查網路設定。';
  @override
  String get webViewUnavailable => '此平台無法使用網頁元件。';
  @override
  String get windowFailed => '無法開啟網頁驗證。';
  @override
  String get runtimeMissing => '找不到 Microsoft Edge WebView2 Runtime，請安裝或更新後再試。';
  @override
  String get proxyUnsupported => '網頁元件尚不支援目前的代理設定，請變更代理設定後重試。';
  @override
  String get busy => '另一個網頁驗證或清理操作正在進行。';
  @override
  String get cancelled => '已取消網頁驗證。';
  @override
  String get timedOut => '網頁驗證逾時，請重新開啟網頁。';
  @override
  String get storageFailed => '無法儲存或清空驗證資料，原本的工作階段仍被保留。';
  @override
  String get captureFailed => '無法讀取網頁工作階段，請重新開啟網頁驗證。';
  @override
  String get cleanupFailed => '網頁資料尚未清理完成，請稍後再次清空。';
  @override
  String get operationSuperseded => '驗證已因清空資料或變更網路設定而取消。';
  @override
  String get noCookies => '網頁尚未提供可用的驗證資料，請完成人機驗證後再返回。';
}

// Path: nativeWindow
class Translations$nativeWindow$zh_TW extends Translations$nativeWindow$en {
  Translations$nativeWindow$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get minimize => '最小化';
  @override
  String get maximize => '最大化';
  @override
  String get restore => '還原';
  @override
  String get close => '關閉';
}

// Path: batchDownload
class Translations$batchDownload$zh_TW extends Translations$batchDownload$en {
  Translations$batchDownload$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '批次下載';
  @override
  String get close => '關閉';
  @override
  String get limitTitle => '這次最多取得幾張？';
  @override
  String get limitHint => '依目前搜尋條件逐頁取得，達到上限後停止。';
  @override
  String get limitLabel => '最多取得';
  @override
  String get positiveInteger => '請輸入大於 0 的整數。';
  @override
  String get start => '取得圖片';
  @override
  String fetchLimit({required Object count}) => '/ 最多 ${count} 張';
  @override
  String get fetching => '已找到的圖片';
  @override
  String progress({required Object current, required Object total}) =>
      '${current} / ${total}';
  @override
  String fetchProgress({required Object current, required Object limit}) =>
      '已取得 ${current} 張，最多 ${limit} 張';
  @override
  String get stopHint => '隨時可以停止，並使用已找到的圖片。';
  @override
  String get stop => '停止取得';
  @override
  String get found => '張圖片可以下載';
  @override
  String get limitReached => '已達到取得上限，可能還有更多搜尋結果。';
  @override
  String get exhausted => '已取得全部符合條件的結果。';
  @override
  String get permissionDenied => '無法取得下載權限，請在系統設定中檢查應用程式權限後重試。';
  @override
  String get enqueueFailed => '無法加入下載任務，請檢查儲存位置及剩餘空間後重試。';
  @override
  String get stopped => '已停止取得，可以下載已找到的圖片。';
  @override
  String get empty => '沒有找到符合條件的圖片。';
  @override
  String get stalled => '來源分頁未能繼續推進。已保留結果，可重試或使用已有圖片。';
  @override
  String get sessionChanged => '來源設定已改變。請關閉視窗後重新取得，或使用已找到的圖片。';
  @override
  String get fetchFailed => '取得未完成。已保留結果，可重試或使用已有圖片。';
  @override
  String get countLabel => '下載數量';
  @override
  String get all => '全部';
  @override
  String countRange({required Object max}) => '請輸入 1～${max}';
  @override
  String get orderHint => '按目前搜尋結果順序下載前 N 張圖片。';
  @override
  String get folderLabel => '資料夾名稱';
  @override
  String get folderHint => '例如：九月收藏';
  @override
  String get folderPlaceholder => '你的資料夾';
  @override
  String get invalidFolder => '請輸入 1～100 個字元，不含路徑分隔符號、保留名稱、前後空格或結尾句點。';
  @override
  String get folderHelp => '同名資料夾會直接沿用，已有檔案不會被覆寫。';
  @override
  String get locationFailed => '無法取得儲存位置。';
  @override
  String get photos => '照片圖庫';
  @override
  String get photosHint => 'iOS 將本次圖片儲存為來源資料夾下的相簿，沿用相簿需要照片圖庫完整存取權限。';
  @override
  String enqueue({required Object count}) => '加入下載佇列 · ${count} 張';
  @override
  String get enqueueing => '正在加入下載佇列';
  @override
  String preparing({required Object current, required Object total}) =>
      '正在準備 ${current} / ${total} 張圖片';
  @override
  String get added => '個任務已加入下載佇列';
  @override
  String get backgroundHint => '可以關閉視窗。應用程式執行期間會繼續加入佇列，再次按一下此入口可查看結果。';
  @override
  String get queueHint => '圖片下載進度可在下載清單中查看。';
  @override
  String failedHint({required Object count}) => '${count} 張未能加入佇列。';
  @override
  String get retryFailed => '重試失敗項目';
  @override
  String queued({required Object added, required Object failed}) =>
      '批次任務：已加入 ${added} 張，加入失敗 ${failed} 張。';
  @override
  String completed({required Object saved, required Object failed}) =>
      '批次下載結束：已儲存 ${saved} 張，失敗或取消 ${failed} 張。';
  @override
  String get done => '完成';
  @override
  String get back => '返回';
  @override
  String get first => '前 N 張';
  @override
  String addedCount({required Object count}) => '已加入 ${count} 張';
  @override
  String savedTo({required Object folder}) => '儲存至「${folder}」';
  @override
  String get viewDownloads => '查看下載';
}

// Path: frost
class Translations$frost$zh_TW extends Translations$frost$en {
  Translations$frost$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get retry => '重試';
  @override
  String get error => '錯誤';
  @override
  String get errorDetails => '錯誤詳細資料';
  @override
  String get copyDetails => '複製詳細資料';
  @override
  String get copied => '已複製';
  @override
  String get loading => '載入中';
  @override
  String get actionSucceeded => '操作成功';
  @override
  String get actionFailed => '操作失敗';
  @override
  String get loadFailed => '載入失敗';
  @override
  String get noItems => '尚無內容';
  @override
  String get noMoreItems => '沒有更多內容';
  @override
  String get pullToRefresh => '下拉重新整理';
  @override
  String get releaseToRefresh => '放開以重新整理';
  @override
  String get refreshing => '重新整理中';
  @override
  String get refreshComplete => '重新整理完成';
  @override
  String get refreshFailed => '重新整理失敗';
  @override
  String get previous => '上一個';
  @override
  String get next => '下一個';
  @override
  String get back => '返回';
  @override
  String get more => '更多';
  @override
  String get expandNavigation => '展開側欄';
  @override
  String get collapseNavigation => '收合側欄';
  @override
  String get clearText => '清除文字';
  @override
  String get search => '搜尋';
  @override
  String noResults({required Object query}) => '找不到「${query}」的結果';
  @override
  String get clearSearch => '清除搜尋';
  @override
  String get dismiss => '關閉';
  @override
  String get expandText => '展開';
  @override
  String get collapseText => '收合';
  @override
  String get showAll => '顯示全部';
  @override
  String get copy => '複製';
  @override
  String get clearAll => '全部清除';
  @override
  String get showPassword => '顯示密碼';
  @override
  String get hidePassword => '隱藏密碼';
  @override
  String get chooseDate => '選擇日期';
  @override
  String get chooseTime => '選擇時間';
  @override
  String get increment => '增加';
  @override
  String get decrement => '減少';
  @override
  String get reorderHandle => '調整順序';
  @override
  String get sortAscending => '遞增';
  @override
  String get sortDescending => '遞減';
  @override
  String get play => '播放';
  @override
  String get pause => '暫停';
  @override
  String get loop => '重複播放';
  @override
  String get mute => '靜音';
  @override
  String get unmute => '取消靜音';
  @override
  String get fullscreen => '全螢幕';
  @override
  String get exitFullscreen => '結束全螢幕';
  @override
  String get reload => '重新載入';
  @override
  String get openInBrowser => '在瀏覽器中開啟';
  @override
  String get minimize => '最小化';
  @override
  String get maximize => '最大化';
  @override
  String get restore => '還原';
  @override
  String get close => '關閉';
  @override
  String get cancel => '取消';
  @override
  String get apply => '套用';
  @override
  String get clear => '清除';
  @override
  String get choose => '選擇';
  @override
  String get showInFolder => '在資料夾中顯示';
  @override
  String selectedCount({required Object count}) => '已選取 ${count} 項';
  @override
  String pageOf({required Object page, required Object total}) =>
      '第 ${page} 頁，共 ${total} 頁';
  @override
  String get selectAll => '全選';
  @override
  String get done => '完成';
  @override
  String itemPosition({required Object position, required Object total}) =>
      '第 ${position} 項，共 ${total} 項';
  @override
  String tableDimensions({required Object rows, required Object columns}) =>
      '${rows} 列，${columns} 欄';
  @override
  String get taskQueued => '等待中';
  @override
  String get taskRunning => '下載中';
  @override
  String get taskPaused => '已暫停';
  @override
  String get taskCompleted => '已完成';
  @override
  String get taskFailed => '失敗';
  @override
  String get taskCancelled => '已取消';
  @override
  String get remove => '移除';
  @override
  String get forward => '前進';
  @override
  String get stop => '停止';
  @override
  String get seek => '播放位置';
  @override
  String get send => '傳送';
  @override
  String get attach => '加入附件';
  @override
  String get readerSettings => '閱讀設定';
  @override
  String get textSize => '文字大小';
  @override
  String get lineSpacing => '行距';
  @override
  String get readingProgress => '閱讀進度';
  @override
  String showReplies({required Object count}) => '顯示 ${count} 則回覆';
  @override
  String characterCount({required Object count, required Object limit}) =>
      '${count} / ${limit} 字';
  @override
  String moreMedia({required Object count}) => '還有 ${count} 張圖片';
  @override
  String navigationCount({required Object count}) => '${count} 項';
  @override
  String navigationProgress({required Object progress}) => '已完成 ${progress}%';
  @override
  String get listSeparator => '，';
}

// Path: navigation
class Translations$navigation$zh_TW extends Translations$navigation$en {
  Translations$navigation$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get browse => '瀏覽';
  @override
  String get search => '搜尋';
  @override
  String get downloads => '下載';
  @override
  String get settings => '設定';
  @override
  String get browseEmpty => '瀏覽喜愛的圖源';
  @override
  String get searchEmpty => '用標籤尋找作品';
  @override
  String get downloadsEmpty => '下載項目會顯示在這裡';
  @override
  String get settingsEmpty => '依照喜好設定 BooruFlow';
}

// Path: settingsV2
class Translations$settingsV2$zh_TW extends Translations$settingsV2$en {
  Translations$settingsV2$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get predictiveBack => '預測返回';
  @override
  String get predictiveBackScope => '預覽 App 內的返回動作；返回主畫面的動畫由系統控制。';
  @override
  String get background => '背景材質';
  @override
  String get ambientBlur => '環境模糊';
  @override
  String get mica => '雲母';
  @override
  String get backgroundOff => '關閉';
  @override
  String get backgroundIntensity => '強度';
  @override
  String get systemTransparencyReduced => '系統已降低透明度';
  @override
  String get customColour => '自訂顏色';
  @override
  String get appearance => '外觀';
  @override
  String get browsing => '瀏覽';
  @override
  String get tone => '色調';
  @override
  String get neutral => '中性';
  @override
  String get cool => '冷色';
  @override
  String get warm => '暖色';
  @override
  String get accent => '強調色';
  @override
  String get customAccent => '自訂強調色';
  @override
  String get customHex => '強調色 HEX';
  @override
  String get invalidHex => '請輸入六位 HEX 顏色。';
  @override
  String get accentRejected => '此強調色在目前表面上無法保持可讀。';
  @override
  String get accentWarning => '此強調色對比度較低，仍要套用嗎？';
  @override
  String get editAccount => '編輯帳號';
  @override
  String get signOutConfirm => '移除此圖源已儲存的帳號憑證？';
  @override
  String get licenses => '開放原始碼授權';
  @override
  String get checkUpdates => '檢查更新';
  @override
  String get help => '說明';
}

// Path: settingsDetails
class Translations$settingsDetails$zh_TW
    extends Translations$settingsDetails$en {
  Translations$settingsDetails$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get mode => '模式';
  @override
  String get custom => '自訂';
  @override
  String get change => '更改';
  @override
  String get routeCache => '路由快取';
  @override
  String hostCount({required Object count}) => '${count} 個主機';
  @override
  String updatedAt({required Object time}) => '更新於 ${time}';
  @override
  String get sourceStatus => '圖源狀態';
  @override
  String get apiAndImages => 'API 與圖片可用';
  @override
  String get apiOnly => 'API 可用 · 圖片未通過';
  @override
  String get status => '狀態';
  @override
  String get content => '內容';
  @override
  String editSourceAccount({required Object source}) => '編輯 ${source} 帳號';
  @override
  String get proxyApplies => '套用後用於圖源、圖片和新的下載。';
  @override
  String version({required Object version, required Object build}) =>
      '版本 ${version} (${build})';
  @override
  String get communityTelegram => 'Telegram 群組';
  @override
  String get communityDiscord => 'Discord 伺服器';
  @override
  String get savedVerifications => '已儲存的驗證';
  @override
  String get systemDnsShort => '系統 DNS';
  @override
  String get refresh => '重新整理';
  @override
  String updateAvailable({required Object version}) => '有新版本 ${version}';
}

// Path: verificationPage
class Translations$verificationPage$zh_TW
    extends Translations$verificationPage$en {
  Translations$verificationPage$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get instructions => '在下方頁面完成驗證，再按一下「完成驗證並返回」。';
  @override
  String get opening => '正在開啟網頁';
  @override
  String get failed => '網頁載入失敗';
  @override
  String get closed => '驗證視窗已關閉';
  @override
  String get failureHelp => '可以重新開啟，或檢查網路設定。';
  @override
  String get reopen => '重新開啟';
  @override
  String signOut({required Object source}) => '登出 ${source} 帳號？';
  @override
  String get signOutHelp => '帳號資訊將從此裝置移除。';
  @override
  String get downloadAdded => '已加入下載';
  @override
  String get downloadFailed => '下載失敗';
  @override
  String get linkCopied => '已複製連結';
  @override
  String get view => '查看';
  @override
  String get networkSettings => '網路設定';
}

// Path: ugoira
class Translations$ugoira$zh_TW extends Translations$ugoira$en {
  Translations$ugoira$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get iosFilesDestination => '其他格式儲存在「檔案」App › BooruFlow';
  @override
  String get iosFormatHelp => '動態 WebP 與 ZIP 儲存到「檔案」。';
  @override
  String get albumName => '相簿名稱';
  @override
  String get openSettings => '前往設定';
  @override
  String get androidDestination => '相簿與下載資料夾';
  @override
  String get iosDestination => '儲存到照片';
  @override
  String get format => '動態圖片儲存格式';
  @override
  String get losslessWebp => '無損動態 WebP';
  @override
  String get originalZip => '原始 ZIP';
  @override
  String get webpRecord => 'WebP · 動態圖片';
  @override
  String get zipRecord => 'ZIP · 原始影格';
  @override
  String get ugoiraInvalidArchive => '動畫壓縮檔無效。';
  @override
  String get ugoiraMetadataMissing => '動畫缺少影格時間資料。';
  @override
  String get ugoiraInvalidMetadata => '動畫影格時間資料無效。';
  @override
  String get ugoiraFrameMissing => '動畫中有影格遺失。';
  @override
  String get ugoiraFrameCorrupt => '動畫中有影格損壞。';
  @override
  String get ugoiraFrameSizeMismatch => '動畫的影格尺寸不一致。';
  @override
  String get ugoiraFrameTooLarge => '動畫影格超過大小限制。';
  @override
  String get ugoiraEncodeFailed => '動畫編碼失敗。';
  @override
  String get ugoiraOutputTooLarge => '動畫編碼結果超過大小限制。';
}

// Path: downloads.messages
class Translations$downloads$messages$zh_TW
    extends Translations$downloads$messages$en {
  Translations$downloads$messages$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get storagePermanentlyDenied => '您已永久拒絕儲存權限。\n請在設定中手動啟用儲存權限。';
  @override
  String get storageDenied => '您已拒絕儲存權限。';
  @override
  String get deviceInfoError => '無法解析裝置資訊。';
  @override
  String get photosPermanentlyDenied => '您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。';
  @override
  String get photosDenied => '您已拒絕照片權限。';
  @override
  String get downloadTaskExists => '下載任務已經存在。';
  @override
  String get imageFileExists => '圖片檔案已經存在。';
  @override
  String downloadRetryWith({required Object name}) => '重試下載任務： ${name}';
  @override
  String downloadStartWith({required Object name}) => '開始下載任務： ${name}';
  @override
  String downloadCompletedWith({required Object name}) => '下載任務完成： ${name}';
  @override
  String downloadFailedWith({required Object name}) => '下載任務失敗： ${name}';
  @override
  String saveFailedWith({required Object name}) => '儲存失敗： 任務 ${name}';
}

// Path: settings.sections
class Translations$settings$sections$zh_TW
    extends Translations$settings$sections$en {
  Translations$settings$sections$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

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
class Translations$settings$source$zh_TW
    extends Translations$settings$source$en {
  Translations$settings$source$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get defaultSource => '預設圖源';
  @override
  String get supportedRatings => '支援的分級';
  @override
  String get safetyRating => '內容分級';
}

// Path: settings.account
class Translations$settings$account$zh_TW
    extends Translations$settings$account$en {
  Translations$settings$account$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get manageAllSubtitle => '圖源分級與帳號設定';
  @override
  String get noAccountRequired => '不需帳號';
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
class Translations$settings$network$zh_TW
    extends Translations$settings$network$en {
  Translations$settings$network$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get proxyCompact => '自訂代理';
  @override
  String get checkCompact => '測試';
  @override
  String get detailsCompact => '詳細';
  @override
  String get advancedCompact => '進階';
  @override
  String get uncheckedCompact => '未測試';
  @override
  String get checkingCompact => '測試中';
  @override
  String get apiShort => 'API';
  @override
  String get imagesShort => '圖片';
  @override
  String get saveCompact => '儲存';
  @override
  String get proxyProtocol => '協定';
  @override
  String get proxyHost => '主機';
  @override
  String get proxyPort => '連接埠';
  @override
  String get proxyReachable => '可連線';
  @override
  String get proxyUnreachable => '無法連線';
  @override
  String get proxyProbe => '測試代理連線';
  @override
  String get proxyProbeHint => '使用目前填寫的代理測試各圖源，不會儲存設定。';
  @override
  String get sourceAvailable => '可用';
  @override
  String get sourcePartial => '部分可用';
  @override
  String get sourceUnavailable => '不可用';
  @override
  String get checkAllSources => '測試全部';
  @override
  String get mediaAvailable => '圖片：可用';
  @override
  String get mediaUnavailable => '圖片：未通過測試或無測試圖片';
  @override
  String get dnsDetails => 'DNS 路由詳細資料（不參與可用性判定）';
  @override
  String get sourceProbeHelp =>
      '綠色：API 與圖片可用；黃色：部分可用；紅色：測試失敗。各圖源同時測試，最多約 26 秒。';
  @override
  String get dnsProvider => 'DNS 服務';
  @override
  String sourceSummary({required Object available, required Object issues}) =>
      '${available} 個可用 · ${issues} 個異常';
  @override
  String get servicesTitle => '全部圖源狀態';
  @override
  String get servicesHint => 'IP 解析與 API 可用性分別測試；API 可用不代表所有圖片均可下載。';
  @override
  String get noFallback =>
      'DNS 服務用於更新下方路由。系統 DNS 模式不使用快取 IP；略過 SNI 模式使用快取 IP，失敗時不自動切換。';
  @override
  String checkProgress({
    required Object done,
    required Object total,
    required Object checked,
    required Object sources,
  }) => 'DNS 已完成 ${done}/${total} · API 已測試 ${checked}/${sources}';
  @override
  String checkSummary({
    required Object available,
    required Object total,
    required Object failed,
  }) => 'API 可用 ${available}/${total} · DNS 失敗 ${failed} 項';
  @override
  String get loadingStatus => '正在讀取快取狀態';
  @override
  String get apiChecking => 'API：測試中';
  @override
  String get apiAvailable => 'API：可用';
  @override
  String get apiFailed => 'API：無法使用';
  @override
  String get apiUnchecked => 'API：尚未測試';
  @override
  String get dnsPending => '尚未解析 · 點選重新整理路由取得 IP';
  @override
  String get dnsResolving => '正在解析';
  @override
  String get dnsResolved => '解析成功';
  @override
  String get dnsCached => '使用已快取 IP · 尚未重新測試';
  @override
  String get dnsFailed => '解析失敗 · 目前無可用路由';
  @override
  String get dnsQueued => '等待解析';
  @override
  String ipCachedAt({required Object time}) => 'IP 已快取 · 更新於 ${time}';
  @override
  String get ipNotCached => 'IP 已解析 · 尚未寫入快取';
  @override
  String get connectionMode => '連線模式';
  @override
  String get proxyUrl => 'Proxy URL';
  @override
  String get proxyTitle => '自訂代理';
  @override
  String get proxyModeOverride =>
      '目前使用自訂代理，保留正常 SNI 和憑證驗證，不疊加「略過 SNI」。連線模式在停用自訂代理後生效。';
  @override
  String get proxyApply => '套用';
  @override
  String get proxyDisable => '停用代理';
  @override
  String proxyActive({required Object endpoint}) => '已套用：${endpoint}（尚不代表連線成功）';
  @override
  String get proxyInactive => '未使用';
  @override
  String get proxyPending => '變更尚未套用，請按一下「套用」。';
  @override
  String get proxyHelp => '輸入位址後按一下「套用」。代理服務必須先啟動；套用後用於圖源、圖片與新的下載請求。';
  @override
  String get proxyCheckHelp =>
      '自訂代理優先於快取 IP 路由。套用後請用下方的圖源 API 測試確認連線；DNS 解析成功不代表代理可用。';
  @override
  String get proxyInvalid => '請分別填寫有效的 IP 或主機名稱和連接埠（1–65535），位址欄不需要填寫協定或路徑。';
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
  String routeCacheStatus({required Object hosts, required Object revision}) =>
      '${hosts} 個主機 · 修訂 ${revision}';
  @override
  String get applied => '網路設定已套用';
  @override
  String get invalidSettings => '網路設定無效';
  @override
  String get routeRefreshFailed => '路由重新整理失敗';
  @override
  String get systemDns => '使用系統 DNS';
  @override
  String get sniBypass => '略過 SNI';
}

// Path: settings.languageDialog
class Translations$settings$languageDialog$zh_TW
    extends Translations$settings$languageDialog$en {
  Translations$settings$languageDialog$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '語言';
}

// Path: settings.themeModeDialog
class Translations$settings$themeModeDialog$zh_TW
    extends Translations$settings$themeModeDialog$en {
  Translations$settings$themeModeDialog$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '主題模式';
}

// Path: settings.downloadDirectoryDialog
class Translations$settings$downloadDirectoryDialog$zh_TW
    extends Translations$settings$downloadDirectoryDialog$en {
  Translations$settings$downloadDirectoryDialog$zh_TW.internal(
    TranslationsZhTw root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '下載資料夾';
  @override
  String get pickerTitle => '選擇資料夾';
  @override
  String get pick => '選擇資料夾';
  @override
  late final Translations$settings$downloadDirectoryDialog$messages$zh_TW
  messages =
      Translations$settings$downloadDirectoryDialog$messages$zh_TW.internal(
        _root,
      );
}

// Path: settings.bypassSniDialog
class Translations$settings$bypassSniDialog$zh_TW
    extends Translations$settings$bypassSniDialog$en {
  Translations$settings$bypassSniDialog$zh_TW.internal(TranslationsZhTw root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '略過 SNI';
}

// Path: settings.columnsPerRowDialog
class Translations$settings$columnsPerRowDialog$zh_TW
    extends Translations$settings$columnsPerRowDialog$en {
  Translations$settings$columnsPerRowDialog$zh_TW.internal(
    TranslationsZhTw root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每列圖片數';
}

// Path: settings.maxSegmentsPerTaskDialog
class Translations$settings$maxSegmentsPerTaskDialog$zh_TW
    extends Translations$settings$maxSegmentsPerTaskDialog$en {
  Translations$settings$maxSegmentsPerTaskDialog$zh_TW.internal(
    TranslationsZhTw root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每個下載任務的最大分段數';
}

// Path: settings.account.statuses
class Translations$settings$account$statuses$zh_TW
    extends Translations$settings$account$statuses$en {
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
  Translations$settings$downloadDirectoryDialog$messages$zh_TW.internal(
    TranslationsZhTw root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhTw _root; // ignore: unused_field

  // Translations
  @override
  String get setToPlatformDefault => '下載資料夾已設為系統預設。';
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
          'generic.copiedWithValue' =>
            ({required Object value}) => '已複製到剪貼簿： ${value}',
          'generic.errorWithValue' =>
            ({required Object value}) => '發生錯誤： ${value}',
          'generic.loading' => '載入中',
          'generic.loadFailed' => '載入失敗',
          'generic.retry' => '重試',
          'generic.noMoreData' => '沒有更多資料',
          'generic.notFound' => '找不到內容',
          'booruError.invalidRequest' => '請求參數無效。',
          'booruError.unsupportedCapability' => '目前圖源不支援此操作。',
          'booruError.authenticationRequired' => '請登入目前圖源後重試。',
          'booruError.authenticationRejected' => '圖源拒絕了帳號憑證。',
          'booruError.permissionDenied' => '圖源拒絕存取此資源。',
          'booruError.rateLimited' => '圖源暫時限制了請求，稍後會自動恢復。',
          'booruError.challengeRequired' =>
            '圖源要求瀏覽器驗證。可嘗試在瀏覽器中開啟圖源完成驗證，或選擇其他圖源。',
          'booruError.routeUnavailable' =>
            '目前網域沒有可用路由。請在網路設定中重新整理路由；不會改用系統 DNS。',
          'booruError.sourceUnavailable' => '目前圖源暫時無法使用。',
          'booruError.network' => '網路請求失敗。請檢查網路連線後重試。',
          'booruError.timeout' => '請求逾時。請檢查網路連線，或稍後重試。',
          'booruError.invalidResponse' => '圖源回傳了無法解析的回應。',
          'booruError.unsafeRedirect' => '圖源回傳了不安全的重新導向。',
          'booruError.mediaValidationFailed' => '媒體回應驗證或解碼失敗。',
          'booruError.cancelled' => '請求已取消。',
          'booruError.internal' => '圖源引擎發生內部錯誤。',
          'update.checkUpdateStart' => '正在檢查更新',
          'update.checkUpdateFailed' => '檢查更新失敗，請檢查您的網路連線。',
          'update.selectDownloadUrlFailed' =>
            '找不到下載連結。請前往專案頁面手動更新，或到 Issue 頁面尋求協助。',
          'update.newVersionFound' =>
            ({required Object version}) => '有新版本 ${version}。請前往「關於」下載更新。',
          'update.noNewVersionFound' => '沒有新版本。',
          'postList.short' => '首頁',
          'postList.title' => '首頁',
          'postList.titleWithTags' =>
            ({required Object tags}) => '含有標籤的作品：${tags}',
          'postDetail.fullscreen' => '全螢幕檢視',
          'postDetail.notFound' => '找不到這個作品',
          'postDetail.parentCount' =>
            ({required Object count}) => '${count} 個父作品',
          'postDetail.childCount' =>
            ({required Object count}) => '${count} 個子作品',
          'postDetail.zoomIn' => '放大',
          'postDetail.zoomOut' => '縮小',
          'postDetail.originalFailed' => '原圖載入失敗',
          'postDetail.previewShown' => '目前顯示的是預覽圖。',
          'postDetail.uploadedAt' => ({required Object date}) => '${date} 上傳',
          'postDetail.pixels' => '像素',
          'postDetail.dimensions' => '尺寸',
          'postDetail.searchTag' => '搜尋此標籤',
          'postDetail.addToSearch' => '加入搜尋',
          'postDetail.excludeTag' => '排除此標籤',
          'postDetail.openSource' => '開啟來源',
          'postDetail.resetZoom' => '重設縮放',
          'postDetail.ratingGeneral' => '一般',
          'postDetail.ratingSensitive' => '敏感',
          'postDetail.ratingQuestionable' => '存疑',
          'postDetail.ratingExplicit' => '成人',
          'postDetail.ratingUnknown' => '未知',
          'postDetail.titleWithId' => ({required Object id}) => '作品：${id}',
          'postDetail.tags' => '標籤',
          'postDetail.details' => '詳細資訊',
          'postDetail.actions' => '操作',
          'postDetail.rating' => '分級',
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
          'postDetail.parent' => '父作品 ID',
          'postDetail.hasChildren' => '有子作品',
          'postDetail.similarPosts' => '相關圖片',
          'postDetail.parentPost' => '父作品',
          'postDetail.childPost' => '子作品',
          'postSearch.title' => '搜尋',
          'imageZoom.title' => '縮放圖片',
          'downloads.fileMissing' => '檔案已不在原來的位置',
          'downloads.locationMissing' => '找不到檔案或資料夾',
          'downloads.redownload' => '重新下載',
          'downloads.remove' => '刪除',
          'downloads.activeTasks' =>
            ({required Object count}) => '正在下載 ${count} 項',
          'downloads.failedTasks' =>
            ({required Object count}) => '${count} 項下載失敗',
          'downloads.retryAll' => '全部重試',
          'downloads.today' => '今天',
          'downloads.yesterday' => '昨天',
          'downloads.transferRate' => ({required Object value}) => '${value}/s',
          'downloads.remainingSeconds' =>
            ({required Object count}) => '約 ${count} 秒',
          'downloads.remainingMinutes' =>
            ({required Object count}) => '約 ${count} 分鐘',
          'downloads.remainingHours' =>
            ({required Object count}) => '約 ${count} 小時',
          'downloads.format' => '格式',
          'downloads.startedAt' => '開始時間',
          'downloads.browse' => '瀏覽',
          'downloads.all' => '全部',
          'downloads.pause' => '暫停',
          'downloads.resume' => '繼續',
          'downloads.pauseAll' => '全部暫停',
          'downloads.resumeAll' => '全部繼續',
          'downloads.retryFailed' => '重試失敗項目',
          'downloads.clearCompleted' => '清除已完成',
          'downloads.openDirectory' => '開啟下載資料夾',
          'downloads.openPost' => '開啟作品',
          'downloads.batch' => '批次下載',
          'downloads.batchProgress' =>
            ({required Object completed, required Object total}) =>
                '${completed} / ${total}',
          'downloads.path' => '儲存路徑',
          'downloads.taskDetails' => '任務詳細資料',
          'downloads.viewLog' => '記錄',
          'downloads.title' => '下載',
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
          'downloads.messages.storagePermanentlyDenied' =>
            '您已永久拒絕儲存權限。\n請在設定中手動啟用儲存權限。',
          'downloads.messages.storageDenied' => '您已拒絕儲存權限。',
          'downloads.messages.deviceInfoError' => '無法解析裝置資訊。',
          'downloads.messages.photosPermanentlyDenied' =>
            '您已永久拒絕照片權限。\n請在設定中手動啟用照片權限。',
          'downloads.messages.photosDenied' => '您已拒絕照片權限。',
          'downloads.messages.downloadTaskExists' => '下載任務已經存在。',
          'downloads.messages.imageFileExists' => '圖片檔案已經存在。',
          'downloads.messages.downloadRetryWith' =>
            ({required Object name}) => '重試下載任務： ${name}',
          'downloads.messages.downloadStartWith' =>
            ({required Object name}) => '開始下載任務： ${name}',
          'downloads.messages.downloadCompletedWith' =>
            ({required Object name}) => '下載任務完成： ${name}',
          'downloads.messages.downloadFailedWith' =>
            ({required Object name}) => '下載任務失敗： ${name}',
          'downloads.messages.saveFailedWith' =>
            ({required Object name}) => '儲存失敗： 任務 ${name}',
          'about.title' => '關於',
          'about.projectUrl' => '專案網址',
          'about.publishPage' => '發佈頁面',
          'about.appVersion' => '應用程式版本',
          'about.freepivPromotionTitle' => '試試 freepiv',
          'about.freepivPromotionSubtitle' => '流暢的跨平台 Pixiv 瀏覽工具。',
          'about.discussion' => '討論',
          'about.downloadUpdate' => '下載更新',
          'about.downloadUpdateHint' => '透過瀏覽器下載適合您裝置的最新版本。',
          'settings.title' => '設定',
          'settings.theme' => '主題',
          'settings.language' => '語言',
          'settings.bypassSni' => '略過 SNI',
          'settings.downloadDirectory' => '下載資料夾',
          'settings.defaultToPlatformSettings' => '使用系統預設',
          'settings.columnsPerRow' => '每列圖片數',
          'settings.maxConcurrentDownloads' => '同時下載',
          'settings.maxSegmentsPerTask' => '每個任務的分段數',
          'settings.platformDefault' => '系統預設',
          'settings.system' => '跟隨系統',
          'settings.light' => '淺色',
          'settings.dark' => '深色',
          'settings.auto' => '自動',
          'settings.downloadsOverview' => '儲存位置與同時下載數',
          'settings.sections.sourcesAndAccounts' => '圖源與帳號',
          'settings.sections.accounts' => '帳號',
          'settings.sections.network' => '網路',
          'settings.sections.general' => '一般',
          'settings.sections.downloads' => '下載',
          'settings.source.defaultSource' => '預設圖源',
          'settings.source.supportedRatings' => '支援的分級',
          'settings.source.safetyRating' => '內容分級',
          'settings.account.manageAllSubtitle' => '圖源分級與帳號設定',
          'settings.account.noAccountRequired' => '不需帳號',
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
          'settings.account.statusValue' =>
            ({required Object status}) => '狀態 · ${status}',
          'settings.account.statuses.notConfigured' => '尚未設定',
          'settings.account.statuses.configuredUnverified' => '已設定，尚未驗證',
          'settings.account.statuses.verified' => '已驗證',
          'settings.account.statuses.rejected' => '已被拒絕',
          'settings.network.proxyCompact' => '自訂代理',
          'settings.network.checkCompact' => '測試',
          'settings.network.detailsCompact' => '詳細',
          'settings.network.advancedCompact' => '進階',
          'settings.network.uncheckedCompact' => '未測試',
          'settings.network.checkingCompact' => '測試中',
          'settings.network.apiShort' => 'API',
          'settings.network.imagesShort' => '圖片',
          'settings.network.saveCompact' => '儲存',
          'settings.network.proxyProtocol' => '協定',
          'settings.network.proxyHost' => '主機',
          'settings.network.proxyPort' => '連接埠',
          'settings.network.proxyReachable' => '可連線',
          'settings.network.proxyUnreachable' => '無法連線',
          'settings.network.proxyProbe' => '測試代理連線',
          'settings.network.proxyProbeHint' => '使用目前填寫的代理測試各圖源，不會儲存設定。',
          'settings.network.sourceAvailable' => '可用',
          'settings.network.sourcePartial' => '部分可用',
          'settings.network.sourceUnavailable' => '不可用',
          'settings.network.checkAllSources' => '測試全部',
          'settings.network.mediaAvailable' => '圖片：可用',
          'settings.network.mediaUnavailable' => '圖片：未通過測試或無測試圖片',
          'settings.network.dnsDetails' => 'DNS 路由詳細資料（不參與可用性判定）',
          'settings.network.sourceProbeHelp' =>
            '綠色：API 與圖片可用；黃色：部分可用；紅色：測試失敗。各圖源同時測試，最多約 26 秒。',
          'settings.network.dnsProvider' => 'DNS 服務',
          'settings.network.sourceSummary' =>
            ({required Object available, required Object issues}) =>
                '${available} 個可用 · ${issues} 個異常',
          'settings.network.servicesTitle' => '全部圖源狀態',
          'settings.network.servicesHint' =>
            'IP 解析與 API 可用性分別測試；API 可用不代表所有圖片均可下載。',
          'settings.network.noFallback' =>
            'DNS 服務用於更新下方路由。系統 DNS 模式不使用快取 IP；略過 SNI 模式使用快取 IP，失敗時不自動切換。',
          'settings.network.checkProgress' =>
            ({
              required Object done,
              required Object total,
              required Object checked,
              required Object sources,
            }) => 'DNS 已完成 ${done}/${total} · API 已測試 ${checked}/${sources}',
          'settings.network.checkSummary' =>
            ({
              required Object available,
              required Object total,
              required Object failed,
            }) => 'API 可用 ${available}/${total} · DNS 失敗 ${failed} 項',
          'settings.network.loadingStatus' => '正在讀取快取狀態',
          'settings.network.apiChecking' => 'API：測試中',
          'settings.network.apiAvailable' => 'API：可用',
          'settings.network.apiFailed' => 'API：無法使用',
          'settings.network.apiUnchecked' => 'API：尚未測試',
          'settings.network.dnsPending' => '尚未解析 · 點選重新整理路由取得 IP',
          'settings.network.dnsResolving' => '正在解析',
          'settings.network.dnsResolved' => '解析成功',
          'settings.network.dnsCached' => '使用已快取 IP · 尚未重新測試',
          'settings.network.dnsFailed' => '解析失敗 · 目前無可用路由',
          'settings.network.dnsQueued' => '等待解析',
          'settings.network.ipCachedAt' =>
            ({required Object time}) => 'IP 已快取 · 更新於 ${time}',
          'settings.network.ipNotCached' => 'IP 已解析 · 尚未寫入快取',
          'settings.network.connectionMode' => '連線模式',
          'settings.network.proxyUrl' => 'Proxy URL',
          'settings.network.proxyTitle' => '自訂代理',
          'settings.network.proxyModeOverride' =>
            '目前使用自訂代理，保留正常 SNI 和憑證驗證，不疊加「略過 SNI」。連線模式在停用自訂代理後生效。',
          'settings.network.proxyApply' => '套用',
          'settings.network.proxyDisable' => '停用代理',
          'settings.network.proxyActive' =>
            ({required Object endpoint}) => '已套用：${endpoint}（尚不代表連線成功）',
          'settings.network.proxyInactive' => '未使用',
          'settings.network.proxyPending' => '變更尚未套用，請按一下「套用」。',
          'settings.network.proxyHelp' =>
            '輸入位址後按一下「套用」。代理服務必須先啟動；套用後用於圖源、圖片與新的下載請求。',
          'settings.network.proxyCheckHelp' =>
            '自訂代理優先於快取 IP 路由。套用後請用下方的圖源 API 測試確認連線；DNS 解析成功不代表代理可用。',
          'settings.network.proxyInvalid' =>
            '請分別填寫有效的 IP 或主機名稱和連接埠（1–65535），位址欄不需要填寫協定或路徑。',
          'settings.network.proxyHint' => '選填 · 例如 http://127.0.0.1:7890',
          'settings.network.applyAndRouteCache' => '套用與路由快取',
          'settings.network.apply' => '套用網路設定',
          'settings.network.refreshRoutes' => '重新整理路由',
          'settings.network.routeCacheUnavailable' => '無法取得路由快取',
          'settings.network.routeCacheStatus' =>
            ({required Object hosts, required Object revision}) =>
                '${hosts} 個主機 · 修訂 ${revision}',
          'settings.network.applied' => '網路設定已套用',
          'settings.network.invalidSettings' => '網路設定無效',
          'settings.network.routeRefreshFailed' => '路由重新整理失敗',
          'settings.network.systemDns' => '使用系統 DNS',
          'settings.network.sniBypass' => '略過 SNI',
          'settings.languageDialog.title' => '語言',
          'settings.themeModeDialog.title' => '主題模式',
          'settings.downloadDirectoryDialog.title' => '下載資料夾',
          'settings.downloadDirectoryDialog.pickerTitle' => '選擇資料夾',
          'settings.downloadDirectoryDialog.pick' => '選擇資料夾',
          'settings.downloadDirectoryDialog.messages.setToPlatformDefault' =>
            '下載資料夾已設為系統預設。',
          'settings.downloadDirectoryDialog.messages.pathNotAbsolute' =>
            '路徑必須是絕對路徑。',
          'settings.downloadDirectoryDialog.messages.pathNotWritable' =>
            '路徑不可寫入。',
          'settings.bypassSniDialog.title' => '略過 SNI',
          'settings.columnsPerRowDialog.title' => '每列圖片數',
          'settings.maxSegmentsPerTaskDialog.title' => '每個下載任務的最大分段數',
          'discovery.mode' => '模式',
          'discovery.timeRange' => '時間範圍',
          'discovery.chooseDate' => '指定日期',
          'discovery.menuWeek' => '本週',
          'discovery.menuMonth' => '本月',
          'discovery.ratingsTitle' => '內容分級',
          'discovery.ratingLabel' => '分級',
          'discovery.ratingSeparator' => '、',
          'discovery.calendarRanges' => '日曆週期',
          'discovery.rollingRanges' => '最近期間',
          'discovery.tooManyRequests' => '請求過於頻繁',
          'discovery.copyLink' => '複製連結',
          'discovery.copyQueryLink' => '複製查詢連結',
          'discovery.copyImage' => '複製圖片',
          'discovery.searchAuthor' => '搜尋此繪師',
          'discovery.mediaAnimation' => '動圖',
          'discovery.mediaVideo' => '影片',
          'discovery.mediaCollection' => '相關圖片',
          'discovery.retryIn' =>
            ({required Object seconds}) => '${seconds} 秒後重試',
          'discovery.searchResults' => '搜尋結果',
          'discovery.searchTermsTitle' =>
            ({required Object count}) => '搜尋 ${count} 個關鍵字',
          'discovery.allAvailable' => '全部可用內容',
          'discovery.defaultRatingsHint' => '未選擇時顯示目前圖源能存取的全部內容。',
          'discovery.resetFilters' => '還原預設',
          'discovery.unsupportedRatings' => '目前圖源不支援所選分級。',
          'discovery.noFilteredPosts' => '沒有符合篩選的內容',
          'discovery.noSearchResults' => '沒有找到符合此查詢的內容。',
          'discovery.noFeedPosts' => '目前圖源暫時沒有可展示的內容。',
          'discovery.historicalPopular' => '歷史熱門',
          'discovery.calendarDay' => '每日',
          'discovery.calendarWeek' => '每週',
          'discovery.calendarMonth' => '每月',
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
          'discovery.clearHistory' => '清空',
          'discovery.recentSearches' => '最近搜尋',
          'discovery.noRecentSearches' => '尚無最近搜尋',
          'discovery.myTags' => '我的標籤',
          'discovery.commonTags' => '常用標籤',
          'discovery.moreTags' => '查看更多',
          'discovery.tagSource' => '適用圖源',
          'discovery.allTagSources' => '通用',
          'discovery.manageTags' => '標籤管理',
          'discovery.manageTagsAction' => '管理',
          'discovery.addTagAction' => '新增',
          'discovery.deleteTag' => '刪除',
          'discovery.addTag' => '新增標籤',
          'discovery.noCustomTags' => '還沒有自訂標籤',
          'discovery.customTagsHint' => '給常用標籤取個好記的名字，搜尋時更容易找到。',
          'discovery.addCustomTag' => '新增為自訂標籤',
          'discovery.editTag' => '編輯自訂標籤',
          'discovery.canonicalTag' => '圖源標籤',
          'discovery.displayName' => '顯示名稱（選填）',
          'discovery.invalidTag' => '請輸入一個非空且不含空格的標籤。',
          'discovery.queryHint' => '搜尋標籤',
          'discovery.unverifiedTag' => '部分標籤尚未在目前圖源驗證，仍可提交搜尋。',
          'discovery.verifiedTag' => '已在目前圖源驗證',
          'discovery.noSuggestions' => '沒有建議',
          'discovery.localFallback' => '暫時無法取得線上建議，仍可使用本機建議。',
          'discovery.retryTags' => '重試常用標籤',
          'discovery.artist' => '繪師',
          'discovery.character' => '角色',
          'discovery.copyright' => '作品',
          'discovery.meta' => '中繼標籤',
          'discovery.general' => '一般',
          'discovery.random' => '隨機',
          'discovery.lifetimeViews' => '累計瀏覽量',
          'discovery.lifetimeFavorites' => '累計收藏數',
          'mediaError.videoProxyBypassed' => '影片不支援目前的 SOCKS 代理，本次播放使用直接連線。',
          'mediaError.videoFailed' => '影片播放失敗',
          'mediaError.downloadOriginal' => '下載原檔案',
          'mediaError.previewUnsupported' => '無法預覽',
          'mediaError.title' => '圖片載入失敗',
          'mediaError.details' => '錯誤詳細資料',
          'mediaError.copyDetails' => '複製詳細資料',
          'mediaError.decodeFailed' => '下載的圖片無法解碼。重試會清除這張圖片的快取並重新下載。',
          'webChallenge.title' => '網頁驗證',
          'webChallenge.open' => '開啟網頁驗證',
          'webChallenge.windowTitle' =>
            ({required Object source}) => '${source} · 完成驗證後關閉視窗',
          'webChallenge.instructions' =>
            '請手動完成網頁中的人機驗證，完成後返回或關閉視窗。應用程式會儲存驗證資料並重新載入圖源。',
          'webChallenge.finish' => '完成驗證並返回',
          'webChallenge.saving' => '正在讀取並驗證網頁工作階段',
          'webChallenge.waiting' => '正在進行網頁驗證',
          'webChallenge.clear' => '清空',
          'webChallenge.clearAll' => '清空所有網頁驗證資料',
          'webChallenge.clearDescription' => '清除 Cookie、瀏覽器識別資訊和網頁快取。',
          'webChallenge.cleared' => '網頁驗證資料已清空',
          'webChallenge.verified' => '已驗證，可以存取',
          'webChallenge.saved' => '已儲存，等待重新驗證',
          'webChallenge.empty' => '沒有已儲存的驗證資料',
          'webChallenge.failed' => '網頁驗證未完成，請重試。',
          'webChallenge.pageLoadFailed' => '網頁載入失敗，請重新開啟驗證視窗或檢查網路設定。',
          'webChallenge.webViewUnavailable' => '此平台無法使用網頁元件。',
          'webChallenge.windowFailed' => '無法開啟網頁驗證。',
          'webChallenge.runtimeMissing' =>
            '找不到 Microsoft Edge WebView2 Runtime，請安裝或更新後再試。',
          'webChallenge.proxyUnsupported' => '網頁元件尚不支援目前的代理設定，請變更代理設定後重試。',
          'webChallenge.busy' => '另一個網頁驗證或清理操作正在進行。',
          'webChallenge.cancelled' => '已取消網頁驗證。',
          'webChallenge.timedOut' => '網頁驗證逾時，請重新開啟網頁。',
          'webChallenge.storageFailed' => '無法儲存或清空驗證資料，原本的工作階段仍被保留。',
          'webChallenge.captureFailed' => '無法讀取網頁工作階段，請重新開啟網頁驗證。',
          'webChallenge.cleanupFailed' => '網頁資料尚未清理完成，請稍後再次清空。',
          'webChallenge.operationSuperseded' => '驗證已因清空資料或變更網路設定而取消。',
          'webChallenge.noCookies' => '網頁尚未提供可用的驗證資料，請完成人機驗證後再返回。',
          'nativeWindow.minimize' => '最小化',
          'nativeWindow.maximize' => '最大化',
          'nativeWindow.restore' => '還原',
          'nativeWindow.close' => '關閉',
          'batchDownload.title' => '批次下載',
          'batchDownload.close' => '關閉',
          'batchDownload.limitTitle' => '這次最多取得幾張？',
          'batchDownload.limitHint' => '依目前搜尋條件逐頁取得，達到上限後停止。',
          'batchDownload.limitLabel' => '最多取得',
          'batchDownload.positiveInteger' => '請輸入大於 0 的整數。',
          'batchDownload.start' => '取得圖片',
          'batchDownload.fetchLimit' =>
            ({required Object count}) => '/ 最多 ${count} 張',
          'batchDownload.fetching' => '已找到的圖片',
          'batchDownload.progress' =>
            ({required Object current, required Object total}) =>
                '${current} / ${total}',
          'batchDownload.fetchProgress' =>
            ({required Object current, required Object limit}) =>
                '已取得 ${current} 張，最多 ${limit} 張',
          'batchDownload.stopHint' => '隨時可以停止，並使用已找到的圖片。',
          'batchDownload.stop' => '停止取得',
          'batchDownload.found' => '張圖片可以下載',
          'batchDownload.limitReached' => '已達到取得上限，可能還有更多搜尋結果。',
          'batchDownload.exhausted' => '已取得全部符合條件的結果。',
          'batchDownload.permissionDenied' => '無法取得下載權限，請在系統設定中檢查應用程式權限後重試。',
          'batchDownload.enqueueFailed' => '無法加入下載任務，請檢查儲存位置及剩餘空間後重試。',
          'batchDownload.stopped' => '已停止取得，可以下載已找到的圖片。',
          'batchDownload.empty' => '沒有找到符合條件的圖片。',
          'batchDownload.stalled' => '來源分頁未能繼續推進。已保留結果，可重試或使用已有圖片。',
          'batchDownload.sessionChanged' => '來源設定已改變。請關閉視窗後重新取得，或使用已找到的圖片。',
          'batchDownload.fetchFailed' => '取得未完成。已保留結果，可重試或使用已有圖片。',
          'batchDownload.countLabel' => '下載數量',
          'batchDownload.all' => '全部',
          'batchDownload.countRange' =>
            ({required Object max}) => '請輸入 1～${max}',
          'batchDownload.orderHint' => '按目前搜尋結果順序下載前 N 張圖片。',
          'batchDownload.folderLabel' => '資料夾名稱',
          'batchDownload.folderHint' => '例如：九月收藏',
          'batchDownload.folderPlaceholder' => '你的資料夾',
          'batchDownload.invalidFolder' =>
            '請輸入 1～100 個字元，不含路徑分隔符號、保留名稱、前後空格或結尾句點。',
          'batchDownload.folderHelp' => '同名資料夾會直接沿用，已有檔案不會被覆寫。',
          'batchDownload.locationFailed' => '無法取得儲存位置。',
          'batchDownload.photos' => '照片圖庫',
          'batchDownload.photosHint' =>
            'iOS 將本次圖片儲存為來源資料夾下的相簿，沿用相簿需要照片圖庫完整存取權限。',
          'batchDownload.enqueue' =>
            ({required Object count}) => '加入下載佇列 · ${count} 張',
          'batchDownload.enqueueing' => '正在加入下載佇列',
          'batchDownload.preparing' =>
            ({required Object current, required Object total}) =>
                '正在準備 ${current} / ${total} 張圖片',
          'batchDownload.added' => '個任務已加入下載佇列',
          'batchDownload.backgroundHint' =>
            '可以關閉視窗。應用程式執行期間會繼續加入佇列，再次按一下此入口可查看結果。',
          'batchDownload.queueHint' => '圖片下載進度可在下載清單中查看。',
          'batchDownload.failedHint' =>
            ({required Object count}) => '${count} 張未能加入佇列。',
          'batchDownload.retryFailed' => '重試失敗項目',
          'batchDownload.queued' =>
            ({required Object added, required Object failed}) =>
                '批次任務：已加入 ${added} 張，加入失敗 ${failed} 張。',
          'batchDownload.completed' =>
            ({required Object saved, required Object failed}) =>
                '批次下載結束：已儲存 ${saved} 張，失敗或取消 ${failed} 張。',
          'batchDownload.done' => '完成',
          'batchDownload.back' => '返回',
          'batchDownload.first' => '前 N 張',
          'batchDownload.addedCount' =>
            ({required Object count}) => '已加入 ${count} 張',
          'batchDownload.savedTo' =>
            ({required Object folder}) => '儲存至「${folder}」',
          'batchDownload.viewDownloads' => '查看下載',
          'frost.retry' => '重試',
          'frost.error' => '錯誤',
          'frost.errorDetails' => '錯誤詳細資料',
          'frost.copyDetails' => '複製詳細資料',
          'frost.copied' => '已複製',
          'frost.loading' => '載入中',
          'frost.actionSucceeded' => '操作成功',
          'frost.actionFailed' => '操作失敗',
          'frost.loadFailed' => '載入失敗',
          'frost.noItems' => '尚無內容',
          'frost.noMoreItems' => '沒有更多內容',
          'frost.pullToRefresh' => '下拉重新整理',
          'frost.releaseToRefresh' => '放開以重新整理',
          'frost.refreshing' => '重新整理中',
          'frost.refreshComplete' => '重新整理完成',
          'frost.refreshFailed' => '重新整理失敗',
          'frost.previous' => '上一個',
          'frost.next' => '下一個',
          'frost.back' => '返回',
          'frost.more' => '更多',
          'frost.expandNavigation' => '展開側欄',
          'frost.collapseNavigation' => '收合側欄',
          'frost.clearText' => '清除文字',
          'frost.search' => '搜尋',
          'frost.noResults' => ({required Object query}) => '找不到「${query}」的結果',
          'frost.clearSearch' => '清除搜尋',
          'frost.dismiss' => '關閉',
          'frost.expandText' => '展開',
          'frost.collapseText' => '收合',
          'frost.showAll' => '顯示全部',
          'frost.copy' => '複製',
          'frost.clearAll' => '全部清除',
          'frost.showPassword' => '顯示密碼',
          'frost.hidePassword' => '隱藏密碼',
          'frost.chooseDate' => '選擇日期',
          'frost.chooseTime' => '選擇時間',
          'frost.increment' => '增加',
          'frost.decrement' => '減少',
          'frost.reorderHandle' => '調整順序',
          'frost.sortAscending' => '遞增',
          'frost.sortDescending' => '遞減',
          'frost.play' => '播放',
          'frost.pause' => '暫停',
          'frost.loop' => '重複播放',
          'frost.mute' => '靜音',
          'frost.unmute' => '取消靜音',
          'frost.fullscreen' => '全螢幕',
          'frost.exitFullscreen' => '結束全螢幕',
          'frost.reload' => '重新載入',
          'frost.openInBrowser' => '在瀏覽器中開啟',
          'frost.minimize' => '最小化',
          _ => null,
        } ??
        switch (path) {
          'frost.maximize' => '最大化',
          'frost.restore' => '還原',
          'frost.close' => '關閉',
          'frost.cancel' => '取消',
          'frost.apply' => '套用',
          'frost.clear' => '清除',
          'frost.choose' => '選擇',
          'frost.showInFolder' => '在資料夾中顯示',
          'frost.selectedCount' =>
            ({required Object count}) => '已選取 ${count} 項',
          'frost.pageOf' =>
            ({required Object page, required Object total}) =>
                '第 ${page} 頁，共 ${total} 頁',
          'frost.selectAll' => '全選',
          'frost.done' => '完成',
          'frost.itemPosition' =>
            ({required Object position, required Object total}) =>
                '第 ${position} 項，共 ${total} 項',
          'frost.tableDimensions' =>
            ({required Object rows, required Object columns}) =>
                '${rows} 列，${columns} 欄',
          'frost.taskQueued' => '等待中',
          'frost.taskRunning' => '下載中',
          'frost.taskPaused' => '已暫停',
          'frost.taskCompleted' => '已完成',
          'frost.taskFailed' => '失敗',
          'frost.taskCancelled' => '已取消',
          'frost.remove' => '移除',
          'frost.forward' => '前進',
          'frost.stop' => '停止',
          'frost.seek' => '播放位置',
          'frost.send' => '傳送',
          'frost.attach' => '加入附件',
          'frost.readerSettings' => '閱讀設定',
          'frost.textSize' => '文字大小',
          'frost.lineSpacing' => '行距',
          'frost.readingProgress' => '閱讀進度',
          'frost.showReplies' => ({required Object count}) => '顯示 ${count} 則回覆',
          'frost.characterCount' =>
            ({required Object count, required Object limit}) =>
                '${count} / ${limit} 字',
          'frost.moreMedia' => ({required Object count}) => '還有 ${count} 張圖片',
          'frost.navigationCount' => ({required Object count}) => '${count} 項',
          'frost.navigationProgress' =>
            ({required Object progress}) => '已完成 ${progress}%',
          'frost.listSeparator' => '，',
          'navigation.browse' => '瀏覽',
          'navigation.search' => '搜尋',
          'navigation.downloads' => '下載',
          'navigation.settings' => '設定',
          'navigation.browseEmpty' => '瀏覽喜愛的圖源',
          'navigation.searchEmpty' => '用標籤尋找作品',
          'navigation.downloadsEmpty' => '下載項目會顯示在這裡',
          'navigation.settingsEmpty' => '依照喜好設定 BooruFlow',
          'settingsV2.predictiveBack' => '預測返回',
          'settingsV2.predictiveBackScope' => '預覽 App 內的返回動作；返回主畫面的動畫由系統控制。',
          'settingsV2.background' => '背景材質',
          'settingsV2.ambientBlur' => '環境模糊',
          'settingsV2.mica' => '雲母',
          'settingsV2.backgroundOff' => '關閉',
          'settingsV2.backgroundIntensity' => '強度',
          'settingsV2.systemTransparencyReduced' => '系統已降低透明度',
          'settingsV2.customColour' => '自訂顏色',
          'settingsV2.appearance' => '外觀',
          'settingsV2.browsing' => '瀏覽',
          'settingsV2.tone' => '色調',
          'settingsV2.neutral' => '中性',
          'settingsV2.cool' => '冷色',
          'settingsV2.warm' => '暖色',
          'settingsV2.accent' => '強調色',
          'settingsV2.customAccent' => '自訂強調色',
          'settingsV2.customHex' => '強調色 HEX',
          'settingsV2.invalidHex' => '請輸入六位 HEX 顏色。',
          'settingsV2.accentRejected' => '此強調色在目前表面上無法保持可讀。',
          'settingsV2.accentWarning' => '此強調色對比度較低，仍要套用嗎？',
          'settingsV2.editAccount' => '編輯帳號',
          'settingsV2.signOutConfirm' => '移除此圖源已儲存的帳號憑證？',
          'settingsV2.licenses' => '開放原始碼授權',
          'settingsV2.checkUpdates' => '檢查更新',
          'settingsV2.help' => '說明',
          'settingsDetails.mode' => '模式',
          'settingsDetails.custom' => '自訂',
          'settingsDetails.change' => '更改',
          'settingsDetails.routeCache' => '路由快取',
          'settingsDetails.hostCount' =>
            ({required Object count}) => '${count} 個主機',
          'settingsDetails.updatedAt' =>
            ({required Object time}) => '更新於 ${time}',
          'settingsDetails.sourceStatus' => '圖源狀態',
          'settingsDetails.apiAndImages' => 'API 與圖片可用',
          'settingsDetails.apiOnly' => 'API 可用 · 圖片未通過',
          'settingsDetails.status' => '狀態',
          'settingsDetails.content' => '內容',
          'settingsDetails.editSourceAccount' =>
            ({required Object source}) => '編輯 ${source} 帳號',
          'settingsDetails.proxyApplies' => '套用後用於圖源、圖片和新的下載。',
          'settingsDetails.version' =>
            ({required Object version, required Object build}) =>
                '版本 ${version} (${build})',
          'settingsDetails.communityTelegram' => 'Telegram 群組',
          'settingsDetails.communityDiscord' => 'Discord 伺服器',
          'settingsDetails.savedVerifications' => '已儲存的驗證',
          'settingsDetails.systemDnsShort' => '系統 DNS',
          'settingsDetails.refresh' => '重新整理',
          'settingsDetails.updateAvailable' =>
            ({required Object version}) => '有新版本 ${version}',
          'verificationPage.instructions' => '在下方頁面完成驗證，再按一下「完成驗證並返回」。',
          'verificationPage.opening' => '正在開啟網頁',
          'verificationPage.failed' => '網頁載入失敗',
          'verificationPage.closed' => '驗證視窗已關閉',
          'verificationPage.failureHelp' => '可以重新開啟，或檢查網路設定。',
          'verificationPage.reopen' => '重新開啟',
          'verificationPage.signOut' =>
            ({required Object source}) => '登出 ${source} 帳號？',
          'verificationPage.signOutHelp' => '帳號資訊將從此裝置移除。',
          'verificationPage.downloadAdded' => '已加入下載',
          'verificationPage.downloadFailed' => '下載失敗',
          'verificationPage.linkCopied' => '已複製連結',
          'verificationPage.view' => '查看',
          'verificationPage.networkSettings' => '網路設定',
          'ugoira.iosFilesDestination' => '其他格式儲存在「檔案」App › BooruFlow',
          'ugoira.iosFormatHelp' => '動態 WebP 與 ZIP 儲存到「檔案」。',
          'ugoira.albumName' => '相簿名稱',
          'ugoira.openSettings' => '前往設定',
          'ugoira.androidDestination' => '相簿與下載資料夾',
          'ugoira.iosDestination' => '儲存到照片',
          'ugoira.format' => '動態圖片儲存格式',
          'ugoira.losslessWebp' => '無損動態 WebP',
          'ugoira.originalZip' => '原始 ZIP',
          'ugoira.webpRecord' => 'WebP · 動態圖片',
          'ugoira.zipRecord' => 'ZIP · 原始影格',
          'ugoira.ugoiraInvalidArchive' => '動畫壓縮檔無效。',
          'ugoira.ugoiraMetadataMissing' => '動畫缺少影格時間資料。',
          'ugoira.ugoiraInvalidMetadata' => '動畫影格時間資料無效。',
          'ugoira.ugoiraFrameMissing' => '動畫中有影格遺失。',
          'ugoira.ugoiraFrameCorrupt' => '動畫中有影格損壞。',
          'ugoira.ugoiraFrameSizeMismatch' => '動畫的影格尺寸不一致。',
          'ugoira.ugoiraFrameTooLarge' => '動畫影格超過大小限制。',
          'ugoira.ugoiraEncodeFailed' => '動畫編碼失敗。',
          'ugoira.ugoiraOutputTooLarge' => '動畫編碼結果超過大小限制。',
          _ => null,
        };
  }
}
