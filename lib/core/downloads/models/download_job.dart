import 'dart:convert';

import 'save_target.dart';
import 'download_request_options.dart';

class DownloadJob {
  DownloadJob({
    required this.id,
    required this.resourceId,
    required this.sourceId,
    required this.postId,
    required this.variantIndex,
    required this.url,
    required this.filename,
    required this.networkOptions,
    required this.validation,
    required this.saveTarget,
    required this.createdAt,
    this.thumbnailUrl,
    this.title,
  });

  factory DownloadJob.create({
    required int resourceId,
    String sourceId = 'direct',
    String? postId,
    required int variantIndex,
    required Uri url,
    required String filename,
    required SaveTarget saveTarget,
    DownloadNetworkOptions networkOptions = const DownloadNetworkOptions(),
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? thumbnailUrl,
    String? title,
  }) {
    final now = DateTime.now();
    return DownloadJob(
      id: downloadJobId(
        resourceId: resourceId,
        sourceId: sourceId,
        postId: postId,
        variantIndex: variantIndex,
      ),
      resourceId: resourceId,
      sourceId: sourceId,
      postId: postId ?? resourceId.toString(),
      variantIndex: variantIndex,
      url: url,
      filename: filename,
      networkOptions: networkOptions.normalizedFor(url),
      validation: validation.normalized(),
      saveTarget: saveTarget,
      thumbnailUrl: thumbnailUrl,
      title: title,
      createdAt: now,
    );
  }

  final String id;
  final int resourceId;
  final String sourceId;
  final String postId;
  final int variantIndex;
  final Uri url;
  final String filename;
  final DownloadNetworkOptions networkOptions;
  final DownloadValidationOptions validation;
  final SaveTarget saveTarget;
  final String? thumbnailUrl;
  final String? title;
  final DateTime createdAt;

  DownloadJob copyWith({
    String? id,
    int? resourceId,
    String? sourceId,
    String? postId,
    int? variantIndex,
    Uri? url,
    String? filename,
    DownloadNetworkOptions? networkOptions,
    DownloadValidationOptions? validation,
    SaveTarget? saveTarget,
    String? thumbnailUrl,
    String? title,
    DateTime? createdAt,
  }) {
    return DownloadJob(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      sourceId: sourceId ?? this.sourceId,
      postId: postId ?? this.postId,
      variantIndex: variantIndex ?? this.variantIndex,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      networkOptions: networkOptions ?? this.networkOptions,
      validation: validation ?? this.validation,
      saveTarget: saveTarget ?? this.saveTarget,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toPlatformJson() {
    return {
      'id': id,
      'resourceId': resourceId,
      'sourceId': sourceId,
      'postId': postId,
      'variantIndex': variantIndex,
      'url': url.toString(),
      'filename': filename,
      'networkOptions': networkOptions.toJson(),
      'validation': validation.toJson(),
      'saveTarget': saveTarget.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

String downloadJobId({
  required int resourceId,
  String? sourceId,
  String? postId,
  required int variantIndex,
}) {
  if (sourceId == null || postId == null) {
    return 'resource_${resourceId}_variant_$variantIndex';
  }
  String encode(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  return 'booru_${encode(sourceId)}_${encode(postId)}_variant_$variantIndex';
}
