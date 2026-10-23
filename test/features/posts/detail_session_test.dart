import 'dart:async';

import 'package:booruflow/features/posts/detail_session.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'detail_switching_r11_test.dart' show item;

void main() {
  test(
    'one family and received results are reused until the page is disposed',
    () async {
      final root = item('100', 1, children: true),
          a = item('101', .5, parent: '100'),
          b = item('102', 2, parent: '100');
      final requests = <PostIdentity>[], families = <PostIdentity>[];
      final parent = Completer<Post>();
      final familyResult = Completer<List<Post>>();
      final session = PostDetailSession(
        initial: a,
        knownPosts: [a],
        loadPost: (key) {
          requests.add(key);
          return key.postId == '100' ? parent.future : Future.value(a);
        },
        loadFamily: (key) {
          families.add(key);
          return familyResult.future;
        },
      );
      session.start();
      final family = session.family(a)!;
      expect(family.keys.map((k) => k.postId), ['100', '101']);
      expect(session.lookup(postIdentity(root)), isNull);
      familyResult.complete([b, root, a]);
      await Future<void>.delayed(Duration.zero);
      expect(session.lookup(postIdentity(root)), same(root));
      expect(family.keys.map((k) => k.postId), ['100', '101', '102']);
      parent.complete(root);
      await Future<void>.delayed(Duration.zero);
      for (final post in [b, root, a, b]) {
        session.select(post);
        expect(session.family(post), same(family));
        expect(family.keys.map((k) => k.postId), ['100', '101', '102']);
      }
      expect(families, [postIdentity(root)]);
      expect(requests.map((k) => k.postId), ['101', '100']);
      session.dispose();
      expect(session.lookup(postIdentity(a)), isNull);
      final reopened = PostDetailSession(
        initial: a,
        knownPosts: [a],
        loadPost: (key) async {
          requests.add(key);
          return a;
        },
        loadFamily: (key) async {
          families.add(key);
          return [root, a, b];
        },
      );
      reopened.start();
      await Future<void>.delayed(Duration.zero);
      expect(families, hasLength(2));
      reopened.dispose();
    },
  );
  test(
    'page exit discards late detail and family results without notification',
    () async {
      final post = item('100', 1, children: true);
      final detail = Completer<Post>(), family = Completer<List<Post>>();
      final session = PostDetailSession(
        initial: post,
        knownPosts: [post],
        loadPost: (_) => detail.future,
        loadFamily: (_) => family.future,
      );
      var notified = 0;
      session.addListener(() => notified++);
      session.start();
      session.dispose();
      detail.complete(post);
      family.complete([post]);
      await Future<void>.delayed(Duration.zero);
      expect(notified, 0);
      expect(session.lookup(postIdentity(post)), isNull);
    },
  );
  test(
    'geometry accepts only this work decoded ratio, not stale async work',
    () {
      final a = item('101', .5), b = item('102', 2);
      final geometry = PostMediaGeometry(b);
      expect(geometry.decoded(a.postKey, .25), false);
      expect(geometry.aspectRatio, 2);
      expect(geometry.decoded(b.postKey, 1.75), true);
      expect(geometry.aspectRatio, 1.75);
      expect(geometry.decoded(b.postKey, double.nan), false);
    },
  );
}
