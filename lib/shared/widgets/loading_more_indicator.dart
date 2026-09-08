import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:booruflow/features/booru/web_challenge_button.dart';

class LoadingMoreIndicator extends StatelessWidget {
  final IndicatorStatus status;
  final void Function() errorRefresh;
  final bool isSliver;
  final Object? error;

  const LoadingMoreIndicator({
    super.key,
    required this.status,
    required this.errorRefresh,
    this.isSliver = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget;
    switch (status) {
      case IndicatorStatus.none:
        widget = const SizedBox();
        break;
      case IndicatorStatus.loadingMoreBusying:
        widget = _FooterIndicator(
          icon: const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: t.generic.loading,
        );
        break;
      case IndicatorStatus.fullScreenBusying:
        widget = _FullScreenIndicator(
          icon: const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          label: t.generic.loading,
        );
        if (isSliver) {
          widget = SliverFillRemaining(hasScrollBody: false, child: widget);
        } else {
          widget = CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(hasScrollBody: false, child: widget),
            ],
          );
        }
        break;
      case IndicatorStatus.error:
        widget = _ErrorContent(
          error: error,
          message: describeBooruError(error),
          onRetry: errorRefresh,
        );
        break;
      case IndicatorStatus.fullScreenError:
        widget = _ErrorContent(
          error: error,
          message: describeBooruError(error),
          onRetry: errorRefresh,
        );
        if (isSliver) {
          widget = SliverFillRemaining(hasScrollBody: false, child: widget);
        } else {
          widget = CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(hasScrollBody: false, child: widget),
            ],
          );
        }
        break;
      case IndicatorStatus.noMoreLoad:
        widget = _FooterIndicator(
          icon: Icon(
            Icons.check,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: t.generic.noMoreData,
        );
        break;
      case IndicatorStatus.empty:
        widget = const _EmptyContent();
        if (isSliver) {
          widget = SliverFillRemaining(hasScrollBody: false, child: widget);
        } else {
          widget = CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(hasScrollBody: false, child: widget),
            ],
          );
        }
        break;
    }
    return widget;
  }
}

class _FooterIndicator extends StatelessWidget {
  const _FooterIndicator({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 56,
      child: Center(
        child: _InlineStatus(icon: icon, label: label),
      ),
    );
    return content;
  }
}

class _FullScreenIndicator extends StatelessWidget {
  const _FullScreenIndicator({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: _InlineStatus(icon: icon, label: label),
  );
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(dimension: 22, child: Center(child: icon)),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ErrorContent extends StatefulWidget {
  const _ErrorContent({
    required this.message,
    required this.onRetry,
    this.error,
  });

  final String message;
  final VoidCallback onRetry;
  final Object? error;

  @override
  State<_ErrorContent> createState() => _ErrorContentState();
}

class _ErrorContentState extends State<_ErrorContent> {
  Timer? _timer;
  int _remaining = 0;
  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void didUpdateWidget(covariant _ErrorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != widget.error) _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    final error = switch (widget.error) {
      BooruReadableException(:final cause) => cause,
      BooruError value => value,
      _ => null,
    };
    final seconds = error?.code == BooruErrorCode.rateLimited
        ? (error?.retryAfterSeconds ?? 60).clamp(0, 86400)
        : 0;
    _remaining = seconds;
    if (seconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _remaining = (seconds - timer.tick).clamp(0, seconds));
        if (_remaining == 0) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final colorScheme = Theme.of(context).colorScheme;
    final hasDetailedMessage = message.contains('\n') || message.length > 120;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.error_outline, size: 44, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: hasDetailedMessage
                      ? TextAlign.start
                      : TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: _remaining > 0
                      ? '${t.generic.retry} (${_remaining}s)'
                      : t.generic.retry,
                  onPressed: _remaining > 0 ? null : widget.onRetry,
                  icon: Icons.refresh,
                ),
                if (challengeError(widget.error)?.sourceId
                    case final source?) ...[
                  const SizedBox(height: 10),
                  WebChallengeButton(sourceId: source),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              t.generic.notFound,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
