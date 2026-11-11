import 'dart:async';

import 'package:booruflow/app/ambient_artwork.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

import 'app_router.dart';
import 'app_window.dart';
import 'frost_config.dart';

class BooruFlowApp extends ConsumerStatefulWidget {
  const BooruFlowApp({
    required this.windowController,
    this.checkUpdates = true,
    this.builder,
    super.key,
  });

  /// Created and prepared at startup; the app only hosts it.
  final FrostWindowController windowController;
  final bool checkUpdates;

  /// Composes the routed application below MaterialApp's live MediaQuery.
  final TransitionBuilder? builder;
  @override
  ConsumerState<BooruFlowApp> createState() => _BooruFlowAppState();
}

class _BooruFlowAppState extends ConsumerState<BooruFlowApp> {
  final _titles = FrostWindowTitleRegistry();
  final _location = ValueNotifier<Uri>(AppRouter.currentUri);
  bool _locationQueued = false;
  @override
  void initState() {
    super.initState();
    AppRouter.router.routerDelegate.addListener(_locationChanged);
    _locationChanged();
    if (widget.checkUpdates) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_checkForUpdate());
      });
    }
  }

  void _locationChanged() {
    // GoRouter can notify while restoring its nested Navigator during build.
    // Publish the window title after that frame, always reading the latest top
    // imperative match. Never reparent the root Navigator for a viewer route.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_locationQueued) return;
      _locationQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _locationQueued = false;
        if (mounted) _locationChanged();
      });
      return;
    }
    final uri = AppRouter.currentUri;
    _location.value = uri;
    _titles.updateLocation(uri);
  }

  Future<void> _checkForUpdate() async {
    try {
      final update = await ref.read(updateCheckProvider.notifier).check();
      if (!mounted || update == null) return;
      FrostToast.actionableInfo(
        t.update.newVersionFound(version: update.version),
        actionLabel: t.about.title,
        onAction: () => AppRouter.router.go('/settings/about'),
      );
    } catch (error) {
      if (mounted) AppToast.errorWithCause(t.update.checkUpdateFailed, error);
    }
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_locationChanged);
    _location.dispose();
    _titles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final artwork = ref.watch(ambientArtworkProvider);
    final config = appFrostConfig.copyWith(
      predictiveBack: settings.predictiveBack,
    );
    final material = settings.background.material;
    ref.listen(settingsProvider.select((value) => value.language), (
      _,
      language,
    ) {
      final locale = applyLanguagePreference(language);
      TagTranslationsService.update(
        language ?? languagePreferenceForAppLocale(locale),
      );
    });
    return FrostScope(
      config: config,
      reduceTransparency: material == BackgroundMaterial.off,
      child: FrostApp.router(
        config: config,
        title: AppInfo.name,
        appearance: settings.appearance,
        routerConfig: AppRouter.router,
        locale: appLocaleForLanguagePreference(settings.language).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final frame = FrostLayoutScope(
            child: FrostWindowTitleScope(
              registry: _titles,
              child: ListenableBuilder(
                listenable: Listenable.merge([_location, _titles]),
                builder: (context, _) {
                  final uri = _location.value;
                  final index = appDestinationIndexForPath(uri.path);
                  final pageTitle =
                      _titles.page(uri.path)?.title ??
                      (index == null
                          ? AppInfo.name
                          : appDestinationLabel(appDestinations[index]));
                  return ValueListenableBuilder<FrostWindowState>(
                    valueListenable: widget.windowController,
                    child: child,
                    builder: (context, state, page) {
                      final systemDisabled =
                          state.reduceTransparency ||
                          MediaQuery.highContrastOf(context);
                      final effective = switch ((
                        systemDisabled,
                        material,
                        state.backdropAvailable,
                      )) {
                        (true, _, _) => BackgroundMaterial.off,
                        (false, BackgroundMaterial.mica, false) =>
                          BackgroundMaterial.ambient,
                        _ => material,
                      };
                      return SystemTransparencyPreference(
                        disabled: systemDisabled,
                        child: Overlay.wrap(
                          child: FrostWindowHost(
                            controller: widget.windowController,
                            // Page first, as each platform's window lists and
                            // task switchers show it.
                            title: pageTitle == AppInfo.name
                                ? AppInfo.name
                                : '$pageTitle — ${AppInfo.name}',
                            backdrop: effective == BackgroundMaterial.mica
                                ? FrostWindowBackdrop.mica
                                : FrostWindowBackdrop.none,
                            child: FrostAmbientBackdropHost(
                              image: effective == BackgroundMaterial.ambient
                                  ? artwork
                                  : null,
                              fallback: effective == BackgroundMaterial.ambient
                                  ? FrostAmbientFallback.accentWash
                                  : FrostAmbientFallback.none,
                              intensity: effective == BackgroundMaterial.off
                                  ? 0
                                  : settings.background.intensity / 100,
                              child: AppWindow(
                                controller: widget.windowController,
                                child: DownloadFlightHost(child: page!),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
          return widget.builder?.call(context, frame) ?? frame;
        },
      ),
    );
  }
}
