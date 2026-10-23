import 'dart:io';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  test(
    'history persists whole queries, deduplicates and isolates sources',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'booruflow-search-history-',
      );
      Hive.init(directory.path);
      addTearDown(() async {
        await Hive.close();
        final target = directory.resolveSymbolicLinksSync();
        final parent = Directory.systemTemp.resolveSymbolicLinksSync();
        if (!target.startsWith(
          '$parent${Platform.pathSeparator}booruflow-search-history-',
        )) {
          throw StateError('Unexpected history fixture path');
        }
        await directory.delete(recursive: true);
      });
      final repository = TagSuggestionRepository();
      await repository.remember('first', ['red', 'blue']);
      await repository.remember('first', ['green']);
      await repository.remember('first', ['red', 'blue']);
      await repository.remember('second', ['other']);
      expect(await repository.recentSearches('first'), ['red blue', 'green']);
      await Hive.close();
      final restored = TagSuggestionRepository();
      expect(await restored.recentSearches('first'), ['red blue', 'green']);
      await restored.removeSearch('first', 'red blue');
      expect(await restored.recentSearches('first'), ['green']);
      await restored.clearSearches('first');
      expect(await restored.recentSearches('first'), isEmpty);
      expect(await restored.recentSearches('second'), ['other']);
    },
  );
}
