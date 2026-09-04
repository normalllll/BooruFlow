import 'package:flutter/material.dart';

/// Paint the fill and inside border as rounded rectangles. Keep ink clipping
/// separate, avoiding a physical-shape edge painted and clipped a second time.
class AppRoundedSurface extends StatelessWidget {
  const AppRoundedSurface({
    super.key,
    required this.color,
    required this.borderColor,
    required this.child,
    this.radius = 8,
    this.borderWidth = 1,
  });
  final Color color;
  final Color borderColor;
  final Widget child;
  final double radius;
  final double borderWidth;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
    position: DecorationPosition.background,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      position: DecorationPosition.foreground,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    ),
  );
}
