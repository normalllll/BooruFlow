// Controlled slow-socket decoder inspection, used only by automation hosts.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/posts/widgets/progressive_image_stream.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'media.dart';

class ProgressiveProbe extends StatefulWidget {
  const ProgressiveProbe({required this.filename, super.key});
  final String filename;
  @override
  State<ProgressiveProbe> createState() => ProgressiveProbeState();
}

class ProgressiveProbeState extends State<ProgressiveProbe> {
  HttpServer? _server;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  RustExtendedNetworkImageProvider? _provider;
  var _partialFrames = 0;
  bool _complete = false, _starting = false;
  String? _error;
  late final _file = File('${mediaFixtureRoot!}/${widget.filename}');
  Map<String, Object?> diagnostics() => {
    'file': widget.filename,
    'partialFrames': _partialFrames,
    'complete': _complete,
    'error': _error,
    'decodeUs': (_stream?.completer as ProgressiveImageStreamCompleter?)
        ?.loading
        .decodeMicros,
    'scanEnds': (_stream?.completer as ProgressiveImageStreamCompleter?)
        ?.loading
        .decodedScanEnds,
  };
  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    final length = await _file.length();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((request) async {
      request.response.bufferOutput = false;
      request.response.contentLength = length;
      try {
        final chunk = math.max(1, (length / 24).ceil());
        for (var offset = 0; offset < length; offset += chunk) {
          request.response.add(
            await _file
                .openRead(offset, math.min(offset + chunk, length))
                .fold<BytesBuilder>(
                  BytesBuilder(copy: false),
                  (builder, bytes) => builder..add(bytes),
                )
                .then((b) => b.takeBytes()),
          );
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
        await request.response.close();
      } on IOException {
        /* The owned page may close during transfer. */
      }
    });
    if (!mounted) {
      await server.close(force: true);
      return;
    }
    final provider = RustExtendedNetworkImageProvider(
      request: MediaRequest(
        sourceId: 'r9-local',
        postId: 'prefix',
        variant: MediaVariantKind.original,
        url: 'http://127.0.0.1:${server.port}/image',
        headers: [],
        routeKey: 'probe',
        cacheKey: 'r9-${server.port}',
        authRevision: 0,
        routeRevision: 'probe',
        allowDiskCache: false,
      ),
      decodeWidth: math.min(
        1280,
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .ceil(),
      ),
      progressive: true,
      retries: 0,
      mediaStream: (request) async* {
        final client = HttpClient();
        try {
          final response = await (await client.getUrl(
            Uri.parse(request.url),
          )).close();
          var received = 0;
          await for (final bytes in response) {
            received += bytes.length;
            yield MediaFetchEvent.chunk(
              bytes: Uint8List.fromList(bytes),
              receivedBytesDecimal: '$received',
              totalBytesDecimal: '$length',
            );
          }
        } finally {
          client.close(force: true);
        }
      },
    );
    _stream = provider.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
        info.dispose();
        if (!mounted) return;
        final complete =
            (_stream!.completer! as ProgressiveImageStreamCompleter).complete;
        setState(() {
          _complete = complete;
          if (!complete) _partialFrames++;
        });
      },
      onError: (Object error, StackTrace? stack) {
        if (mounted) setState(() => _error = '$error');
      },
    );
    _stream!.addListener(_listener!);
    setState(() => _provider = provider);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    unawaited(_server?.close(force: true));
    _provider?.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FrostPageHeader(
        title: FrostText(widget.filename),
        actions: [
          FrostToolbarItem.action(
            label: 'Load image',
            icon: appIcons.play,
            onPressed: _start,
          ),
        ],
      ),
      Expanded(
        child: Center(
          child: _error == null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: ResizeImage(FileImage(_file), width: 64),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    if (_provider != null)
                      Image(
                        image: _provider!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (_, error, _) => FrostText('$error'),
                      ),
                  ],
                )
              : FrostText(_error!),
        ),
      ),
    ],
  );
}
