import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// What a route shows when its data is missing or invalid.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    maxWidth: 760,
    isEmpty: true,
    empty: FrostEmptyState(
      icon: appIcons.error,
      title: t.generic.notFound,
      message: t.generic.notFoundMessage,
      actionLabel: t.generic.backToBrowse,
      onAction: () => context.goNamed(AppRoute.posts.name),
    ),
    header: FrostPageHeader(title: FrostText(t.generic.notFound)),
    slivers: const [],
  );
}
