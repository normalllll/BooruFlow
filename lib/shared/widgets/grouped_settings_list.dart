import 'package:flutter/material.dart';

class GroupedSettingsList extends StatelessWidget {
  const GroupedSettingsList({required this.groups, super.key});

  final List<List<Widget>> groups;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final wideLayout = MediaQuery.sizeOf(context).width >= 600;
    final horizontalPadding = wideLayout ? 24.0 : 16.0;
    final topPadding = wideLayout ? 24.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentInset =
            (constraints.maxWidth - 760).clamp(0.0, double.infinity) / 2;
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            contentInset + horizontalPadding,
            topPadding,
            contentInset + horizontalPadding,
            28,
          ),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, groupIndex) {
            final items = groups[groupIndex];
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: ListTileTheme.merge(
                tileColor: Colors.transparent,
                shape: const RoundedRectangleBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      items[index],
                      if (index < items.length - 1)
                        Divider(
                          height: 9,
                          thickness: 1,
                          indent: 56,
                          endIndent: 16,
                          color: colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
