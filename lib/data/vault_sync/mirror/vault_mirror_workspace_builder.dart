import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/data/bundles/datasources/local/bundles_local_data_source.dart';
import 'package:pass_doc_manager/data/bundles/dtos/bundle_record_dto.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_detail_dto.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';
import 'package:pass_doc_manager/data/notes/datasources/local/secure_notes_local_data_source.dart';
import 'package:pass_doc_manager/data/notes/dtos/secure_note_dto.dart';
import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_record_dto.dart';
import 'package:pass_doc_manager/data/tasks/datasources/local/tasks_local_data_source.dart';
import 'package:pass_doc_manager/data/tasks/dtos/task_record_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_metadata_keys.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';

class VaultMirrorWorkspaceBuilder {
  VaultMirrorWorkspaceBuilder({
    required this.documentLocalDataSource,
    required this.collectionsLocalDataSource,
    required this.bundlesLocalDataSource,
    required this.tasksLocalDataSource,
    required this.credentialLocalDataSource,
    required this.profileLocalDataSource,
    required this.secureNotesLocalDataSource,
  });

  final DocumentLocalDataSource documentLocalDataSource;
  final CollectionsLocalDataSource collectionsLocalDataSource;
  final BundlesLocalDataSource bundlesLocalDataSource;
  final TasksLocalDataSource tasksLocalDataSource;
  final CredentialLocalDataSource credentialLocalDataSource;
  final ProfileLocalDataSource profileLocalDataSource;
  final SecureNotesLocalDataSource secureNotesLocalDataSource;

  final _directories = <String>{VaultMirrorWorkspace.metadataDir};
  final _files = <VaultMirrorFile>[];
  final _nodes = <VaultMirrorNode>[];
  final _usedPaths = <String>{};
  final _warnings = <String>[];

  Future<VaultMirrorWorkspace> build({
    required String deviceId,
    required int revision,
  }) async {
    await LocalAssetPathResolver.initialize();
    _directories
      ..clear()
      ..add(VaultMirrorWorkspace.metadataDir)
      ..add('${VaultMirrorWorkspace.metadataDir}/assets');
    _files.clear();
    _nodes.clear();
    _usedPaths.clear();
    _warnings.clear();

    final generatedAtIso = DateTime.now().toUtc().toIso8601String();
    final documents = _stableDocuments(
      await documentLocalDataSource.getDocuments(),
    );
    final collections = _stableCollections(
      await collectionsLocalDataSource.getCollections(),
    );
    final bundles = _stableBundles(await bundlesLocalDataSource.getBundles());
    final tasks = _stableTaskLists(await tasksLocalDataSource.getTaskLists());
    final profile = await profileLocalDataSource.readProfile();
    final credentials = _stableCredentials(await _readCredentialDetails());
    final secureNotes = _stableSecureNotes(
      await secureNotesLocalDataSource.getAllNoteDetails(),
    );

    await _buildDocuments(documents);
    await _buildCollections(collections);
    await _buildBundles(bundles);
    await _buildTasks(tasks);
    await _buildProfile(profile);
    await _buildCredentials(credentials);
    await _buildSecureNotes(secureNotes);

    final snapshot = {
      'schema_version': 1,
      'documents': documents.map((item) => item.toMap()).toList(),
      'collections': collections.map((item) => item.toMap()).toList(),
      'bundles': bundles.map((item) => item.toMap()).toList(),
      'tasks': tasks.map((item) => item.toMap()).toList(),
      'profile': profile.toMap(),
      'credentials': credentials.map(_credentialToMap).toList(),
      'secure_notes': secureNotes.map((item) => item.toMap()).toList(),
    };

    await _addTextFile(
      VaultMirrorWorkspace.snapshotPath,
      const JsonEncoder.withIndent('  ').convert(snapshot),
    );

    final contentChecksum = await _buildStableContentChecksum();
    final manifest = {
      'schema_version': 1,
      'revision': revision,
      'device_id': deviceId,
      'generated_at_iso': generatedAtIso,
      'content_checksum': contentChecksum,
      'roots': const [
        'Documents',
        'Collections',
        'Bundles',
        'Tasks',
        'Credentials',
        'Profile',
        'Secure Notes',
      ],
      'directories': _directories.toList()..sort(),
      'files': _files.map((file) => file.toManifestMap()).toList()
        ..sort((a, b) => '${a['path']}'.compareTo('${b['path']}')),
      'nodes': _nodes.map((node) => node.toMap()).toList()
        ..sort((a, b) => '${a['path']}'.compareTo('${b['path']}')),
      if (_warnings.isNotEmpty) 'warnings': List<String>.from(_warnings),
    };
    final manifestText = const JsonEncoder.withIndent('  ').convert(manifest);
    final manifestChecksum = await _hashBytes(utf8.encode(manifestText));

    return VaultMirrorWorkspace(
      revision: revision,
      deviceId: deviceId,
      generatedAtIso: generatedAtIso,
      directories: Set<String>.from(_directories),
      files: List<VaultMirrorFile>.unmodifiable(_files),
      nodes: List<VaultMirrorNode>.unmodifiable(_nodes),
      snapshot: snapshot,
      manifestText: manifestText,
      manifestChecksum: manifestChecksum,
      contentChecksum: contentChecksum,
      warnings: List<String>.unmodifiable(_warnings),
    );
  }

  Future<List<CredentialDetailDto>> _readCredentialDetails() async {
    final summaries = await credentialLocalDataSource.getCredentialSummaries();
    final details = <CredentialDetailDto>[];
    for (final summary in summaries) {
      try {
        details.add(
          await credentialLocalDataSource.getCredentialDetailById(
            id: summary.id,
          ),
        );
      } catch (_) {
        // A stale summary should not block the rest of the mirror.
      }
    }
    return details;
  }

  List<DocumentRecordDto> _stableDocuments(List<DocumentRecordDto> documents) {
    return documents.toList(growable: false)..sort(
      (a, b) => _compareStableText(
        [_documentDirectory(a), _documentDisplayStem(a), a.id],
        [_documentDirectory(b), _documentDisplayStem(b), b.id],
      ),
    );
  }

  List<CollectionRecordDto> _stableCollections(
    List<CollectionRecordDto> collections,
  ) {
    return collections.toList(growable: false)..sort((a, b) {
      final byPosition = _compareOptionalPosition(a.position, b.position);
      if (byPosition != 0) return byPosition;
      return _compareStableText([a.name, a.id], [b.name, b.id]);
    });
  }

  List<BundleRecordDto> _stableBundles(List<BundleRecordDto> bundles) {
    return bundles.toList(growable: false)
      ..sort((a, b) => _compareStableText([a.title, a.id], [b.title, b.id]));
  }

  List<TaskListRecordDto> _stableTaskLists(List<TaskListRecordDto> lists) {
    return lists.toList(growable: false)
      ..sort((a, b) => _compareStableText([a.title, a.id], [b.title, b.id]));
  }

  List<CredentialDetailDto> _stableCredentials(
    List<CredentialDetailDto> credentials,
  ) {
    return credentials.toList(growable: false)..sort(
      (a, b) => _compareStableText(
        [a.categoryKey, a.serviceName, a.accountLabel, a.username, a.id],
        [b.categoryKey, b.serviceName, b.accountLabel, b.username, b.id],
      ),
    );
  }

  List<SecureNoteDetailDto> _stableSecureNotes(
    List<SecureNoteDetailDto> notes,
  ) {
    return notes.toList(growable: false)..sort(
      (a, b) => _compareStableText(
        [a.note.title, a.note.id],
        [b.note.title, b.note.id],
      ),
    );
  }

  Future<void> _buildDocuments(List<DocumentRecordDto> documents) async {
    _addDirectory('Documents');
    for (var i = 0; i < documents.length; i++) {
      final document = documents[i];
      final directory = _documentDirectory(document);
      _addDirectory(directory);
      final attachments = _sourceAttachmentsForDocument(document);
      final basename = _slug(_documentDisplayStem(document));
      var nodePath = directory;
      if (attachments.isNotEmpty) {
        for (var fileIndex = 0; fileIndex < attachments.length; fileIndex++) {
          final attachment = attachments[fileIndex];
          final suffix = _attachmentSuffix(
            attachments: attachments,
            attachment: attachment,
            index: fileIndex,
          );
          final fallbackType = _firstNonEmptyString([
            attachment.mime,
            attachment.originalName,
            document.fileName,
          ]);
          final path = await _addSourceFile(
            '$directory/${_slug('$basename$suffix')}${_sourceFileExtension(attachment.sourcePath, fallbackType)}',
            attachment.sourcePath,
            identityKey: 'document:${document.id}:attachment:$fileIndex',
          );
          if (fileIndex == 0) {
            nodePath = path;
          }
        }
      } else {
        nodePath = await _addTextFile(
          '$directory/$basename.md',
          _documentMarkdown(document),
          identityKey: 'document:${document.id}:body',
        );
      }
      await _addNode(
        id: document.id,
        type: 'document',
        displayName: _documentDisplayStem(document),
        path: nodePath,
        order: i,
        updatedAtIso: document.updatedAtIso,
        metadata: document.toMap(),
      );
    }
  }

  Future<void> _buildCollections(List<CollectionRecordDto> collections) async {
    _addDirectory('Collections');
    for (var i = 0; i < collections.length; i++) {
      final collection = collections[i];
      final collectionDir = 'Collections/${_slug(collection.name)}';
      _addDirectory(collectionDir);
      await _addNode(
        id: collection.id,
        type: 'collection',
        displayName: collection.name,
        path: collectionDir,
        order: collection.position == 0 ? i : collection.position,
        updatedAtIso: collection.updatedAtIso,
        metadata: collection.toMap(),
      );
      await _copyAssetIfPresent(
        sourcePath: collection.iconImagePath,
        path:
            '${VaultMirrorWorkspace.metadataDir}/assets/collections/${collection.id}/icon${_extensionFromPath(collection.iconImagePath) ?? '.bin'}',
        identityKey: 'collection:${collection.id}:icon',
      );
      await _copyAssetIfPresent(
        sourcePath: collection.coverImageUrl,
        path:
            '${VaultMirrorWorkspace.metadataDir}/assets/collections/${collection.id}/cover${_extensionFromPath(collection.coverImageUrl) ?? '.bin'}',
        identityKey: 'collection:${collection.id}:cover',
      );
      final byParent = <String, List<CollectionBlockRecordDto>>{};
      for (final block in collection.blocks) {
        byParent.putIfAbsent(block.parentBlockId ?? '', () => []).add(block);
      }
      for (final blocks in byParent.values) {
        blocks.sort(_compareCollectionBlocks);
      }
      await _buildCollectionBlocks(
        collectionId: collection.id,
        blocks: byParent[''] ?? const <CollectionBlockRecordDto>[],
        byParent: byParent,
        directory: collectionDir,
        parentId: collection.id,
      );
    }
  }

  Future<void> _buildCollectionBlocks({
    required String collectionId,
    required List<CollectionBlockRecordDto> blocks,
    required Map<String, List<CollectionBlockRecordDto>> byParent,
    required String directory,
    required String parentId,
  }) async {
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final title = block.title.trim().isEmpty ? block.typeKey : block.title;
      final blockMetadata = block.toMap();
      final type = block.typeKey;
      if (type == 'folder' || type == 'section') {
        final blockDir = '$directory/${_slug(title)}';
        _addDirectory(blockDir);
        await _addNode(
          id: block.id,
          type: type,
          displayName: title,
          path: blockDir,
          parentId: parentId,
          order: block.position == 0 ? i : block.position,
          updatedAtIso: block.updatedAtIso,
          metadata: blockMetadata,
        );
        await _copyBlockIconAsset(block);
        await _buildCollectionBlocks(
          collectionId: collectionId,
          blocks: byParent[block.id] ?? const <CollectionBlockRecordDto>[],
          byParent: byParent,
          directory: blockDir,
          parentId: block.id,
        );
        continue;
      }

      await _addCollectionContentBlock(
        directory: directory,
        parentId: parentId,
        block: block,
        order: block.position == 0 ? i : block.position,
      );
    }
  }

  Future<void> _addCollectionContentBlock({
    required String directory,
    required String parentId,
    required CollectionBlockRecordDto block,
    required int order,
  }) async {
    final title = block.title.trim().isEmpty ? block.typeKey : block.title;
    final metadata = block.toMap();
    String path = directory;

    switch (block.typeKey) {
      case 'document':
        final rawSource = block.filePath;
        final source = _existingLocalPath(rawSource);
        final slug = _slug(_collectionFileStem(block, source));
        if (source != null) {
          path = await _addSourceFile(
            '$directory/$slug${_sourceFileExtension(source, block.fileType)}',
            source,
            identityKey: 'collection_block:${block.id}:content',
          );
        } else {
          path = _missingReferencePath(directory, slug);
          _addMissingReferenceWarning(
            typeLabel: 'document',
            displayName: _collectionBlockLabel(block),
            rawPath: rawSource,
          );
        }
        break;
      case 'image':
        final rawSource = block.filePath ?? block.imageUrl;
        final source = _existingLocalPath(rawSource);
        final slug = _slug(_collectionFileStem(block, source));
        if (source != null) {
          path = await _addSourceFile(
            '$directory/$slug${_sourceFileExtension(source, block.fileType)}',
            source,
            identityKey: 'collection_block:${block.id}:content',
          );
        } else {
          path = _missingReferencePath(directory, slug);
          _addMissingReferenceWarning(
            typeLabel: 'image',
            displayName: _collectionBlockLabel(block),
            rawPath: rawSource,
          );
        }
        break;
      case 'note':
        final slug = _slug(title);
        path = await _addTextFile(
          '$directory/$slug.md',
          _noteMarkdown(block),
          identityKey: 'collection_block:${block.id}:content',
        );
        break;
      case 'input':
        final slug = _slug(title);
        path = await _addTextFile(
          '$directory/$slug.md',
          _inputMarkdown(block),
          identityKey: 'collection_block:${block.id}:content',
        );
        break;
      case 'checklist':
        final slug = _slug(title);
        path = await _addTextFile(
          '$directory/$slug.md',
          _checklistMarkdown(block),
          identityKey: 'collection_block:${block.id}:content',
        );
        break;
      case 'link':
        final slug = _slug(title);
        final url = (block.url ?? '').trim();
        path = await _addTextFile(
          '$directory/$slug.url',
          '[InternetShortcut]\nURL=$url\n',
          identityKey: 'collection_block:${block.id}:content',
        );
        break;
      default:
        final slug = _slug(title);
        path = await _addTextFile(
          '$directory/$slug.md',
          _blockMarkdown(block),
          identityKey: 'collection_block:${block.id}:content',
        );
    }

    await _copyBlockIconAsset(block);
    await _addNode(
      id: block.id,
      type: block.typeKey,
      displayName: title,
      path: path,
      parentId: parentId,
      order: order,
      updatedAtIso: block.updatedAtIso,
      metadata: metadata,
    );
  }

  Future<void> _buildBundles(List<BundleRecordDto> bundles) async {
    _addDirectory('Bundles');
    for (var i = 0; i < bundles.length; i++) {
      final bundle = bundles[i];
      final directory = 'Bundles/${_slug(bundle.title)}';
      _addDirectory(directory);
      await _addTextFile(
        '$directory/README.md',
        _bundleMarkdown(bundle),
        identityKey: 'bundle:${bundle.id}:body',
      );
      await _addNode(
        id: bundle.id,
        type: 'bundle',
        displayName: bundle.title,
        path: directory,
        order: i,
        updatedAtIso: bundle.updatedAtIso,
        metadata: bundle.toMap(),
      );
    }
  }

  Future<void> _buildTasks(List<TaskListRecordDto> lists) async {
    _addDirectory('Tasks');
    for (var i = 0; i < lists.length; i++) {
      final list = lists[i];
      final path = await _addTextFile(
        'Tasks/${_slug(list.title)}.md',
        _taskListMarkdown(list),
        identityKey: 'task_list:${list.id}:body',
      );
      await _addNode(
        id: list.id,
        type: 'task_list',
        displayName: list.title,
        path: path,
        order: i,
        updatedAtIso: list.updatedAtIso,
        metadata: list.toMap(),
      );
    }
  }

  Future<void> _buildProfile(ProfileRecordDto profile) async {
    _addDirectory('Profile');
    final path = await _addTextFile(
      'Profile/Profile.md',
      _profileMarkdown(profile),
      identityKey: 'profile:profile:body',
    );
    await _copyAssetIfPresent(
      sourcePath: profile.photoPath,
      path: 'Profile/photo${_extensionFromPath(profile.photoPath) ?? '.bin'}',
      identityKey: 'profile:profile:photo',
    );
    await _addNode(
      id: 'profile',
      type: 'profile',
      displayName: 'Profile',
      path: path,
      order: 0,
      updatedAtIso: profile.updatedAtIso,
      metadata: profile.toMap(),
    );
  }

  Future<void> _buildCredentials(List<CredentialDetailDto> credentials) async {
    _addDirectory('Credentials');
    for (var i = 0; i < credentials.length; i++) {
      final credential = credentials[i];
      final directory =
          'Credentials/${_slug(credential.categoryKey.isEmpty ? 'General' : credential.categoryKey)}';
      _addDirectory(directory);
      final account = credential.accountLabel.trim().isEmpty
          ? credential.username
          : credential.accountLabel;
      final path = await _addTextFile(
        '$directory/${_slug('${credential.serviceName} - $account')}.md',
        _credentialMarkdown(credential),
        identityKey: 'credential:${credential.id}:body',
      );
      await _copyAssetIfPresent(
        sourcePath: credential.logoPath,
        path:
            '${VaultMirrorWorkspace.metadataDir}/assets/credentials/${credential.id}/logo${_extensionFromPath(credential.logoPath) ?? '.bin'}',
        identityKey: 'credential:${credential.id}:logo',
      );
      await _addNode(
        id: credential.id,
        type: 'credential',
        displayName: credential.serviceName,
        path: path,
        order: i,
        metadata: _credentialToMap(credential),
      );
    }
  }

  Future<void> _buildSecureNotes(List<SecureNoteDetailDto> notes) async {
    _addDirectory('Secure Notes');
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final title = note.note.title.trim().isEmpty
          ? 'Untitled Note'
          : note.note.title.trim();
      final path = await _addTextFile(
        'Secure Notes/${_slug(title)}.md',
        _secureNoteMarkdown(note),
        identityKey: 'secure_note:${note.note.id}:body',
      );
      await _copySecureNoteAssets(note);
      await _addNode(
        id: note.note.id,
        type: 'secure_note',
        displayName: title,
        path: path,
        order: i,
        updatedAtIso: note.note.updatedAtIso,
        metadata: note.toMap().cast<String, dynamic>(),
      );
    }
  }

  Future<void> _copySecureNoteAssets(SecureNoteDetailDto note) async {
    var assetIndex = 0;
    for (final source in _localPathsFromObject(note.toMap())) {
      final extension = _extensionFromPath(source) ?? '.bin';
      await _copyAssetIfPresent(
        sourcePath: source,
        path:
            '${VaultMirrorWorkspace.metadataDir}/assets/secure_notes/${note.note.id}/asset_${assetIndex + 1}$extension',
        identityKey: 'secure_note:${note.note.id}:asset:$assetIndex',
      );
      assetIndex += 1;
    }
  }

  Future<void> _addNode({
    required String id,
    required String type,
    required String displayName,
    required String path,
    required int order,
    required Map<String, dynamic> metadata,
    String? parentId,
    String? updatedAtIso,
  }) async {
    final metadataText = jsonEncode(_canonicalizeForFingerprint(metadata));
    _nodes.add(
      VaultMirrorNode(
        id: id,
        type: type,
        displayName: displayName,
        path: path,
        parentId: parentId,
        order: order,
        metadata: metadata,
        contentHash: await _hashBytes(utf8.encode('$id|$type|$path|$order')),
        metadataHash: await _hashBytes(utf8.encode(metadataText)),
        updatedAtIso: updatedAtIso,
      ),
    );
  }

  Future<String> _buildStableContentChecksum() {
    final files =
        _files
            .where(_isCanonicalChecksumFile)
            .map(
              (file) => {
                'identity': _canonicalChecksumFileIdentity(file),
                'sha256': file.contentHash,
                'size_bytes': file.sizeBytes,
              },
            )
            .toList()
          ..sort((a, b) => '${a['identity']}'.compareTo('${b['identity']}'));
    final nodes =
        _nodes
            .map(
              (node) => {
                'id': node.id,
                'type': node.type,
                'metadata_hash': node.metadataHash,
              },
            )
            .toList()
          ..sort(
            (a, b) =>
                '${a['type']}|${a['id']}'.compareTo('${b['type']}|${b['id']}'),
          );
    final payload = {'schema_version': 2, 'files': files, 'nodes': nodes};
    return _hashBytes(utf8.encode(jsonEncode(payload)));
  }

  bool _isCanonicalChecksumFile(VaultMirrorFile file) {
    if (file.relativePath == VaultMirrorWorkspace.snapshotPath) {
      return false;
    }
    return !_isDerivedInlineMirrorFile(file);
  }

  bool _isDerivedInlineMirrorFile(VaultMirrorFile file) {
    if (!file.isInline) {
      return false;
    }
    final path = file.relativePath.trim().toLowerCase();
    return path.endsWith('.md') || path.endsWith('.url');
  }

  String _canonicalChecksumFileIdentity(VaultMirrorFile file) {
    final identity = file.identityKey?.trim();
    if (identity != null && identity.isNotEmpty) {
      return identity;
    }
    return 'path:${file.relativePath}';
  }

  Object? _canonicalizeForFingerprint(Object? value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
      return {
        for (final entry in entries)
          '${entry.key}': _canonicalizeForFingerprint(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(_canonicalizeForFingerprint).toList(growable: false);
    }
    if (value is String) {
      return _canonicalizeStringForFingerprint(value);
    }
    return value;
  }

  String _canonicalizeStringForFingerprint(String value) {
    final normalized = LocalAssetPathResolver.normalizePath(value);
    if (_isLocalAssetReference(normalized)) {
      return '<local-file>';
    }
    return value;
  }

  bool _isLocalAssetReference(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:') ||
        trimmed.startsWith('blob:')) {
      return false;
    }
    if (LocalAssetPathResolver.extractPortablePath(trimmed) != null ||
        LocalAssetPathResolver.isPortablePath(trimmed)) {
      return true;
    }
    if (trimmed.startsWith('file://') || trimmed.startsWith('/')) {
      return true;
    }
    return _existingLocalPath(trimmed) != null;
  }

  void _addDirectory(String path) {
    final clean = _cleanRelativePath(path);
    if (clean.isEmpty) {
      return;
    }
    final parts = clean.split('/');
    for (var i = 1; i <= parts.length; i++) {
      _directories.add(parts.take(i).join('/'));
    }
  }

  Future<String> _addTextFile(
    String relativePath,
    String text, {
    String? identityKey,
  }) async {
    final bytes = utf8.encode(text);
    final path = _reservePath(relativePath);
    _addDirectory(_parentPath(path));
    _files.add(
      VaultMirrorFile(
        relativePath: path,
        contentHash: await _hashBytes(bytes),
        sizeBytes: bytes.length,
        bytes: bytes,
        identityKey: identityKey,
      ),
    );
    return path;
  }

  Future<String> _addSourceFile(
    String relativePath,
    String sourcePath, {
    String? identityKey,
  }) async {
    final file = File(sourcePath);
    final sizeBytes = await file.length();
    final path = _reservePath(relativePath);
    if (sizeBytes >= 25 * 1024 * 1024) {
      debugPrint(
        '[BackupMirror] Streaming large file ${_formatBytes(sizeBytes)} '
        'to $path',
      );
    }
    _addDirectory(_parentPath(path));
    _files.add(
      VaultMirrorFile(
        relativePath: path,
        contentHash: await _hashFile(file),
        sizeBytes: sizeBytes,
        sourcePath: sourcePath,
        identityKey: identityKey,
      ),
    );
    return path;
  }

  Future<void> _copyAssetIfPresent({
    required String? sourcePath,
    required String path,
    String? identityKey,
  }) async {
    final source = _existingLocalPath(sourcePath);
    if (source == null) {
      return;
    }
    await _addSourceFile(path, source, identityKey: identityKey);
  }

  Future<void> _copyBlockIconAsset(CollectionBlockRecordDto block) async {
    await _copyAssetIfPresent(
      sourcePath: block.metadata[CollectionBlockMetadataKeys.iconImagePath],
      path:
          '${VaultMirrorWorkspace.metadataDir}/assets/collections/${block.collectionId}/blocks/${block.id}/icon${_extensionFromPath(block.metadata[CollectionBlockMetadataKeys.iconImagePath]) ?? '.bin'}',
      identityKey: 'collection_block:${block.id}:icon',
    );
  }

  List<_MirrorSourceAttachment> _sourceAttachmentsForDocument(
    DocumentRecordDto document,
  ) {
    final attachments = <_MirrorSourceAttachment>[];
    final seenPaths = <String>{};

    void addAttachment({
      required String? path,
      required String label,
      String? originalName,
      String? mime,
    }) {
      final sourcePath = _existingLocalPath(path);
      if (sourcePath == null) {
        return;
      }
      final dedupeKey = sourcePath.toLowerCase();
      if (!seenPaths.add(dedupeKey)) {
        return;
      }
      attachments.add(
        _MirrorSourceAttachment(
          sourcePath: sourcePath,
          label: label.trim(),
          originalName: (originalName ?? '').trim(),
          mime: (mime ?? '').trim(),
        ),
      );
    }

    for (final field in document.structuredFields) {
      final label = (field['label'] ?? '').trim();
      if (_sameLabel(label, DocumentMetadataFieldLabels.referenceAssetsJson)) {
        final rawJson = (field['value'] ?? '').trim();
        if (rawJson.isEmpty) {
          continue;
        }
        try {
          final decoded = jsonDecode(rawJson);
          if (decoded is List) {
            for (final rawItem in decoded) {
              if (rawItem is! Map) {
                continue;
              }
              final item = Map<String, dynamic>.from(rawItem);
              addAttachment(
                path: item['path']?.toString(),
                label: _firstNonEmptyString([item['label']?.toString(), label]),
                originalName: item['name']?.toString(),
                mime: item['mime']?.toString(),
              );
            }
          }
        } catch (_) {
          // Malformed legacy payloads should not block direct path fields below.
        }
        continue;
      }

      if (_isDocumentSourcePathLabel(label)) {
        addAttachment(
          path: field['value'],
          label: label,
          originalName: _fieldValue(document.structuredFields, const [
            DocumentMetadataFieldLabels.referenceAssetName,
            'File Name',
            'Filename',
          ]),
          mime: _fieldValue(document.structuredFields, const [
            DocumentMetadataFieldLabels.referenceAssetMime,
          ]),
        );
      }
    }

    return attachments;
  }

  bool _isDocumentSourcePathLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return normalized ==
            DocumentMetadataFieldLabels.referenceAssetPath.toLowerCase() ||
        normalized ==
            DocumentMetadataFieldLabels.frontImagePath.toLowerCase() ||
        normalized == DocumentMetadataFieldLabels.backImagePath.toLowerCase() ||
        normalized == 'file path' ||
        normalized == 'document path' ||
        normalized == 'attachment path';
  }

  bool _sameLabel(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }

  String? _existingLocalPath(String? path) {
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return null;
    }
    final resolved = LocalAssetPathResolver.resolveExistingPathSync(trimmed);
    if (resolved != null && resolved.trim().isNotEmpty) {
      return resolved;
    }
    return File(trimmed).existsSync() ? trimmed : null;
  }

  String _documentDisplayStem(DocumentRecordDto document) {
    final fields = document.structuredFields;
    final documentTitle = _fieldValue(fields, const [
      'Document Title',
      DocumentMetadataFieldLabels.workStatementTitle,
    ]);
    if ((documentTitle ?? '').trim().isNotEmpty) {
      return documentTitle!.trim();
    }

    if (document.categoryKey == 'identity') {
      final issuer = document.title.trim();
      final type = _prettyKey(document.documentType);
      final identityTitle = [
        issuer,
        type,
      ].where((part) => part.trim().isNotEmpty).join(' ');
      if (identityTitle.trim().isNotEmpty) {
        return identityTitle.trim();
      }
    }

    final title = document.title.trim();
    if (title.isNotEmpty) {
      return title;
    }

    final fileStem = _fileStem(document.fileName);
    if (fileStem.isNotEmpty && !_looksGeneratedName(fileStem)) {
      return fileStem;
    }

    return 'Document';
  }

  String _collectionFileStem(
    CollectionBlockRecordDto block,
    String? sourcePath,
  ) {
    final title = block.title.trim();
    if (title.isNotEmpty && !_looksGeneratedName(title)) {
      return title;
    }
    final subtitle = block.subtitle.trim();
    if (subtitle.isNotEmpty && !_looksGeneratedName(subtitle)) {
      return subtitle;
    }
    final fileStem = _fileStem(sourcePath);
    if (fileStem.isNotEmpty && !_looksGeneratedName(fileStem)) {
      return fileStem;
    }
    return block.typeKey == 'image' ? 'Image' : 'Document';
  }

  String _collectionBlockLabel(CollectionBlockRecordDto block) {
    final title = block.title.trim();
    if (title.isNotEmpty && !_looksGeneratedName(title)) {
      return title;
    }
    final subtitle = block.subtitle.trim();
    if (subtitle.isNotEmpty) {
      return subtitle;
    }
    return block.typeKey == 'image' ? 'Image' : 'Document';
  }

  String _missingReferencePath(String directory, String slug) {
    return _reservePath(
      '$directory/${slug.trim().isEmpty ? 'missing' : slug}.missing',
    );
  }

  void _addMissingReferenceWarning({
    required String typeLabel,
    required String displayName,
    required String? rawPath,
  }) {
    final fileName = _fileNameFromPath(rawPath);
    final source = fileName.isEmpty ? 'local file' : fileName;
    _warnings.add('Collection $typeLabel "$displayName" is missing $source.');
  }

  String _fileNameFromPath(String? path) {
    final value = (path ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    final normalized = value.replaceAll('\\', '/');
    return normalized.split('/').last.trim();
  }

  String _attachmentSuffix({
    required List<_MirrorSourceAttachment> attachments,
    required _MirrorSourceAttachment attachment,
    required int index,
  }) {
    if (attachments.length <= 1) {
      return '';
    }
    final cleanedLabel = _cleanAttachmentLabel(attachment.label);
    if (cleanedLabel.isNotEmpty &&
        !_isGenericAttachmentLabel(cleanedLabel) &&
        attachments
                .where(
                  (item) =>
                      _cleanAttachmentLabel(item.label).toLowerCase() ==
                      cleanedLabel.toLowerCase(),
                )
                .length ==
            1) {
      return ' - $cleanedLabel';
    }
    return ' - File ${index + 1}';
  }

  String _cleanAttachmentLabel(String rawLabel) {
    final normalized = rawLabel
        .trim()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return '';
    }
    const dropWords = <String>{
      'reference',
      'asset',
      'attachment',
      'document',
      'file',
      'path',
      'image',
      'mime',
    };
    final words = normalized
        .split(' ')
        .where((word) => !dropWords.contains(word.toLowerCase()))
        .toList(growable: false);
    final cleaned = words.isEmpty ? normalized : words.join(' ');
    return _prettyKey(cleaned);
  }

  bool _isGenericAttachmentLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'file' ||
        normalized == 'document' ||
        normalized == 'attachment' ||
        normalized == 'path' ||
        normalized == 'reference' ||
        normalized == 'asset' ||
        normalized == 'image';
  }

  String? _fieldValue(List<Map<String, String>> fields, List<String> labels) {
    for (final target in labels) {
      final normalizedTarget = target.trim().toLowerCase();
      for (final field in fields) {
        if ((field['label'] ?? '').trim().toLowerCase() != normalizedTarget) {
          continue;
        }
        final value = (field['value'] ?? '').trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  String _firstNonEmptyString(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  int _compareCollectionBlocks(
    CollectionBlockRecordDto a,
    CollectionBlockRecordDto b,
  ) {
    final byPosition = _compareOptionalPosition(a.position, b.position);
    if (byPosition != 0) return byPosition;
    return _compareStableText(
      [a.typeKey, a.title, a.subtitle, a.id],
      [b.typeKey, b.title, b.subtitle, b.id],
    );
  }

  int _compareOptionalPosition(int left, int right) {
    final hasLeft = left > 0;
    final hasRight = right > 0;
    if (hasLeft && hasRight && left != right) {
      return left.compareTo(right);
    }
    if (hasLeft != hasRight) {
      return hasLeft ? -1 : 1;
    }
    return 0;
  }

  int _compareStableText(List<String> left, List<String> right) {
    final length = left.length > right.length ? left.length : right.length;
    for (var index = 0; index < length; index++) {
      final a = index < left.length ? left[index].trim().toLowerCase() : '';
      final b = index < right.length ? right[index].trim().toLowerCase() : '';
      final comparison = a.compareTo(b);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  String _documentDirectory(DocumentRecordDto document) {
    final fields = _fieldMap(document.structuredFields);
    switch (document.categoryKey) {
      case 'identity':
        return 'Documents/Identity';
      case 'work':
        final company =
            fields[DocumentMetadataFieldLabels.workCompanyName] ?? 'Work';
        final folder =
            fields[DocumentMetadataFieldLabels.workFolderType] ?? 'Documents';
        return 'Documents/Work/${_slug(company)}/${_slug(folder)}';
      case 'property':
        final property =
            fields[DocumentMetadataFieldLabels.propertyName] ?? 'Property';
        final asset =
            fields[DocumentMetadataFieldLabels.propertyAssetType] ??
            'Documents';
        return 'Documents/Property/${_slug(property)}/${_slug(asset)}';
      case 'travel':
        final trip =
            fields[DocumentMetadataFieldLabels.travelTripTitle] ?? 'Travel';
        return 'Documents/Travel/${_slug(trip)}';
      default:
        return 'Documents/${_slug(document.categoryKey.isEmpty ? 'Other' : document.categoryKey)}';
    }
  }

  Map<String, String> _fieldMap(List<Map<String, String>> fields) {
    return {
      for (final field in fields)
        if ((field['label'] ?? '').trim().isNotEmpty)
          (field['label'] ?? '').trim(): (field['value'] ?? '').trim(),
    };
  }

  String _documentMarkdown(DocumentRecordDto document) {
    final buffer = StringBuffer()
      ..writeln('# ${document.title}')
      ..writeln()
      ..writeln('- Category: ${document.categoryKey}')
      ..writeln('- Type: ${document.documentType}')
      ..writeln('- File name: ${document.fileName}')
      ..writeln('- Updated: ${document.updatedAtIso}');
    if (document.expiryAtIso.isNotEmpty) {
      buffer.writeln('- Expires: ${document.expiryAtIso}');
    }
    if (document.structuredFields.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Fields');
      for (final field in document.structuredFields) {
        buffer.writeln('- ${field['label']}: ${field['value']}');
      }
    }
    return buffer.toString();
  }

  String _noteMarkdown(CollectionBlockRecordDto block) {
    return '# ${block.title}\n\n${block.description}\n';
  }

  String _inputMarkdown(CollectionBlockRecordDto block) {
    return [
      '# ${block.title}',
      '',
      block.description,
      '',
      'Value:',
      block.subtitle,
      if (block.url?.trim().isNotEmpty == true) 'URL: ${block.url}',
    ].where((line) => line.trim().isNotEmpty).join('\n');
  }

  String _checklistMarkdown(CollectionBlockRecordDto block) {
    final buffer = StringBuffer()
      ..writeln('# ${block.title}')
      ..writeln();
    for (final item in block.checklistItems) {
      buffer.writeln('- [${item.isDone ? 'x' : ' '}] ${item.title}');
    }
    if (block.description.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(block.description);
    }
    return buffer.toString();
  }

  String _blockMarkdown(CollectionBlockRecordDto block) {
    final buffer = StringBuffer()
      ..writeln('# ${block.title}')
      ..writeln()
      ..writeln('- Type: ${block.typeKey}')
      ..writeln('- Status: ${block.statusLabel ?? ''}')
      ..writeln('- Updated: ${block.updatedAtIso}');
    if (block.subtitle.trim().isNotEmpty) {
      buffer.writeln('- Subtitle: ${block.subtitle}');
    }
    if (block.description.trim().isNotEmpty) {
      buffer.writeln('\n${block.description}');
    }
    if (block.url?.trim().isNotEmpty == true) {
      buffer.writeln('- URL: ${block.url}');
    }
    if (block.amount != null) {
      buffer.writeln('- Amount: ${block.amount} ${block.currencyCode ?? ''}');
    }
    if (block.eventAtIso?.trim().isNotEmpty == true) {
      buffer.writeln('- Event: ${block.eventAtIso}');
    }
    if (block.expiryDateIso?.trim().isNotEmpty == true) {
      buffer.writeln('- Reminder: ${block.expiryDateIso}');
    }
    if (block.locationLabel?.trim().isNotEmpty == true) {
      buffer.writeln('- Location: ${block.locationLabel}');
    }
    if (block.latitude != null && block.longitude != null) {
      buffer.writeln('- Coordinates: ${block.latitude}, ${block.longitude}');
    }
    return buffer.toString();
  }

  String _bundleMarkdown(BundleRecordDto bundle) {
    final buffer = StringBuffer()
      ..writeln('# ${bundle.title}')
      ..writeln()
      ..writeln('- Purpose: ${bundle.purpose ?? ''}')
      ..writeln('- Status: ${bundle.statusKey}')
      ..writeln('- Template: ${bundle.templateKey ?? ''}')
      ..writeln()
      ..writeln(bundle.description ?? '');
    if (bundle.items.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Items');
      for (final item in bundle.items) {
        buffer.writeln('- ${item.displayName} (${item.typeKey})');
      }
    }
    if (bundle.history.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## History');
      for (final event in bundle.history) {
        buffer.writeln(
          '- ${event.atIso}: ${event.kindKey} ${event.detail ?? ''}',
        );
      }
    }
    return buffer.toString();
  }

  String _taskListMarkdown(TaskListRecordDto list) {
    final sorted = list.tasks.toList(growable: false)
      ..sort((a, b) => a.position.compareTo(b.position));
    final buffer = StringBuffer()
      ..writeln('# ${list.title}')
      ..writeln();
    if (list.description?.trim().isNotEmpty == true) {
      buffer
        ..writeln(list.description)
        ..writeln();
    }
    for (final task in sorted) {
      buffer.write('- [${task.isDone ? 'x' : ' '}] ${task.title}');
      if (task.dueAtIso?.trim().isNotEmpty == true) {
        buffer.write(' (due ${task.dueAtIso})');
      }
      buffer.writeln();
      if (task.notes?.trim().isNotEmpty == true) {
        buffer.writeln('  ${task.notes}');
      }
    }
    return buffer.toString();
  }

  String _profileMarkdown(ProfileRecordDto profile) {
    return '''
# Profile

- Name: ${('${profile.firstName} ${profile.lastName}').trim()}
- Email: ${profile.email}
- Phone: ${profile.phone}
- Address: ${profile.address}
- Social links: ${profile.socialLinks}
- Updated: ${profile.updatedAtIso}
''';
  }

  String _credentialMarkdown(CredentialDetailDto credential) {
    return '''
# ${credential.serviceName}

- Account: ${credential.accountLabel}
- Username: ${credential.username}
- Password: ${credential.password}
- URL: ${credential.url}
- Category: ${credential.categoryKey}
- Secure: ${credential.isSecure}
- Favorite: ${credential.isFavorite}
- MFA recovery: ${credential.mfaRecovery}

${credential.notes}
''';
  }

  String _secureNoteMarkdown(SecureNoteDetailDto note) {
    final buffer = StringBuffer()
      ..writeln(
        '# ${note.note.title.trim().isEmpty ? 'Untitled Note' : note.note.title.trim()}',
      )
      ..writeln();
    final blocks = note.blocks.toList(growable: false)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    for (final block in blocks) {
      if (block.plainText.trim().isNotEmpty) {
        buffer
          ..writeln(block.plainText.trim())
          ..writeln();
        continue;
      }
      if (block.contentJson.trim().isNotEmpty) {
        buffer
          ..writeln(block.contentJson.trim())
          ..writeln();
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> _credentialToMap(CredentialDetailDto dto) {
    return {
      'id': dto.id,
      'serviceName': dto.serviceName,
      'accountLabel': dto.accountLabel,
      'username': dto.username,
      'category': dto.categoryKey,
      'password': dto.password,
      'url': dto.url,
      'notes': dto.notes,
      'lastSecurityUpdate': dto.lastSecurityUpdate,
      'mfaRecovery': dto.mfaRecovery,
      'isSecure': dto.isSecure,
      'brandHex': dto.brandHex,
      'logoPath': dto.logoPath,
      'breachedCount': dto.breachedCount,
      'isFavorite': dto.isFavorite,
      'displayName': dto.serviceName,
      'hasWarning': !dto.isSecure || dto.breachedCount > 0,
    };
  }

  Set<String> _localPathsFromObject(Object? value) {
    final paths = <String>{};
    void visit(Object? item) {
      if (item is String) {
        final source = _existingLocalPath(item);
        if (source != null) {
          paths.add(source);
          return;
        }
        final trimmed = item.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          try {
            visit(jsonDecode(trimmed));
          } catch (_) {}
        }
        return;
      }
      if (item is Map) {
        for (final value in item.values) {
          visit(value);
        }
        return;
      }
      if (item is Iterable) {
        for (final value in item) {
          visit(value);
        }
      }
    }

    visit(value);
    return paths;
  }

  String _reservePath(String rawPath) {
    final clean = _cleanRelativePath(rawPath);
    if (_usedPaths.add(clean)) {
      return clean;
    }
    final slash = clean.lastIndexOf('/');
    final folder = slash == -1 ? '' : clean.substring(0, slash + 1);
    final fileName = slash == -1 ? clean : clean.substring(slash + 1);
    final dot = fileName.lastIndexOf('.');
    final base = dot == -1 ? fileName : fileName.substring(0, dot);
    final ext = dot == -1 ? '' : fileName.substring(dot);
    var index = 2;
    while (true) {
      final candidate = '$folder$base ($index)$ext';
      if (_usedPaths.add(candidate)) {
        return candidate;
      }
      index += 1;
    }
  }

  String _slug(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return 'Untitled';
    }
    return normalized.length > 90
        ? normalized.substring(0, 90).trim()
        : normalized;
  }

  String _cleanRelativePath(String value) {
    return value
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .map(_slug)
        .where((part) => part.isNotEmpty && part != '.')
        .join('/');
  }

  String _parentPath(String path) {
    final index = path.lastIndexOf('/');
    return index == -1 ? '' : path.substring(0, index);
  }

  String _sourceFileExtension(String? sourcePath, String? fallback) {
    return _extensionFromPath(sourcePath) ??
        _extensionFromPath(fallback) ??
        _extensionFromMime(fallback) ??
        '.bin';
  }

  String? _extensionFromPath(String? path) {
    final trimmed = path?.trim() ?? '';
    final lastSegment = trimmed.split('/').last;
    final index = lastSegment.lastIndexOf('.');
    if (index == -1 || index == lastSegment.length - 1) {
      return null;
    }
    final extension = lastSegment.substring(index).toLowerCase();
    return extension.length > 12 ? null : extension;
  }

  String? _extensionFromMime(String? mime) {
    return switch ((mime ?? '').trim().toLowerCase()) {
      'application/pdf' => '.pdf',
      'image/jpeg' || 'image/jpg' => '.jpg',
      'image/png' => '.png',
      'image/heic' || 'image/heif' => '.heic',
      'text/plain' => '.txt',
      _ => null,
    };
  }

  String _fileStem(String? path) {
    final value = (path ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    final normalized = value.replaceAll('\\', '/');
    final lastSegment = normalized.split('/').last;
    final dot = lastSegment.lastIndexOf('.');
    return dot <= 0 ? lastSegment : lastSegment.substring(0, dot);
  }

  String _prettyKey(String value) {
    final words = value
        .trim()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return '';
    }
    return words
        .map(
          (word) => word.length <= 2
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  bool _looksGeneratedName(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    if (RegExp(r'(^|[_\-\s])\d{10,}($|[_\-\s])').hasMatch(normalized)) {
      return true;
    }
    return normalized.startsWith('property_doc_') ||
        normalized.startsWith('property_doc_group_') ||
        normalized.startsWith('payslip_') ||
        normalized.startsWith('travel_wallet_') ||
        normalized.startsWith('travel_receipt_') ||
        normalized.startsWith('travel_event_') ||
        normalized.startsWith('image_picker') ||
        normalized.startsWith('image picker') ||
        normalized.startsWith('img_') ||
        normalized.startsWith('identity_reference_') ||
        normalized.startsWith('id_reference_');
  }

  Future<String> _hashBytes(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return base64UrlEncode(hash.bytes);
  }

  Future<String> _hashFile(File file) async {
    final sink = Sha256().toSync().newHashSink();
    await for (final chunk in file.openRead()) {
      sink.add(chunk);
    }
    sink.close();
    final hash = await sink.hash();
    return base64UrlEncode(hash.bytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _MirrorSourceAttachment {
  const _MirrorSourceAttachment({
    required this.sourcePath,
    required this.label,
    required this.originalName,
    required this.mime,
  });

  final String sourcePath;
  final String label;
  final String originalName;
  final String mime;
}
