import 'dart:ui' as ui;
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/posts/widgets/post_detail_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'media header automatic back and more share the scoped circular plate $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final reselection = ValueNotifier((index: 0, sequence: 0));
        addTearDown(reselection.dispose);
        await tester.pumpWidget(
          browseTestApp(
            Builder(
              builder: (context) => FrostShellNavigationScope(
                ownsBackControl: false,
                canGoBack: true,
                goBack: () {},
                primaryReselection: reselection,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: PostMediaHeader(
                    title: const SizedBox.shrink(),
                    actions: [
                      postMoreAction(context, [
                        FrostMenuAction(
                          'Copy',
                          icon: appIcons.copy,
                          onSelected: () {},
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            brightness: brightness,
            platform: TargetPlatform.android,
          ),
        );
        await tester.pumpAndSettle();
        final header = find.byType(PostMediaHeader);
        final tokens = FrostThemeTokens.of(tester.element(header));
        final circles = find
            .descendant(
              of: header,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.decoration is ShapeDecoration &&
                    (w.decoration as ShapeDecoration).shape is CircleBorder &&
                    (w.decoration as ShapeDecoration).color ==
                        tokens.onMediaScrim,
              ),
            )
            .hitTestable();
        expect(circles, findsNWidgets(2));
        final glyphs = find
            .descendant(of: header, matching: find.byType(FrostIcon))
            .hitTestable();
        for (final glyph in glyphs.evaluate()) {
          final center = tester.getCenter(find.byWidget(glyph.widget));
          final distance = circles
              .evaluate()
              .map(
                (circle) =>
                    (center - tester.getCenter(find.byWidget(circle.widget)))
                        .distance,
              )
              .reduce((a, b) => a < b ? a : b);
          expect(
            distance,
            lessThan(.01),
            reason: 'media glyph must be centered',
          );
        }
        expect(
          tester
              .widgetList<FrostIcon>(
                find.descendant(of: header, matching: find.byType(FrostIcon)),
              )
              .every((w) => w.color == tokens.onMediaInk),
          isTrue,
        );

        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final pinned in [false, true]) {
    for (final background in [Colors.white, Colors.black]) {
      testWidgets('media system icons and scrim pinned=$pinned $background', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 47, bottom: 24);
        addTearDown(tester.view.reset);
        const capture = ValueKey('media system region');
        const header = PostMediaHeader(title: SizedBox.shrink(), actions: []);
        await tester.pumpWidget(
          browseTestApp(
            RepaintBoundary(
              key: capture,
              child: FrostMediaSystemChromeHost(
                child: ColoredBox(
                  color: background,
                  child: pinned
                      ? const FrostPinnedChrome(
                          chrome: header,
                          body: SizedBox.expand(),
                        )
                      : const Align(
                          alignment: Alignment.topCenter,
                          child: header,
                        ),
                ),
              ),
            ),
            platform: TargetPlatform.android,
          ),
        );
        await tester.pumpAndSettle();
        final toolbar = find.descendant(
          of: find.byType(PostMediaHeader),
          matching: find.byType(FrostToolbar),
        );
        expect(tester.getRect(toolbar).top, 47);
        expect(
          tester.getSize(find.byType(PostMediaHeader)).height,
          tester.getSize(toolbar).height + (pinned ? 0 : 47),
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        final overlay = boundary.debugLayer!.find<SystemUiOverlayStyle>(
          const Offset(195, 10),
        );
        expect(overlay?.statusBarIconBrightness, Brightness.light);
        expect(overlay?.systemStatusBarContrastEnforced, isFalse);
        final tokens = FrostThemeTokens.of(
          tester.element(find.byType(PostMediaHeader)),
        );
        final image = (await tester.runAsync(() => boundary.toImage()))!;
        final bytes = (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        Color pixel(int y) {
          final at = (y * image.width + 195) * 4;
          return Color.fromARGB(
            255,
            bytes.getUint8(at),
            bytes.getUint8(at + 1),
            bytes.getUint8(at + 2),
          );
        }

        final atTen = Color.lerp(
          tokens.onMediaScrim.withValues(alpha: 1),
          tokens.onMediaScrim,
          10.5 / 47,
        )!;
        final expected = Color.alphaBlend(atTen, background);
        expect(
          pixel(10).r,
          closeTo(expected.r, 1 / 255),
          reason: 'the scrim fades smoothly from the very top',
        );
        expect(
          pixel(80),
          background,
          reason: 'scrim fades away below status bar',
        );
        if (background == Colors.white) {
          expect(
            pixel(0).computeLuminance(),
            lessThan(pixel(10).computeLuminance()),
          );
          expect(
            pixel(10).computeLuminance(),
            lessThan(pixel(30).computeLuminance()),
          );
        }
        final luminance = pixel(46).computeLuminance();
        expect(
          1.05 / (luminance + .05),
          greaterThanOrEqualTo(3),
          reason: 'status icons retain non-text contrast even over white media',
        );
        image.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
