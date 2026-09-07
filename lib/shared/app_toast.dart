import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/app/window/native_window.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';

class AppToastWrapper extends StatelessWidget {
  const AppToastWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      config: ToastificationConfig(
        alignment: AppPlatform.isDesktop
            ? Alignment.topRight
            : Alignment.bottomCenter,
        maxToastLimit: 5,
        marginBuilder: (context, alignment) {
          final y = alignment.resolve(Directionality.of(context)).y;
          return EdgeInsets.only(
            top: y <= -0.5 ? 12 + desktopTitleBarInset : 0,
            bottom: y >= 0.5 ? 12 : 0,
          );
        },
      ),
      child: child,
    );
  }
}

abstract final class AppToast {
  static const _defaultDuration = Duration(seconds: 3);
  static const _closeButton = ToastCloseButton(
    showType: CloseButtonShowType.none,
  );

  static void show(Object message, {Duration duration = _defaultDuration}) {
    _show(message, type: ToastificationType.info, duration: duration);
  }

  static void success(Object message, {Duration duration = _defaultDuration}) {
    _show(message, type: ToastificationType.success, duration: duration);
  }

  static void error(Object message, {Duration duration = _defaultDuration}) {
    _show(message, type: ToastificationType.error, duration: duration);
  }

  static void errorWithCause(
    Object message,
    Object cause, {
    Duration duration = _defaultDuration,
  }) {
    error(
      t.generic.errorWithCause(
        message: message,
        cause: describeBooruError(cause),
      ),
      duration: duration,
    );
  }

  static void info(Object message, {Duration duration = _defaultDuration}) {
    _show(message, type: ToastificationType.info, duration: duration);
  }

  static void _show(
    Object message, {
    required ToastificationType type,
    required Duration duration,
  }) {
    toastification.show(
      type: type,
      style: ToastificationStyle.flatColored,
      title: Text(message is String ? message : '$message'),
      autoCloseDuration: duration,
      closeButton: _closeButton,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      showProgressBar: false,
    );
  }
}
