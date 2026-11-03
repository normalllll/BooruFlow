import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// The layers FrostApp adds that pages read, for a test that mounts its own
/// MaterialApp to choose the platform.
Widget frostAppLayers(Widget child) =>
    FrostInputFeedback(child: FrostToastHost(child: child));
