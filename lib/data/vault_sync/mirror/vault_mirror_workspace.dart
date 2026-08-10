import 'dart:convert';
import 'dart:io';

class VaultMirrorWorkspace {
  const VaultMirrorWorkspace({
    required this.revision,
    required this.deviceId,
    required this.generatedAtIso,
    required this.directories,
    required this.files,
    required this.nodes,
    required this.snapshot,
    required this.manifestText,
    required this.manifestChecksum,
    required this.contentChecksum,
    this.warnings = const <String>[],
  });

  /// The hidden metadata directory that holds the mirror's manifest, head,
  /// snapshot, and content-addressed assets.
  static const metadataDir = '.credence';

  static const manifestPath = '$metadataDir/manifest.json';
  static const headPath = '$metadataDir/head.json';
  static const snapshotPath = '$metadataDir/snapshot.json';
  static const syncDir = '$metadataDir/sync';

  /// Whether [rawPath] is one of the reserved metadata files (manifest, head,
  /// or snapshot).
  static bool isReservedMetadataFile(String rawPath) {
    final path = rawPath.trim().replaceAll('\\', '/');
    return path == manifestPath || path == headPath || path == snapshotPath;
  }

  /// Whether [rawPath] lives inside the metadata dir but is NOT a user-visible
  /// asset (assets live at `<metadataDir>/assets/...`).
  static bool isInternalMetadataPath(String rawPath) {
    final path = rawPath.trim().replaceAll('\\', '/');
    return path.startsWith('$metadataDir/') &&
        !path.startsWith('$metadataDir/assets/');
  }

  /// The inverse of [isInternalMetadataPath]: content and assets a restore
  /// should surface. Everything outside the metadata dir, plus `.../assets/...`.
  static bool isUserVisibleMirrorPath(String rawPath) =>
      !isInternalMetadataPath(rawPath);

  final int revision;
  final String deviceId;
  final String generatedAtIso;
  final Set<String> directories;
  final List<VaultMirrorFile> files;
  final List<VaultMirrorNode> nodes;
  final Map<String, dynamic> snapshot;
  final String manifestText;
  final String manifestChecksum;
  final String contentChecksum;
  final List<String> warnings;

  int get fileCount => files.length;
  int get directoryCount => directories.length;
  int get nodeCount => nodes.length;
  int get byteCount => files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
  String? get warningMessage {
    if (warnings.isEmpty) return null;
    final count = warnings.length;
    final label = count == 1 ? 'file reference' : 'file references';
    return '$count missing $label could not be included. Backup contains the available vault data only.';
  }
}

class VaultMirrorFile {
  const VaultMirrorFile({
    required this.relativePath,
    required this.contentHash,
    required this.sizeBytes,
    this.bytes,
    this.sourcePath,
    this.identityKey,
  });

  final String relativePath;
  final String contentHash;
  final int sizeBytes;
  final List<int>? bytes;
  final String? sourcePath;
  final String? identityKey;

  bool get isInline => bytes != null;

  Future<List<int>> readBytes() async {
    final inlineBytes = bytes;
    if (inlineBytes != null) {
      return inlineBytes;
    }
    throw StateError('Source-backed mirror files must be consumed as streams.');
  }

  Stream<List<int>> openRead() {
    final inlineBytes = bytes;
    if (inlineBytes != null) {
      return Stream<List<int>>.value(inlineBytes);
    }
    final path = sourcePath;
    if (path == null || path.trim().isEmpty) {
      return const Stream<List<int>>.empty();
    }
    return File(path).openRead();
  }

  Map<String, dynamic> toManifestMap() {
    final path = sourcePath?.trim();
    return {
      'path': relativePath,
      'sha256': contentHash,
      'size_bytes': sizeBytes,
      if (path != null && path.isNotEmpty) 'source_path': path,
      if ((identityKey ?? '').trim().isNotEmpty)
        'identity_key': identityKey!.trim(),
    };
  }
}

class VaultMirrorNode {
  const VaultMirrorNode({
    required this.id,
    required this.type,
    required this.displayName,
    required this.path,
    required this.order,
    required this.metadata,
    required this.contentHash,
    required this.metadataHash,
    this.parentId,
    this.updatedAtIso,
  });

  final String id;
  final String type;
  final String displayName;
  final String path;
  final String? parentId;
  final int order;
  final Map<String, dynamic> metadata;
  final String contentHash;
  final String metadataHash;
  final String? updatedAtIso;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'display_name': displayName,
      'path': path,
      'parent_id': parentId,
      'order': order,
      'metadata': metadata,
      'content_hash': contentHash,
      'metadata_hash': metadataHash,
      'updated_at_iso': updatedAtIso,
    };
  }
}

class VaultMirrorManifest {
  const VaultMirrorManifest({
    required this.revision,
    required this.deviceId,
    required this.generatedAtIso,
    required this.contentChecksum,
    required this.fileHashesByPath,
    required this.filesByPath,
    required this.filesByIdentity,
    required this.managedDirectories,
  });

  factory VaultMirrorManifest.empty() {
    return const VaultMirrorManifest(
      revision: 0,
      deviceId: '',
      generatedAtIso: '',
      contentChecksum: '',
      fileHashesByPath: <String, String>{},
      filesByPath: <String, VaultMirrorManifestFile>{},
      filesByIdentity: <String, VaultMirrorManifestFile>{},
      managedDirectories: <String>{},
    );
  }

  factory VaultMirrorManifest.fromJsonText(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      return VaultMirrorManifest.empty();
    }
    final map = Map<String, dynamic>.from(decoded);
    final rawFiles = map['files'];
    final rawDirectories = map['directories'];
    final fileHashes = <String, String>{};
    final filesByPath = <String, VaultMirrorManifestFile>{};
    final filesByIdentity = <String, VaultMirrorManifestFile>{};
    if (rawFiles is List) {
      for (final rawFile in rawFiles.whereType<Map>()) {
        final file = Map<String, dynamic>.from(rawFile);
        final parsed = VaultMirrorManifestFile.fromMap(file);
        if (parsed.path.isNotEmpty && parsed.sha256.isNotEmpty) {
          fileHashes[parsed.path] = parsed.sha256;
          filesByPath[parsed.path] = parsed;
          if (parsed.identityKey != null) {
            filesByIdentity[parsed.identityKey!] = parsed;
          }
        }
      }
    }

    return VaultMirrorManifest(
      revision: _asInt(map['revision']),
      deviceId: '${map['device_id'] ?? ''}'.trim(),
      generatedAtIso: '${map['generated_at_iso'] ?? ''}'.trim(),
      contentChecksum: '${map['content_checksum'] ?? ''}'.trim(),
      fileHashesByPath: fileHashes,
      filesByPath: filesByPath,
      filesByIdentity: filesByIdentity,
      managedDirectories: rawDirectories is List
          ? rawDirectories
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toSet()
          : <String>{},
    );
  }

  final int revision;
  final String deviceId;
  final String generatedAtIso;
  final String contentChecksum;
  final Map<String, String> fileHashesByPath;
  final Map<String, VaultMirrorManifestFile> filesByPath;
  final Map<String, VaultMirrorManifestFile> filesByIdentity;
  final Set<String> managedDirectories;

  Set<String> get managedFiles => {
    ...fileHashesByPath.keys,
    VaultMirrorWorkspace.manifestPath,
    VaultMirrorWorkspace.headPath,
  };

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}

class VaultMirrorManifestFile {
  const VaultMirrorManifestFile({
    required this.path,
    required this.sha256,
    required this.sizeBytes,
    this.sourcePath,
    this.identityKey,
  });

  factory VaultMirrorManifestFile.fromMap(Map<String, dynamic> map) {
    return VaultMirrorManifestFile(
      path: '${map['path'] ?? ''}'.trim(),
      sha256: '${map['sha256'] ?? ''}'.trim(),
      sizeBytes: VaultMirrorManifest._asInt(map['size_bytes']),
      sourcePath: _nullableString(map['source_path']),
      identityKey: _nullableString(map['identity_key']),
    );
  }

  final String path;
  final String sha256;
  final int sizeBytes;
  final String? sourcePath;
  final String? identityKey;
}

String? _nullableString(dynamic value) {
  final resolved = '${value ?? ''}'.trim();
  return resolved.isEmpty || resolved.toLowerCase() == 'null' ? null : resolved;
}

class VaultMirrorResult {
  const VaultMirrorResult({
    required this.revision,
    required this.fileCount,
    required this.directoryCount,
    required this.entityCount,
    required this.byteCount,
    required this.checksum,
    required this.manifestPath,
    this.contentIndex = const <String, String>{},
    this.contentPayloadIndex = const <String, Map<String, dynamic>>{},
    this.warningMessage,
  });

  final int revision;
  final int fileCount;
  final int directoryCount;
  final int entityCount;
  final int byteCount;
  final String checksum;
  final String manifestPath;
  final Map<String, String> contentIndex;
  final Map<String, Map<String, dynamic>> contentPayloadIndex;
  final String? warningMessage;
}
