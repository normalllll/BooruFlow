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
class TranslationsZhCn extends Translations with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsZhCn({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.zhCn,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ),
       super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
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
  TranslationsZhCn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) =>
      TranslationsZhCn(meta: meta ?? this.$meta);

  // Translations
  @override
  late final Translations$generic$zh_CN generic = Translations$generic$zh_CN.internal(_root);
  @override
  late final Translations$booruError$zh_CN booruError = Translations$booruError$zh_CN.internal(_root);
  @override
  late final Translations$update$zh_CN update = Translations$update$zh_CN.internal(_root);
  @override
  late final Translations$postList$zh_CN postList = Translations$postList$zh_CN.internal(_root);
  @override
  late final Translations$postDetail$zh_CN postDetail = Translations$postDetail$zh_CN.internal(_root);
  @override
  late final Translations$postSearch$zh_CN postSearch = Translations$postSearch$zh_CN.internal(_root);
  @override
  late final Translations$imageZoom$zh_CN imageZoom = Translations$imageZoom$zh_CN.internal(_root);
  @override
  late final Translations$downloads$zh_CN downloads = Translations$downloads$zh_CN.internal(_root);
  @override
  late final Translations$about$zh_CN about = Translations$about$zh_CN.internal(_root);
  @override
  late final Translations$settings$zh_CN settings = Translations$settings$zh_CN.internal(_root);
  @override
  late final Translations$discovery$zh_CN discovery = Translations$discovery$zh_CN.internal(_root);
  @override
  late final Translations$mediaError$zh_CN mediaError = Translations$mediaError$zh_CN.internal(_root);
}

// Path: generic
class Translations$generic$zh_CN extends Translations$generic$en {
  Translations$generic$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

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
  String errorWithCause({required Object message, required Object cause}) => '${message}：${cause}';
  @override
  String get loading => '正在加载...';
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
  Translations$booruError$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

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
  String get rateLimited => '请求受到图源限流，请稍后重试。';
  @override
  String get challengeRequired => '图源要求浏览器验证。可尝试在浏览器中打开图源完成验证，或选择其他图源。';
  @override
  String get routeUnavailable => '当前域名没有可用路由。请在网络设置中刷新路由；不会回退到系统 DNS。';
  @override
  String get sourceUnavailable => '当前图源暂时不可用。';
  @override
  String get network => '网络请求失败。请检查网络连接并重试。如果问题持续，可尝试使用代理服务器。';
  @override
  String get timeout => '请求超时。请检查网络连接，或稍后重试。';
  @override
  String get invalidResponse => '图源返回了无法解析的响应。';
  @override
  String get unsafeRedirect => '图源返回了不安全的重定向。';
  @override
  String get mediaValidationFailed => '图片响应校验或解码失败。';
  @override
  String get cancelled => '请求已取消。';
  @override
  String get internal => '图源引擎发生内部错误。';
}

// Path: update
class Translations$update$zh_CN extends Translations$update$en {
  Translations$update$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get checkUpdateStart => '正在检查更新...';
  @override
  String get checkUpdateFailed => '检查更新失败，请检查你的网络连接。';
  @override
  String get selectDownloadUrlFailed => '找不到下载链接。\n请访问项目页面手动更新，或在项目 Issue 页面寻求帮助。';
  @override
  String newVersionFound({required Object version}) => '发现新版本: ${version}。请转到“关于”页面并点击“下载更新”。';
  @override
  String get noNewVersionFound => '没有新版本。';
}

// Path: postList
class Translations$postList$zh_CN extends Translations$postList$en {
  Translations$postList$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

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
  Translations$postDetail$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String titleWithId({required Object id}) => '帖子: ${id}';
  @override
  String get tags => '标签';
  @override
  String get details => '详细信息';
  @override
  String get actions => '操作';
  @override
  String get rating => '安全评级';
  @override
  String get fileType => '文件类型';
  @override
  String get viewOriginal => '查看原图';
  @override
  String get download => '下载';
  @override
  String get relatedLoadFailed => '关联图片加载失败，可以重试。';
  @override
  String get createdAt => '创建时间';
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
  String get similarPosts => '相似帖子';
  @override
  String get parentPost => '父帖子';
  @override
  String get childPost => '子帖子';
}

// Path: postSearch
class Translations$postSearch$zh_CN extends Translations$postSearch$en {
  Translations$postSearch$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '搜索';
}

// Path: imageZoom
class Translations$imageZoom$zh_CN extends Translations$imageZoom$en {
  Translations$imageZoom$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '缩放图片';
}

// Path: downloads
class Translations$downloads$zh_CN extends Translations$downloads$en {
  Translations$downloads$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '下载项';
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
  late final Translations$downloads$messages$zh_CN messages = Translations$downloads$messages$zh_CN.internal(_root);
}

// Path: about
class Translations$about$zh_CN extends Translations$about$en {
  Translations$about$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

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
  Translations$settings$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

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
  String get maxConcurrentDownloads => '最大同时下载任务数';
  @override
  String get maxSegmentsPerTask => '每个下载任务的最大分段数';
  @override
  String get platformDefault => '平台默认';
  @override
  String get system => '系统';
  @override
  String get light => '浅色模式';
  @override
  String get dark => '深色模式';
  @override
  String get auto => '自动';
  @override
  String get downloadsOverview => '保存位置与下载并发';
  @override
  late final Translations$settings$sections$zh_CN sections = Translations$settings$sections$zh_CN.internal(_root);
  @override
  late final Translations$settings$source$zh_CN source = Translations$settings$source$zh_CN.internal(_root);
  @override
  late final Translations$settings$account$zh_CN account = Translations$settings$account$zh_CN.internal(_root);
  @override
  late final Translations$settings$network$zh_CN network = Translations$settings$network$zh_CN.internal(_root);
  @override
  late final Translations$settings$languageDialog$zh_CN languageDialog =
      Translations$settings$languageDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$themeModeDialog$zh_CN themeModeDialog =
      Translations$settings$themeModeDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$downloadDirectoryDialog$zh_CN downloadDirectoryDialog =
      Translations$settings$downloadDirectoryDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$bypassSniDialog$zh_CN bypassSniDialog =
      Translations$settings$bypassSniDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$columnsPerRowDialog$zh_CN columnsPerRowDialog =
      Translations$settings$columnsPerRowDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$maxConcurrentDownloadsDialog$zh_CN maxConcurrentDownloadsDialog =
      Translations$settings$maxConcurrentDownloadsDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$maxSegmentsPerTaskDialog$zh_CN maxSegmentsPerTaskDialog =
      Translations$settings$maxSegmentsPerTaskDialog$zh_CN.internal(_root);
}

// Path: discovery
class Translations$discovery$zh_CN extends Translations$discovery$en {
  Translations$discovery$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get searchResults => '搜索结果';
  @override
  String get allAvailable => '全部可用内容';
  @override
  String get defaultRatingsHint => '分级偏好适用于所有图源。未选择分级时，显示当前图源和账号能访问的所有内容。';
  @override
  String get resetFilters => '恢复默认';
  @override
  String get unsupportedRatings => '当前图源不支持所选分级，请恢复默认以浏览可用内容。';
  @override
  String get noFilteredPosts => '没有符合当前筛选条件的内容。';
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
  String get filteredContinue => '当前几页没有符合筛选的帖子，继续浏览';
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
  String get addTag => '添加标签';
  @override
  String get noCustomTags => '还没有自定义标签';
  @override
  String get customTagsHint => '为常用标签设置易记的名称，搜索时更容易找到。';
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
  String get queryHint => '输入标签或图源查询语句…';
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
  Translations$mediaError$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '图片加载失败';
  @override
  String get details => '错误详情';
  @override
  String get copyDetails => '复制详情';
  @override
  String get decodeFailed => '下载的图片无法解码。重试会清除这张图片的缓存并重新下载。';
}

// Path: downloads.messages
class Translations$downloads$messages$zh_CN extends Translations$downloads$messages$en {
  Translations$downloads$messages$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

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
class Translations$settings$sections$zh_CN extends Translations$settings$sections$en {
  Translations$settings$sections$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

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
class Translations$settings$source$zh_CN extends Translations$settings$source$en {
  Translations$settings$source$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get defaultSource => '默认图源';
  @override
  String get supportedRatings => '支持的分级';
  @override
  String get safetyRating => '全局内容分级';
}

// Path: settings.account
class Translations$settings$account$zh_CN extends Translations$settings$account$en {
  Translations$settings$account$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get manageAllSubtitle => '图源分级与账号配置';
  @override
  String get noAccountRequired => '此图源无需配置账号';
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
class Translations$settings$network$zh_CN extends Translations$settings$network$en {
  Translations$settings$network$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get dnsProvider => 'DNS 服务';
  @override
  String get servicesTitle => '全部图源状态';
  @override
  String get servicesHint => 'IP 解析与 API 可用性分别检测；API 可用不代表所有图片均可下载。';
  @override
  String get noFallback => '仅使用所选 DNS，失败直接报错；不会回退到系统 DNS 或自动切换服务。';
  @override
  String checkProgress({
    required Object done,
    required Object total,
    required Object checked,
    required Object sources,
  }) => 'DNS 已完成 ${done}/${total} · API 已检测 ${checked}/${sources}';
  @override
  String checkSummary({required Object available, required Object total, required Object failed}) =>
      'API 可用 ${available}/${total} · DNS 失败 ${failed} 项';
  @override
  String get loadingStatus => '正在读取缓存状态…';
  @override
  String get apiChecking => 'API：检测中…';
  @override
  String get apiAvailable => 'API：可用';
  @override
  String get apiFailed => 'API：不可用';
  @override
  String get apiUnchecked => 'API：尚未检测';
  @override
  String get dnsPending => '尚未解析 · 点击刷新路由获取 IP';
  @override
  String get dnsResolving => '正在解析…';
  @override
  String get dnsResolved => '解析成功';
  @override
  String get dnsCached => '使用已缓存 IP · 尚未重新检测';
  @override
  String get dnsFailed => '解析失败 · 当前无可用路由';
  @override
  String get dnsQueued => '等待解析…';
  @override
  String ipCachedAt({required Object time}) => 'IP 已缓存 · 更新于 ${time}';
  @override
  String get ipNotCached => 'IP 已解析 · 尚未写入缓存';
  @override
  String get connectionMode => '连接模式';
  @override
  String get proxyUrl => '代理 URL';
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
  String routeCacheStatus({required Object hosts, required Object revision}) => '${hosts} 个主机 · 修订 ${revision}';
  @override
  String get applied => '网络设置已应用';
  @override
  String get invalidSettings => '网络设置无效';
  @override
  String get routeRefreshFailed => '路由刷新失败';
  @override
  String get systemDns => '系统 DNS';
  @override
  String get sniBypass => '绕过 SNI';
  @override
  String get legacyIpUrl => '旧版 IP URL';
}

// Path: settings.languageDialog
class Translations$settings$languageDialog$zh_CN extends Translations$settings$languageDialog$en {
  Translations$settings$languageDialog$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '语言';
}

// Path: settings.themeModeDialog
class Translations$settings$themeModeDialog$zh_CN extends Translations$settings$themeModeDialog$en {
  Translations$settings$themeModeDialog$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '主题模式';
}

// Path: settings.downloadDirectoryDialog
class Translations$settings$downloadDirectoryDialog$zh_CN extends Translations$settings$downloadDirectoryDialog$en {
  Translations$settings$downloadDirectoryDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
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
  late final Translations$settings$downloadDirectoryDialog$messages$zh_CN messages =
      Translations$settings$downloadDirectoryDialog$messages$zh_CN.internal(_root);
}

// Path: settings.bypassSniDialog
class Translations$settings$bypassSniDialog$zh_CN extends Translations$settings$bypassSniDialog$en {
  Translations$settings$bypassSniDialog$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '绕过 SNI';
}

// Path: settings.columnsPerRowDialog
class Translations$settings$columnsPerRowDialog$zh_CN extends Translations$settings$columnsPerRowDialog$en {
  Translations$settings$columnsPerRowDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每行列数';
}

// Path: settings.maxConcurrentDownloadsDialog
class Translations$settings$maxConcurrentDownloadsDialog$zh_CN
    extends Translations$settings$maxConcurrentDownloadsDialog$en {
  Translations$settings$maxConcurrentDownloadsDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '最大同时下载任务数';
}

// Path: settings.maxSegmentsPerTaskDialog
class Translations$settings$maxSegmentsPerTaskDialog$zh_CN extends Translations$settings$maxSegmentsPerTaskDialog$en {
  Translations$settings$maxSegmentsPerTaskDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '每个下载任务的最大分段数';
}

// Path: settings.account.statuses
class Translations$settings$account$statuses$zh_CN extends Translations$settings$account$statuses$en {
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
  Translations$settings$downloadDirectoryDialog$messages$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
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
      'generic.copiedWithValue' => ({required Object value}) => '已复制到剪贴板: ${value}',
      'generic.errorWithValue' => ({required Object value}) => '发生错误: ${value}',
      'generic.errorWithCause' => ({required Object message, required Object cause}) => '${message}：${cause}',
      'generic.loading' => '正在加载...',
      'generic.loadFailed' => '加载失败',
      'generic.retry' => '重试',
      'generic.noMoreData' => '没有更多数据',
      'generic.notFound' => '未找到内容',
      'booruError.invalidRequest' => '请求参数无效。',
      'booruError.unsupportedCapability' => '当前图源不支持此操作。',
      'booruError.authenticationRequired' => '请登录当前图源后重试。',
      'booruError.authenticationRejected' => '图源拒绝了账号凭据。',
      'booruError.permissionDenied' => '图源拒绝访问此资源。',
      'booruError.rateLimited' => '请求受到图源限流，请稍后重试。',
      'booruError.challengeRequired' => '图源要求浏览器验证。可尝试在浏览器中打开图源完成验证，或选择其他图源。',
      'booruError.routeUnavailable' => '当前域名没有可用路由。请在网络设置中刷新路由；不会回退到系统 DNS。',
      'booruError.sourceUnavailable' => '当前图源暂时不可用。',
      'booruError.network' => '网络请求失败。请检查网络连接并重试。如果问题持续，可尝试使用代理服务器。',
      'booruError.timeout' => '请求超时。请检查网络连接，或稍后重试。',
      'booruError.invalidResponse' => '图源返回了无法解析的响应。',
      'booruError.unsafeRedirect' => '图源返回了不安全的重定向。',
      'booruError.mediaValidationFailed' => '图片响应校验或解码失败。',
      'booruError.cancelled' => '请求已取消。',
      'booruError.internal' => '图源引擎发生内部错误。',
      'update.checkUpdateStart' => '正在检查更新...',
      'update.checkUpdateFailed' => '检查更新失败，请检查你的网络连接。',
      'update.selectDownloadUrlFailed' => '找不到下载链接。\n请访问项目页面手动更新，或在项目 Issue 页面寻求帮助。',
      'update.newVersionFound' => ({required Object version}) => '发现新版本: ${version}。请转到“关于”页面并点击“下载更新”。',
      'update.noNewVersionFound' => '没有新版本。',
      'postList.short' => '首页',
      'postList.title' => '首页',
      'postList.titleWithTags' => ({required Object tags}) => '带有标签的帖子: ${tags}',
      'postDetail.titleWithId' => ({required Object id}) => '帖子: ${id}',
      'postDetail.tags' => '标签',
      'postDetail.details' => '详细信息',
      'postDetail.actions' => '操作',
      'postDetail.rating' => '安全评级',
      'postDetail.fileType' => '文件类型',
      'postDetail.viewOriginal' => '查看原图',
      'postDetail.download' => '下载',
      'postDetail.relatedLoadFailed' => '关联图片加载失败，可以重试。',
      'postDetail.createdAt' => '创建时间',
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
      'postDetail.similarPosts' => '相似帖子',
      'postDetail.parentPost' => '父帖子',
      'postDetail.childPost' => '子帖子',
      'postSearch.title' => '搜索',
      'imageZoom.title' => '缩放图片',
      'downloads.title' => '下载项',
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
      'downloads.messages.storagePermanentlyDenied' => '你已永久拒绝存储权限。\n请在设置中手动启用存储权限。',
      'downloads.messages.storageDenied' => '你已拒绝存储权限。',
      'downloads.messages.deviceInfoError' => '无法解析设备信息。',
      'downloads.messages.photosPermanentlyDenied' => '你已永久拒绝照片权限。\n请在设置中手动启用照片权限。',
      'downloads.messages.photosDenied' => '你已拒绝照片权限。',
      'downloads.messages.downloadTaskExists' => '下载任务已存在。',
      'downloads.messages.imageFileExists' => '图片文件已存在。',
      'downloads.messages.downloadRetryWith' => ({required Object name}) => '重试下载任务: ${name}',
      'downloads.messages.downloadStartWith' => ({required Object name}) => '开始下载任务: ${name}',
      'downloads.messages.downloadCompletedWith' => ({required Object name}) => '下载任务完成: ${name}',
      'downloads.messages.downloadFailedWith' => ({required Object name}) => '下载任务失败: ${name}',
      'downloads.messages.saveFailedWith' => ({required Object name}) => '保存失败: 任务 ${name}',
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
      'settings.maxConcurrentDownloads' => '最大同时下载任务数',
      'settings.maxSegmentsPerTask' => '每个下载任务的最大分段数',
      'settings.platformDefault' => '平台默认',
      'settings.system' => '系统',
      'settings.light' => '浅色模式',
      'settings.dark' => '深色模式',
      'settings.auto' => '自动',
      'settings.downloadsOverview' => '保存位置与下载并发',
      'settings.sections.sourcesAndAccounts' => '图源与账号',
      'settings.sections.accounts' => '账号',
      'settings.sections.network' => '网络',
      'settings.sections.general' => '通用',
      'settings.sections.downloads' => '下载',
      'settings.source.defaultSource' => '默认图源',
      'settings.source.supportedRatings' => '支持的分级',
      'settings.source.safetyRating' => '全局内容分级',
      'settings.account.manageAllSubtitle' => '图源分级与账号配置',
      'settings.account.noAccountRequired' => '此图源无需配置账号',
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
      'settings.account.statusValue' => ({required Object status}) => '状态 · ${status}',
      'settings.account.statuses.notConfigured' => '尚未配置',
      'settings.account.statuses.configuredUnverified' => '已配置，尚未验证',
      'settings.account.statuses.verified' => '已验证',
      'settings.account.statuses.rejected' => '已被拒绝',
      'settings.network.dnsProvider' => 'DNS 服务',
      'settings.network.servicesTitle' => '全部图源状态',
      'settings.network.servicesHint' => 'IP 解析与 API 可用性分别检测；API 可用不代表所有图片均可下载。',
      'settings.network.noFallback' => '仅使用所选 DNS，失败直接报错；不会回退到系统 DNS 或自动切换服务。',
      'settings.network.checkProgress' =>
        ({required Object done, required Object total, required Object checked, required Object sources}) =>
            'DNS 已完成 ${done}/${total} · API 已检测 ${checked}/${sources}',
      'settings.network.checkSummary' =>
        ({required Object available, required Object total, required Object failed}) =>
            'API 可用 ${available}/${total} · DNS 失败 ${failed} 项',
      'settings.network.loadingStatus' => '正在读取缓存状态…',
      'settings.network.apiChecking' => 'API：检测中…',
      'settings.network.apiAvailable' => 'API：可用',
      'settings.network.apiFailed' => 'API：不可用',
      'settings.network.apiUnchecked' => 'API：尚未检测',
      'settings.network.dnsPending' => '尚未解析 · 点击刷新路由获取 IP',
      'settings.network.dnsResolving' => '正在解析…',
      'settings.network.dnsResolved' => '解析成功',
      'settings.network.dnsCached' => '使用已缓存 IP · 尚未重新检测',
      'settings.network.dnsFailed' => '解析失败 · 当前无可用路由',
      'settings.network.dnsQueued' => '等待解析…',
      'settings.network.ipCachedAt' => ({required Object time}) => 'IP 已缓存 · 更新于 ${time}',
      'settings.network.ipNotCached' => 'IP 已解析 · 尚未写入缓存',
      'settings.network.connectionMode' => '连接模式',
      'settings.network.proxyUrl' => '代理 URL',
      'settings.network.proxyHint' => '选填 · 例如 http://127.0.0.1:7890',
      'settings.network.applyAndRouteCache' => '应用与路由缓存',
      'settings.network.apply' => '应用网络设置',
      'settings.network.refreshRoutes' => '刷新路由',
      'settings.network.routeCacheUnavailable' => '无法获取路由缓存',
      'settings.network.routeCacheStatus' =>
        ({required Object hosts, required Object revision}) => '${hosts} 个主机 · 修订 ${revision}',
      'settings.network.applied' => '网络设置已应用',
      'settings.network.invalidSettings' => '网络设置无效',
      'settings.network.routeRefreshFailed' => '路由刷新失败',
      'settings.network.systemDns' => '系统 DNS',
      'settings.network.sniBypass' => '绕过 SNI',
      'settings.network.legacyIpUrl' => '旧版 IP URL',
      'settings.languageDialog.title' => '语言',
      'settings.themeModeDialog.title' => '主题模式',
      'settings.downloadDirectoryDialog.title' => '下载目录',
      'settings.downloadDirectoryDialog.pickerTitle' => '选择目录',
      'settings.downloadDirectoryDialog.pick' => '选择目录',
      'settings.downloadDirectoryDialog.messages.setToPlatformDefault' => '下载目录已设为平台默认。',
      'settings.downloadDirectoryDialog.messages.pathNotAbsolute' => '路径必须是绝对路径。',
      'settings.downloadDirectoryDialog.messages.pathNotWritable' => '路径不可写入。',
      'settings.bypassSniDialog.title' => '绕过 SNI',
      'settings.columnsPerRowDialog.title' => '每行列数',
      'settings.maxConcurrentDownloadsDialog.title' => '最大同时下载任务数',
      'settings.maxSegmentsPerTaskDialog.title' => '每个下载任务的最大分段数',
      'discovery.searchResults' => '搜索结果',
      'discovery.allAvailable' => '全部可用内容',
      'discovery.defaultRatingsHint' => '分级偏好适用于所有图源。未选择分级时，显示当前图源和账号能访问的所有内容。',
      'discovery.resetFilters' => '恢复默认',
      'discovery.unsupportedRatings' => '当前图源不支持所选分级，请恢复默认以浏览可用内容。',
      'discovery.noFilteredPosts' => '没有符合当前筛选条件的内容。',
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
      'discovery.filteredContinue' => '当前几页没有符合筛选的帖子，继续浏览',
      'discovery.commonTags' => '常用标签',
      'discovery.moreTags' => '查看更多',
      'discovery.tagSource' => '适用图源',
      'discovery.allTagSources' => '通用',
      'discovery.manageTags' => '标签管理',
      'discovery.addTag' => '添加标签',
      'discovery.noCustomTags' => '还没有自定义标签',
      'discovery.customTagsHint' => '为常用标签设置易记的名称，搜索时更容易找到。',
      'discovery.addCustomTag' => '添加为自定义标签',
      'discovery.editTag' => '编辑自定义标签',
      'discovery.canonicalTag' => '图源标签',
      'discovery.displayName' => '显示名称（可选）',
      'discovery.invalidTag' => '请输入一个非空且不含空格的标签。',
      'discovery.queryHint' => '输入标签或图源查询语句…',
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
      'mediaError.title' => '图片加载失败',
      'mediaError.details' => '错误详情',
      'mediaError.copyDetails' => '复制详情',
      'mediaError.decodeFailed' => '下载的图片无法解码。重试会清除这张图片的缓存并重新下载。',
      _ => null,
    };
  }
}
