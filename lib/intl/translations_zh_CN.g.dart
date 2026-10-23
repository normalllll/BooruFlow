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
class TranslationsZhCn extends Translations
    with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsZhCn({
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
             locale: AppLocale.zhCn,
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

  /// Metadata for the translations of <zh-CN>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key) ?? super[key];

  late final TranslationsZhCn _root = this; // ignore: unused_field

  @override
  TranslationsZhCn $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => TranslationsZhCn(meta: meta ?? this.$meta);

  // Translations
  @override
  late final Translations$generic$zh_CN generic =
      Translations$generic$zh_CN.internal(_root);
  @override
  late final Translations$booruError$zh_CN booruError =
      Translations$booruError$zh_CN.internal(_root);
  @override
  late final Translations$update$zh_CN update =
      Translations$update$zh_CN.internal(_root);
  @override
  late final Translations$postList$zh_CN postList =
      Translations$postList$zh_CN.internal(_root);
  @override
  late final Translations$postDetail$zh_CN postDetail =
      Translations$postDetail$zh_CN.internal(_root);
  @override
  late final Translations$postSearch$zh_CN postSearch =
      Translations$postSearch$zh_CN.internal(_root);
  @override
  late final Translations$imageZoom$zh_CN imageZoom =
      Translations$imageZoom$zh_CN.internal(_root);
  @override
  late final Translations$downloads$zh_CN downloads =
      Translations$downloads$zh_CN.internal(_root);
  @override
  late final Translations$about$zh_CN about = Translations$about$zh_CN.internal(
    _root,
  );
  @override
  late final Translations$settings$zh_CN settings =
      Translations$settings$zh_CN.internal(_root);
  @override
  late final Translations$discovery$zh_CN discovery =
      Translations$discovery$zh_CN.internal(_root);
  @override
  late final Translations$mediaError$zh_CN mediaError =
      Translations$mediaError$zh_CN.internal(_root);
  @override
  late final Translations$webChallenge$zh_CN webChallenge =
      Translations$webChallenge$zh_CN.internal(_root);
  @override
  late final Translations$nativeWindow$zh_CN nativeWindow =
      Translations$nativeWindow$zh_CN.internal(_root);
  @override
  late final Translations$batchDownload$zh_CN batchDownload =
      Translations$batchDownload$zh_CN.internal(_root);
  @override
  late final Translations$frost$zh_CN frost = Translations$frost$zh_CN.internal(
    _root,
  );
  @override
  late final Translations$navigation$zh_CN navigation =
      Translations$navigation$zh_CN.internal(_root);
  @override
  late final Translations$settingsV2$zh_CN settingsV2 =
      Translations$settingsV2$zh_CN.internal(_root);
  @override
  late final Translations$settingsDetails$zh_CN settingsDetails =
      Translations$settingsDetails$zh_CN.internal(_root);
  @override
  late final Translations$verificationPage$zh_CN verificationPage =
      Translations$verificationPage$zh_CN.internal(_root);
  @override
  late final Translations$ugoira$zh_CN ugoira =
      Translations$ugoira$zh_CN.internal(_root);
}

// Path: generic
class Translations$generic$zh_CN extends Translations$generic$en {
  Translations$generic$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get ok => '确定';
  @override
  String get cancel => '取消';
  @override
  String get clear => '清除';
  @override
  String get confirm => '确认';
  @override
  String get enabled => '启用';
  @override
  String get disabled => '停用';
  @override
  String copiedWithValue({required Object value}) => '已复制到剪贴板: ${value}';
  @override
  String errorWithValue({required Object value}) => '发生错误: ${value}';
  @override
  String get loading => '正在加载';
  @override
  String get loadFailed => '加载失败';
  @override
  String get retry => '重试';
  @override
  String get noMoreData => '没有更多数据';
  @override
  String get notFound => '未找到内容';
}

// Path: booruError
class Translations$booruError$zh_CN extends Translations$booruError$en {
  Translations$booruError$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get invalidRequest => '请求参数无效。';
  @override
  String get unsupportedCapability => '当前图源不支持此操作。';
  @override
  String get authenticationRequired => '请登录当前图源后重试。';
  @override
  String get authenticationRejected => '图源拒绝了账号凭据。';
  @override
  String get permissionDenied => '图源拒绝访问此资源。';
  @override
  String get rateLimited => '图源暂时限制了请求，稍后会自动恢复。';
  @override
  String get challengeRequired => '图源要求浏览器验证。可尝试在浏览器中打开图源完成验证，或选择其他图源。';
  @override
  String get routeUnavailable => '当前域名没有可用路由。请在网络设置中刷新路由；不会回退到系统 DNS。';
  @override
  String get sourceUnavailable => '当前图源暂时不可用。';
  @override
  String get network => '网络请求失败。请检查网络连接后重试。';
  @override
  String get timeout => '请求超时。请检查网络连接，或稍后重试。';
  @override
  String get invalidResponse => '图源返回了无法解析的响应。';
  @override
  String get unsafeRedirect => '图源返回了不安全的重定向。';
  @override
  String get mediaValidationFailed => '媒体验证或解码失败。';
  @override
  String get cancelled => '请求已取消。';
  @override
  String get internal => '图源引擎发生内部错误。';
}

// Path: update
class Translations$update$zh_CN extends Translations$update$en {
  Translations$update$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get checkUpdateStart => '正在检查更新';
  @override
  String get checkUpdateFailed => '检查更新失败，请检查你的网络连接。';
  @override
  String get selectDownloadUrlFailed =>
      '找不到下载链接。\n请访问项目页面手动更新，或在项目 Issue 页面寻求帮助。';
  @override
  String newVersionFound({required Object version}) =>
      '发现新版本: ${version}。请转到“关于”页面并点击“下载更新”。';
  @override
  String get noNewVersionFound => '没有新版本。';
}

// Path: postList
class Translations$postList$zh_CN extends Translations$postList$en {
  Translations$postList$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get short => '首页';
  @override
  String get title => '首页';
  @override
  String titleWithTags({required Object tags}) => '带有标签的帖子: ${tags}';
}

// Path: postDetail
class Translations$postDetail$zh_CN extends Translations$postDetail$en {
  Translations$postDetail$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get fullscreen => '全屏查看';
  @override
  String get notFound => '找不到这个作品';
  @override
  String parentCount({required Object count}) => '${count} 个父作品';
  @override
  String childCount({required Object count}) => '${count} 个子作品';
  @override
  String get zoomIn => '放大';
  @override
  String get zoomOut => '缩小';
  @override
  String get originalFailed => '原图加载失败';
  @override
  String get previewShown => '现在显示的是预览图。';
  @override
  String uploadedAt({required Object date}) => '${date} 上传';
  @override
  String get pixels => '像素';
  @override
  String get dimensions => '尺寸';
  @override
  String get searchTag => '搜索此标签';
  @override
  String get addToSearch => '添加到搜索';
  @override
  String get excludeTag => '排除此标签';
  @override
  String get openSource => '打开来源';
  @override
  String get resetZoom => '重置缩放';
  @override
  String get ratingGeneral => '一般';
  @override
  String get ratingSensitive => '敏感';
  @override
  String get ratingQuestionable => '可疑';
  @override
  String get ratingExplicit => '成人';
  @override
  String get ratingUnknown => '未知';
  @override
  String titleWithId({required Object id}) => '帖子: ${id}';
  @override
  String get tags => '标签';
  @override
  String get details => '详细信息';
  @override
  String get actions => '操作';
  @override
  String get rating => '分级';
  @override
  String get fileType => '文件类型';
  @override
  String get viewOriginal => '查看原图';
  @override
  String get download => '下载';
  @override
  String get relatedLoadFailed => '关联图片加载失败，可以重试。';
  @override
  String get createdAt => '创建于';
  @override
  String get author => '作者';
  @override
  String get unknownAuthor => '未知';
  @override
  String get imageSource => '图源';
  @override
  String get source => '来源';
  @override
  String get width => '宽度';
  @override
  String get height => '高度';
  @override
  String get score => '评分';
  @override
  String get size => '大小';
  @override
  String get parent => '父 ID';
  @override
  String get hasChildren => '有子帖子';
  @override
  String get similarPosts => '相关图片';
  @override
  String get parentPost => '父帖子';
  @override
  String get childPost => '子帖子';
}

// Path: postSearch
class Translations$postSearch$zh_CN extends Translations$postSearch$en {
  Translations$postSearch$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '搜索';
}

// Path: imageZoom
class Translations$imageZoom$zh_CN extends Translations$imageZoom$en {
  Translations$imageZoom$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '缩放图片';
}

// Path: downloads
class Translations$downloads$zh_CN extends Translations$downloads$en {
  Translations$downloads$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get fileMissing => '文件已不在原位置';
  @override
  String get locationMissing => '找不到文件或文件夹';
  @override
  String get redownload => '重新下载';
  @override
  String get remove => '删除';
  @override
  String activeTasks({required Object count}) => '正在下载 ${count} 项';
  @override
  String failedTasks({required Object count}) => '${count} 项下载失败';
  @override
  String get retryAll => '全部重试';
  @override
  String get today => '今天';
  @override
  String get yesterday => '昨天';
  @override
  String transferRate({required Object value}) => '${value}/s';
  @override
  String remainingSeconds({required Object count}) => '约 ${count} 秒';
  @override
  String remainingMinutes({required Object count}) => '约 ${count} 分钟';
  @override
  String remainingHours({required Object count}) => '约 ${count} 小时';
  @override
  String get format => '格式';
  @override
  String get startedAt => '开始于';
  @override
  String get browse => '去浏览';
  @override
  String get all => '全部';
  @override
  String get pause => '暂停';
  @override
  String get resume => '继续';
  @override
  String get pauseAll => '全部暂停';
  @override
  String get resumeAll => '全部继续';
  @override
  String get retryFailed => '重试失败项';
  @override
  String get clearCompleted => '清除已完成';
  @override
  String get openDirectory => '打开下载目录';
  @override
  String get openPost => '打开作品';
  @override
  String get batch => '批量下载';
  @override
  String batchProgress({required Object completed, required Object total}) =>
      '${completed} / ${total}';
  @override
  String get path => '保存路径';
  @override
  String get taskDetails => '任务详情';
  @override
  String get viewLog => '日志';
  @override
  String get title => '下载';
  @override
  String get tasksTitle => '下载任务';
  @override
  String get noTasks => '暂无下载任务';
  @override
  String get noTasksMessage => '下载的图片会显示在这里。';
  @override
  String get total => '总数';
  @override
  String get active => '进行中';
  @override
  String get saved => '已保存';
  @override
  String get completed => '已完成';
  @override
  String get failed => '失败';
  @override
  String get waiting => '等待中';
  @override
  String get downloading => '下载中';
  @override
  String get needsAttention => '需要处理';
  @override
  String get queued => '排队中';
  @override
  String get running => '正在下载';
  @override
  String get paused => '已暂停';
  @override
  String get downloaded => '已下载';
  @override
  String get cancelled => '已取消';
  @override
  String get savePending => '等待保存';
  @override
  String get saving => '正在保存';
  @override
  String get saveFailed => '保存失败';
  @override
  String get retrySave => '重试保存';
  @override
  String get cancel => '取消';
  @override
  String get deleteTask => '删除任务';
  @override
  String get sync => '同步';
  @override
  String get syncFailed => '下载状态同步失败';
  @override
  String get actionFailed => '下载操作失败';
  @override
  String get expand => '展开';
  @override
  String get collapse => '收起';
  @override
  late final Translations$downloads$messages$zh_CN messages =
      Translations$downloads$messages$zh_CN.internal(_root);
}

// Path: about
class Translations$about$zh_CN extends Translations$about$en {
  Translations$about$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '关于';
  @override
  String get projectUrl => '项目网址';
  @override
  String get publishPage => '发布页面';
  @override
  String get appVersion => '应用版本';
  @override
  String get freepivPromotionTitle => '试试 freepiv';
  @override
  String get freepivPromotionSubtitle => '现代、流畅的跨平台 Pixiv 第三方客户端。';
  @override
  String get discussion => '讨论';
  @override
  String get downloadUpdate => '下载更新';
  @override
  String get downloadUpdateHint => '通过浏览器下载适合你设备的最新版本。';
}

// Path: settings
class Translations$settings$zh_CN extends Translations$settings$en {
  Translations$settings$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '设置';
  @override
  String get theme => '主题';
  @override
  String get language => '语言';
  @override
  String get bypassSni => '绕过 SNI';
  @override
  String get downloadDirectory => '下载目录';
  @override
  String get defaultToPlatformSettings => '使用平台默认设置';
  @override
  String get columnsPerRow => '每行列数';
  @override
  String get maxConcurrentDownloads => '同时下载';
  @override
  String get maxSegmentsPerTask => '每个任务的分段数';
  @override
  String get platformDefault => '平台默认';
  @override
  String get system => '跟随系统';
  @override
  String get light => '浅色';
  @override
  String get dark => '深色';
  @override
  String get auto => '自动';
  @override
  String get downloadsOverview => '保存位置与下载并发';
  @override
  late final Translations$settings$sections$zh_CN sections =
      Translations$settings$sections$zh_CN.internal(_root);
  @override
  late final Translations$settings$source$zh_CN source =
      Translations$settings$source$zh_CN.internal(_root);
  @override
  late final Translations$settings$account$zh_CN account =
      Translations$settings$account$zh_CN.internal(_root);
  @override
  late final Translations$settings$network$zh_CN network =
      Translations$settings$network$zh_CN.internal(_root);
  @override
  late final Translations$settings$languageDialog$zh_CN languageDialog =
      Translations$settings$languageDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$themeModeDialog$zh_CN themeModeDialog =
      Translations$settings$themeModeDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$downloadDirectoryDialog$zh_CN
  downloadDirectoryDialog =
      Translations$settings$downloadDirectoryDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$bypassSniDialog$zh_CN bypassSniDialog =
      Translations$settings$bypassSniDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$columnsPerRowDialog$zh_CN
  columnsPerRowDialog =
      Translations$settings$columnsPerRowDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$maxSegmentsPerTaskDialog$zh_CN
  maxSegmentsPerTaskDialog =
      Translations$settings$maxSegmentsPerTaskDialog$zh_CN.internal(_root);
}

// Path: discovery
class Translations$discovery$zh_CN extends Translations$discovery$en {
  Translations$discovery$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get mode => '模式';
  @override
  String get timeRange => '时间范围';
  @override
  String get chooseDate => '指定日期';
  @override
  String get menuWeek => '本周';
  @override
  String get menuMonth => '本月';
  @override
  String get ratingsTitle => '内容分级';
  @override
  String get ratingLabel => '分级';
  @override
  String get ratingSeparator => '、';
  @override
  String get calendarRanges => '自然周期';
  @override
  String get rollingRanges => '滚动区间';
  @override
  String get tooManyRequests => '请求太频繁';
  @override
  String get copyLink => '复制链接';
  @override
  String get copyQueryLink => '复制查询链接';
  @override
  String get copyImage => '复制图片';
  @override
  String get searchAuthor => '搜索此画师';
  @override
  String get mediaAnimation => '动图';
  @override
  String get mediaVideo => '视频';
  @override
  String get mediaCollection => '关联图片';
  @override
  String retryIn({required Object seconds}) => '${seconds} 秒后重试';
  @override
  String get searchResults => '搜索结果';
  @override
  String searchTermsTitle({required Object count}) => '搜索${count}个词条';
  @override
  String get allAvailable => '全部可用内容';
  @override
  String get defaultRatingsHint => '不选时显示当前图源能访问的全部内容。';
  @override
  String get resetFilters => '恢复默认';
  @override
  String get unsupportedRatings => '当前图源不支持所选分级。';
  @override
  String get noFilteredPosts => '没有符合筛选的内容';
  @override
  String get noSearchResults => '没有找到符合此查询的内容。';
  @override
  String get noFeedPosts => '当前图源暂时没有可展示的内容。';
  @override
  String get historicalPopular => '历史热门';
  @override
  String get calendarDay => '自然日';
  @override
  String get calendarWeek => '自然周';
  @override
  String get calendarMonth => '自然月';
  @override
  String get latest => '最新';
  @override
  String get popular => '热门';
  @override
  String get today => '今日';
  @override
  String get thisWeek => '本周';
  @override
  String get thisMonth => '本月';
  @override
  String get lastDay => '最近 24 小时';
  @override
  String get lastThreeDays => '最近 3 天';
  @override
  String get lastWeek => '最近一周';
  @override
  String get lastMonth => '最近一个月';
  @override
  String get lastThreeMonths => '最近三个月';
  @override
  String get lastSixMonths => '最近六个月';
  @override
  String get lastYear => '最近一年';
  @override
  String get rankingComplete => '榜单已全部加载';
  @override
  String get latestFallback => '此图源仅支持最新帖子。';
  @override
  String get filters => '筛选';
  @override
  String get loadMore => '加载更多';
  @override
  String get clearHistory => '清空';
  @override
  String get recentSearches => '最近搜索';
  @override
  String get noRecentSearches => '暂无最近搜索';
  @override
  String get myTags => '我的标签';
  @override
  String get commonTags => '常用标签';
  @override
  String get moreTags => '查看更多';
  @override
  String get tagSource => '适用图源';
  @override
  String get allTagSources => '通用';
  @override
  String get manageTags => '标签管理';
  @override
  String get manageTagsAction => '管理';
  @override
  String get addTagAction => '添加';
  @override
  String get deleteTag => '删除';
  @override
  String get addTag => '添加标签';
  @override
  String get noCustomTags => '还没有自定义标签';
  @override
  String get customTagsHint => '给常用标签起个好记的名字，搜索时更容易找到。';
  @override
  String get addCustomTag => '添加为自定义标签';
  @override
  String get editTag => '编辑自定义标签';
  @override
  String get canonicalTag => '图源标签';
  @override
  String get displayName => '显示名称（可选）';
  @override
  String get invalidTag => '请输入一个非空且不含空格的标签。';
  @override
  String get queryHint => '搜索标签';
  @override
  String get unverifiedTag => '部分标签尚未在当前图源验证，仍可提交搜索。';
  @override
  String get verifiedTag => '已在当前图源验证';
  @override
  String get noSuggestions => '没有建议';
  @override
  String get localFallback => '在线补全暂不可用，仍可使用本地建议。';
  @override
  String get retryTags => '重试常用标签';
  @override
  String get artist => '画师';
  @override
  String get character => '角色';
  @override
  String get copyright => '作品';
  @override
  String get meta => '元标签';
  @override
  String get general => '通用';
  @override
  String get random => '随机';
  @override
  String get lifetimeViews => '累计浏览量';
  @override
  String get lifetimeFavorites => '累计收藏数';
}

// Path: mediaError
class Translations$mediaError$zh_CN extends Translations$mediaError$en {
  Translations$mediaError$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get videoProxyBypassed => '视频不支持当前的 SOCKS 代理，本次播放使用了直连。';
  @override
  String get videoFailed => '视频播放失败';
  @override
  String get downloadOriginal => '下载原文件';
  @override
  String get previewUnsupported => '无法预览';
  @override
  String get title => '图片加载失败';
  @override
  String get details => '错误详情';
  @override
  String get copyDetails => '复制详情';
  @override
  String get decodeFailed => '下载的图片无法解码。重试会清除这张图片的缓存并重新下载。';
}

// Path: webChallenge
class Translations$webChallenge$zh_CN extends Translations$webChallenge$en {
  Translations$webChallenge$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '网页验证';
  @override
  String get open => '打开网页验证';
  @override
  String windowTitle({required Object source}) => '${source} · 完成验证后关闭窗口';
  @override
  String get instructions => '请手动完成网页中的人机验证，完成后返回或关闭窗口。应用会保存验证数据并重新加载图源。';
  @override
  String get finish => '完成验证并返回';
  @override
  String get saving => '正在读取并验证网页会话';
  @override
  String get waiting => '正在进行网页验证';
  @override
  String get clear => '清空';
  @override
  String get clearAll => '清空全部网页验证数据';
  @override
  String get clearDescription => '清除 Cookie、浏览器标识和网页缓存。';
  @override
  String get cleared => '网页验证数据已清空';
  @override
  String get verified => '已验证，可访问';
  @override
  String get saved => '已保存，等待重新验证';
  @override
  String get empty => '没有已保存的验证数据';
  @override
  String get failed => '网页验证未完成，请重试。';
  @override
  String get pageLoadFailed => '网页加载失败，可重新打开验证窗口或检查网络设置。';
  @override
  String get webViewUnavailable => '当前平台无法使用网页组件。';
  @override
  String get windowFailed => '无法打开网页验证。';
  @override
  String get runtimeMissing => '找不到 Microsoft Edge WebView2 Runtime，请安装或更新后重试。';
  @override
  String get proxyUnsupported => '网页组件暂不支持当前代理设置，请更换代理配置后重试。';
  @override
  String get busy => '另一个网页验证或清理操作正在进行。';
  @override
  String get cancelled => '已取消网页验证。';
  @override
  String get timedOut => '网页验证超时，请重新打开网页。';
  @override
  String get storageFailed => '无法保存或清空验证数据，原来的会话仍被保留。';
  @override
  String get captureFailed => '无法读取网页会话，请重新打开网页验证。';
  @override
  String get cleanupFailed => '网页数据尚未清理完成，请稍后再次清空。';
  @override
  String get operationSuperseded => '验证已被清空操作或网络设置变更取消。';
  @override
  String get noCookies => '网页尚未提供可用的验证数据，请完成人机验证后再返回。';
}

// Path: nativeWindow
class Translations$nativeWindow$zh_CN extends Translations$nativeWindow$en {
  Translations$nativeWindow$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get minimize => '最小化';
  @override
  String get maximize => '最大化';
  @override
  String get restore => '还原';
  @override
  String get close => '关闭';
}

// Path: batchDownload
class Translations$batchDownload$zh_CN extends Translations$batchDownload$en {
  Translations$batchDownload$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '批量下载';
  @override
  String get close => '关闭';
  @override
  String get limitTitle => '这次最多获取多少张？';
  @override
  String get limitHint => '按当前搜索条件逐页获取，达到上限后停止。';
  @override
  String get limitLabel => '最多获取';
  @override
  String get positiveInteger => '请输入大于 0 的整数。';
  @override
  String get start => '获取图片';
  @override
  String fetchLimit({required Object count}) => '/ 最多 ${count} 张';
  @override
  String get fetching => '已找到的图片';
  @override
  String progress({required Object current, required Object total}) =>
      '${current} / ${total}';
  @override
  String fetchProgress({required Object current, required Object limit}) =>
      '已获取 ${current} 张，最多 ${limit} 张';
  @override
  String get stopHint => '随时可以停止，并使用已找到的图片。';
  @override
  String get stop => '停止获取';
  @override
  String get found => '张图片可以下载';
  @override
  String get limitReached => '已达到获取上限，可能还有更多搜索结果。';
  @override
  String get exhausted => '已获取全部匹配结果。';
  @override
  String get permissionDenied => '下载权限不可用，请在系统设置中检查应用权限后重试。';
  @override
  String get enqueueFailed => '无法加入下载任务，请检查保存位置及剩余空间后重试。';
  @override
  String get stopped => '已停止获取，可以下载已找到的图片。';
  @override
  String get empty => '没有找到符合条件的图片。';
  @override
  String get stalled => '源站分页未能继续推进。已保留结果，可重试或使用已有图片。';
  @override
  String get sessionChanged => '源站设置已改变。请关闭窗口后重新获取，或使用已找到的图片。';
  @override
  String get fetchFailed => '获取未完成。已保留结果，可重试或使用已有图片。';
  @override
  String get countLabel => '下载数量';
  @override
  String get all => '全部';
  @override
  String countRange({required Object max}) => '请输入 1～${max}';
  @override
  String get orderHint => '按当前搜索结果顺序下载前 N 张图片。';
  @override
  String get folderLabel => '文件夹名';
  @override
  String get folderHint => '例如：九月收藏';
  @override
  String get folderPlaceholder => '你的文件夹';
  @override
  String get invalidFolder => '请输入 1～100 个字符，不含路径分隔符、保留名称、首尾空格或末尾句点。';
  @override
  String get folderHelp => '同名文件夹会直接沿用，已有文件不会被覆盖。';
  @override
  String get locationFailed => '无法获取保存位置。';
  @override
  String get photos => '照片库';
  @override
  String get photosHint => 'iOS 将本次图片保存为源站文件夹下的相册，复用相册需要照片库完整访问权限。';
  @override
  String enqueue({required Object count}) => '加入下载队列 · ${count} 张';
  @override
  String get enqueueing => '正在加入下载队列';
  @override
  String preparing({required Object current, required Object total}) =>
      '正在准备 ${current} / ${total} 张图片';
  @override
  String get added => '个任务已加入下载队列';
  @override
  String get backgroundHint => '可以关闭窗口。应用运行期间会继续入队，再次点击此入口可查看结果。';
  @override
  String get queueHint => '图片下载进度可在下载列表中查看。';
  @override
  String failedHint({required Object count}) => '${count} 张未能加入队列。';
  @override
  String get retryFailed => '重试失败项';
  @override
  String queued({required Object added, required Object failed}) =>
      '批量任务：已加入 ${added} 张，入队失败 ${failed} 张。';
  @override
  String completed({required Object saved, required Object failed}) =>
      '批量下载结束：已保存 ${saved} 张，失败或取消 ${failed} 张。';
  @override
  String get done => '完成';
  @override
  String get back => '返回';
  @override
  String get first => '前 N 张';
  @override
  String addedCount({required Object count}) => '已加入 ${count} 张';
  @override
  String savedTo({required Object folder}) => '保存到“${folder}”';
  @override
  String get viewDownloads => '查看下载';
}

// Path: frost
class Translations$frost$zh_CN extends Translations$frost$en {
  Translations$frost$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get retry => '重试';
  @override
  String get error => '错误';
  @override
  String get errorDetails => '错误详情';
  @override
  String get copyDetails => '复制详情';
  @override
  String get copied => '已复制';
  @override
  String get loading => '正在加载';
  @override
  String get actionSucceeded => '操作成功';
  @override
  String get actionFailed => '操作失败';
  @override
  String get loadFailed => '加载失败';
  @override
  String get noItems => '暂无内容';
  @override
  String get noMoreItems => '没有更多内容';
  @override
  String get pullToRefresh => '下拉刷新';
  @override
  String get releaseToRefresh => '松开刷新';
  @override
  String get refreshing => '正在刷新';
  @override
  String get refreshComplete => '刷新完成';
  @override
  String get refreshFailed => '刷新失败';
  @override
  String get previous => '上一个';
  @override
  String get next => '下一个';
  @override
  String get back => '返回';
  @override
  String get more => '更多';
  @override
  String get expandNavigation => '展开侧栏';
  @override
  String get collapseNavigation => '收起侧栏';
  @override
  String get clearText => '清除文字';
  @override
  String get search => '搜索';
  @override
  String noResults({required Object query}) => '未找到“${query}”的结果';
  @override
  String get clearSearch => '清除搜索';
  @override
  String get dismiss => '关闭';
  @override
  String get expandText => '展开';
  @override
  String get collapseText => '收起';
  @override
  String get showAll => '显示全部';
  @override
  String get copy => '复制';
  @override
  String get clearAll => '全部清除';
  @override
  String get showPassword => '显示密码';
  @override
  String get hidePassword => '隐藏密码';
  @override
  String get chooseDate => '选择日期';
  @override
  String get chooseTime => '选择时间';
  @override
  String get increment => '增加';
  @override
  String get decrement => '减少';
  @override
  String get reorderHandle => '调整顺序';
  @override
  String get sortAscending => '升序';
  @override
  String get sortDescending => '降序';
  @override
  String get play => '播放';
  @override
  String get pause => '暂停';
  @override
  String get loop => '循环';
  @override
  String get mute => '静音';
  @override
  String get unmute => '取消静音';
  @override
  String get fullscreen => '全屏';
  @override
  String get exitFullscreen => '退出全屏';
  @override
  String get reload => '重新加载';
  @override
  String get openInBrowser => '在浏览器中打开';
  @override
  String get minimize => '最小化';
  @override
  String get maximize => '最大化';
  @override
  String get restore => '还原';
  @override
  String get close => '关闭';
  @override
  String get cancel => '取消';
  @override
  String get apply => '应用';
  @override
  String get clear => '清除';
  @override
  String get choose => '选择';
  @override
  String get showInFolder => '在文件夹中显示';
  @override
  String selectedCount({required Object count}) => '已选 ${count} 项';
  @override
  String pageOf({required Object page, required Object total}) =>
      '第 ${page} 页，共 ${total} 页';
  @override
  String get selectAll => '全选';
  @override
  String get done => '完成';
  @override
  String itemPosition({required Object position, required Object total}) =>
      '第 ${position} 项，共 ${total} 项';
  @override
  String tableDimensions({required Object rows, required Object columns}) =>
      '${rows} 行，${columns} 列';
  @override
  String get taskQueued => '等待中';
  @override
  String get taskRunning => '下载中';
  @override
  String get taskPaused => '已暂停';
  @override
  String get taskCompleted => '已完成';
  @override
  String get taskFailed => '失败';
  @override
  String get taskCancelled => '已取消';
  @override
  String get remove => '移除';
  @override
  String get forward => '前进';
  @override
  String get stop => '停止';
  @override
  String get seek => '播放位置';
  @override
  String get send => '发送';
  @override
  String get attach => '添加附件';
  @override
  String get readerSettings => '阅读设置';
  @override
  String get textSize => '字号';
  @override
  String get lineSpacing => '行距';
  @override
  String get readingProgress => '阅读进度';
  @override
  String showReplies({required Object count}) => '显示 ${count} 条回复';
  @override
  String characterCount({required Object count, required Object limit}) =>
      '${count} / ${limit} 字';
  @override
  String moreMedia({required Object count}) => '还有 ${count} 张图片';
  @override
  String navigationCount({required Object count}) => '${count} 项';
  @override
  String navigationProgress({required Object progress}) => '已完成 ${progress}%';
  @override
  String get listSeparator => '，';
}

// Path: navigation
class Translations$navigation$zh_CN extends Translations$navigation$en {
  Translations$navigation$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get browse => '浏览';
  @override
  String get search => '搜索';
  @override
  String get downloads => '下载';
  @override
  String get settings => '设置';
  @override
  String get browseEmpty => '浏览喜欢的图源';
  @override
  String get searchEmpty => '通过标签查找作品';
  @override
  String get downloadsEmpty => '下载任务将显示在这里';
  @override
  String get settingsEmpty => '按喜好设置 BooruFlow';
}

// Path: settingsV2
class Translations$settingsV2$zh_CN extends Translations$settingsV2$en {
  Translations$settingsV2$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get predictiveBack => '预测性返回';
  @override
  String get predictiveBackScope => '预览 App 内的返回动作；返回桌面的动画由系统控制。';
  @override
  String get background => '背景材质';
  @override
  String get ambientBlur => '环境模糊';
  @override
  String get mica => '云母';
  @override
  String get backgroundOff => '关闭';
  @override
  String get backgroundIntensity => '强度';
  @override
  String get systemTransparencyReduced => '系统已降低透明度';
  @override
  String get customColour => '自定义颜色';
  @override
  String get appearance => '外观';
  @override
  String get browsing => '浏览';
  @override
  String get tone => '色调';
  @override
  String get neutral => '中性';
  @override
  String get cool => '冷色';
  @override
  String get warm => '暖色';
  @override
  String get accent => '强调色';
  @override
  String get customAccent => '自定义强调色';
  @override
  String get customHex => '强调色 HEX';
  @override
  String get invalidHex => '请输入六位 HEX 颜色。';
  @override
  String get accentRejected => '此强调色在当前表面上无法保持可读。';
  @override
  String get accentWarning => '此强调色对比度较低，仍要应用吗？';
  @override
  String get editAccount => '编辑账号';
  @override
  String get signOutConfirm => '移除此图源已保存的账号凭据？';
  @override
  String get licenses => '开源许可';
  @override
  String get checkUpdates => '检查更新';
  @override
  String get help => '帮助';
}

// Path: settingsDetails
class Translations$settingsDetails$zh_CN
    extends Translations$settingsDetails$en {
  Translations$settingsDetails$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get mode => '模式';
  @override
  String get custom => '自定义';
  @override
  String get change => '更改';
  @override
  String get routeCache => '路由缓存';
  @override
  String hostCount({required Object count}) => '${count} 个主机';
  @override
  String updatedAt({required Object time}) => '更新于 ${time}';
  @override
  String get sourceStatus => '图源状态';
  @override
  String get apiAndImages => 'API 与图片可用';
  @override
  String get apiOnly => 'API 可用 · 图片未通过';
  @override
  String get status => '状态';
  @override
  String get content => '内容';
  @override
  String editSourceAccount({required Object source}) => '编辑 ${source} 账号';
  @override
  String get proxyApplies => '应用后用于图源、图片和新的下载。';
  @override
  String version({required Object version, required Object build}) =>
      '版本 ${version} (${build})';
  @override
  String get communityTelegram => 'Telegram 群组';
  @override
  String get communityDiscord => 'Discord 服务器';
  @override
  String get savedVerifications => '已保存的验证';
  @override
  String get systemDnsShort => '系统 DNS';
  @override
  String get refresh => '刷新';
  @override
  String updateAvailable({required Object version}) => '有新版本 ${version}';
}

// Path: verificationPage
class Translations$verificationPage$zh_CN
    extends Translations$verificationPage$en {
  Translations$verificationPage$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get instructions => '在下方页面完成人机验证，然后点“完成验证并返回”。';
  @override
  String get opening => '正在打开网页';
  @override
  String get failed => '网页加载失败';
  @override
  String get closed => '验证窗口已关闭';
  @override
  String get failureHelp => '可以重新打开，或检查网络设置。';
  @override
  String get reopen => '重新打开';
  @override
  String signOut({required Object source}) => '退出 ${source} 账号？';
  @override
  String get signOutHelp => '账号信息会从此设备移除。';
  @override
  String get downloadAdded => '已加入下载';
  @override
  String get downloadFailed => '下载失败';
  @override
  String get linkCopied => '已复制链接';
  @override
  String get view => '查看';
  @override
  String get networkSettings => '网络设置';
}

// Path: ugoira
class Translations$ugoira$zh_CN extends Translations$ugoira$en {
  Translations$ugoira$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get iosFilesDestination => '其他格式保存在“文件”App › BooruFlow';
  @override
  String get iosFormatHelp => '动态 WebP 和 ZIP 保存到“文件”。';
  @override
  String get albumName => '相簿名';
  @override
  String get openSettings => '前往设置';
  @override
  String get androidDestination => '相册与下载文件夹';
  @override
  String get iosDestination => '保存到照片';
  @override
  String get format => '动图保存格式';
  @override
  String get losslessWebp => '无损动态 WebP';
  @override
  String get originalZip => '原始 ZIP';
  @override
  String get webpRecord => 'WebP · 动图';
  @override
  String get zipRecord => 'ZIP · 原始帧';
  @override
  String get ugoiraInvalidArchive => '动画压缩包无效。';
  @override
  String get ugoiraMetadataMissing => '动画缺少帧时长元数据。';
  @override
  String get ugoiraInvalidMetadata => '动画帧时长元数据无效。';
  @override
  String get ugoiraFrameMissing => '动画中有帧缺失。';
  @override
  String get ugoiraFrameCorrupt => '动画中有帧损坏。';
  @override
  String get ugoiraFrameSizeMismatch => '动画的帧尺寸不一致。';
  @override
  String get ugoiraFrameTooLarge => '动画帧超过大小限制。';
  @override
  String get ugoiraEncodeFailed => '动画编码失败。';
  @override
  String get ugoiraOutputTooLarge => '动画编码结果超过大小限制。';
}

// Path: downloads.messages
class Translations$downloads$messages$zh_CN
    extends Translations$downloads$messages$en {
  Translations$downloads$messages$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get storagePermanentlyDenied => '你已永久拒绝存储权限。\n请在设置中手动启用存储权限。';
  @override
  String get storageDenied => '你已拒绝存储权限。';
  @override
  String get deviceInfoError => '无法解析设备信息。';
  @override
  String get photosPermanentlyDenied => '你已永久拒绝照片权限。\n请在设置中手动启用照片权限。';
  @override
  String get photosDenied => '你已拒绝照片权限。';
  @override
  String get downloadTaskExists => '下载任务已存在。';
  @override
  String get imageFileExists => '图片文件已存在。';
  @override
  String downloadRetryWith({required Object name}) => '重试下载任务: ${name}';
  @override
  String downloadStartWith({required Object name}) => '开始下载任务: ${name}';
  @override
  String downloadCompletedWith({required Object name}) => '下载任务完成: ${name}';
  @override
  String downloadFailedWith({required Object name}) => '下载任务失败: ${name}';
  @override
  String saveFailedWith({required Object name}) => '保存失败: 任务 ${name}';
}

// Path: settings.sections
class Translations$settings$sections$zh_CN
    extends Translations$settings$sections$en {
  Translations$settings$sections$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get sourcesAndAccounts => '图源与账号';
  @override
  String get accounts => '账号';
  @override
  String get network => '网络';
  @override
  String get general => '通用';
  @override
  String get downloads => '下载';
}

// Path: settings.source
class Translations$settings$source$zh_CN
    extends Translations$settings$source$en {
  Translations$settings$source$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get defaultSource => '默认图源';
  @override
  String get supportedRatings => '支持的分级';
  @override
  String get safetyRating => '内容分级';
}

// Path: settings.account
class Translations$settings$account$zh_CN
    extends Translations$settings$account$en {
  Translations$settings$account$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get manageAllSubtitle => '图源分级与账号配置';
  @override
  String get noAccountRequired => '无需账号';
  @override
  String get openSignInPage => '打开登录页面';
  @override
  String get cookieHeader => 'Cookie 请求头';
  @override
  String get storedLocally => '仅保存在此设备';
  @override
  String get browserUserAgent => '浏览器 User-Agent';
  @override
  String get browserUserAgentHint => '使用与已登录浏览器相同的 User-Agent';
  @override
  String get required => '必填';
  @override
  String get optional => '选填';
  @override
  String get actions => '账号操作';
  @override
  String get save => '保存';
  @override
  String get verify => '验证';
  @override
  String get signOut => '退出登录';
  @override
  String get saved => '账号已保存';
  @override
  String get saveFailed => '无法保存账号';
  @override
  String get verified => '账号已验证';
  @override
  String get verificationFailed => '验证失败';
  @override
  String get username => '用户名';
  @override
  String get userId => '用户 ID';
  @override
  String get apiKey => 'API 密钥';
  @override
  String statusValue({required Object status}) => '状态 · ${status}';
  @override
  late final Translations$settings$account$statuses$zh_CN statuses =
      Translations$settings$account$statuses$zh_CN.internal(_root);
}

// Path: settings.network
class Translations$settings$network$zh_CN
    extends Translations$settings$network$en {
  Translations$settings$network$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get proxyCompact => '自定义代理';
  @override
  String get checkCompact => '检测';
  @override
  String get detailsCompact => '详情';
  @override
  String get advancedCompact => '高级';
  @override
  String get uncheckedCompact => '未检测';
  @override
  String get checkingCompact => '检测中';
  @override
  String get apiShort => 'API';
  @override
  String get imagesShort => '图片';
  @override
  String get saveCompact => '保存';
  @override
  String get proxyProtocol => '协议';
  @override
  String get proxyHost => '主机';
  @override
  String get proxyPort => '端口';
  @override
  String get proxyReachable => '可连接';
  @override
  String get proxyUnreachable => '无法连接';
  @override
  String get proxyProbe => '检测代理可用性';
  @override
  String get proxyProbeHint => '探测仅使用当前填写的代理，不会保存设置。每个图源独立检测并显示结果。';
  @override
  String get sourceAvailable => '可用';
  @override
  String get sourcePartial => '部分可用';
  @override
  String get sourceUnavailable => '不可用';
  @override
  String get checkAllSources => '检测全部';
  @override
  String get mediaAvailable => '图片：可用';
  @override
  String get mediaUnavailable => '图片：未通过检测或无测试图片';
  @override
  String get dnsDetails => 'DNS 路由详情（不参与可用性判定）';
  @override
  String get sourceProbeHelp =>
      '绿色：API 和图片均可用；黄色：部分通过；红色：检测失败。各图源并行检测，最多约 26 秒。';
  @override
  String get dnsProvider => 'DNS 服务';
  @override
  String sourceSummary({required Object available, required Object issues}) =>
      '${available} 个可用 · ${issues} 个异常';
  @override
  String get servicesTitle => '全部图源状态';
  @override
  String get servicesHint => 'IP 解析与 API 可用性分别检测；API 可用不代表所有图片均可下载。';
  @override
  String get noFallback =>
      'DNS 提供商用于下方的路由刷新。系统 DNS 模式不使用缓存 IP；绕过 SNI 模式使用缓存 IP，失败时不自动切换。';
  @override
  String checkProgress({
    required Object done,
    required Object total,
    required Object checked,
    required Object sources,
  }) => 'DNS 已完成 ${done}/${total} · API 已检测 ${checked}/${sources}';
  @override
  String checkSummary({
    required Object available,
    required Object total,
    required Object failed,
  }) => 'API 可用 ${available}/${total} · DNS 失败 ${failed} 项';
  @override
  String get loadingStatus => '正在读取缓存状态';
  @override
  String get apiChecking => 'API：检测中';
  @override
  String get apiAvailable => 'API：可用';
  @override
  String get apiFailed => 'API：不可用';
  @override
  String get apiUnchecked => 'API：尚未检测';
  @override
  String get dnsPending => '尚未解析 · 点击刷新路由获取 IP';
  @override
  String get dnsResolving => '正在解析';
  @override
  String get dnsResolved => '解析成功';
  @override
  String get dnsCached => '使用已缓存 IP · 尚未重新检测';
  @override
  String get dnsFailed => '解析失败 · 当前无可用路由';
  @override
  String get dnsQueued => '等待解析';
  @override
  String ipCachedAt({required Object time}) => 'IP 已缓存 · 更新于 ${time}';
  @override
  String get ipNotCached => 'IP 已解析 · 尚未写入缓存';
  @override
  String get connectionMode => '连接模式';
  @override
  String get proxyUrl => '代理 URL';
  @override
  String get proxyTitle => '自定义代理';
  @override
  String get proxyModeOverride =>
      '当前使用自定义代理，保留正常 SNI 和证书校验，不叠加“绕过 SNI”。连接模式在停用自定义代理后生效。';
  @override
  String get proxyApply => '应用';
  @override
  String get proxyDisable => '停用代理';
  @override
  String proxyActive({required Object endpoint}) => '已应用：${endpoint}（尚不代表连接成功）';
  @override
  String get proxyInactive => '未使用';
  @override
  String get proxyPending => '修改尚未应用，请点击“应用代理设置”。';
  @override
  String get proxyHelp => '输入代理地址后点击下方按钮。代理服务需要事先启动；应用后用于图源列表、图片和新的下载请求。';
  @override
  String get proxyCheckHelp =>
      '自定义代理优先于缓存 IP 路由。应用后请用下方的图源 API 检测确认连接；DNS 解析成功不代表代理可用。';
  @override
  String get proxyInvalid => '请分别填写有效的 IP 或主机名和端口（1–65535），地址栏不需要填写协议或路径。';
  @override
  String get proxyHint => '选填 · 例如 http://127.0.0.1:7890';
  @override
  String get applyAndRouteCache => '应用与路由缓存';
  @override
  String get apply => '应用网络设置';
  @override
  String get refreshRoutes => '刷新路由';
  @override
  String get routeCacheUnavailable => '无法获取路由缓存';
  @override
  String routeCacheStatus({required Object hosts, required Object revision}) =>
      '${hosts} 个主机 · 修订 ${revision}';
  @override
  String get applied => '网络设置已应用';
  @override
  String get invalidSettings => '网络设置无效';
  @override
  String get routeRefreshFailed => '路由刷新失败';
  @override
  String get systemDns => '使用系统 DNS';
  @override
  String get sniBypass => '绕过 SNI';
}

// Path: settings.languageDialog
class Translations$settings$languageDialog$zh_CN
    extends Translations$settings$languageDialog$en {
  Translations$settings$languageDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '语言';
}

// Path: settings.themeModeDialog
class Translations$settings$themeModeDialog$zh_CN
    extends Translations$settings$themeModeDialog$en {
  Translations$settings$themeModeDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '主题模式';
}

// Path: settings.downloadDirectoryDialog
class Translations$settings$downloadDirectoryDialog$zh_CN
    extends Translations$settings$downloadDirectoryDialog$en {
  Translations$settings$downloadDirectoryDialog$zh_CN.internal(
    TranslationsZhCn root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '下载目录';
  @override
  String get pickerTitle => '选择目录';
  @override
  String get pick => '选择目录';
  @override
  late final Translations$settings$downloadDirectoryDialog$messages$zh_CN
  messages =
      Translations$settings$downloadDirectoryDialog$messages$zh_CN.internal(
        _root,
      );
}

// Path: settings.bypassSniDialog
class Translations$settings$bypassSniDialog$zh_CN
    extends Translations$settings$bypassSniDialog$en {
  Translations$settings$bypassSniDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '绕过 SNI';
}

// Path: settings.columnsPerRowDialog
class Translations$settings$columnsPerRowDialog$zh_CN
    extends Translations$settings$columnsPerRowDialog$en {
  Translations$settings$columnsPerRowDialog$zh_CN.internal(
    TranslationsZhCn root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每行列数';
}

// Path: settings.maxSegmentsPerTaskDialog
class Translations$settings$maxSegmentsPerTaskDialog$zh_CN
    extends Translations$settings$maxSegmentsPerTaskDialog$en {
  Translations$settings$maxSegmentsPerTaskDialog$zh_CN.internal(
    TranslationsZhCn root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每个下载任务的最大分段数';
}

// Path: settings.account.statuses
class Translations$settings$account$statuses$zh_CN
    extends Translations$settings$account$statuses$en {
  Translations$settings$account$statuses$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get notConfigured => '尚未配置';
  @override
  String get configuredUnverified => '已配置，尚未验证';
  @override
  String get verified => '已验证';
  @override
  String get rejected => '已被拒绝';
}

// Path: settings.downloadDirectoryDialog.messages
class Translations$settings$downloadDirectoryDialog$messages$zh_CN
    extends Translations$settings$downloadDirectoryDialog$messages$en {
  Translations$settings$downloadDirectoryDialog$messages$zh_CN.internal(
    TranslationsZhCn root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get setToPlatformDefault => '下载目录已设为平台默认。';
  @override
  String get pathNotAbsolute => '路径必须是绝对路径。';
  @override
  String get pathNotWritable => '路径不可写入。';
}

/// The flat map containing all translations for locale <zh-CN>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhCn {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
          'generic.ok' => '确定',
          'generic.cancel' => '取消',
          'generic.clear' => '清除',
          'generic.confirm' => '确认',
          'generic.enabled' => '启用',
          'generic.disabled' => '停用',
          'generic.copiedWithValue' =>
            ({required Object value}) => '已复制到剪贴板: ${value}',
          'generic.errorWithValue' =>
            ({required Object value}) => '发生错误: ${value}',
          'generic.loading' => '正在加载',
          'generic.loadFailed' => '加载失败',
          'generic.retry' => '重试',
          'generic.noMoreData' => '没有更多数据',
          'generic.notFound' => '未找到内容',
          'booruError.invalidRequest' => '请求参数无效。',
          'booruError.unsupportedCapability' => '当前图源不支持此操作。',
          'booruError.authenticationRequired' => '请登录当前图源后重试。',
          'booruError.authenticationRejected' => '图源拒绝了账号凭据。',
          'booruError.permissionDenied' => '图源拒绝访问此资源。',
          'booruError.rateLimited' => '图源暂时限制了请求，稍后会自动恢复。',
          'booruError.challengeRequired' =>
            '图源要求浏览器验证。可尝试在浏览器中打开图源完成验证，或选择其他图源。',
          'booruError.routeUnavailable' =>
            '当前域名没有可用路由。请在网络设置中刷新路由；不会回退到系统 DNS。',
          'booruError.sourceUnavailable' => '当前图源暂时不可用。',
          'booruError.network' => '网络请求失败。请检查网络连接后重试。',
          'booruError.timeout' => '请求超时。请检查网络连接，或稍后重试。',
          'booruError.invalidResponse' => '图源返回了无法解析的响应。',
          'booruError.unsafeRedirect' => '图源返回了不安全的重定向。',
          'booruError.mediaValidationFailed' => '媒体验证或解码失败。',
          'booruError.cancelled' => '请求已取消。',
          'booruError.internal' => '图源引擎发生内部错误。',
          'update.checkUpdateStart' => '正在检查更新',
          'update.checkUpdateFailed' => '检查更新失败，请检查你的网络连接。',
          'update.selectDownloadUrlFailed' =>
            '找不到下载链接。\n请访问项目页面手动更新，或在项目 Issue 页面寻求帮助。',
          'update.newVersionFound' =>
            ({required Object version}) =>
                '发现新版本: ${version}。请转到“关于”页面并点击“下载更新”。',
          'update.noNewVersionFound' => '没有新版本。',
          'postList.short' => '首页',
          'postList.title' => '首页',
          'postList.titleWithTags' =>
            ({required Object tags}) => '带有标签的帖子: ${tags}',
          'postDetail.fullscreen' => '全屏查看',
          'postDetail.notFound' => '找不到这个作品',
          'postDetail.parentCount' =>
            ({required Object count}) => '${count} 个父作品',
          'postDetail.childCount' =>
            ({required Object count}) => '${count} 个子作品',
          'postDetail.zoomIn' => '放大',
          'postDetail.zoomOut' => '缩小',
          'postDetail.originalFailed' => '原图加载失败',
          'postDetail.previewShown' => '现在显示的是预览图。',
          'postDetail.uploadedAt' => ({required Object date}) => '${date} 上传',
          'postDetail.pixels' => '像素',
          'postDetail.dimensions' => '尺寸',
          'postDetail.searchTag' => '搜索此标签',
          'postDetail.addToSearch' => '添加到搜索',
          'postDetail.excludeTag' => '排除此标签',
          'postDetail.openSource' => '打开来源',
          'postDetail.resetZoom' => '重置缩放',
          'postDetail.ratingGeneral' => '一般',
          'postDetail.ratingSensitive' => '敏感',
          'postDetail.ratingQuestionable' => '可疑',
          'postDetail.ratingExplicit' => '成人',
          'postDetail.ratingUnknown' => '未知',
          'postDetail.titleWithId' => ({required Object id}) => '帖子: ${id}',
          'postDetail.tags' => '标签',
          'postDetail.details' => '详细信息',
          'postDetail.actions' => '操作',
          'postDetail.rating' => '分级',
          'postDetail.fileType' => '文件类型',
          'postDetail.viewOriginal' => '查看原图',
          'postDetail.download' => '下载',
          'postDetail.relatedLoadFailed' => '关联图片加载失败，可以重试。',
          'postDetail.createdAt' => '创建于',
          'postDetail.author' => '作者',
          'postDetail.unknownAuthor' => '未知',
          'postDetail.imageSource' => '图源',
          'postDetail.source' => '来源',
          'postDetail.width' => '宽度',
          'postDetail.height' => '高度',
          'postDetail.score' => '评分',
          'postDetail.size' => '大小',
          'postDetail.parent' => '父 ID',
          'postDetail.hasChildren' => '有子帖子',
          'postDetail.similarPosts' => '相关图片',
          'postDetail.parentPost' => '父帖子',
          'postDetail.childPost' => '子帖子',
          'postSearch.title' => '搜索',
          'imageZoom.title' => '缩放图片',
          'downloads.fileMissing' => '文件已不在原位置',
          'downloads.locationMissing' => '找不到文件或文件夹',
          'downloads.redownload' => '重新下载',
          'downloads.remove' => '删除',
          'downloads.activeTasks' =>
            ({required Object count}) => '正在下载 ${count} 项',
          'downloads.failedTasks' =>
            ({required Object count}) => '${count} 项下载失败',
          'downloads.retryAll' => '全部重试',
          'downloads.today' => '今天',
          'downloads.yesterday' => '昨天',
          'downloads.transferRate' => ({required Object value}) => '${value}/s',
          'downloads.remainingSeconds' =>
            ({required Object count}) => '约 ${count} 秒',
          'downloads.remainingMinutes' =>
            ({required Object count}) => '约 ${count} 分钟',
          'downloads.remainingHours' =>
            ({required Object count}) => '约 ${count} 小时',
          'downloads.format' => '格式',
          'downloads.startedAt' => '开始于',
          'downloads.browse' => '去浏览',
          'downloads.all' => '全部',
          'downloads.pause' => '暂停',
          'downloads.resume' => '继续',
          'downloads.pauseAll' => '全部暂停',
          'downloads.resumeAll' => '全部继续',
          'downloads.retryFailed' => '重试失败项',
          'downloads.clearCompleted' => '清除已完成',
          'downloads.openDirectory' => '打开下载目录',
          'downloads.openPost' => '打开作品',
          'downloads.batch' => '批量下载',
          'downloads.batchProgress' =>
            ({required Object completed, required Object total}) =>
                '${completed} / ${total}',
          'downloads.path' => '保存路径',
          'downloads.taskDetails' => '任务详情',
          'downloads.viewLog' => '日志',
          'downloads.title' => '下载',
          'downloads.tasksTitle' => '下载任务',
          'downloads.noTasks' => '暂无下载任务',
          'downloads.noTasksMessage' => '下载的图片会显示在这里。',
          'downloads.total' => '总数',
          'downloads.active' => '进行中',
          'downloads.saved' => '已保存',
          'downloads.completed' => '已完成',
          'downloads.failed' => '失败',
          'downloads.waiting' => '等待中',
          'downloads.downloading' => '下载中',
          'downloads.needsAttention' => '需要处理',
          'downloads.queued' => '排队中',
          'downloads.running' => '正在下载',
          'downloads.paused' => '已暂停',
          'downloads.downloaded' => '已下载',
          'downloads.cancelled' => '已取消',
          'downloads.savePending' => '等待保存',
          'downloads.saving' => '正在保存',
          'downloads.saveFailed' => '保存失败',
          'downloads.retrySave' => '重试保存',
          'downloads.cancel' => '取消',
          'downloads.deleteTask' => '删除任务',
          'downloads.sync' => '同步',
          'downloads.syncFailed' => '下载状态同步失败',
          'downloads.actionFailed' => '下载操作失败',
          'downloads.expand' => '展开',
          'downloads.collapse' => '收起',
          'downloads.messages.storagePermanentlyDenied' =>
            '你已永久拒绝存储权限。\n请在设置中手动启用存储权限。',
          'downloads.messages.storageDenied' => '你已拒绝存储权限。',
          'downloads.messages.deviceInfoError' => '无法解析设备信息。',
          'downloads.messages.photosPermanentlyDenied' =>
            '你已永久拒绝照片权限。\n请在设置中手动启用照片权限。',
          'downloads.messages.photosDenied' => '你已拒绝照片权限。',
          'downloads.messages.downloadTaskExists' => '下载任务已存在。',
          'downloads.messages.imageFileExists' => '图片文件已存在。',
          'downloads.messages.downloadRetryWith' =>
            ({required Object name}) => '重试下载任务: ${name}',
          'downloads.messages.downloadStartWith' =>
            ({required Object name}) => '开始下载任务: ${name}',
          'downloads.messages.downloadCompletedWith' =>
            ({required Object name}) => '下载任务完成: ${name}',
          'downloads.messages.downloadFailedWith' =>
            ({required Object name}) => '下载任务失败: ${name}',
          'downloads.messages.saveFailedWith' =>
            ({required Object name}) => '保存失败: 任务 ${name}',
          'about.title' => '关于',
          'about.projectUrl' => '项目网址',
          'about.publishPage' => '发布页面',
          'about.appVersion' => '应用版本',
          'about.freepivPromotionTitle' => '试试 freepiv',
          'about.freepivPromotionSubtitle' => '现代、流畅的跨平台 Pixiv 第三方客户端。',
          'about.discussion' => '讨论',
          'about.downloadUpdate' => '下载更新',
          'about.downloadUpdateHint' => '通过浏览器下载适合你设备的最新版本。',
          'settings.title' => '设置',
          'settings.theme' => '主题',
          'settings.language' => '语言',
          'settings.bypassSni' => '绕过 SNI',
          'settings.downloadDirectory' => '下载目录',
          'settings.defaultToPlatformSettings' => '使用平台默认设置',
          'settings.columnsPerRow' => '每行列数',
          'settings.maxConcurrentDownloads' => '同时下载',
          'settings.maxSegmentsPerTask' => '每个任务的分段数',
          'settings.platformDefault' => '平台默认',
          'settings.system' => '跟随系统',
          'settings.light' => '浅色',
          'settings.dark' => '深色',
          'settings.auto' => '自动',
          'settings.downloadsOverview' => '保存位置与下载并发',
          'settings.sections.sourcesAndAccounts' => '图源与账号',
          'settings.sections.accounts' => '账号',
          'settings.sections.network' => '网络',
          'settings.sections.general' => '通用',
          'settings.sections.downloads' => '下载',
          'settings.source.defaultSource' => '默认图源',
          'settings.source.supportedRatings' => '支持的分级',
          'settings.source.safetyRating' => '内容分级',
          'settings.account.manageAllSubtitle' => '图源分级与账号配置',
          'settings.account.noAccountRequired' => '无需账号',
          'settings.account.openSignInPage' => '打开登录页面',
          'settings.account.cookieHeader' => 'Cookie 请求头',
          'settings.account.storedLocally' => '仅保存在此设备',
          'settings.account.browserUserAgent' => '浏览器 User-Agent',
          'settings.account.browserUserAgentHint' => '使用与已登录浏览器相同的 User-Agent',
          'settings.account.required' => '必填',
          'settings.account.optional' => '选填',
          'settings.account.actions' => '账号操作',
          'settings.account.save' => '保存',
          'settings.account.verify' => '验证',
          'settings.account.signOut' => '退出登录',
          'settings.account.saved' => '账号已保存',
          'settings.account.saveFailed' => '无法保存账号',
          'settings.account.verified' => '账号已验证',
          'settings.account.verificationFailed' => '验证失败',
          'settings.account.username' => '用户名',
          'settings.account.userId' => '用户 ID',
          'settings.account.apiKey' => 'API 密钥',
          'settings.account.statusValue' =>
            ({required Object status}) => '状态 · ${status}',
          'settings.account.statuses.notConfigured' => '尚未配置',
          'settings.account.statuses.configuredUnverified' => '已配置，尚未验证',
          'settings.account.statuses.verified' => '已验证',
          'settings.account.statuses.rejected' => '已被拒绝',
          'settings.network.proxyCompact' => '自定义代理',
          'settings.network.checkCompact' => '检测',
          'settings.network.detailsCompact' => '详情',
          'settings.network.advancedCompact' => '高级',
          'settings.network.uncheckedCompact' => '未检测',
          'settings.network.checkingCompact' => '检测中',
          'settings.network.apiShort' => 'API',
          'settings.network.imagesShort' => '图片',
          'settings.network.saveCompact' => '保存',
          'settings.network.proxyProtocol' => '协议',
          'settings.network.proxyHost' => '主机',
          'settings.network.proxyPort' => '端口',
          'settings.network.proxyReachable' => '可连接',
          'settings.network.proxyUnreachable' => '无法连接',
          'settings.network.proxyProbe' => '检测代理可用性',
          'settings.network.proxyProbeHint' =>
            '探测仅使用当前填写的代理，不会保存设置。每个图源独立检测并显示结果。',
          'settings.network.sourceAvailable' => '可用',
          'settings.network.sourcePartial' => '部分可用',
          'settings.network.sourceUnavailable' => '不可用',
          'settings.network.checkAllSources' => '检测全部',
          'settings.network.mediaAvailable' => '图片：可用',
          'settings.network.mediaUnavailable' => '图片：未通过检测或无测试图片',
          'settings.network.dnsDetails' => 'DNS 路由详情（不参与可用性判定）',
          'settings.network.sourceProbeHelp' =>
            '绿色：API 和图片均可用；黄色：部分通过；红色：检测失败。各图源并行检测，最多约 26 秒。',
          'settings.network.dnsProvider' => 'DNS 服务',
          'settings.network.sourceSummary' =>
            ({required Object available, required Object issues}) =>
                '${available} 个可用 · ${issues} 个异常',
          'settings.network.servicesTitle' => '全部图源状态',
          'settings.network.servicesHint' =>
            'IP 解析与 API 可用性分别检测；API 可用不代表所有图片均可下载。',
          'settings.network.noFallback' =>
            'DNS 提供商用于下方的路由刷新。系统 DNS 模式不使用缓存 IP；绕过 SNI 模式使用缓存 IP，失败时不自动切换。',
          'settings.network.checkProgress' =>
            ({
              required Object done,
              required Object total,
              required Object checked,
              required Object sources,
            }) => 'DNS 已完成 ${done}/${total} · API 已检测 ${checked}/${sources}',
          'settings.network.checkSummary' =>
            ({
              required Object available,
              required Object total,
              required Object failed,
            }) => 'API 可用 ${available}/${total} · DNS 失败 ${failed} 项',
          'settings.network.loadingStatus' => '正在读取缓存状态',
          'settings.network.apiChecking' => 'API：检测中',
          'settings.network.apiAvailable' => 'API：可用',
          'settings.network.apiFailed' => 'API：不可用',
          'settings.network.apiUnchecked' => 'API：尚未检测',
          'settings.network.dnsPending' => '尚未解析 · 点击刷新路由获取 IP',
          'settings.network.dnsResolving' => '正在解析',
          'settings.network.dnsResolved' => '解析成功',
          'settings.network.dnsCached' => '使用已缓存 IP · 尚未重新检测',
          'settings.network.dnsFailed' => '解析失败 · 当前无可用路由',
          'settings.network.dnsQueued' => '等待解析',
          'settings.network.ipCachedAt' =>
            ({required Object time}) => 'IP 已缓存 · 更新于 ${time}',
          'settings.network.ipNotCached' => 'IP 已解析 · 尚未写入缓存',
          'settings.network.connectionMode' => '连接模式',
          'settings.network.proxyUrl' => '代理 URL',
          'settings.network.proxyTitle' => '自定义代理',
          'settings.network.proxyModeOverride' =>
            '当前使用自定义代理，保留正常 SNI 和证书校验，不叠加“绕过 SNI”。连接模式在停用自定义代理后生效。',
          'settings.network.proxyApply' => '应用',
          'settings.network.proxyDisable' => '停用代理',
          'settings.network.proxyActive' =>
            ({required Object endpoint}) => '已应用：${endpoint}（尚不代表连接成功）',
          'settings.network.proxyInactive' => '未使用',
          'settings.network.proxyPending' => '修改尚未应用，请点击“应用代理设置”。',
          'settings.network.proxyHelp' =>
            '输入代理地址后点击下方按钮。代理服务需要事先启动；应用后用于图源列表、图片和新的下载请求。',
          'settings.network.proxyCheckHelp' =>
            '自定义代理优先于缓存 IP 路由。应用后请用下方的图源 API 检测确认连接；DNS 解析成功不代表代理可用。',
          'settings.network.proxyInvalid' =>
            '请分别填写有效的 IP 或主机名和端口（1–65535），地址栏不需要填写协议或路径。',
          'settings.network.proxyHint' => '选填 · 例如 http://127.0.0.1:7890',
          'settings.network.applyAndRouteCache' => '应用与路由缓存',
          'settings.network.apply' => '应用网络设置',
          'settings.network.refreshRoutes' => '刷新路由',
          'settings.network.routeCacheUnavailable' => '无法获取路由缓存',
          'settings.network.routeCacheStatus' =>
            ({required Object hosts, required Object revision}) =>
                '${hosts} 个主机 · 修订 ${revision}',
          'settings.network.applied' => '网络设置已应用',
          'settings.network.invalidSettings' => '网络设置无效',
          'settings.network.routeRefreshFailed' => '路由刷新失败',
          'settings.network.systemDns' => '使用系统 DNS',
          'settings.network.sniBypass' => '绕过 SNI',
          'settings.languageDialog.title' => '语言',
          'settings.themeModeDialog.title' => '主题模式',
          'settings.downloadDirectoryDialog.title' => '下载目录',
          'settings.downloadDirectoryDialog.pickerTitle' => '选择目录',
          'settings.downloadDirectoryDialog.pick' => '选择目录',
          'settings.downloadDirectoryDialog.messages.setToPlatformDefault' =>
            '下载目录已设为平台默认。',
          'settings.downloadDirectoryDialog.messages.pathNotAbsolute' =>
            '路径必须是绝对路径。',
          'settings.downloadDirectoryDialog.messages.pathNotWritable' =>
            '路径不可写入。',
          'settings.bypassSniDialog.title' => '绕过 SNI',
          'settings.columnsPerRowDialog.title' => '每行列数',
          'settings.maxSegmentsPerTaskDialog.title' => '每个下载任务的最大分段数',
          'discovery.mode' => '模式',
          'discovery.timeRange' => '时间范围',
          'discovery.chooseDate' => '指定日期',
          'discovery.menuWeek' => '本周',
          'discovery.menuMonth' => '本月',
          'discovery.ratingsTitle' => '内容分级',
          'discovery.ratingLabel' => '分级',
          'discovery.ratingSeparator' => '、',
          'discovery.calendarRanges' => '自然周期',
          'discovery.rollingRanges' => '滚动区间',
          'discovery.tooManyRequests' => '请求太频繁',
          'discovery.copyLink' => '复制链接',
          'discovery.copyQueryLink' => '复制查询链接',
          'discovery.copyImage' => '复制图片',
          'discovery.searchAuthor' => '搜索此画师',
          'discovery.mediaAnimation' => '动图',
          'discovery.mediaVideo' => '视频',
          'discovery.mediaCollection' => '关联图片',
          'discovery.retryIn' =>
            ({required Object seconds}) => '${seconds} 秒后重试',
          'discovery.searchResults' => '搜索结果',
          'discovery.searchTermsTitle' =>
            ({required Object count}) => '搜索${count}个词条',
          'discovery.allAvailable' => '全部可用内容',
          'discovery.defaultRatingsHint' => '不选时显示当前图源能访问的全部内容。',
          'discovery.resetFilters' => '恢复默认',
          'discovery.unsupportedRatings' => '当前图源不支持所选分级。',
          'discovery.noFilteredPosts' => '没有符合筛选的内容',
          'discovery.noSearchResults' => '没有找到符合此查询的内容。',
          'discovery.noFeedPosts' => '当前图源暂时没有可展示的内容。',
          'discovery.historicalPopular' => '历史热门',
          'discovery.calendarDay' => '自然日',
          'discovery.calendarWeek' => '自然周',
          'discovery.calendarMonth' => '自然月',
          'discovery.latest' => '最新',
          'discovery.popular' => '热门',
          'discovery.today' => '今日',
          'discovery.thisWeek' => '本周',
          'discovery.thisMonth' => '本月',
          'discovery.lastDay' => '最近 24 小时',
          'discovery.lastThreeDays' => '最近 3 天',
          'discovery.lastWeek' => '最近一周',
          'discovery.lastMonth' => '最近一个月',
          'discovery.lastThreeMonths' => '最近三个月',
          'discovery.lastSixMonths' => '最近六个月',
          'discovery.lastYear' => '最近一年',
          'discovery.rankingComplete' => '榜单已全部加载',
          'discovery.latestFallback' => '此图源仅支持最新帖子。',
          'discovery.filters' => '筛选',
          'discovery.loadMore' => '加载更多',
          'discovery.clearHistory' => '清空',
          'discovery.recentSearches' => '最近搜索',
          'discovery.noRecentSearches' => '暂无最近搜索',
          'discovery.myTags' => '我的标签',
          'discovery.commonTags' => '常用标签',
          'discovery.moreTags' => '查看更多',
          'discovery.tagSource' => '适用图源',
          'discovery.allTagSources' => '通用',
          'discovery.manageTags' => '标签管理',
          'discovery.manageTagsAction' => '管理',
          'discovery.addTagAction' => '添加',
          'discovery.deleteTag' => '删除',
          'discovery.addTag' => '添加标签',
          'discovery.noCustomTags' => '还没有自定义标签',
          'discovery.customTagsHint' => '给常用标签起个好记的名字，搜索时更容易找到。',
          'discovery.addCustomTag' => '添加为自定义标签',
          'discovery.editTag' => '编辑自定义标签',
          'discovery.canonicalTag' => '图源标签',
          'discovery.displayName' => '显示名称（可选）',
          'discovery.invalidTag' => '请输入一个非空且不含空格的标签。',
          'discovery.queryHint' => '搜索标签',
          'discovery.unverifiedTag' => '部分标签尚未在当前图源验证，仍可提交搜索。',
          'discovery.verifiedTag' => '已在当前图源验证',
          'discovery.noSuggestions' => '没有建议',
          'discovery.localFallback' => '在线补全暂不可用，仍可使用本地建议。',
          'discovery.retryTags' => '重试常用标签',
          'discovery.artist' => '画师',
          'discovery.character' => '角色',
          'discovery.copyright' => '作品',
          'discovery.meta' => '元标签',
          'discovery.general' => '通用',
          'discovery.random' => '随机',
          'discovery.lifetimeViews' => '累计浏览量',
          'discovery.lifetimeFavorites' => '累计收藏数',
          'mediaError.videoProxyBypassed' => '视频不支持当前的 SOCKS 代理，本次播放使用了直连。',
          'mediaError.videoFailed' => '视频播放失败',
          'mediaError.downloadOriginal' => '下载原文件',
          'mediaError.previewUnsupported' => '无法预览',
          'mediaError.title' => '图片加载失败',
          'mediaError.details' => '错误详情',
          'mediaError.copyDetails' => '复制详情',
          'mediaError.decodeFailed' => '下载的图片无法解码。重试会清除这张图片的缓存并重新下载。',
          'webChallenge.title' => '网页验证',
          'webChallenge.open' => '打开网页验证',
          'webChallenge.windowTitle' =>
            ({required Object source}) => '${source} · 完成验证后关闭窗口',
          'webChallenge.instructions' =>
            '请手动完成网页中的人机验证，完成后返回或关闭窗口。应用会保存验证数据并重新加载图源。',
          'webChallenge.finish' => '完成验证并返回',
          'webChallenge.saving' => '正在读取并验证网页会话',
          'webChallenge.waiting' => '正在进行网页验证',
          'webChallenge.clear' => '清空',
          'webChallenge.clearAll' => '清空全部网页验证数据',
          'webChallenge.clearDescription' => '清除 Cookie、浏览器标识和网页缓存。',
          'webChallenge.cleared' => '网页验证数据已清空',
          'webChallenge.verified' => '已验证，可访问',
          'webChallenge.saved' => '已保存，等待重新验证',
          'webChallenge.empty' => '没有已保存的验证数据',
          'webChallenge.failed' => '网页验证未完成，请重试。',
          'webChallenge.pageLoadFailed' => '网页加载失败，可重新打开验证窗口或检查网络设置。',
          'webChallenge.webViewUnavailable' => '当前平台无法使用网页组件。',
          'webChallenge.windowFailed' => '无法打开网页验证。',
          'webChallenge.runtimeMissing' =>
            '找不到 Microsoft Edge WebView2 Runtime，请安装或更新后重试。',
          'webChallenge.proxyUnsupported' => '网页组件暂不支持当前代理设置，请更换代理配置后重试。',
          'webChallenge.busy' => '另一个网页验证或清理操作正在进行。',
          'webChallenge.cancelled' => '已取消网页验证。',
          'webChallenge.timedOut' => '网页验证超时，请重新打开网页。',
          'webChallenge.storageFailed' => '无法保存或清空验证数据，原来的会话仍被保留。',
          'webChallenge.captureFailed' => '无法读取网页会话，请重新打开网页验证。',
          'webChallenge.cleanupFailed' => '网页数据尚未清理完成，请稍后再次清空。',
          'webChallenge.operationSuperseded' => '验证已被清空操作或网络设置变更取消。',
          'webChallenge.noCookies' => '网页尚未提供可用的验证数据，请完成人机验证后再返回。',
          'nativeWindow.minimize' => '最小化',
          'nativeWindow.maximize' => '最大化',
          'nativeWindow.restore' => '还原',
          'nativeWindow.close' => '关闭',
          'batchDownload.title' => '批量下载',
          'batchDownload.close' => '关闭',
          'batchDownload.limitTitle' => '这次最多获取多少张？',
          'batchDownload.limitHint' => '按当前搜索条件逐页获取，达到上限后停止。',
          'batchDownload.limitLabel' => '最多获取',
          'batchDownload.positiveInteger' => '请输入大于 0 的整数。',
          'batchDownload.start' => '获取图片',
          'batchDownload.fetchLimit' =>
            ({required Object count}) => '/ 最多 ${count} 张',
          'batchDownload.fetching' => '已找到的图片',
          'batchDownload.progress' =>
            ({required Object current, required Object total}) =>
                '${current} / ${total}',
          'batchDownload.fetchProgress' =>
            ({required Object current, required Object limit}) =>
                '已获取 ${current} 张，最多 ${limit} 张',
          'batchDownload.stopHint' => '随时可以停止，并使用已找到的图片。',
          'batchDownload.stop' => '停止获取',
          'batchDownload.found' => '张图片可以下载',
          'batchDownload.limitReached' => '已达到获取上限，可能还有更多搜索结果。',
          'batchDownload.exhausted' => '已获取全部匹配结果。',
          'batchDownload.permissionDenied' => '下载权限不可用，请在系统设置中检查应用权限后重试。',
          'batchDownload.enqueueFailed' => '无法加入下载任务，请检查保存位置及剩余空间后重试。',
          'batchDownload.stopped' => '已停止获取，可以下载已找到的图片。',
          'batchDownload.empty' => '没有找到符合条件的图片。',
          'batchDownload.stalled' => '源站分页未能继续推进。已保留结果，可重试或使用已有图片。',
          'batchDownload.sessionChanged' => '源站设置已改变。请关闭窗口后重新获取，或使用已找到的图片。',
          'batchDownload.fetchFailed' => '获取未完成。已保留结果，可重试或使用已有图片。',
          'batchDownload.countLabel' => '下载数量',
          'batchDownload.all' => '全部',
          'batchDownload.countRange' =>
            ({required Object max}) => '请输入 1～${max}',
          'batchDownload.orderHint' => '按当前搜索结果顺序下载前 N 张图片。',
          'batchDownload.folderLabel' => '文件夹名',
          'batchDownload.folderHint' => '例如：九月收藏',
          'batchDownload.folderPlaceholder' => '你的文件夹',
          'batchDownload.invalidFolder' =>
            '请输入 1～100 个字符，不含路径分隔符、保留名称、首尾空格或末尾句点。',
          'batchDownload.folderHelp' => '同名文件夹会直接沿用，已有文件不会被覆盖。',
          'batchDownload.locationFailed' => '无法获取保存位置。',
          'batchDownload.photos' => '照片库',
          'batchDownload.photosHint' =>
            'iOS 将本次图片保存为源站文件夹下的相册，复用相册需要照片库完整访问权限。',
          'batchDownload.enqueue' =>
            ({required Object count}) => '加入下载队列 · ${count} 张',
          'batchDownload.enqueueing' => '正在加入下载队列',
          'batchDownload.preparing' =>
            ({required Object current, required Object total}) =>
                '正在准备 ${current} / ${total} 张图片',
          'batchDownload.added' => '个任务已加入下载队列',
          'batchDownload.backgroundHint' => '可以关闭窗口。应用运行期间会继续入队，再次点击此入口可查看结果。',
          'batchDownload.queueHint' => '图片下载进度可在下载列表中查看。',
          'batchDownload.failedHint' =>
            ({required Object count}) => '${count} 张未能加入队列。',
          'batchDownload.retryFailed' => '重试失败项',
          'batchDownload.queued' =>
            ({required Object added, required Object failed}) =>
                '批量任务：已加入 ${added} 张，入队失败 ${failed} 张。',
          'batchDownload.completed' =>
            ({required Object saved, required Object failed}) =>
                '批量下载结束：已保存 ${saved} 张，失败或取消 ${failed} 张。',
          'batchDownload.done' => '完成',
          'batchDownload.back' => '返回',
          'batchDownload.first' => '前 N 张',
          'batchDownload.addedCount' =>
            ({required Object count}) => '已加入 ${count} 张',
          'batchDownload.savedTo' =>
            ({required Object folder}) => '保存到“${folder}”',
          'batchDownload.viewDownloads' => '查看下载',
          'frost.retry' => '重试',
          'frost.error' => '错误',
          'frost.errorDetails' => '错误详情',
          'frost.copyDetails' => '复制详情',
          'frost.copied' => '已复制',
          'frost.loading' => '正在加载',
          'frost.actionSucceeded' => '操作成功',
          'frost.actionFailed' => '操作失败',
          'frost.loadFailed' => '加载失败',
          'frost.noItems' => '暂无内容',
          'frost.noMoreItems' => '没有更多内容',
          'frost.pullToRefresh' => '下拉刷新',
          'frost.releaseToRefresh' => '松开刷新',
          'frost.refreshing' => '正在刷新',
          'frost.refreshComplete' => '刷新完成',
          'frost.refreshFailed' => '刷新失败',
          'frost.previous' => '上一个',
          'frost.next' => '下一个',
          'frost.back' => '返回',
          'frost.more' => '更多',
          'frost.expandNavigation' => '展开侧栏',
          'frost.collapseNavigation' => '收起侧栏',
          'frost.clearText' => '清除文字',
          'frost.search' => '搜索',
          'frost.noResults' => ({required Object query}) => '未找到“${query}”的结果',
          'frost.clearSearch' => '清除搜索',
          'frost.dismiss' => '关闭',
          'frost.expandText' => '展开',
          'frost.collapseText' => '收起',
          'frost.showAll' => '显示全部',
          'frost.copy' => '复制',
          'frost.clearAll' => '全部清除',
          'frost.showPassword' => '显示密码',
          'frost.hidePassword' => '隐藏密码',
          'frost.chooseDate' => '选择日期',
          'frost.chooseTime' => '选择时间',
          'frost.increment' => '增加',
          'frost.decrement' => '减少',
          'frost.reorderHandle' => '调整顺序',
          'frost.sortAscending' => '升序',
          'frost.sortDescending' => '降序',
          'frost.play' => '播放',
          'frost.pause' => '暂停',
          'frost.loop' => '循环',
          'frost.mute' => '静音',
          'frost.unmute' => '取消静音',
          'frost.fullscreen' => '全屏',
          'frost.exitFullscreen' => '退出全屏',
          'frost.reload' => '重新加载',
          'frost.openInBrowser' => '在浏览器中打开',
          'frost.minimize' => '最小化',
          _ => null,
        } ??
        switch (path) {
          'frost.maximize' => '最大化',
          'frost.restore' => '还原',
          'frost.close' => '关闭',
          'frost.cancel' => '取消',
          'frost.apply' => '应用',
          'frost.clear' => '清除',
          'frost.choose' => '选择',
          'frost.showInFolder' => '在文件夹中显示',
          'frost.selectedCount' => ({required Object count}) => '已选 ${count} 项',
          'frost.pageOf' =>
            ({required Object page, required Object total}) =>
                '第 ${page} 页，共 ${total} 页',
          'frost.selectAll' => '全选',
          'frost.done' => '完成',
          'frost.itemPosition' =>
            ({required Object position, required Object total}) =>
                '第 ${position} 项，共 ${total} 项',
          'frost.tableDimensions' =>
            ({required Object rows, required Object columns}) =>
                '${rows} 行，${columns} 列',
          'frost.taskQueued' => '等待中',
          'frost.taskRunning' => '下载中',
          'frost.taskPaused' => '已暂停',
          'frost.taskCompleted' => '已完成',
          'frost.taskFailed' => '失败',
          'frost.taskCancelled' => '已取消',
          'frost.remove' => '移除',
          'frost.forward' => '前进',
          'frost.stop' => '停止',
          'frost.seek' => '播放位置',
          'frost.send' => '发送',
          'frost.attach' => '添加附件',
          'frost.readerSettings' => '阅读设置',
          'frost.textSize' => '字号',
          'frost.lineSpacing' => '行距',
          'frost.readingProgress' => '阅读进度',
          'frost.showReplies' => ({required Object count}) => '显示 ${count} 条回复',
          'frost.characterCount' =>
            ({required Object count, required Object limit}) =>
                '${count} / ${limit} 字',
          'frost.moreMedia' => ({required Object count}) => '还有 ${count} 张图片',
          'frost.navigationCount' => ({required Object count}) => '${count} 项',
          'frost.navigationProgress' =>
            ({required Object progress}) => '已完成 ${progress}%',
          'frost.listSeparator' => '，',
          'navigation.browse' => '浏览',
          'navigation.search' => '搜索',
          'navigation.downloads' => '下载',
          'navigation.settings' => '设置',
          'navigation.browseEmpty' => '浏览喜欢的图源',
          'navigation.searchEmpty' => '通过标签查找作品',
          'navigation.downloadsEmpty' => '下载任务将显示在这里',
          'navigation.settingsEmpty' => '按喜好设置 BooruFlow',
          'settingsV2.predictiveBack' => '预测性返回',
          'settingsV2.predictiveBackScope' => '预览 App 内的返回动作；返回桌面的动画由系统控制。',
          'settingsV2.background' => '背景材质',
          'settingsV2.ambientBlur' => '环境模糊',
          'settingsV2.mica' => '云母',
          'settingsV2.backgroundOff' => '关闭',
          'settingsV2.backgroundIntensity' => '强度',
          'settingsV2.systemTransparencyReduced' => '系统已降低透明度',
          'settingsV2.customColour' => '自定义颜色',
          'settingsV2.appearance' => '外观',
          'settingsV2.browsing' => '浏览',
          'settingsV2.tone' => '色调',
          'settingsV2.neutral' => '中性',
          'settingsV2.cool' => '冷色',
          'settingsV2.warm' => '暖色',
          'settingsV2.accent' => '强调色',
          'settingsV2.customAccent' => '自定义强调色',
          'settingsV2.customHex' => '强调色 HEX',
          'settingsV2.invalidHex' => '请输入六位 HEX 颜色。',
          'settingsV2.accentRejected' => '此强调色在当前表面上无法保持可读。',
          'settingsV2.accentWarning' => '此强调色对比度较低，仍要应用吗？',
          'settingsV2.editAccount' => '编辑账号',
          'settingsV2.signOutConfirm' => '移除此图源已保存的账号凭据？',
          'settingsV2.licenses' => '开源许可',
          'settingsV2.checkUpdates' => '检查更新',
          'settingsV2.help' => '帮助',
          'settingsDetails.mode' => '模式',
          'settingsDetails.custom' => '自定义',
          'settingsDetails.change' => '更改',
          'settingsDetails.routeCache' => '路由缓存',
          'settingsDetails.hostCount' =>
            ({required Object count}) => '${count} 个主机',
          'settingsDetails.updatedAt' =>
            ({required Object time}) => '更新于 ${time}',
          'settingsDetails.sourceStatus' => '图源状态',
          'settingsDetails.apiAndImages' => 'API 与图片可用',
          'settingsDetails.apiOnly' => 'API 可用 · 图片未通过',
          'settingsDetails.status' => '状态',
          'settingsDetails.content' => '内容',
          'settingsDetails.editSourceAccount' =>
            ({required Object source}) => '编辑 ${source} 账号',
          'settingsDetails.proxyApplies' => '应用后用于图源、图片和新的下载。',
          'settingsDetails.version' =>
            ({required Object version, required Object build}) =>
                '版本 ${version} (${build})',
          'settingsDetails.communityTelegram' => 'Telegram 群组',
          'settingsDetails.communityDiscord' => 'Discord 服务器',
          'settingsDetails.savedVerifications' => '已保存的验证',
          'settingsDetails.systemDnsShort' => '系统 DNS',
          'settingsDetails.refresh' => '刷新',
          'settingsDetails.updateAvailable' =>
            ({required Object version}) => '有新版本 ${version}',
          'verificationPage.instructions' => '在下方页面完成人机验证，然后点“完成验证并返回”。',
          'verificationPage.opening' => '正在打开网页',
          'verificationPage.failed' => '网页加载失败',
          'verificationPage.closed' => '验证窗口已关闭',
          'verificationPage.failureHelp' => '可以重新打开，或检查网络设置。',
          'verificationPage.reopen' => '重新打开',
          'verificationPage.signOut' =>
            ({required Object source}) => '退出 ${source} 账号？',
          'verificationPage.signOutHelp' => '账号信息会从此设备移除。',
          'verificationPage.downloadAdded' => '已加入下载',
          'verificationPage.downloadFailed' => '下载失败',
          'verificationPage.linkCopied' => '已复制链接',
          'verificationPage.view' => '查看',
          'verificationPage.networkSettings' => '网络设置',
          'ugoira.iosFilesDestination' => '其他格式保存在“文件”App › BooruFlow',
          'ugoira.iosFormatHelp' => '动态 WebP 和 ZIP 保存到“文件”。',
          'ugoira.albumName' => '相簿名',
          'ugoira.openSettings' => '前往设置',
          'ugoira.androidDestination' => '相册与下载文件夹',
          'ugoira.iosDestination' => '保存到照片',
          'ugoira.format' => '动图保存格式',
          'ugoira.losslessWebp' => '无损动态 WebP',
          'ugoira.originalZip' => '原始 ZIP',
          'ugoira.webpRecord' => 'WebP · 动图',
          'ugoira.zipRecord' => 'ZIP · 原始帧',
          'ugoira.ugoiraInvalidArchive' => '动画压缩包无效。',
          'ugoira.ugoiraMetadataMissing' => '动画缺少帧时长元数据。',
          'ugoira.ugoiraInvalidMetadata' => '动画帧时长元数据无效。',
          'ugoira.ugoiraFrameMissing' => '动画中有帧缺失。',
          'ugoira.ugoiraFrameCorrupt' => '动画中有帧损坏。',
          'ugoira.ugoiraFrameSizeMismatch' => '动画的帧尺寸不一致。',
          'ugoira.ugoiraFrameTooLarge' => '动画帧超过大小限制。',
          'ugoira.ugoiraEncodeFailed' => '动画编码失败。',
          'ugoira.ugoiraOutputTooLarge' => '动画编码结果超过大小限制。',
          _ => null,
        };
  }
}
