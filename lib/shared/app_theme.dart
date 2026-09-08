import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SystemUiOverlayStyle appSystemUiOverlayStyle(Brightness brightness) {
  final icons = switch (brightness) {
    Brightness.dark => Brightness.light,
    _ => Brightness.dark,
  };
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: brightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}

/// Reusable visual tokens shared by application and feature widgets.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.brand,
    required this.accent,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceTint,
    required this.surfaceMuted,
    required this.line,
    required this.shadow,
  });

  static const brandPink = Color(0xFFFC619D);

  static const light = AppThemeTokens(
    brand: brandPink,
    accent: Color(0xFF7BBDEB),
    surface: Color(0xFFFFFBFD),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFFFF4F8),
    surfaceMuted: Color(0xFFF6F1F4),
    line: Color(0xFFEBDDE4),
    shadow: Color(0x10000000),
  );

  static const dark = AppThemeTokens(
    brand: Color(0xFFFF79AD),
    accent: Color(0xFF8FB8D8),
    surface: Color(0xFF121214),
    surfaceRaised: Color(0xFF1B1B1E),
    surfaceTint: Color(0xFF222226),
    surfaceMuted: Color(0xFF242428),
    line: Color(0xFF323238),
    shadow: Color(0x52000000),
  );

  final Color brand;
  final Color accent;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceTint;
  final Color surfaceMuted;
  final Color line;
  final Color shadow;

  static AppThemeTokens of(BuildContext context) {
    final fallback = switch (Theme.of(context).brightness) {
      Brightness.dark => dark,
      _ => light,
    };
    return Theme.of(context).extension<AppThemeTokens>() ?? fallback;
  }

  @override
  AppThemeTokens copyWith({
    Color? brand,
    Color? accent,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceTint,
    Color? surfaceMuted,
    Color? line,
    Color? shadow,
  }) {
    return AppThemeTokens(
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      line: line ?? this.line,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemeTokens lerp(covariant AppThemeTokens? other, double t) {
    if (other == null) return this;
    return AppThemeTokens(
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

ThemeData lightTheme([Color primaryColor = AppThemeTokens.brandPink]) {
  return _buildTheme(AppThemeTokens.light, Brightness.light, primaryColor);
}

ThemeData darkTheme([Color primaryColor = const Color(0xFFFF79AD)]) {
  return _buildTheme(AppThemeTokens.dark, Brightness.dark, primaryColor);
}

ThemeData _buildTheme(
  AppThemeTokens tokens,
  Brightness brightness,
  Color primaryColor,
) {
  final colorScheme = _colorScheme(tokens, brightness, primaryColor);
  final base = ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.surface,
    useMaterial3: true,
    extensions: [tokens],
  );

  return base.copyWith(
    splashColor: primaryColor.withValues(alpha: 0.10),
    highlightColor: primaryColor.withValues(alpha: 0.06),
    hoverColor: primaryColor.withValues(alpha: 0.05),
    dividerColor: tokens.line.withValues(
      alpha: switch (brightness) {
        Brightness.light => 0.55,
        _ => 0.45,
      },
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: appSystemUiOverlayStyle(brightness),
      backgroundColor: tokens.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: tokens.line.withValues(alpha: 0.42)),
      ),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: tokens.surfaceRaised,
      elevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: tokens.surfaceMuted,
      indicatorColor: primaryColor,
    ),
    cardTheme: CardThemeData(
      color: tokens.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shadowColor: tokens.shadow,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: _inputBorder(tokens.line),
      enabledBorder: _inputBorder(tokens.line),
      focusedBorder: _inputBorder(tokens.line),
      errorBorder: _inputBorder(colorScheme.error),
      focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.4),
      hintStyle: base.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: tokens.line),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: primaryColor,
      textColor: colorScheme.onSurface,
      tileColor: tokens.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

ColorScheme _colorScheme(
  AppThemeTokens tokens,
  Brightness brightness,
  Color primaryColor,
) {
  final base = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: brightness,
  );
  if (brightness == Brightness.light) {
    return base.copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFD8E8),
      onPrimaryContainer: const Color(0xFF4E102E),
      secondary: tokens.accent,
      onSecondary: const Color(0xFF082B42),
      secondaryContainer: const Color(0xFFE3F3FF),
      onSecondaryContainer: const Color(0xFF12344D),
      error: const Color(0xFFFF4F68),
      onError: Colors.white,
      surface: tokens.surface,
      onSurface: const Color(0xFF251821),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFFFF7FA),
      surfaceContainer: const Color(0xFFFFF3F7),
      surfaceContainerHigh: const Color(0xFFF9EEF3),
      surfaceContainerHighest: const Color(0xFFF3E8EE),
      onSurfaceVariant: const Color(0xFF6B5261),
      outline: const Color(0xFFD9C4CF),
      outlineVariant: tokens.line,
      shadow: tokens.shadow,
    );
  }

  return base.copyWith(
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF5A263D),
    onPrimaryContainer: const Color(0xFFFFD8E8),
    secondary: tokens.accent,
    onSecondary: const Color(0xFF102A3C),
    secondaryContainer: const Color(0xFF283D4E),
    onSecondaryContainer: const Color(0xFFE3F3FF),
    error: const Color(0xFFFF8A9A),
    onError: const Color(0xFF3A0710),
    surface: tokens.surface,
    onSurface: const Color(0xFFF1EEF0),
    surfaceContainerLowest: const Color(0xFF0E0E10),
    surfaceContainerLow: const Color(0xFF171719),
    surfaceContainer: const Color(0xFF1C1C1F),
    surfaceContainerHigh: const Color(0xFF232327),
    surfaceContainerHighest: const Color(0xFF2B2B30),
    onSurfaceVariant: const Color(0xFFC9C3C8),
    outline: const Color(0xFF6B666D),
    outlineVariant: tokens.line,
    shadow: tokens.shadow,
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
}
