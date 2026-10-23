// Shared asymmetric-shape consumers, isolated from production main.
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

class ShapeFillAudit extends StatefulWidget {
  const ShapeFillAudit({super.key});
  @override
  State<ShapeFillAudit> createState() => _ShapeFillAuditState();
}

class _ShapeFillAuditState extends State<ShapeFillAudit> {
  num _value = 5;
  int _choice = 0;
  @override
  Widget build(BuildContext context) {
    Widget cell(String title, Widget child) => SizedBox(
      width: 350,
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostText(title),
          const SizedBox(height: 16),
          Expanded(
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
        ],
      ),
    );
    Widget surface(FrostSurfaceRole role, BorderRadius radius) => SizedBox(
      width: 350,
      height: 100,
      child: FrostSurface(
        role: role,
        borderRadius: radius,
        elevated: false,
        child: const SizedBox.expand(),
      ),
    );
    const top = BorderRadius.vertical(top: Radius.circular(16));
    return ColoredBox(
      color: FrostThemeTokens.of(context).canvas,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            cell(
              'Grouped rows',
              FrostGroupedSection(
                children: [
                  FrostListRow(title: 'Audit first', onPressed: () {}),
                  FrostListRow(
                    title: 'Audit middle',
                    selected: true,
                    onPressed: () {},
                  ),
                  FrostListRow(title: 'Audit last', onPressed: () {}),
                ],
              ),
            ),
            cell(
              'Stepper ends',
              FrostStepper(
                semanticLabel: 'Audit stepper',
                value: _value,
                min: 0,
                max: 10,
                onChanged: (v) => setState(() => _value = v),
              ),
            ),
            cell(
              'Segments (uniform corners)',
              FrostPicker<int>.segmented(
                label: 'Audit segments',
                value: _choice,
                options: const [
                  FrostPickerOption(value: 0, label: 'First'),
                  FrostPickerOption(value: 1, label: 'Middle'),
                  FrostPickerOption(value: 2, label: 'Last'),
                ],
                onChanged: (v) => setState(() => _choice = v),
              ),
            ),
            cell('Sheet top corners', surface(FrostSurfaceRole.sheet, top)),
            cell('Chrome top corners', surface(FrostSurfaceRole.chrome, top)),
            cell(
              'Panel trailing corners',
              surface(
                FrostSurfaceRole.panel,
                const BorderRadius.horizontal(right: Radius.circular(16)),
              ),
            ),
            cell(
              'Drop highlight top corners',
              surface(
                FrostSurfaceRole.sheet,
                top,
              ).frostDropTarget(active: true),
            ),
          ],
        ),
      ),
    );
  }
}
