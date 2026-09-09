import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:flutter/material.dart';

class SettingsSelectTile<T extends Object> extends StatelessWidget {
  const SettingsSelectTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });
  SettingsSelectTile.values({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required List<T> values,
    required String Function(T) label,
    required this.onChanged,
    this.enabled = true,
  }) : items = [
         for (final item in values)
           AppSelectItem(value: item, label: label(item)),
       ];

  final IconData icon;
  final String title;
  final T value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      icon,
      color: enabled ? null : Theme.of(context).disabledColor,
    ),
    title: ExcludeFocus(
      excluding: !enabled,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.38,
          child: AppSelect<T>(
            label: title,
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}
