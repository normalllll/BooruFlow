// Dedicated component probe; normal main never imports automation code.
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

class R16InteractionProbe extends StatelessWidget {
  const R16InteractionProbe({super.key});
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: FrostTypography.of(context)
        .style(FrostTextRole.body)
        .copyWith(color: FrostThemeTokens.of(context).textPrimary),
    child: Column(
      children: [
        FrostPageHeader(
          title: const FrostText('Preview pointer probe'),
          actions: [
            FrostToolbarItem.menu(
              label: 'Probe menu',
              icon: FrostIconSet.of(context).more,
              entries: [FrostMenuAction('Menu action', onSelected: () {})],
            ),
          ],
        ),
        Expanded(
          child: FrostContentColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: FrostGap.section),
                for (final name in ['First', 'Second']) ...[
                  FrostHoverPreview(
                    previewBuilder: (_) => FrostText('$name preview content'),
                    child: FrostButton(
                      label: '$name preview target',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
                const Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height: 1600,
                      child: FrostText('Scrollable outside region'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
