import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

const nativeFailure = BooruError(
  code: BooruErrorCode.internal,
  sourceId: 'aibooru',
  userMessageKey: 'webChallenge.windowFailed',
  diagnosticId: 'toast-test',
  details: 'stage=webview-create\nHRESULT=0x80070005',
);
Widget app(VoidCallback fail) => TranslationProvider(
  child: FrostScope(
    config: appFrostConfig,
    child: MaterialApp(
      navigatorKey: AppRouter.rootNavigatorKey,
      theme: FrostTheme.build(
        config: appFrostConfig,
        brightness: Brightness.light,
        platform: TargetPlatform.windows,
        locale: const Locale('en'),
      ),
      builder: (_, child) => FrostToastHost(child: child!),
      home: Scaffold(
        body: FrostButton(label: 'Fail', onPressed: fail),
      ),
    ),
  ),
);
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  testWidgets(
    'App operation wrapper preserves summary and structured native details through one shared path',
    (tester) async {
      await tester.pumpWidget(
        app(() => AppToast.errorWithCause('Operation failed', nativeFailure)),
      );
      await tester.tap(find.text('Fail'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Operation failed'), findsOneWidget);
      expect(find.textContaining('HRESULT'), findsNothing);
      final label = FrostScope.labelsOf(
        tester.element(find.byType(FrostToastHost)),
      ).errorDetails;
      final button = find.byWidgetPredicate(
        (w) => w is FrostButton && w.label == label,
      );
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final details = tester
          .widget<FrostErrorDetails>(find.byType(FrostErrorDetails))
          .details;
      expect(details, contains('stage=webview-create'));
      expect(details, contains('HRESULT=0x80070005'));
      expect(details, contains('source=aibooru'));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'message-only failures retain their operation summary without invented details',
    (tester) async {
      await tester.pumpWidget(app(() => AppToast.error('Validation failed')));
      await tester.tap(find.text('Fail'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Validation failed'), findsOneWidget);
      expect(find.byType(FrostErrorDetails), findsNothing);
      final label = FrostScope.labelsOf(
        tester.element(find.byType(FrostToastHost)),
      ).errorDetails;
      expect(
        find.byWidgetPredicate((w) => w is FrostButton && w.label == label),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
