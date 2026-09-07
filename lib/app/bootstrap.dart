import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/app/app_http_overrides.dart';
import 'package:booruflow/core/downloads/download_manager.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/frb_generated.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();

  await RustLib.init();
  final packageInfo = await PackageInfo.fromPlatform();
  AppInfo.version = packageInfo.version;
  AppInfo.buildNumber = packageInfo.buildNumber;

  await Hive.initFlutter();
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

  runApp(
    TranslationProvider(child: const ProviderScope(child: BooruFlowApp())),
  );
}
