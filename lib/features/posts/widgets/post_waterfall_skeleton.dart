import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yande_gui/shared/app_theme.dart';

const _ratios = <double>[
  1.32,
  0.78,
  1.08,
  1.58,
  0.92,
  1.22,
  1.44,
  0.86,
  1.16,
  0.88,
  1.42,
  1.02,
  1.26,
  0.96,
  1.52,
  1.12,
  0.82,
  1.36,
  1.06,
  1.46,
];

class PostWaterfallSkeleton extends StatelessWidget {
  const PostWaterfallSkeleton({this.configuredColumns, super.key});

  final int? configuredColumns;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const padding = 12.0;
        const spacing = 8.0;
        const maxCrossAxisExtent = 240.0;
        const shortestAspectRatio = 1.58;
        const footerHeight = 58.0;
        final availableWidth = math.max(
          1.0,
          constraints.crossAxisExtent - padding * 2,
        );
        final columnCount =
            configuredColumns?.clamp(1, 100) ??
            math.max(
              1,
              ((availableWidth + spacing) / (maxCrossAxisExtent + spacing))
                  .ceil(),
            );
        final itemWidth = math.max(
          1.0,
          (availableWidth - spacing * (columnCount - 1)) / columnCount,
        );
        final shortestItemHeight =
            itemWidth / shortestAspectRatio + footerHeight;
        final rows = math.max(
          1,
          (constraints.viewportMainAxisExtent / (shortestItemHeight + spacing))
                  .ceil() +
              1,
        );
        final itemCount = math.max(_ratios.length, rows * columnCount);

        return SliverPadding(
          padding: const EdgeInsets.all(padding),
          sliver: SliverWaterfallFlow(
            gridDelegate: configuredColumns == null
                ? const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: maxCrossAxisExtent,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  )
                : SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PostSkeletonCard(
                aspectRatio: _ratios[index % _ratios.length],
              ),
              childCount: itemCount,
            ),
          ),
        );
      },
    );
  }
}

class _PostSkeletonCard extends StatelessWidget {
  const _PostSkeletonCard({required this.aspectRatio});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final radius = BorderRadius.circular(8);

    return Skeletonizer.zone(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: tokens.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: const Bone(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 9, 8, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone.text(width: 72),
                    SizedBox(height: 7),
                    Bone.text(width: 108),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
