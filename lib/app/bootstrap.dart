import 'dart:io';

import 'package:booruflow/app/app_http_overrides.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/app/licenses.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/downloads/download_manager.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/downloads/platform/macos_folder_access.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/frb_generated.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Narrow desktop windows use the same compact content layout as a phone.
const _minimumWindowSize = Size(320, 480);

/// Wraps the app for a harness. The harness gets the window controller that
/// the app's window host uses.
typedef AppBuilder = Widget Function(Widget app, FrostWindowController window);

/// Starts the app. [restoreWindowPlacement] is false for a harness that places
/// the native window itself.
Future<void> bootstrap({
  AppBuilder? appBuilder,
  bool restoreWindowPlacement = true,
  List<Override> overrides = const [],
}) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();

  await initializeDateFormatting();
  await RustLib.init();
  final packageInfo = await PackageInfo.fromPlatform();
  AppInfo.version = packageInfo.version;
  AppInfo.buildNumber = packageInfo.buildNumber;

  await SettingsService.initialize();
  await BooruService.instance.initialize(packageInfo.version);

  final appLocale = applyLanguagePreference(SettingsService.language);
  await TagTranslationsService.loadAll();
  TagTranslationsService.update(
    SettingsService.language ?? languagePreferenceForAppLocale(appLocale),
  );
  configureDownloadManager(
    DownloadManagerConfiguration(
      maxConcurrentDownloads: () => SettingsService.maxConcurrentDownloads,
    ),
  );
  await MacosFolderAccess.restore();
  await BooruDownloads.instance.initialize();

  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 512 << 20;
  registerAppLicenses();

  // The native window stays hidden until the first frame is ready, so the
  // runner's template rectangle never shows. A saved placement that no longer
  // fits (a missing display, a changed work area) comes back adjusted.
  final window = FrostWindowController(minimumSize: _minimumWindowSize);
  final hasNativeWindow =
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  if (hasNativeWindow && restoreWindowPlacement) {
    try {
      final placement = await window.prepare(
        saved: SettingsService.windowPlacement,
      );
      debugPrint('Window placement adjustments: ${placement.adjustments}');
    } on FrostWindowFailure catch (error) {
      // The app still starts, in the runner's own window.
      debugPrint('Window placement failed: $error');
    }
  }

  final app = TranslationProvider(
    child: ProviderScope(
      overrides: overrides,
      child: BooruFlowApp(windowController: window),
    ),
  );
  runApp(appBuilder?.call(app, window) ?? app);

  if (hasNativeWindow) {
    await binding.waitUntilFirstFrameRasterized;
    try {
      await window.show();
    } on FrostWindowFailure catch (error) {
      debugPrint('Window show failed: $error');
    }
    window.geometry.addListener(() {
      final geometry = window.geometry.value;
      if (geometry != null) {
        SettingsService.windowPlacement = geometry.placement;
      }
    });
  }
}
