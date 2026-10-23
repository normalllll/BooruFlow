import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

// Small windows demonstrate the palette, not an additional application theme.
const _tonePreviewWidth = 64.0, _tonePreviewHeight = 44.0;

class AppearanceSettings extends ConsumerStatefulWidget {
  const AppearanceSettings({super.key});
  @override
  ConsumerState<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends ConsumerState<AppearanceSettings> {
  bool _saving = false, _savingBackground = false;
  FrostAppearance get _appearance => ref.read(settingsProvider).appearance;
  Brightness get _brightness =>
      FrostThemeTokens.of(context).isDark ? Brightness.dark : Brightness.light;
  Future<bool> _save(FrostAppearance appearance, {bool? custom}) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsProvider.notifier)
          .setAppearance(
            appearance,
            accentBrightness: custom == null ? null : _brightness,
            customSelected: custom,
          );
      return true;
    } catch (error) {
      if (mounted) AppToast.errorWithCause(t.generic.loadFailed, error);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _accent(Color color, {bool custom = false}) async {
    final validation = validateAccent(
      color,
      _brightness,
      appFrostConfig.palettes,
    );
    if (!validation.canApply) {
      AppToast.error(t.settingsV2.accentRejected);
      return false;
    }
    if (validation.severity == FrostAccentSeverity.warning) {
      if (!await showFrostConfirm(
            context: context,
            title: t.settingsV2.accent,
            message: t.settingsV2.accentWarning,
            confirmLabel: t.generic.confirm,
            destructive: false,
          ) ||
          !mounted) {
        return false;
      }
    }
    final appearance = _appearance;
    return _save(
      _brightness == Brightness.light
          ? appearance.copyWith(
              lightAccent: color,
              lightCustomAccent: custom ? color : null,
            )
          : appearance.copyWith(
              darkAccent: color,
              darkCustomAccent: custom ? color : null,
            ),
      custom: custom,
    );
  }

  Future<void> _customAccent() async {
    final key = GlobalKey<_AccentFormState>();
    await showFrostFormDialog(
      context: context,
      title: t.settingsV2.customAccent,
      sections: [
        _AccentForm(
          key: key,
          initial: accentHex(
            _appearance.customAccentFor(_brightness) ??
                _appearance.accentFor(_brightness),
          ),
          onApply: (color) => _accent(color, custom: true),
        ),
      ],
      submitLabel: t.generic.confirm,
      onSubmit: () => key.currentState?.submit() ?? Future.value(false),
    );
  }

  Future<void> _saveBackground(Future<void> Function() save) async {
    if (_savingBackground) return;
    setState(() => _savingBackground = true);
    try {
      await save();
    } catch (error) {
      if (mounted) AppToast.errorWithCause(t.generic.loadFailed, error);
    } finally {
      if (mounted) setState(() => _savingBackground = false);
    }
  }

  Future<void> _saveIntensity(double value) async {
    try {
      await ref.read(settingsProvider.notifier).saveBackgroundIntensity(value);
    } catch (error) {
      if (mounted) AppToast.errorWithCause(t.generic.loadFailed, error);
    }
  }

  String _toneLabel(FrostTone tone) => switch (tone) {
    FrostTone.neutral => t.settingsV2.neutral,
    FrostTone.cool => t.settingsV2.cool,
    FrostTone.warm => t.settingsV2.warm,
  };
  Widget _preview(FrostThemeTokens palette) => SizedBox(
    height: _tonePreviewHeight,
    child: ColoredBox(
      color: palette.canvas,
      child: Padding(
        padding: const EdgeInsets.all(FrostGap.related),
        child: Row(
          children: [
            SizedBox(
              width: FrostGap.of(context).page,
              child: ColoredBox(
                color: palette.surfaceRaised,
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(width: FrostGap.inline),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: FrostGap.related,
                    child: ColoredBox(color: palette.accent),
                  ),
                  const SizedBox(height: FrostGap.related),
                  Expanded(child: ColoredBox(color: palette.surface)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _tone(FrostTone tone) {
    final appearance = _appearance;
    final palette = appFrostConfig.palettes.palette(
      _brightness,
      tone,
      appearance.accentFor(_brightness),
    );
    final selected = appearance.effectiveToneFor(_brightness) == tone;
    final enabled = !_saving && appearance.mode != ThemeMode.system;
    return SizedBox(
      width: _tonePreviewWidth,
      child: Column(
        children: [
          SizedBox(
            height: _tonePreviewHeight,
            width: double.infinity,
            child: FrostThumbnail(
              image: _preview(palette),
              semanticLabel: _toneLabel(tone),
              selected: selected,
              onPressed: !enabled
                  ? null
                  : () => _save(
                      _brightness == Brightness.light
                          ? appearance.copyWith(lightTone: tone)
                          : appearance.copyWith(darkTone: tone),
                    ),
            ),
          ),
          const SizedBox(height: FrostGap.related),
          FrostText(
            _toneLabel(tone),
            role: FrostTextRole.footnote,
            tone: selected ? FrostTextTone.accent : FrostTextTone.secondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final settings = ref.watch(settingsProvider),
        appearance = settings.appearance;
    final colours = appFrostConfig.palettes.accentPresets;
    final custom = appearance.customAccentFor(_brightness);
    final customSelected = _brightness == Brightness.light
        ? settings.lightCustomSelected
        : settings.darkCustomSelected;
    Widget optionsRow(String title, Widget controls) => Padding(
      padding: EdgeInsets.all(FrostGap.of(context).rowInset),
      child: FrostFormRow(
        label: FrostText(title, role: FrostTextRole.body),
        control: controls,
      ),
    );
    final tones = Wrap(
      spacing: FrostGap.group,
      runSpacing: FrostGap.related,
      children: [
        for (final tone in FrostTone.values) ...[_tone(tone)],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostGroupedSection(
          children: [
            FrostListRow(
              title: t.settingsDetails.mode,
              trailing: FrostPicker<ThemeMode>.segmented(
                label: t.settings.theme,
                value: appearance.mode,
                options: [
                  FrostPickerOption(
                    value: ThemeMode.light,
                    label: t.settings.light,
                  ),
                  FrostPickerOption(
                    value: ThemeMode.dark,
                    label: t.settings.dark,
                  ),
                  FrostPickerOption(
                    value: ThemeMode.system,
                    label: t.settings.system,
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (mode) => _save(appearance.copyWith(mode: mode)),
              ),
            ),
            FrostListRow(
              title: t.settingsV2.tone,
              // Thumbnail selection rings extend outside their square bounds.
              trailing: Padding(
                padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
                child: tones,
              ),
              enabled: !_saving && appearance.mode != ThemeMode.system,
            ),
            optionsRow(
              t.settingsV2.accent,
              FrostPicker<Color>.palette(
                label: t.settingsV2.accent,
                value: customSelected
                    ? null
                    : appearance.accentFor(_brightness),
                options: [
                  for (final color in colours)
                    FrostPickerOption(
                      value: color,
                      label: '#${accentHex(color)}',
                      color: color,
                      enabled: validateAccent(
                        color,
                        _brightness,
                        appFrostConfig.palettes,
                      ).canApply,
                    ),
                ],
                onChanged: _saving ? null : _accent,
                trailingSwatch: FrostColorSwatch(
                  color: custom ?? FrostThemeTokens.of(context).fill,
                  label: t.settingsV2.customColour,
                  selected: customSelected,
                  icon: custom == null ? appIcons.add : null,
                  onPressed: _saving ? null : _customAccent,
                ),
              ),
            ),
          ],
        ),
        if (ref.watch(predictiveBackAvailableProvider).value == true) ...[
          const SizedBox(height: FrostGap.section),
          FrostGroupedSection(
            footer: t.settingsV2.predictiveBackScope,
            children: [
              FrostListRow.toggle(
                title: t.settingsV2.predictiveBack,
                value: settings.predictiveBack,
                onChanged: ref
                    .read(settingsProvider.notifier)
                    .setPredictiveBack,
              ),
            ],
          ),
        ],
        const SizedBox(height: FrostGap.section),
        FrostGroupedSection(
          footer: SystemTransparencyPreference.disabledOf(context)
              ? t.settingsV2.systemTransparencyReduced
              : null,
          children: [
            optionsRow(
              t.settingsV2.background,
              FrostPicker<BackgroundMaterial>.segmented(
                label: t.settingsV2.background,
                value: settings.background.material,
                options: [
                  FrostPickerOption(
                    value: BackgroundMaterial.ambient,
                    label: t.settingsV2.ambientBlur,
                  ),
                  if (FrostWindowCaptionScope.systemBackdropAvailableOf(
                    context,
                  ))
                    FrostPickerOption(
                      value: BackgroundMaterial.mica,
                      label: t.settingsV2.mica,
                    ),
                  FrostPickerOption(
                    value: BackgroundMaterial.off,
                    label: t.settingsV2.backgroundOff,
                  ),
                ],
                onChanged: _savingBackground
                    ? null
                    : (value) => _saveBackground(
                        () => ref
                            .read(settingsProvider.notifier)
                            .setBackgroundMaterial(value),
                      ),
              ),
            ),
            FrostPresence(
              visible:
                  settings.background.material == BackgroundMaterial.ambient,
              effect: FrostPresenceEffect.expand,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FrostListRow(title: t.settingsV2.backgroundIntensity),
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: FrostGap.of(context).rowInset,
                      end: FrostGap.of(context).rowInset,
                      bottom: FrostGap.related,
                    ),
                    child: FrostSlider(
                      value: settings.background.intensity.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 18,
                      semanticLabel: t.settingsV2.backgroundIntensity,
                      valueLabel: (value) => '${value.round()}%',
                      onChanged: _savingBackground
                          ? null
                          : ref
                                .read(settingsProvider.notifier)
                                .previewBackgroundIntensity,
                      onChangeEnd: _saveIntensity,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccentForm extends StatefulWidget {
  const _AccentForm({required this.initial, required this.onApply, super.key});
  final String initial;
  final Future<bool> Function(Color) onApply;
  @override
  State<_AccentForm> createState() => _AccentFormState();
}

class _AccentFormState extends State<_AccentForm> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<bool> submit() async {
    final color = parseAccentHex(_text.text);
    final brightness = FrostThemeTokens.of(context).brightness;
    if (color == null) {
      setState(() => _error = t.settingsV2.invalidHex);
      return false;
    }
    if (!validateAccent(color, brightness, appFrostConfig.palettes).canApply) {
      setState(() => _error = t.settingsV2.accentRejected);
      return false;
    }
    return widget.onApply(color);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return FrostTextField(
      label: t.settingsV2.customHex,
      controller: _text,
      monospace: true,
      error: _error,
      autofocus: true,
    );
  }
}
