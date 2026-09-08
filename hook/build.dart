import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final environment = <String, String>{};
    final code = input.config.code;
    if (code.targetOS == OS.iOS) {
      // Hook processes do not necessarily inherit Xcode's deployment settings.
      // Flutter 3.47 requires iOS 15; honor higher targets supplied by Flutter.
      final minimumVersion = code.iOS.targetVersion < 15
          ? 15
          : code.iOS.targetVersion;
      final sdk = await Process.run('xcrun', [
        '--sdk',
        code.iOS.targetSdk.toString(),
        '--show-sdk-path',
      ]);
      final sdkPath = (sdk.stdout as String).trim();
      if (sdk.exitCode != 0 || sdkPath.isEmpty) {
        throw StateError('Unable to resolve iOS SDK: ${sdk.stderr}');
      }
      environment['IPHONEOS_DEPLOYMENT_TARGET'] = '$minimumVersion.0';
      environment['SDKROOT'] = sdkPath;
    }

    await FlutterRustBridgeNativeAssetsBuilder(
      cratePath: 'rust',
      extraCargoEnvironmentVariables: environment,
      extraCargoBuildArgs: [
        if (code.targetOS == OS.windows) ...[
          '--features',
          'web-challenge-window',
        ],
      ],
    ).run(input: input, output: output);
  });
}
