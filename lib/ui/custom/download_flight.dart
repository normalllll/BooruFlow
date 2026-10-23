// frost-escape: BOORUFLOW_REBUILD_PLAN section 7 authorizes the measured download flight and navigation landing bounce.
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

// The App-owned exception specified by the rebuild plan. Geometry is measured
// from the real navigation target, never estimated from sidebar internals.
const _flightArcFraction = .25;
const _flightMaximumArc = 160.0;
const _flightFadeStart = .8;
const _landingAmplitude = .06;

class DownloadFlightHost extends StatefulWidget {
  const DownloadFlightHost({required this.child, super.key});
  final Widget child;
  static DownloadFlightHostState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FlightScope>()?.host;
  @override
  DownloadFlightHostState createState() => DownloadFlightHostState();
}

class DownloadFlightHostState extends State<DownloadFlightHost>
    with TickerProviderStateMixin {
  final target = GlobalKey();
  final landed = ValueNotifier<int>(0);
  final _flights = <_Flight>[];
  void fly({required Rect source, required ImageProvider image}) {
    if (!mounted ||
        MediaQuery.disableAnimationsOf(context) ||
        target.currentContext == null) {
      return;
    }
    final controller = AnimationController.unbounded(vsync: this);
    final flight = _Flight(source, image, controller);
    setState(() => _flights.add(flight));
    FrostMotion.springTo(
      context,
      controller,
      1,
      FrostMotion.standard,
    ).whenCompleteOrCancel(() {
      if (!mounted || !_flights.contains(flight)) return;
      setState(() => _flights.remove(flight));
      controller.dispose();
      landed.value++;
    });
  }

  @override
  void dispose() {
    final flights = List.of(_flights);
    _flights.clear();
    for (final flight in flights) {
      flight.progress.dispose();
    }
    landed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FlightScope(
    host: this,
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        for (final flight in _flights)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: flight.progress,
                builder: (context, _) {
                  final destination = target.currentContext?.findRenderObject();
                  final host = this.context.findRenderObject();
                  if (destination is! RenderBox ||
                      !destination.attached ||
                      host is! RenderBox ||
                      !host.attached) {
                    return const SizedBox.shrink();
                  }
                  final t = flight.progress.value.clamp(0.0, 1.0);
                  final start = host.globalToLocal(flight.source.center);
                  final end = host.globalToLocal(
                    destination.localToGlobal(
                      destination.size.center(Offset.zero),
                    ),
                  );
                  final control = Offset(
                    (start.dx + end.dx) / 2,
                    math.min(start.dy, end.dy) -
                        math.min(
                          _flightMaximumArc,
                          (end - start).distance * _flightArcFraction,
                        ),
                  );
                  final center =
                      start * ((1 - t) * (1 - t)) +
                      control * (2 * (1 - t) * t) +
                      end * (t * t);
                  final size = Size.lerp(
                    flight.source.size,
                    Size.square(FrostControlSize.compact.iconSize),
                    t,
                  )!;
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: Rect.fromCenter(
                          center: center,
                          width: size.width,
                          height: size.height,
                        ),
                        child: Opacity(
                          opacity: t <= _flightFadeStart
                              ? 1
                              : (1 - t) / (1 - _flightFadeStart),
                          child: ClipPath(
                            clipper: ShapeBorderClipper(
                              shape: FrostRadius.shape(context, FrostRadius.sm),
                            ),
                            child: Image(
                              image: flight.image,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    ),
  );
}

class _Flight {
  _Flight(this.source, this.image, this.progress);
  final Rect source;
  final ImageProvider image;
  final AnimationController progress;
}

class _FlightScope extends InheritedWidget {
  const _FlightScope({required this.host, required super.child});
  final DownloadFlightHostState host;
  @override
  bool updateShouldNotify(_FlightScope oldWidget) => oldWidget.host != host;
}

class DownloadFlightTarget extends StatefulWidget {
  const DownloadFlightTarget({required this.child, super.key});
  final Widget child;
  @override
  State<DownloadFlightTarget> createState() => _DownloadFlightTargetState();
}

class _DownloadFlightTargetState extends State<DownloadFlightTarget>
    with SingleTickerProviderStateMixin {
  late final _scale = AnimationController.unbounded(vsync: this, value: 1);
  DownloadFlightHostState? _host;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _scale.value = 1;
    final next = DownloadFlightHost.maybeOf(context);
    if (next != _host) {
      _host?.landed.removeListener(_bounce);
      _host = next;
      _host?.landed.addListener(_bounce);
    }
  }

  void _bounce() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    // One small positive lobe, starting at the current value. Consecutive
    // arrivals share the running confirmation instead of stacking impulses.
    if (_scale.isAnimating) return;
    final spring = FrostMotion.snappy;
    final velocity =
        _landingAmplitude * math.e * math.sqrt(spring.stiffness / spring.mass);
    _scale.animateWith(
      SpringSimulation(spring, _scale.value, 1, velocity, snapToEnd: true),
    );
  }

  @override
  void dispose() {
    _host?.landed.removeListener(_bounce);
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: _host?.target,
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
