import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yande_gui/app/yande_app.dart';
import 'package:yande_gui/app/app_http_overrides.dart';
import 'package:yande_gui/core/downloads/download_manager.dart';
import 'package:yande_gui/core/downloads/download_manager_configuration.dart';
import 'package:yande_gui/core/app_runtime.dart';
import 'package:yande_gui/core/settings_service.dart';
import 'package:yande_gui/features/downloads/logic.dart';
import 'package:yande_gui/features/posts/network/yande_network_policy.dart';
import 'package:yande_gui/features/search/custom_tags_service.dart';
import 'package:yande_gui/features/tags/tag_translations_service.dart';
import 'package:yande_gui/intl/locale_preferences.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/src/rust/frb_generated.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();

  await RustLib.init();
  final packageInfo = await PackageInfo.fromPlatform();
  AppInfo.version = packageInfo.version;
  AppInfo.buildNumber = packageInfo.buildNumber;

  await Hive.initFlutter();
  await SettingsService.initialize();
  await applyYandeNetworkSettings();

  final appLocale = applyLanguagePreference(SettingsService.language);
  await CustomTagsService.initialize();
  await TagTranslationsService.loadAll();
  TagTranslationsService.update(
    SettingsService.language ?? languagePreferenceForAppLocale(appLocale),
  );
  configureDownloadManager(
    DownloadManagerConfiguration(
      maxConcurrentDownloads: () => SettingsService.maxConcurrentDownloads,
      resolveNetworkOptions: YandeNetworkPolicy.resolveDownloadOptions,
    ),
  );
  await YandeDownloads.instance.initialize();

  runApp(TranslationProvider(child: const ProviderScope(child: YandeApp())));
}
