import 'dart:async';

import 'package:booruflow/core/media/booru_media_source.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fake_media_cancel.dart';

// Flutter normally remembers only pending exceptions. Keep noticed errors as
// well so consuming an exception cannot accidentally make a UI test pass.
class _StrictWidgetBinding extends AutomatedTestWidgetsFlutterBinding {
  final errors = <FlutterErrorDetails>[];

  @override
  void reportExceptionNoticed(FlutterErrorDetails exception) {
    errors.add(exception);
    super.reportExceptionNoticed(exception);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  configurePluralRules();
  // Fake engines need no native library to stop a download.
  createMediaCancel = FakeMediaCancel.new;
  final binding = _StrictWidgetBinding();
  setUp(binding.errors.clear);
  tearDown(() {
    expect(
      binding.errors,
      isEmpty,
      reason: binding.errors.map((error) => error.toString()).join('\n\n'),
    );
  });
  await testMain();
}
