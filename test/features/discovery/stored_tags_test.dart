import 'dart:io';

import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  test(
    'discard incompatible stored tag data and retain current aliases and search history',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'booruflow-tags-',
      );
      Hive.init(directory.path);
      final box = await Hive.openBox<dynamic>('discovery_tags');
      try {
        await box.put('aliases', [
          {'id': 'old', 'value': 'sky'},
        ]);
        await box.put('migrated', true);
        await box.put('cache:old', {
          'items': ['sky'],
        });
        await box.put('index:old', [
          {'value': 'sky', 'category': -1},
        ]);
        await box.put('history:yande', ['sky']);
        final repository = TagSuggestionRepository();
        await repository.initialize();
        expect(repository.aliases, isEmpty);
        expect(box.keys, ['history:yande']);
        await repository.saveAlias(
          const UserTagAlias(
            id: 'current',
            value: 'sky',
            sourceId: 'yande',
            locale: 'zh-CN',
            displayName: '天空',
          ),
        );
        final reopened = TagSuggestionRepository();
        await reopened.initialize();
        expect(reopened.aliases.single.displayName, '天空');
        expect(box.get('history:yande'), ['sky']);
        await reopened.saveAlias(
          const UserTagAlias(
            id: 'global',
            value: 'sky',
            sourceId: UserTagAlias.allSources,
            locale: 'zh-CN',
            displayName: '通用天空',
          ),
        );
        expect(reopened.displayName('yande', 'zh-CN', 'sky'), '天空');
        expect(reopened.displayName('danbooru', 'zh-CN', 'sky'), '通用天空');
        final globalReopened = TagSuggestionRepository();
        await globalReopened.initialize();
        expect(globalReopened.displayName('danbooru', 'zh-CN', 'sky'), '通用天空');
        await globalReopened.saveAlias(
          const UserTagAlias(
            id: 'global',
            value: 'sky',
            sourceId: 'danbooru',
            locale: 'zh-CN',
            displayName: '站点天空',
          ),
        );
        expect(globalReopened.displayName('danbooru', 'zh-CN', 'sky'), '站点天空');
        expect(globalReopened.displayName('yande', 'zh-CN', 'sky'), '天空');
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
