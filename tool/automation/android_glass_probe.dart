// R6 native glass diagnostic. Normal App entrypoints never import this file.
import 'dart:convert';
import 'dart:io';
import 'package:booruflow/app/frost_config.dart';
import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/src/motion/_material_reveal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var dark = false;
  late StateSetter update;
  runApp(
    FrostScope(
      config: appFrostConfig,
      child: StatefulBuilder(
        builder: (context, set) {
          update = set;
          return MaterialApp(
            theme: FrostTheme.build(
              config: appFrostConfig,
              locale: const Locale('en'),
              brightness: dark ? Brightness.dark : Brightness.light,
              platform: TargetPlatform.android,
            ),
            home: FrostLayoutScope(
              child: Builder(
                builder: (context) {
                  return Scaffold(
                    body: SafeArea(
                      child: Column(
                        children: [
                          const Text(
                            'R6 glass: no filter / actual filter / uncovered',
                          ),
                          for (final sample in [0, 1, 2])
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Row(
                                    children: [
                                      for (final black in [true, false])
                                        Expanded(
                                          child: ColoredBox(
                                            color: black
                                                ? Colors.black
                                                : Colors.white,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Related images\nHIGH CONTRAST\n0123456789',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: black
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (sample < 2)
                                    Positioned.fill(
                                      child: FrostContentRevealScope(
                                        opacity: 1,
                                        nestedProgress: sample.toDouble(),
                                        handle: FrostRevealHandle(),
                                        parent: null,
                                        child: const FrostSurface(
                                          role: FrostSurfaceRole.chrome,
                                          edge: FrostSurfaceEdge.none,
                                          elevated: false,
                                          borderRadius: BorderRadius.zero,
                                          child: SizedBox.expand(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    ),
  );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9415);
  await for (final request in server) {
    final data =
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
    if (data['command'] == 'dark') update(() => dark = data['enabled'] as bool);
    request.response.write(jsonEncode({'dark': dark}));
    await request.response.close();
  }
}
