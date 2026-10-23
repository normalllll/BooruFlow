import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import 'detail_viewer_v2_test.dart' show data;

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  test('post date follows the selected application locale', () async {
    await initializeDateFormatting();
    final post = Post(data('101'));
    final date = DateTime.parse(post.data.createdAtIso8601!).toLocal();
    for (final locale in [AppLocale.zhCn, AppLocale.ja, AppLocale.en]) {
      LocaleSettings.setLocaleSync(locale);
      expect(postDate(post), DateFormat.yMd(locale.languageTag).format(date));
      expect(
        postDate(post, full: true),
        DateFormat.yMd(locale.languageTag).add_jm().format(date),
      );
    }
  });
  test('source display removes only transport and redundant www prefix', () {
    expect(
      postSourceDisplay('https://www.pixiv.net/artworks/123456789'),
      'pixiv.net/artworks/123456789',
    );
    expect(
      postSourceDisplay('https://example.org/work?id=3#detail'),
      'example.org/work?id=3#detail',
    );
    expect(postSourceDisplay('A source note'), 'A source note');
  });
  test('headline uses artist then character then copyright then ID', () {
    Post withTags(List<BooruTag> tags) {
      final base = data('101');
      return Post(
        BooruPost(
          sourceId: base.sourceId,
          postId: base.postId,
          postKey: base.postKey,
          rating: base.rating,
          tags: tags,
          media: base.media,
          flags: base.flags,
        ),
      );
    }

    const artist = BooruTag(
      name: 'actual_artist',
      category: TagCategory.artist,
    );
    const character = BooruTag(
      name: 'main_character',
      category: TagCategory.character,
    );
    const work = BooruTag(
      name: 'original_work',
      category: TagCategory.copyright,
    );
    expect(postCreator(withTags([work, character, artist])), 'actual artist');
    expect(postCopyrightMetadata(withTags([work, character, artist])), isEmpty);
    expect(postCopyrightMetadata(withTags([work, character])), [
      'original work',
    ]);
    expect(postCopyrightMetadata(withTags([work])), isEmpty);
    expect(postCreator(withTags([work, character])), 'main character');
    expect(postCreator(withTags([work])), 'original work');
    expect(postCreator(withTags([])), '#101');
  });
  test(
    'redundant translations ignore case and underscore or space formatting',
    () {
      for (final translated in ['Bikini', ' bikini ', 'BIKINI']) {
        expect(distinctTagTranslation('bikini', translated), isNull);
      }
      expect(distinctTagTranslation('long_hair', 'Long  Hair'), isNull);
      expect(distinctTagTranslation('long_hair', '長髮'), '長髮');
      expect(distinctTagTranslation('tattoo', ''), isNull);
      for (final invalid in [
        '##!!!!',
        '...',
        '   ',
        'null',
        'TODO',
        'N/A',
        '???',
      ]) {
        expect(distinctTagTranslation('bra', invalid), isNull);
      }
      for (final valid in ['下着', '胸罩', 'Lingerie (1)', '肌着・下着']) {
        expect(distinctTagTranslation('bra', valid), valid);
      }
    },
  );
  for (final width in [340.0, 260.0, 100.0]) {
    testWidgets(
      'actions remain one row, fit and retain original activation at $width',
      (tester) async {
        var opens = 0;
        await tester.pumpWidget(
          ProviderScope(
            child: browseTestApp(
              Center(
                child: SizedBox(
                  width: width,
                  child: PostDetailActions(
                    post: Post(data('101')),
                    onOpen: () => opens++,
                  ),
                ),
              ),
              scale: 2,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final fit = find.byType(FrostFit);
        expect(fit, findsOneWidget);
        final visible = find
            .byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.postDetail.viewOriginal,
            )
            .hitTestable();
        if (visible.evaluate().isNotEmpty) {
          final download = find
              .byWidgetPredicate(
                (w) => w is FrostButton && w.label == t.postDetail.download,
              )
              .hitTestable();
          expect(tester.getCenter(visible).dy, tester.getCenter(download).dy);
          await tester.tap(visible);
        } else {
          final original = find
              .byWidgetPredicate(
                (w) => w is FrostButton && w.label == t.postDetail.viewOriginal,
              )
              .last;
          await tester.ensureVisible(original);
          await tester.pumpAndSettle();
          await tester.tap(original);
        }
        expect(opens, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
