import 'dart:io';

import 'package:flutter/services.dart';

/// Whether CJK text is drawn with the Noto Sans subsets bundled into the app.
///
/// Windows's own CJK fonts render poorly and Linux installations do not
/// always have one, so the app package for those two platforms carries the
/// subsets. Android, iOS and macOS draw CJK text with their system fonts and
/// their packages leave the subset files out (see `platforms` in
/// pubspec.yaml).
final bool bundlesCjkFonts = Platform.isWindows || Platform.isLinux;

const bundledJapaneseFamily = 'Noto Sans JP';
const bundledSimplifiedChineseFamily = 'Noto Sans SC';

/// Registers the bundled CJK families. Fonts listed in the `fonts` section of
/// pubspec.yaml go into every platform's package, so the subsets are plain
/// assets registered here before the first frame.
Future<void> loadBundledFonts() async {
  if (!bundlesCjkFonts) return;
  await Future.wait([
    for (final (family, file) in const [
      (bundledJapaneseFamily, 'NotoSansJP-Subset.ttf'),
      (bundledSimplifiedChineseFamily, 'NotoSansSC-Subset.ttf'),
    ])
      (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file')))
          .load(),
  ]);
}
