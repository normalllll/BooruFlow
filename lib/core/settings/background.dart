import 'package:flutter/widgets.dart';

/// Saved user intent; system accessibility preferences override paint only.
enum BackgroundMaterial { ambient, mica, off }

const _defaultIntensity = 100;
const _minimumIntensity = 10;
const _intensityStep = 5;

@immutable
class BackgroundSettings {
  const BackgroundSettings({
    this.material = BackgroundMaterial.ambient,
    this.intensity = _defaultIntensity,
  }) : assert(
         intensity >= _minimumIntensity &&
             intensity <= _defaultIntensity &&
             intensity % _intensityStep == 0,
       );
  factory BackgroundSettings.fromRecord(Object? record) {
    if (record is! Map) return const BackgroundSettings();
    return BackgroundSettings(
      material:
          BackgroundMaterial.values
              .where((v) => v.name == record['material'])
              .firstOrNull ??
          BackgroundMaterial.ambient,
      intensity: record['intensity'] is num
          ? normalizeIntensity((record['intensity'] as num).toDouble())
          : _defaultIntensity,
    );
  }
  final BackgroundMaterial material;
  final int intensity;
  static int normalizeIntensity(double value) => value.isFinite
      ? ((value / _intensityStep).round() * _intensityStep).clamp(
          _minimumIntensity,
          _defaultIntensity,
        )
      : _defaultIntensity;
  BackgroundSettings copyWith({BackgroundMaterial? material, int? intensity}) =>
      BackgroundSettings(
        material: material ?? this.material,
        intensity: intensity ?? this.intensity,
      );
  Map<String, Object> toRecord() => {
    'material': material.name,
    'intensity': intensity,
  };
}

/// System preference comes from the live window host, not persisted settings.
class SystemTransparencyPreference extends InheritedWidget {
  const SystemTransparencyPreference({
    required this.disabled,
    required super.child,
    super.key,
  });
  final bool disabled;
  static bool disabledOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SystemTransparencyPreference>()
          ?.disabled ??
      MediaQuery.highContrastOf(context);
  @override
  bool updateShouldNotify(SystemTransparencyPreference oldWidget) =>
      disabled != oldWidget.disabled;
}
