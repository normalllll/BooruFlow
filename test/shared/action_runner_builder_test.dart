import 'dart:async';

import 'package:booruflow/shared/action_runner_builder.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../support/browse_support.dart' show browseTestApp;

void main() {
  for (final (showsResult, succeeded) in [(true, true), (false, false)]) {
    testWidgets(
      'showsResult: $showsResult ${showsResult ? 'keeps' : 'drops'} the '
      'result after the action',
      (tester) async {
        final done = Completer<bool>();
        FrostActionState? state;
        await tester.pumpWidget(
          browseTestApp(
            ActionRunnerBuilder(
              showsResult: showsResult,
              builder: (context, runner) {
                state = runner.state;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => runner.run(() => done.future),
                  child: const SizedBox(width: 40, height: 40),
                );
              },
            ),
          ),
        );
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        expect(state, isNot(FrostActionState.idle));
        done.complete(true);
        await tester.pump();
        await tester.pump();
        expect(state == FrostActionState.idle, !succeeded);
      },
    );
  }

  testWidgets('running only: a second press is ignored while it runs', (
    tester,
  ) async {
    var runs = 0;
    final done = Completer<bool>();
    await tester.pumpWidget(
      browseTestApp(
        ActionRunnerBuilder(
          showsResult: false,
          builder: (context, runner) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => runner.run(() {
              runs++;
              return done.future;
            }),
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GestureDetector));
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(runs, 1);
    done.complete(false);
    await tester.pump();
    await tester.tap(find.byType(GestureDetector));
    expect(runs, 2);
    done.future.ignore();
  });
}
