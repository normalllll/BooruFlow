// Standalone Flutter reproduction, with no frost_ui rendering dependencies.
import 'package:flutter/widgets.dart';

void main() => runApp(
  const Directionality(
    textDirection: TextDirection.ltr,
    child: SuperellipseSeams(),
  ),
);

class SuperellipseSeams extends StatelessWidget {
  const SuperellipseSeams({super.key});
  Widget sample(int mode, BorderRadius radius) {
    const color = Color(0x29ffffff);
    final shape = RoundedSuperellipseBorder(borderRadius: radius);
    final fill = const SizedBox.expand(child: ColoredBox(color: color));
    return SizedBox(
      width: 260,
      height: 40,
      child: switch (mode) {
        0 => DecoratedBox(
          decoration: ShapeDecoration(color: color, shape: shape),
        ),
        1 => ClipRSuperellipse(borderRadius: radius, child: fill),
        2 => ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: fill,
        ),
        _ => ClipRSuperellipse(
          borderRadius: radius,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: fill,
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: const TextStyle(fontSize: 14, color: Color(0xffeeeeee)),
    child: ColoredBox(
      color: const Color(0xff373737),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Native shaped fill / native clip + rectangle / path clip + rectangle / native clip + saveLayer',
            ),
            const SizedBox(height: 24),
            for (final radius in [
              const BorderRadius.vertical(top: Radius.circular(16)),
              const BorderRadius.horizontal(left: Radius.circular(16)),
              const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomRight: Radius.circular(8),
              ),
              BorderRadius.circular(16),
            ]) ...[
              Row(
                children: [
                  for (var mode = 0; mode < 4; mode++) ...[
                    sample(mode, radius),
                    const SizedBox(width: 24),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    ),
  );
}
