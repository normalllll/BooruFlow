// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_database.dart';

// ignore_for_file: type=lint
class $DownloadJobsTable extends DownloadJobs
    with TableInfo<$DownloadJobsTable, DownloadJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<int> resourceId = GeneratedColumn<int>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('direct'),
  );
  static const VerificationMeta _postIdMeta = const VerificationMeta('postId');
  @override
  late final GeneratedColumn<String> postId = GeneratedColumn<String>(
    'post_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _variantIndexMeta = const VerificationMeta(
    'variantIndex',
  );
  @override
  late final GeneratedColumn<int> variantIndex = GeneratedColumn<int>(
    'variant_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headersJsonMeta = const VerificationMeta(
    'headersJson',
  );
  @override
  late final GeneratedColumn<String> headersJson = GeneratedColumn<String>(
    'headers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _networkOptionsJsonMeta =
      const VerificationMeta('networkOptionsJson');
  @override
  late final GeneratedColumn<String> networkOptionsJson =
      GeneratedColumn<String>(
        'network_options_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _validationJsonMeta = const VerificationMeta(
    'validationJson',
  );
  @override
  late final GeneratedColumn<String> validationJson = GeneratedColumn<String>(
    'validation_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _saveTargetJsonMeta = const VerificationMeta(
    'saveTargetJson',
  );
  @override
  late final GeneratedColumn<String> saveTargetJson = GeneratedColumn<String>(
    'save_target_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    resourceId,
    sourceId,
    postId,
    variantIndex,
    url,
    filename,
    headersJson,
    networkOptionsJson,
    validationJson,
    saveTargetJson,
    thumbnailUrl,
    title,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('post_id')) {
      context.handle(
        _postIdMeta,
        postId.isAcceptableOrUnknown(data['post_id']!, _postIdMeta),
      );
    }
    if (data.containsKey('variant_index')) {
      context.handle(
        _variantIndexMeta,
        variantIndex.isAcceptableOrUnknown(
          data['variant_index']!,
          _variantIndexMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('headers_json')) {
      context.handle(
        _headersJsonMeta,
        headersJson.isAcceptableOrUnknown(
          data['headers_json']!,
          _headersJsonMeta,
        ),
      );
    }
    if (data.containsKey('network_options_json')) {
      context.handle(
        _networkOptionsJsonMeta,
        networkOptionsJson.isAcceptableOrUnknown(
          data['network_options_json']!,
          _networkOptionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('validation_json')) {
      context.handle(
        _validationJsonMeta,
        validationJson.isAcceptableOrUnknown(
          data['validation_json']!,
          _validationJsonMeta,
        ),
      );
    }
    if (data.containsKey('save_target_json')) {
      context.handle(
        _saveTargetJsonMeta,
        saveTargetJson.isAcceptableOrUnknown(
          data['save_target_json']!,
          _saveTargetJsonMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      postId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}post_id'],
      )!,
      variantIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}variant_index'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      headersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers_json'],
      )!,
      networkOptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network_options_json'],
      )!,
      validationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validation_json'],
      )!,
      saveTargetJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}save_target_json'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DownloadJobsTable createAlias(String alias) {
    return $DownloadJobsTable(attachedDatabase, alias);
  }
}

class DownloadJob extends DataClass implements Insertable<DownloadJob> {
  final String id;
  final int resourceId;
  final String sourceId;
  final String postId;
  final int variantIndex;
  final String url;
  final String filename;
  final String headersJson;
  final String networkOptionsJson;
  final String validationJson;
  final String saveTargetJson;
  final String? thumbnailUrl;
  final String? title;
  final int createdAt;
  final int updatedAt;
  const DownloadJob({
    required this.id,
    required this.resourceId,
    required this.sourceId,
    required this.postId,
    required this.variantIndex,
    required this.url,
    required this.filename,
    required this.headersJson,
    required this.networkOptionsJson,
    required this.validationJson,
    required this.saveTargetJson,
    this.thumbnailUrl,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['resource_id'] = Variable<int>(resourceId);
    map['source_id'] = Variable<String>(sourceId);
    map['post_id'] = Variable<String>(postId);
    map['variant_index'] = Variable<int>(variantIndex);
    map['url'] = Variable<String>(url);
    map['filename'] = Variable<String>(filename);
    map['headers_json'] = Variable<String>(headersJson);
    map['network_options_json'] = Variable<String>(networkOptionsJson);
    map['validation_json'] = Variable<String>(validationJson);
    map['save_target_json'] = Variable<String>(saveTargetJson);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DownloadJobsCompanion toCompanion(bool nullToAbsent) {
    return DownloadJobsCompanion(
      id: Value(id),
      resourceId: Value(resourceId),
      sourceId: Value(sourceId),
      postId: Value(postId),
      variantIndex: Value(variantIndex),
      url: Value(url),
      filename: Value(filename),
      headersJson: Value(headersJson),
      networkOptionsJson: Value(networkOptionsJson),
      validationJson: Value(validationJson),
      saveTargetJson: Value(saveTargetJson),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadJob(
      id: serializer.fromJson<String>(json['id']),
      resourceId: serializer.fromJson<int>(json['resourceId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      postId: serializer.fromJson<String>(json['postId']),
      variantIndex: serializer.fromJson<int>(json['variantIndex']),
      url: serializer.fromJson<String>(json['url']),
      filename: serializer.fromJson<String>(json['filename']),
      headersJson: serializer.fromJson<String>(json['headersJson']),
      networkOptionsJson: serializer.fromJson<String>(
        json['networkOptionsJson'],
      ),
      validationJson: serializer.fromJson<String>(json['validationJson']),
      saveTargetJson: serializer.fromJson<String>(json['saveTargetJson']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'resourceId': serializer.toJson<int>(resourceId),
      'sourceId': serializer.toJson<String>(sourceId),
      'postId': serializer.toJson<String>(postId),
      'variantIndex': serializer.toJson<int>(variantIndex),
      'url': serializer.toJson<String>(url),
      'filename': serializer.toJson<String>(filename),
      'headersJson': serializer.toJson<String>(headersJson),
      'networkOptionsJson': serializer.toJson<String>(networkOptionsJson),
      'validationJson': serializer.toJson<String>(validationJson),
      'saveTargetJson': serializer.toJson<String>(saveTargetJson),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'title': serializer.toJson<String?>(title),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DownloadJob copyWith({
    String? id,
    int? resourceId,
    String? sourceId,
    String? postId,
    int? variantIndex,
    String? url,
    String? filename,
    String? headersJson,
    String? networkOptionsJson,
    String? validationJson,
    String? saveTargetJson,
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<String?> title = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => DownloadJob(
    id: id ?? this.id,
    resourceId: resourceId ?? this.resourceId,
    sourceId: sourceId ?? this.sourceId,
    postId: postId ?? this.postId,
    variantIndex: variantIndex ?? this.variantIndex,
    url: url ?? this.url,
    filename: filename ?? this.filename,
    headersJson: headersJson ?? this.headersJson,
    networkOptionsJson: networkOptionsJson ?? this.networkOptionsJson,
    validationJson: validationJson ?? this.validationJson,
    saveTargetJson: saveTargetJson ?? this.saveTargetJson,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    title: title.present ? title.value : this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DownloadJob copyWithCompanion(DownloadJobsCompanion data) {
    return DownloadJob(
      id: data.id.present ? data.id.value : this.id,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      postId: data.postId.present ? data.postId.value : this.postId,
      variantIndex: data.variantIndex.present
          ? data.variantIndex.value
          : this.variantIndex,
      url: data.url.present ? data.url.value : this.url,
      filename: data.filename.present ? data.filename.value : this.filename,
      headersJson: data.headersJson.present
          ? data.headersJson.value
          : this.headersJson,
      networkOptionsJson: data.networkOptionsJson.present
          ? data.networkOptionsJson.value
          : this.networkOptionsJson,
      validationJson: data.validationJson.present
          ? data.validationJson.value
          : this.validationJson,
      saveTargetJson: data.saveTargetJson.present
          ? data.saveTargetJson.value
          : this.saveTargetJson,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJob(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('sourceId: $sourceId, ')
          ..write('postId: $postId, ')
          ..write('variantIndex: $variantIndex, ')
          ..write('url: $url, ')
          ..write('filename: $filename, ')
          ..write('headersJson: $headersJson, ')
          ..write('networkOptionsJson: $networkOptionsJson, ')
          ..write('validationJson: $validationJson, ')
          ..write('saveTargetJson: $saveTargetJson, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    resourceId,
    sourceId,
    postId,
    variantIndex,
    url,
    filename,
    headersJson,
    networkOptionsJson,
    validationJson,
    saveTargetJson,
    thumbnailUrl,
    title,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadJob &&
          other.id == this.id &&
          other.resourceId == this.resourceId &&
          other.sourceId == this.sourceId &&
          other.postId == this.postId &&
          other.variantIndex == this.variantIndex &&
          other.url == this.url &&
          other.filename == this.filename &&
          other.headersJson == this.headersJson &&
          other.networkOptionsJson == this.networkOptionsJson &&
          other.validationJson == this.validationJson &&
          other.saveTargetJson == this.saveTargetJson &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DownloadJobsCompanion extends UpdateCompanion<DownloadJob> {
  final Value<String> id;
  final Value<int> resourceId;
  final Value<String> sourceId;
  final Value<String> postId;
  final Value<int> variantIndex;
  final Value<String> url;
  final Value<String> filename;
  final Value<String> headersJson;
  final Value<String> networkOptionsJson;
  final Value<String> validationJson;
  final Value<String> saveTargetJson;
  final Value<String?> thumbnailUrl;
  final Value<String?> title;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DownloadJobsCompanion({
    this.id = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.postId = const Value.absent(),
    this.variantIndex = const Value.absent(),
    this.url = const Value.absent(),
    this.filename = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.networkOptionsJson = const Value.absent(),
    this.validationJson = const Value.absent(),
    this.saveTargetJson = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadJobsCompanion.insert({
    required String id,
    required int resourceId,
    this.sourceId = const Value.absent(),
    this.postId = const Value.absent(),
    this.variantIndex = const Value.absent(),
    required String url,
    required String filename,
    this.headersJson = const Value.absent(),
    this.networkOptionsJson = const Value.absent(),
    this.validationJson = const Value.absent(),
    this.saveTargetJson = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.title = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       resourceId = Value(resourceId),
       url = Value(url),
       filename = Value(filename),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DownloadJob> custom({
    Expression<String>? id,
    Expression<int>? resourceId,
    Expression<String>? sourceId,
    Expression<String>? postId,
    Expression<int>? variantIndex,
    Expression<String>? url,
    Expression<String>? filename,
    Expression<String>? headersJson,
    Expression<String>? networkOptionsJson,
    Expression<String>? validationJson,
    Expression<String>? saveTargetJson,
    Expression<String>? thumbnailUrl,
    Expression<String>? title,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resourceId != null) 'resource_id': resourceId,
      if (sourceId != null) 'source_id': sourceId,
      if (postId != null) 'post_id': postId,
      if (variantIndex != null) 'variant_index': variantIndex,
      if (url != null) 'url': url,
      if (filename != null) 'filename': filename,
      if (headersJson != null) 'headers_json': headersJson,
      if (networkOptionsJson != null)
        'network_options_json': networkOptionsJson,
      if (validationJson != null) 'validation_json': validationJson,
      if (saveTargetJson != null) 'save_target_json': saveTargetJson,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadJobsCompanion copyWith({
    Value<String>? id,
    Value<int>? resourceId,
    Value<String>? sourceId,
    Value<String>? postId,
    Value<int>? variantIndex,
    Value<String>? url,
    Value<String>? filename,
    Value<String>? headersJson,
    Value<String>? networkOptionsJson,
    Value<String>? validationJson,
    Value<String>? saveTargetJson,
    Value<String?>? thumbnailUrl,
    Value<String?>? title,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DownloadJobsCompanion(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      sourceId: sourceId ?? this.sourceId,
      postId: postId ?? this.postId,
      variantIndex: variantIndex ?? this.variantIndex,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      headersJson: headersJson ?? this.headersJson,
      networkOptionsJson: networkOptionsJson ?? this.networkOptionsJson,
      validationJson: validationJson ?? this.validationJson,
      saveTargetJson: saveTargetJson ?? this.saveTargetJson,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<int>(resourceId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (postId.present) {
      map['post_id'] = Variable<String>(postId.value);
    }
    if (variantIndex.present) {
      map['variant_index'] = Variable<int>(variantIndex.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (headersJson.present) {
      map['headers_json'] = Variable<String>(headersJson.value);
    }
    if (networkOptionsJson.present) {
      map['network_options_json'] = Variable<String>(networkOptionsJson.value);
    }
    if (validationJson.present) {
      map['validation_json'] = Variable<String>(validationJson.value);
    }
    if (saveTargetJson.present) {
      map['save_target_json'] = Variable<String>(saveTargetJson.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobsCompanion(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('sourceId: $sourceId, ')
          ..write('postId: $postId, ')
          ..write('variantIndex: $variantIndex, ')
          ..write('url: $url, ')
          ..write('filename: $filename, ')
          ..write('headersJson: $headersJson, ')
          ..write('networkOptionsJson: $networkOptionsJson, ')
          ..write('validationJson: $validationJson, ')
          ..write('saveTargetJson: $saveTargetJson, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadStatesTable extends DownloadStates
    with TableInfo<$DownloadStatesTable, DownloadState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES download_jobs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saveStateMeta = const VerificationMeta(
    'saveState',
  );
  @override
  late final GeneratedColumn<String> saveState = GeneratedColumn<String>(
    'save_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedBytesMeta = const VerificationMeta(
    'receivedBytes',
  );
  @override
  late final GeneratedColumn<int> receivedBytes = GeneratedColumn<int>(
    'received_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _galleryAssetIdMeta = const VerificationMeta(
    'galleryAssetId',
  );
  @override
  late final GeneratedColumn<String> galleryAssetId = GeneratedColumn<String>(
    'gallery_asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logMeta = const VerificationMeta('log');
  @override
  late final GeneratedColumn<String> log = GeneratedColumn<String>(
    'log',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    jobId,
    status,
    saveState,
    receivedBytes,
    totalBytes,
    progress,
    localPath,
    galleryAssetId,
    error,
    log,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('save_state')) {
      context.handle(
        _saveStateMeta,
        saveState.isAcceptableOrUnknown(data['save_state']!, _saveStateMeta),
      );
    } else if (isInserting) {
      context.missing(_saveStateMeta);
    }
    if (data.containsKey('received_bytes')) {
      context.handle(
        _receivedBytesMeta,
        receivedBytes.isAcceptableOrUnknown(
          data['received_bytes']!,
          _receivedBytesMeta,
        ),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('gallery_asset_id')) {
      context.handle(
        _galleryAssetIdMeta,
        galleryAssetId.isAcceptableOrUnknown(
          data['gallery_asset_id']!,
          _galleryAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('log')) {
      context.handle(
        _logMeta,
        log.isAcceptableOrUnknown(data['log']!, _logMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jobId};
  @override
  DownloadState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadState(
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      saveState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}save_state'],
      )!,
      receivedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_bytes'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      galleryAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gallery_asset_id'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      log: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DownloadStatesTable createAlias(String alias) {
    return $DownloadStatesTable(attachedDatabase, alias);
  }
}

class DownloadState extends DataClass implements Insertable<DownloadState> {
  final String jobId;
  final String status;
  final String saveState;
  final int receivedBytes;
  final int? totalBytes;
  final double progress;
  final String? localPath;
  final String? galleryAssetId;
  final String? error;
  final String? log;
  final int updatedAt;
  const DownloadState({
    required this.jobId,
    required this.status,
    required this.saveState,
    required this.receivedBytes,
    this.totalBytes,
    required this.progress,
    this.localPath,
    this.galleryAssetId,
    this.error,
    this.log,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['job_id'] = Variable<String>(jobId);
    map['status'] = Variable<String>(status);
    map['save_state'] = Variable<String>(saveState);
    map['received_bytes'] = Variable<int>(receivedBytes);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || galleryAssetId != null) {
      map['gallery_asset_id'] = Variable<String>(galleryAssetId);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || log != null) {
      map['log'] = Variable<String>(log);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DownloadStatesCompanion toCompanion(bool nullToAbsent) {
    return DownloadStatesCompanion(
      jobId: Value(jobId),
      status: Value(status),
      saveState: Value(saveState),
      receivedBytes: Value(receivedBytes),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      progress: Value(progress),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      galleryAssetId: galleryAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(galleryAssetId),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      log: log == null && nullToAbsent ? const Value.absent() : Value(log),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadState(
      jobId: serializer.fromJson<String>(json['jobId']),
      status: serializer.fromJson<String>(json['status']),
      saveState: serializer.fromJson<String>(json['saveState']),
      receivedBytes: serializer.fromJson<int>(json['receivedBytes']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      progress: serializer.fromJson<double>(json['progress']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      galleryAssetId: serializer.fromJson<String?>(json['galleryAssetId']),
      error: serializer.fromJson<String?>(json['error']),
      log: serializer.fromJson<String?>(json['log']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'jobId': serializer.toJson<String>(jobId),
      'status': serializer.toJson<String>(status),
      'saveState': serializer.toJson<String>(saveState),
      'receivedBytes': serializer.toJson<int>(receivedBytes),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'progress': serializer.toJson<double>(progress),
      'localPath': serializer.toJson<String?>(localPath),
      'galleryAssetId': serializer.toJson<String?>(galleryAssetId),
      'error': serializer.toJson<String?>(error),
      'log': serializer.toJson<String?>(log),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DownloadState copyWith({
    String? jobId,
    String? status,
    String? saveState,
    int? receivedBytes,
    Value<int?> totalBytes = const Value.absent(),
    double? progress,
    Value<String?> localPath = const Value.absent(),
    Value<String?> galleryAssetId = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<String?> log = const Value.absent(),
    int? updatedAt,
  }) => DownloadState(
    jobId: jobId ?? this.jobId,
    status: status ?? this.status,
    saveState: saveState ?? this.saveState,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
    progress: progress ?? this.progress,
    localPath: localPath.present ? localPath.value : this.localPath,
    galleryAssetId: galleryAssetId.present
        ? galleryAssetId.value
        : this.galleryAssetId,
    error: error.present ? error.value : this.error,
    log: log.present ? log.value : this.log,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DownloadState copyWithCompanion(DownloadStatesCompanion data) {
    return DownloadState(
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      status: data.status.present ? data.status.value : this.status,
      saveState: data.saveState.present ? data.saveState.value : this.saveState,
      receivedBytes: data.receivedBytes.present
          ? data.receivedBytes.value
          : this.receivedBytes,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      progress: data.progress.present ? data.progress.value : this.progress,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      galleryAssetId: data.galleryAssetId.present
          ? data.galleryAssetId.value
          : this.galleryAssetId,
      error: data.error.present ? data.error.value : this.error,
      log: data.log.present ? data.log.value : this.log,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadState(')
          ..write('jobId: $jobId, ')
          ..write('status: $status, ')
          ..write('saveState: $saveState, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('progress: $progress, ')
          ..write('localPath: $localPath, ')
          ..write('galleryAssetId: $galleryAssetId, ')
          ..write('error: $error, ')
          ..write('log: $log, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    jobId,
    status,
    saveState,
    receivedBytes,
    totalBytes,
    progress,
    localPath,
    galleryAssetId,
    error,
    log,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadState &&
          other.jobId == this.jobId &&
          other.status == this.status &&
          other.saveState == this.saveState &&
          other.receivedBytes == this.receivedBytes &&
          other.totalBytes == this.totalBytes &&
          other.progress == this.progress &&
          other.localPath == this.localPath &&
          other.galleryAssetId == this.galleryAssetId &&
          other.error == this.error &&
          other.log == this.log &&
          other.updatedAt == this.updatedAt);
}

class DownloadStatesCompanion extends UpdateCompanion<DownloadState> {
  final Value<String> jobId;
  final Value<String> status;
  final Value<String> saveState;
  final Value<int> receivedBytes;
  final Value<int?> totalBytes;
  final Value<double> progress;
  final Value<String?> localPath;
  final Value<String?> galleryAssetId;
  final Value<String?> error;
  final Value<String?> log;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DownloadStatesCompanion({
    this.jobId = const Value.absent(),
    this.status = const Value.absent(),
    this.saveState = const Value.absent(),
    this.receivedBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.progress = const Value.absent(),
    this.localPath = const Value.absent(),
    this.galleryAssetId = const Value.absent(),
    this.error = const Value.absent(),
    this.log = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadStatesCompanion.insert({
    required String jobId,
    required String status,
    required String saveState,
    this.receivedBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.progress = const Value.absent(),
    this.localPath = const Value.absent(),
    this.galleryAssetId = const Value.absent(),
    this.error = const Value.absent(),
    this.log = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : jobId = Value(jobId),
       status = Value(status),
       saveState = Value(saveState),
       updatedAt = Value(updatedAt);
  static Insertable<DownloadState> custom({
    Expression<String>? jobId,
    Expression<String>? status,
    Expression<String>? saveState,
    Expression<int>? receivedBytes,
    Expression<int>? totalBytes,
    Expression<double>? progress,
    Expression<String>? localPath,
    Expression<String>? galleryAssetId,
    Expression<String>? error,
    Expression<String>? log,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (jobId != null) 'job_id': jobId,
      if (status != null) 'status': status,
      if (saveState != null) 'save_state': saveState,
      if (receivedBytes != null) 'received_bytes': receivedBytes,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (progress != null) 'progress': progress,
      if (localPath != null) 'local_path': localPath,
      if (galleryAssetId != null) 'gallery_asset_id': galleryAssetId,
      if (error != null) 'error': error,
      if (log != null) 'log': log,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadStatesCompanion copyWith({
    Value<String>? jobId,
    Value<String>? status,
    Value<String>? saveState,
    Value<int>? receivedBytes,
    Value<int?>? totalBytes,
    Value<double>? progress,
    Value<String?>? localPath,
    Value<String?>? galleryAssetId,
    Value<String?>? error,
    Value<String?>? log,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DownloadStatesCompanion(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      saveState: saveState ?? this.saveState,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      galleryAssetId: galleryAssetId ?? this.galleryAssetId,
      error: error ?? this.error,
      log: log ?? this.log,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (saveState.present) {
      map['save_state'] = Variable<String>(saveState.value);
    }
    if (receivedBytes.present) {
      map['received_bytes'] = Variable<int>(receivedBytes.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (galleryAssetId.present) {
      map['gallery_asset_id'] = Variable<String>(galleryAssetId.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (log.present) {
      map['log'] = Variable<String>(log.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadStatesCompanion(')
          ..write('jobId: $jobId, ')
          ..write('status: $status, ')
          ..write('saveState: $saveState, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('progress: $progress, ')
          ..write('localPath: $localPath, ')
          ..write('galleryAssetId: $galleryAssetId, ')
          ..write('error: $error, ')
          ..write('log: $log, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DownloadDatabase extends GeneratedDatabase {
  _$DownloadDatabase(QueryExecutor e) : super(e);
  $DownloadDatabaseManager get managers => $DownloadDatabaseManager(this);
  late final $DownloadJobsTable downloadJobs = $DownloadJobsTable(this);
  late final $DownloadStatesTable downloadStates = $DownloadStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    downloadJobs,
    downloadStates,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'download_jobs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('download_states', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DownloadJobsTableCreateCompanionBuilder =
    DownloadJobsCompanion Function({
      required String id,
      required int resourceId,
      Value<String> sourceId,
      Value<String> postId,
      Value<int> variantIndex,
      required String url,
      required String filename,
      Value<String> headersJson,
      Value<String> networkOptionsJson,
      Value<String> validationJson,
      Value<String> saveTargetJson,
      Value<String?> thumbnailUrl,
      Value<String?> title,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DownloadJobsTableUpdateCompanionBuilder =
    DownloadJobsCompanion Function({
      Value<String> id,
      Value<int> resourceId,
      Value<String> sourceId,
      Value<String> postId,
      Value<int> variantIndex,
      Value<String> url,
      Value<String> filename,
      Value<String> headersJson,
      Value<String> networkOptionsJson,
      Value<String> validationJson,
      Value<String> saveTargetJson,
      Value<String?> thumbnailUrl,
      Value<String?> title,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$DownloadJobsTableReferences
    extends
        BaseReferences<_$DownloadDatabase, $DownloadJobsTable, DownloadJob> {
  $$DownloadJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DownloadStatesTable, List<DownloadState>>
  _downloadStatesRefsTable(_$DownloadDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.downloadStates,
        aliasName: 'download_jobs__id__download_states__job_id',
      );

  $$DownloadStatesTableProcessedTableManager get downloadStatesRefs {
    final manager = $$DownloadStatesTableTableManager(
      $_db,
      $_db.downloadStates,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_downloadStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DownloadJobsTableFilterComposer
    extends Composer<_$DownloadDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postId => $composableBuilder(
    column: $table.postId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get variantIndex => $composableBuilder(
    column: $table.variantIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get networkOptionsJson => $composableBuilder(
    column: $table.networkOptionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validationJson => $composableBuilder(
    column: $table.validationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saveTargetJson => $composableBuilder(
    column: $table.saveTargetJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> downloadStatesRefs(
    Expression<bool> Function($$DownloadStatesTableFilterComposer f) f,
  ) {
    final $$DownloadStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadStates,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadStatesTableFilterComposer(
            $db: $db,
            $table: $db.downloadStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DownloadJobsTableOrderingComposer
    extends Composer<_$DownloadDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postId => $composableBuilder(
    column: $table.postId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get variantIndex => $composableBuilder(
    column: $table.variantIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get networkOptionsJson => $composableBuilder(
    column: $table.networkOptionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validationJson => $composableBuilder(
    column: $table.validationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saveTargetJson => $composableBuilder(
    column: $table.saveTargetJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadJobsTableAnnotationComposer
    extends Composer<_$DownloadDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get postId =>
      $composableBuilder(column: $table.postId, builder: (column) => column);

  GeneratedColumn<int> get variantIndex => $composableBuilder(
    column: $table.variantIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get networkOptionsJson => $composableBuilder(
    column: $table.networkOptionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get validationJson => $composableBuilder(
    column: $table.validationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saveTargetJson => $composableBuilder(
    column: $table.saveTargetJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> downloadStatesRefs<T extends Object>(
    Expression<T> Function($$DownloadStatesTableAnnotationComposer a) f,
  ) {
    final $$DownloadStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadStates,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DownloadJobsTableTableManager
    extends
        RootTableManager<
          _$DownloadDatabase,
          $DownloadJobsTable,
          DownloadJob,
          $$DownloadJobsTableFilterComposer,
          $$DownloadJobsTableOrderingComposer,
          $$DownloadJobsTableAnnotationComposer,
          $$DownloadJobsTableCreateCompanionBuilder,
          $$DownloadJobsTableUpdateCompanionBuilder,
          (DownloadJob, $$DownloadJobsTableReferences),
          DownloadJob,
          PrefetchHooks Function({bool downloadStatesRefs})
        > {
  $$DownloadJobsTableTableManager(
    _$DownloadDatabase db,
    $DownloadJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> resourceId = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> postId = const Value.absent(),
                Value<int> variantIndex = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<String> headersJson = const Value.absent(),
                Value<String> networkOptionsJson = const Value.absent(),
                Value<String> validationJson = const Value.absent(),
                Value<String> saveTargetJson = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobsCompanion(
                id: id,
                resourceId: resourceId,
                sourceId: sourceId,
                postId: postId,
                variantIndex: variantIndex,
                url: url,
                filename: filename,
                headersJson: headersJson,
                networkOptionsJson: networkOptionsJson,
                validationJson: validationJson,
                saveTargetJson: saveTargetJson,
                thumbnailUrl: thumbnailUrl,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int resourceId,
                Value<String> sourceId = const Value.absent(),
                Value<String> postId = const Value.absent(),
                Value<int> variantIndex = const Value.absent(),
                required String url,
                required String filename,
                Value<String> headersJson = const Value.absent(),
                Value<String> networkOptionsJson = const Value.absent(),
                Value<String> validationJson = const Value.absent(),
                Value<String> saveTargetJson = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobsCompanion.insert(
                id: id,
                resourceId: resourceId,
                sourceId: sourceId,
                postId: postId,
                variantIndex: variantIndex,
                url: url,
                filename: filename,
                headersJson: headersJson,
                networkOptionsJson: networkOptionsJson,
                validationJson: validationJson,
                saveTargetJson: saveTargetJson,
                thumbnailUrl: thumbnailUrl,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DownloadJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({downloadStatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (downloadStatesRefs) db.downloadStates,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (downloadStatesRefs)
                    await $_getPrefetchedData<
                      DownloadJob,
                      $DownloadJobsTable,
                      DownloadState
                    >(
                      currentTable: table,
                      referencedTable: $$DownloadJobsTableReferences
                          ._downloadStatesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DownloadJobsTableReferences(
                            db,
                            table,
                            p0,
                          ).downloadStatesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.jobId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DownloadJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$DownloadDatabase,
      $DownloadJobsTable,
      DownloadJob,
      $$DownloadJobsTableFilterComposer,
      $$DownloadJobsTableOrderingComposer,
      $$DownloadJobsTableAnnotationComposer,
      $$DownloadJobsTableCreateCompanionBuilder,
      $$DownloadJobsTableUpdateCompanionBuilder,
      (DownloadJob, $$DownloadJobsTableReferences),
      DownloadJob,
      PrefetchHooks Function({bool downloadStatesRefs})
    >;
typedef $$DownloadStatesTableCreateCompanionBuilder =
    DownloadStatesCompanion Function({
      required String jobId,
      required String status,
      required String saveState,
      Value<int> receivedBytes,
      Value<int?> totalBytes,
      Value<double> progress,
      Value<String?> localPath,
      Value<String?> galleryAssetId,
      Value<String?> error,
      Value<String?> log,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DownloadStatesTableUpdateCompanionBuilder =
    DownloadStatesCompanion Function({
      Value<String> jobId,
      Value<String> status,
      Value<String> saveState,
      Value<int> receivedBytes,
      Value<int?> totalBytes,
      Value<double> progress,
      Value<String?> localPath,
      Value<String?> galleryAssetId,
      Value<String?> error,
      Value<String?> log,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$DownloadStatesTableReferences
    extends
        BaseReferences<
          _$DownloadDatabase,
          $DownloadStatesTable,
          DownloadState
        > {
  $$DownloadStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DownloadJobsTable _jobIdTable(_$DownloadDatabase db) =>
      db.downloadJobs.createAlias('download_states__job_id__download_jobs__id');

  $$DownloadJobsTableProcessedTableManager get jobId {
    final $_column = $_itemColumn<String>('job_id')!;

    final manager = $$DownloadJobsTableTableManager(
      $_db,
      $_db.downloadJobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DownloadStatesTableFilterComposer
    extends Composer<_$DownloadDatabase, $DownloadStatesTable> {
  $$DownloadStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saveState => $composableBuilder(
    column: $table.saveState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get galleryAssetId => $composableBuilder(
    column: $table.galleryAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get log => $composableBuilder(
    column: $table.log,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DownloadJobsTableFilterComposer get jobId {
    final $$DownloadJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableFilterComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadStatesTableOrderingComposer
    extends Composer<_$DownloadDatabase, $DownloadStatesTable> {
  $$DownloadStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saveState => $composableBuilder(
    column: $table.saveState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get galleryAssetId => $composableBuilder(
    column: $table.galleryAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get log => $composableBuilder(
    column: $table.log,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DownloadJobsTableOrderingComposer get jobId {
    final $$DownloadJobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableOrderingComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadStatesTableAnnotationComposer
    extends Composer<_$DownloadDatabase, $DownloadStatesTable> {
  $$DownloadStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get saveState =>
      $composableBuilder(column: $table.saveState, builder: (column) => column);

  GeneratedColumn<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get galleryAssetId => $composableBuilder(
    column: $table.galleryAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get log =>
      $composableBuilder(column: $table.log, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DownloadJobsTableAnnotationComposer get jobId {
    final $$DownloadJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadStatesTableTableManager
    extends
        RootTableManager<
          _$DownloadDatabase,
          $DownloadStatesTable,
          DownloadState,
          $$DownloadStatesTableFilterComposer,
          $$DownloadStatesTableOrderingComposer,
          $$DownloadStatesTableAnnotationComposer,
          $$DownloadStatesTableCreateCompanionBuilder,
          $$DownloadStatesTableUpdateCompanionBuilder,
          (DownloadState, $$DownloadStatesTableReferences),
          DownloadState,
          PrefetchHooks Function({bool jobId})
        > {
  $$DownloadStatesTableTableManager(
    _$DownloadDatabase db,
    $DownloadStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> jobId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> saveState = const Value.absent(),
                Value<int> receivedBytes = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> galleryAssetId = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> log = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadStatesCompanion(
                jobId: jobId,
                status: status,
                saveState: saveState,
                receivedBytes: receivedBytes,
                totalBytes: totalBytes,
                progress: progress,
                localPath: localPath,
                galleryAssetId: galleryAssetId,
                error: error,
                log: log,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String jobId,
                required String status,
                required String saveState,
                Value<int> receivedBytes = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> galleryAssetId = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> log = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadStatesCompanion.insert(
                jobId: jobId,
                status: status,
                saveState: saveState,
                receivedBytes: receivedBytes,
                totalBytes: totalBytes,
                progress: progress,
                localPath: localPath,
                galleryAssetId: galleryAssetId,
                error: error,
                log: log,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DownloadStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jobId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (jobId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.jobId,
                                referencedTable: $$DownloadStatesTableReferences
                                    ._jobIdTable(db),
                                referencedColumn:
                                    $$DownloadStatesTableReferences
                                        ._jobIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DownloadStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$DownloadDatabase,
      $DownloadStatesTable,
      DownloadState,
      $$DownloadStatesTableFilterComposer,
      $$DownloadStatesTableOrderingComposer,
      $$DownloadStatesTableAnnotationComposer,
      $$DownloadStatesTableCreateCompanionBuilder,
      $$DownloadStatesTableUpdateCompanionBuilder,
      (DownloadState, $$DownloadStatesTableReferences),
      DownloadState,
      PrefetchHooks Function({bool jobId})
    >;

class $DownloadDatabaseManager {
  final _$DownloadDatabase _db;
  $DownloadDatabaseManager(this._db);
  $$DownloadJobsTableTableManager get downloadJobs =>
      $$DownloadJobsTableTableManager(_db, _db.downloadJobs);
  $$DownloadStatesTableTableManager get downloadStates =>
      $$DownloadStatesTableTableManager(_db, _db.downloadStates);
}
