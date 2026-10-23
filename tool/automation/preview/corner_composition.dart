// Diagnostic AA comparison; never imported by production main.
import 'package:flutter/widgets.dart';

class CornerComposition extends StatelessWidget {
  const CornerComposition({super.key});
  static const corners = BorderRadius.all(Radius.circular(16));
  Widget _card(int mode, double opacity) {
    Widget fill(Color color, BorderRadius radius) => mode == 2
        ? ColoredBox(color: color)
        : DecoratedBox(
            decoration: ShapeDecoration(
              color: color,
              shape: RoundedSuperellipseBorder(borderRadius: radius),
            ),
          );
    return SizedBox(
      width: 300,
      height: 120,
      child: ClipRSuperellipse(
        borderRadius: corners,
        clipBehavior: mode == 0 ? Clip.antiAlias : Clip.antiAliasWithSaveLayer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            fill(const Color(0xff373737), corners),
            Column(
              children: [
                Expanded(
                  child: SizedBox.expand(
                    child: fill(
                      const Color(0xffffffff).withValues(alpha: opacity),
                      const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox.expand()),
                Expanded(
                  child: SizedBox.expand(
                    child: fill(
                      const Color(0xffffffff).withValues(alpha: opacity),
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: const TextStyle(color: Color(0xffeeeeee), fontSize: 14),
    child: ColoredBox(
      color: const Color(0xff151515),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A: current AA / B: saveLayer, same shapes / C: single AA, rectangular fills',
            ),
            const SizedBox(height: 24),
            for (final opacity in [0.0, .08, .16]) ...[
              Text('highlight alpha $opacity'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var mode = 0; mode < 3; mode++) ...[
                    _card(mode, opacity),
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
