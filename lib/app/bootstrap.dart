import 'dart:io';

import 'package:booruflow/app/app_http_overrides.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/app/licenses.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/downloads/download_manager.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/frb_generated.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> bootstrap({Widget Function(Widget app)? appBuilder}) async {
  WidgetsFlutterBinding.ensureInitialized();
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
  await BooruDownloads.instance.initialize();

  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 512 << 20;
  registerAppLicenses();

  final app = TranslationProvider(
    child: const ProviderScope(child: BooruFlowApp()),
  );
  runApp(appBuilder?.call(app) ?? app);
}
