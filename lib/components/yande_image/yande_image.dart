import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yande_gui/global.dart';


class YandeImage extends StatelessWidget {
  final String url;
  final Color? color;

  final BlendMode? colorBlendMode;

  final double? width;

  final double? height;

  final BoxFit? fit;

  final Widget Function(Widget imageWidget)? imageBuilder;

  final Widget? placeholderWidget;

  const YandeImage(this.url, {super.key, this.color, this.colorBlendMode, this.width, this.height, this.fit, this.imageBuilder, this.placeholderWidget});

  @override
  Widget build(BuildContext context) {
    return ExtendedImage(
      image: ExtendedNetworkImageProvider(
        url,
        cache: true,
        printError: false,
        bytesLoader: (void Function(ImageChunkEvent event) chunkEvent) async {
          return await yandeClient.downloadToMemory(
            url: url,
            progressCallback: (BigInt received, BigInt total) {
              chunkEvent(ImageChunkEvent(cumulativeBytesLoaded: received.toInt(), expectedTotalBytes: total.toInt()));
            },
          );
        },
      ),
      handleLoadingProgress: true,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            if (state.loadingProgress case ImageChunkEvent event?) {
              if (event.expectedTotalBytes case int total?) {
                double progress = switch (total == 0) {
                  true => 1.0,
                  false => event.cumulativeBytesLoaded / total,
                };
                if (placeholderWidget case Widget widget?) {
                  return Stack(children: [widget, Positioned(left: 0, top: 0, right: 0, child: LinearProgressIndicator(value: progress))]);
                } else {
                  return Padding(padding: const EdgeInsets.all(5), child: Center(child: CircularProgressIndicator(value: progress)));
                }
              }
            } else {
              if (placeholderWidget case Widget widget?) {
                return Stack(children: [widget, const Positioned(left: 0, top: 0, right: 0, child: LinearProgressIndicator())]);
              } else {
                return const Padding(padding: EdgeInsets.all(5), child: Center(child: CupertinoActivityIndicator()));
              }
            }
            return const Padding(padding: EdgeInsets.all(5), child: Center(child: CupertinoActivityIndicator()));
          case LoadState.completed:
            return imageBuilder?.call(state.completedWidget);
          case LoadState.failed:
            return Center(child: IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: state.reLoadImage));
        }
      },
      color: color,
      colorBlendMode: colorBlendMode,
      clearMemoryCacheWhenDispose: false,
      width: width,
      height: height,
      fit: fit ?? BoxFit.fitWidth,
    );
  }
}
