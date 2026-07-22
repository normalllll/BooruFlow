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
       $meta =
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
    super.$meta.setFlatMapFunction(
      $meta.getTranslation,
    ); // copy base translations to super.$meta
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <zh-CN>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  @override
  dynamic operator [](String key) =>
      $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

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
}

// Path: update
class Translations$update$zh_CN extends Translations$update$en {
  Translations$update$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get checkUpdateStart => '正在检查更新...';
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
  String get short => '帖子';
  @override
  String get title => '帖子列表';
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
  String titleWithId({required Object id}) => '帖子: ${id}';
  @override
  String get createdAt => '创建时间';
  @override
  String get author => '作者';
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
  String get title => '下载项';
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
  String get dartVersion => 'Dart 版本';
  @override
  String get rustVersion => 'Rust 版本';
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
  String get prefetchDns => '预解析 DNS';
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
  late final Translations$settings$dnsPrefetchDialog$zh_CN dnsPrefetchDialog =
      Translations$settings$dnsPrefetchDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$columnsPerRowDialog$zh_CN
  columnsPerRowDialog =
      Translations$settings$columnsPerRowDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$maxConcurrentDownloadsDialog$zh_CN
  maxConcurrentDownloadsDialog =
      Translations$settings$maxConcurrentDownloadsDialog$zh_CN.internal(_root);
  @override
  late final Translations$settings$maxSegmentsPerTaskDialog$zh_CN
  maxSegmentsPerTaskDialog =
      Translations$settings$maxSegmentsPerTaskDialog$zh_CN.internal(_root);
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

// Path: settings.dnsPrefetchDialog
class Translations$settings$dnsPrefetchDialog$zh_CN
    extends Translations$settings$dnsPrefetchDialog$en {
  Translations$settings$dnsPrefetchDialog$zh_CN.internal(TranslationsZhCn root)
    : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'DNS 预解析';
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

// Path: settings.maxConcurrentDownloadsDialog
class Translations$settings$maxConcurrentDownloadsDialog$zh_CN
    extends Translations$settings$maxConcurrentDownloadsDialog$en {
  Translations$settings$maxConcurrentDownloadsDialog$zh_CN.internal(
    TranslationsZhCn root,
  ) : this._root = root,
      super.internal(root);

  final TranslationsZhCn _root; // ignore: unused_field

  // Translations
  @override
  String get title => '最大同时下载任务数';
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
      'generic.errorWithValue' => ({required Object value}) => '发生错误: ${value}',
      'update.checkUpdateStart' => '正在检查更新...',
      'update.checkUpdateFailed' => '检查更新失败，请检查你的网络连接。',
      'update.selectDownloadUrlFailed' =>
        '找不到下载链接。\n请访问项目页面手动更新，或在项目 Issue 页面寻求帮助。',
      'update.newVersionFound' =>
        ({required Object version}) => '发现新版本: ${version}。请转到“关于”页面并点击“下载更新”。',
      'update.noNewVersionFound' => '没有新版本。',
      'postList.short' => '帖子',
      'postList.title' => '帖子列表',
      'postList.titleWithTags' =>
        ({required Object tags}) => '带有标签的帖子: ${tags}',
      'postDetail.titleWithId' => ({required Object id}) => '帖子: ${id}',
      'postDetail.createdAt' => '创建时间',
      'postDetail.author' => '作者',
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
      'about.dartVersion' => 'Dart 版本',
      'about.rustVersion' => 'Rust 版本',
      'about.discussion' => '讨论',
      'about.downloadUpdate' => '下载更新',
      'about.downloadUpdateHint' => '通过浏览器下载适合你设备的最新版本。',
      'settings.title' => '设置',
      'settings.theme' => '主题',
      'settings.language' => '语言',
      'settings.prefetchDns' => '预解析 DNS',
      'settings.downloadDirectory' => '下载目录',
      'settings.defaultToPlatformSettings' => '使用平台默认设置',
      'settings.columnsPerRow' => '每行列数',
      'settings.maxConcurrentDownloads' => '最大同时下载任务数',
      'settings.maxSegmentsPerTask' => '每个下载任务的最大分段数',
      'settings.platformDefault' => '平台默认',
      'settings.system' => '系统',
      'settings.light' => '浅色模式',
      'settings.dark' => '深色模式',
      'settings.languageDialog.title' => '语言',
      'settings.themeModeDialog.title' => '主题模式',
      'settings.downloadDirectoryDialog.title' => '下载目录',
      'settings.downloadDirectoryDialog.pickerTitle' => '选择目录',
      'settings.downloadDirectoryDialog.pick' => '选择目录',
      'settings.downloadDirectoryDialog.messages.setToPlatformDefault' =>
        '下载目录已设为平台默认。',
      'settings.downloadDirectoryDialog.messages.pathNotAbsolute' =>
        '路径必须是绝对路径。',
      'settings.downloadDirectoryDialog.messages.pathNotWritable' => '路径不可写入。',
      'settings.dnsPrefetchDialog.title' => 'DNS 预解析',
      'settings.columnsPerRowDialog.title' => '每行列数',
      'settings.maxConcurrentDownloadsDialog.title' => '最大同时下载任务数',
      'settings.maxSegmentsPerTaskDialog.title' => '每个下载任务的最大分段数',
      _ => null,
    };
  }
}
