// app-owned: measured download flight and navigation landing bounce animations.
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

// The App-owned exception specified by the rebuild plan. Geometry is measured
// from the real navigation target, never estimated from sidebar internals.
//
// A flight is a long gesture, not a page transition, so it runs on a timed
// curve instead of the page-level spring: it leaves slowly, speeds into the
// target and settles into one small bounce there.
const _flightArcFraction = .25;
const _flightMaximumArc = 160.0;
const _flightShortestDuration = Duration(milliseconds: 400);
const _flightLongestDuration = Duration(milliseconds: 600);
// The distances over which the duration grows from shortest to longest.
const _flightShortDistance = 240.0;
const _flightLongDistance = 900.0;
// The first stretch of the flight shrinks the card to a small thumbnail; the
// last one shrinks that to the icon it lands on.
const _flightThumbnailEnd = .3;
// The small thumbnail (FrostThumbnailSize.small) the card shrinks to.
const _flightThumbnailExtent = 48.0;
const _flightIconStart = .65;
const _flightFadeStart = .9;
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

  /// The claim each flight in the air carries (null for none). A floating
  /// entry that shows only with downloads is there to receive them, and the
  /// entry's count leaves out the downloads whose flight has not landed yet.
  final inAir = ValueNotifier<List<Object?>>(const []);
  final _flights = <_Flight>[];

  /// Starts a flight of [image] from [source] (global) to the target. False
  /// when none can start: reduced motion, or no target to land on. [claim]
  /// names the download the flight carries.
  bool fly({
    required Rect source,
    required ImageProvider image,
    Object? claim,
  }) {
    final destination = target.currentContext?.findRenderObject();
    if (!mounted ||
        MediaQuery.disableAnimationsOf(context) ||
        destination is! RenderBox ||
        !destination.attached) {
      return false;
    }
    final distance = destination.hasSize
        ? (destination.localToGlobal(destination.size.center(Offset.zero)) -
                  source.center)
              .distance
        : _flightLongDistance;
    final controller = AnimationController(
      vsync: this,
      duration:
          _flightShortestDuration +
          (_flightLongestDuration - _flightShortestDuration) *
              ((distance - _flightShortDistance) /
                      (_flightLongDistance - _flightShortDistance))
                  .clamp(0.0, 1.0),
    );
    final flight = _Flight(source, image, controller, claim);
    setState(() => _flights.add(flight));
    inAir.value = _claims;
    controller.forward().whenCompleteOrCancel(() {
      if (!mounted || !_flights.contains(flight)) return;
      setState(() => _flights.remove(flight));
      controller.dispose();
      inAir.value = _claims;
      landed.value++;
    });
    return true;
  }

  List<Object?> get _claims => List.unmodifiable([
    for (final flight in _flights) flight.claim,
  ]);

  @override
  void dispose() {
    final flights = List.of(_flights);
    _flights.clear();
    for (final flight in flights) {
      flight.progress.dispose();
    }
    landed.dispose();
    inAir.dispose();
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
                  // Time drives the size and the fade; the way along the arc
                  // accelerates, so the card slows at the start and speeds
                  // into the target.
                  final time = flight.progress.value.clamp(0.0, 1.0);
                  final t = Curves.easeInQuad.transform(time);
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
                  final thumbnail = Size.square(
                    math.min(
                      _flightThumbnailExtent,
                      flight.source.shortestSide,
                    ),
                  );
                  final size = Size.lerp(
                    Size.lerp(
                      flight.source.size,
                      thumbnail,
                      Curves.easeOutCubic.transform(
                        (time / _flightThumbnailEnd).clamp(0.0, 1.0),
                      ),
                    ),
                    Size.square(FrostControlSize.compact.iconSize),
                    Curves.easeInCubic.transform(
                      ((time - _flightIconStart) / (1 - _flightIconStart))
                          .clamp(0.0, 1.0),
                    ),
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
                          opacity: time <= _flightFadeStart
                              ? 1
                              : (1 - time) / (1 - _flightFadeStart),
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
  _Flight(this.source, this.image, this.progress, this.claim);
  final Object? claim;
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
    // One bounce of the small confirmation spring, starting at the current
    // value. Consecutive arrivals share the running bounce instead of
    // stacking impulses.
    if (_scale.isAnimating) return;
    _scale.animateWith(
      SpringSimulation(
        FrostMotion.bouncy,
        _scale.value,
        1,
        _bounceVelocity(FrostMotion.bouncy, _landingAmplitude),
        snapToEnd: true,
      ),
    );
  }

  @override
  void dispose() {
    _host?.landed.removeListener(_bounce);
    _scale.dispose();
    super.dispose();
  }

  // The key sits inside the scale: the measured box is the child itself, and
  // scaling about its center leaves the point a flight lands on where it is.
  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: KeyedSubtree(key: _host?.target, child: widget.child),
  );
}

/// The velocity from which an underdamped [spring] at rest at its target
/// first peaks [amplitude] away from it.
double _bounceVelocity(SpringDescription spring, double amplitude) {
  final omega = math.sqrt(spring.stiffness / spring.mass);
  final zeta = spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));
  final decay = zeta * omega;
  final damped = omega * math.sqrt(1 - zeta * zeta);
  final peak = math.atan2(damped, decay) / damped;
  return amplitude *
      damped /
      (math.exp(-decay * peak) * math.sin(damped * peak));
}
