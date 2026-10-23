import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only binding. Redirects framework notifications, never Windows focus.
class AutomationBinding extends WidgetsFlutterBinding
    with TestDefaultBinaryMessengerBinding {
  AutomationBinding(this.handler) {
    FocusManager.instance.rootScope.canRequestFocus = !Platform.isWindows;
    if (Platform.isWindows) {
      // Observe actual outgoing caption updates, then forward unchanged to the
      // real native plugin. No window method or hit-test behavior is mocked.
      const channel = MethodChannel('frost_window');
      const codec = StandardMethodCodec();
      defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        final response = await defaultBinaryMessenger.delegate.send(
          channel.name,
          codec.encodeMethodCall(call),
        );
        final result = response == null ? null : codec.decodeEnvelope(response);
        if (call.method == 'setRegions') {
          captionRegions = List<Object?>.unmodifiable(
            call.arguments as List<Object?>,
          );
        }
        return result;
      });
    }
  }
  final DataHandler handler;
  List<Object?> captionRegions = const [];
  // The SDK deliberately exposes its Driver extension only for test harnesses.
  // ignore: invalid_use_of_visible_for_testing_member
  FlutterDriverExtension? _driver;
  bool pretendForeground = false;
  AppLifecycleState? rawLifecycle;
  final Map<int, ui.ViewFocusEvent> rawViewFocus = {};
  final ValueNotifier<int> changes = ValueNotifier(0);

  void initializePlatformState({
    required bool visible,
    required bool isForeground,
  }) {
    // A window that has never been activated can have no initial lifecycle
    // message. Seed that missing state from the runner's actual OS observation.
    if (rawLifecycle == null && visible) {
      // Do not introduce an artificial hidden lifecycle during the first show.
      handleAppLifecycleStateChanged(
        isForeground ? AppLifecycleState.resumed : AppLifecycleState.inactive,
      );
    }
  }

  @override
  bool debugCheckZone(String entryPoint) => true;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    // Android uses scoped HTTP controls and the actual platform IME. The Driver
    // extension's text emulation would replace that IME even in AOT.
    if (!Platform.isWindows) return;
    // An explicit test entrypoint needs a custom binding to intercept events
    // before framework observers, rather than patching the application's UI.
    // ignore: invalid_use_of_visible_for_testing_member
    final extension = _driver = FlutterDriverExtension(handler, false, true);
    // Same test-only extension API as the SDK's standard driver binding.
    // ignore: invalid_use_of_visible_for_testing_member
    registerServiceExtension(name: 'driver', callback: extension.call);
  }

  Future<void> enterText(String text) async {
    final driver = _driver;
    if (driver == null) {
      throw StateError(
        'Internal text entry requires the dedicated Windows Debug Driver extension',
      );
    }
    // Feed the SDK Driver's existing emulated text-input channel. Do not assign
    // an application's controller or send keys to the host desktop.
    // ignore: invalid_use_of_visible_for_testing_member
    final result = await driver.call({'command': 'enter_text', 'text': text});
    if (result['isError'] == true) throw StateError('${result['response']}');
  }

  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    rawLifecycle = state;
    super.handleAppLifecycleStateChanged(
      pretendForeground ? AppLifecycleState.resumed : state,
    );
    changes.value++;
  }

  @override
  void handleViewFocusChanged(ui.ViewFocusEvent event) {
    rawViewFocus[event.viewId] = event;
    if (Platform.isWindows &&
        !pretendForeground &&
        event.state == ui.ViewFocusState.unfocused) {
      FocusManager.instance.rootScope.canRequestFocus = false;
    }
    super.handleViewFocusChanged(
      pretendForeground ? _focused(event.viewId) : event,
    );
    if (!pretendForeground && event.state == ui.ViewFocusState.focused) {
      FocusManager.instance.rootScope.canRequestFocus = true;
    }
    changes.value++;
  }

  void setPretendForeground(bool enabled) {
    if (pretendForeground == enabled) return;
    pretendForeground = enabled;
    if (!enabled && Platform.isWindows) {
      FocusManager.instance.rootScope.canRequestFocus = false;
    }
    // Replay actual platform state on disable. Do not request real view focus.
    final effective = enabled
        ? AppLifecycleState.resumed
        : (rawLifecycle ?? AppLifecycleState.inactive);
    super.handleAppLifecycleStateChanged(effective);
    SystemChrome.handleAppLifecycleStateChanged(effective);
    for (final view in platformDispatcher.views) {
      super.handleViewFocusChanged(
        enabled
            ? _focused(view.viewId)
            : (rawViewFocus[view.viewId] ??
                  ui.ViewFocusEvent(
                    viewId: view.viewId,
                    state: ui.ViewFocusState.unfocused,
                    direction: ui.ViewFocusDirection.undefined,
                  )),
      );
    }
    // Notify View's focus observer before enabling focus traversal. Otherwise
    // gaining framework focus would ask Windows to activate the real view.
    FocusManager.instance.rootScope.canRequestFocus =
        enabled ||
        !Platform.isWindows ||
        rawViewFocus.values.any(
          (event) => event.state == ui.ViewFocusState.focused,
        );
    changes.value++;
  }

  ui.ViewFocusEvent _focused(int id) => ui.ViewFocusEvent(
    viewId: id,
    state: ui.ViewFocusState.focused,
    direction: ui.ViewFocusDirection.undefined,
  );
}
