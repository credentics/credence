import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'package:pass_doc_manager/features/backup/domain/entities/backup_chain.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';

class BackupIntegrityService {
  /// Prefix marking a value produced by [computeHash] — a SHA-256 over raw
  /// archive bytes. Manifest-level checksums (base64url over the manifest
  /// text) intentionally do NOT carry this prefix.
  static const String _byteHashPrefix = 'sha256:';

  /// Computes a SHA-256 hash of [bytes] and returns it as
  /// `"sha256:<hex-encoded hash>"`.
  Future<String> computeHash(Uint8List bytes) async {
    final algorithm = Sha256();
    final hash = await algorithm.hash(bytes);
    final hexString = hash.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '$_byteHashPrefix$hexString';
  }

  /// Recomputes the hash of [bytes] and compares it against [expectedHash].
  ///
  /// Returns `true` when the hashes match.
  Future<bool> validateHash(Uint8List bytes, String expectedHash) async {
    final computedHash = await computeHash(bytes);
    return computedHash == expectedHash;
  }

  /// Validates raw archive [bytes] against a manifest's `archiveHash`.
  ///
  /// [expectedHash] may be one of two shapes:
  ///  * a byte hash (`"sha256:<hex>"`, produced by [computeHash]) — enforced
  ///    by recomputing and comparing;
  ///  * a manifest-level checksum (bare base64url over the manifest text, used
  ///    by folder-mirror backups) or empty — which is NOT a hash of these
  ///    bytes and therefore cannot be verified here. In that case we return
  ///    `true` and rely on the AES-GCM MAC (checked during decryption) plus
  ///    the mirror importer's per-file hash checks for integrity.
  ///
  /// This prevents a manifest checksum from being mistaken for a byte hash and
  /// causing a valid backup to be rejected as "corrupted".
  Future<bool> validateArchiveBytes(
    Uint8List bytes,
    String expectedHash,
  ) async {
    if (!expectedHash.startsWith(_byteHashPrefix)) {
      debugPrint(
        '[Integrity] archiveHash is not a byte hash '
        '("${expectedHash.isEmpty ? '<empty>' : expectedHash}") — '
        'skipping byte comparison; relying on GCM MAC for integrity.',
      );
      return true;
    }
    return validateHash(bytes, expectedHash);
  }

  /// Validates the structural integrity of a backup [chain].
  ///
  /// Checks performed:
  /// 1. The chain is not empty.
  /// 2. The first backup in the chain is a full or compacted snapshot (base).
  /// 3. Every subsequent backup references the previous one as its parent.
  /// 4. No orphaned entries exist (every non-base backup has a valid parent).
  ChainValidationResult validateChain(List<BackupManifest> chain) {
    if (chain.isEmpty) {
      return const ChainValidationResult(
        status: ChainValidationStatus.empty,
        message: 'Chain contains no backups.',
      );
    }

    // The base must be a full or compacted backup.
    final base = chain.first;
    if (!base.isFull) {
      return const ChainValidationResult(
        status: ChainValidationStatus.noBase,
        message: 'Chain does not start with a full or compacted backup.',
      );
    }

    // Walk the chain and verify parent linkage.
    for (var i = 1; i < chain.length; i++) {
      final current = chain[i];
      final previous = chain[i - 1];

      if (current.parentBackupId == null) {
        return ChainValidationResult(
          status: ChainValidationStatus.orphaned,
          brokenAtIndex: i,
          message:
              'Backup at index $i (${current.backupId}) has no parent reference.',
        );
      }

      if (current.parentBackupId != previous.backupId) {
        return ChainValidationResult(
          status: ChainValidationStatus.broken,
          brokenAtIndex: i,
          message:
              'Backup at index $i (${current.backupId}) references parent '
              '${current.parentBackupId}, but the previous backup is '
              '${previous.backupId}.',
        );
      }
    }

    return const ChainValidationResult(
      status: ChainValidationStatus.valid,
    );
  }
}
