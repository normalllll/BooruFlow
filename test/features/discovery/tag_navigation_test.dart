import 'dart:async';
import 'dart:io';

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/features/about/about_page.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:toastification/toastification.dart';

import 'search_interaction_test.dart' show testSource, SearchRepositoryFake;

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  toastification.dismissAll(delayForAnimation: false);
  await tester.pumpAndSettle();
}

void main() {
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp(
      'booruflow-tag-navigation-',
    );
    Hive.init(directory.path);
    await TagSuggestionRepository.instance.initialize();
    BooruService.instance.useSourcesForTesting([
      testSource('first'),
      testSource('second'),
    ]);
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'registered tag manager uses shell back on desktop and AppBar back on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AppRouter.router.go(AppRoute.about.path);
      await tester.pumpWidget(
        ProviderScope(
          child: AppToastWrapper(
            child: MaterialApp.router(
              theme: darkTheme(),
              routerConfig: AppRouter.router,
            ),
          ),
        ),
      );
      await settle(tester);
      final context = tester.element(find.byType(AboutPage));
      context.pushUserTags<void>(sourceId: 'first');
      await settle(tester);
      expect(find.byType(UserTagsPage), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(AppRouter.rightNavigatorCanPop.value, isTrue);
      expect(find.text(t.discovery.noCustomTags), findsOneWidget);
      expect(find.text(t.discovery.customTagsHint), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.text(t.discovery.addTag));
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.tap(find.text(t.generic.cancel));
      await settle(tester);
      await tester.runAsync(
        () => TagSuggestionRepository.instance.saveAlias(
          const UserTagAlias(
            id: 'test',
            value: 'sky',
            sourceId: 'first',
            locale: 'en',
          ),
        ),
      );
      await settle(tester);
      expect(find.text(t.discovery.noCustomTags), findsNothing);
      await tester.runAsync(
        () => TagSuggestionRepository.instance.saveAlias(
          const UserTagAlias(
            id: 'test2',
            value: 'cloud',
            sourceId: UserTagAlias.allSources,
            locale: 'en',
          ),
        ),
      );
      await settle(tester);
      final card = find.byKey(const ValueKey('custom-tag-test'));
      final secondCard = find.byKey(const ValueKey('custom-tag-test2'));
      expect(tester.getRect(card).left, tester.getRect(secondCard).left);
      expect(tester.getRect(secondCard).top - tester.getRect(card).bottom, 12);
      final title = find
          .descendant(of: card, matching: find.text('#sky', findRichText: true))
          .first;
      expect(tester.getRect(title).left - tester.getRect(card).left, 14);
      expect(find.text(t.discovery.allTagSources), findsOneWidget);
      await tester.runAsync(
        () => TagSuggestionRepository.instance.deleteAlias('test2'),
      );
      await settle(tester);
      expect(find.text(t.discovery.addTag), findsOneWidget);
      await tester.tap(find.text(t.discovery.addTag));
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(t.generic.cancel));
      await settle(tester);
      await tester.runAsync(
        () => TagSuggestionRepository.instance.deleteAlias('test'),
      );
      await settle(tester);
      expect(find.text(t.discovery.noCustomTags), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.byType(UserTagsPage), findsNothing);
      expect(find.byType(AboutPage), findsOneWidget);
      expect(AppRouter.rightNavigatorCanPop.value, isFalse);

      // The editor lives in a modal on the same content navigator.
      showModalBottomSheet<void>(
        context: tester.element(find.byType(AboutPage)),
        isScrollControlled: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: .92,
          child: PostSearchPage(
            sourceId: 'first',
            repository: SearchRepositoryFake(),
            onSubmit: (_, _) {},
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.text(t.discovery.manageTags));
      await settle(tester);
      expect(find.byType(UserTagsPage), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.byType(PostSearchPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(PostSearchPage))).pop();
      await settle(tester);

      tester.view.physicalSize = const Size(360, 740);
      await settle(tester);
      tester
          .element(find.byType(AboutPage))
          .pushUserTags<void>(sourceId: 'first');
      await settle(tester);
      expect(find.byType(UserTagsPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.text(t.discovery.addTag));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'mobile_tag');
      await tester.runAsync(() async {
        final saved = Completer<void>();
        void onSaved() {
          if (!saved.isCompleted) saved.complete();
        }

        final subscription = TagSuggestionRepository.instance.changes.listen(
          (_) => onSaved(),
        );
        try {
          await tester.tap(find.text(t.generic.confirm));
          await saved.future.timeout(const Duration(seconds: 3));
        } finally {
          await subscription.cancel();
        }
      });
      await settle(tester);
      expect(TagSuggestionRepository.instance.aliases.single.sourceId, 'first');
      expect(find.text('#mobile_tag', findRichText: true), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(UserTagsPage), findsNothing);
      expect(find.byType(AboutPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
    },
  );
}
