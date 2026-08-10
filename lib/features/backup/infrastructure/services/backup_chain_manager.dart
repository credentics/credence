import 'package:pass_doc_manager/features/backup/domain/entities/backup_chain.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_type.dart';

class BackupChainManager {
  static const int maxChainDepth = 10;

  /// Determines what type of backup to create next based on the current chain
  /// state.
  ///
  /// - If there is no chain or the chain is empty, a [BackupType.full] backup
  ///   is needed to establish a new base.
  /// - If the chain has reached [maxChainDepth], a [BackupType.compacted]
  ///   backup collapses the chain into a new base.
  /// - Otherwise, a [BackupType.delta] (incremental) backup is sufficient.
  BackupType computeNextBackupType(BackupChain? currentChain) {
    if (currentChain == null || currentChain.isEmpty) {
      return BackupType.full;
    }
    if (currentChain.depth >= maxChainDepth) {
      return BackupType.compacted;
    }
    return BackupType.delta;
  }

  /// Builds a [BackupChain] by walking backwards from [targetBackupId] to
  /// the chain's base (a full or compacted backup with no parent).
  ///
  /// Returns `null` if [targetBackupId] is not found in [allManifests] or if
  /// the chain is broken (a referenced parent does not exist).
  BackupChain? buildChain(
    String targetBackupId,
    List<BackupManifest> allManifests,
  ) {
    // Index manifests by ID for O(1) lookup.
    final manifestById = <String, BackupManifest>{
      for (final m in allManifests) m.backupId: m,
    };

    final target = manifestById[targetBackupId];
    if (target == null) return null;

    // Walk from target back to the base.
    final chain = <BackupManifest>[target];
    var current = target;

    while (current.parentBackupId != null) {
      final parent = manifestById[current.parentBackupId!];
      if (parent == null) {
        // Broken chain -- parent not found.
        return null;
      }
      chain.insert(0, parent);
      current = parent;
    }

    // The first entry must be a full or compacted backup (a valid base).
    if (!chain.first.isFull) {
      return null;
    }

    return BackupChain(
      chainId: chain.first.backupId,
      baseBackupId: chain.first.backupId,
      headBackupId: chain.last.backupId,
      depth: chain.length,
      deviceId: chain.first.deviceId,
      backups: chain,
    );
  }

  /// Validates that [chain] has a valid base, no gaps, and correct parent
  /// links.
  ChainValidationResult validateChain(BackupChain chain) {
    final backups = chain.backups;

    if (backups.isEmpty) {
      return const ChainValidationResult(
        status: ChainValidationStatus.empty,
        message: 'Chain contains no backups.',
      );
    }

    // Base must be full or compacted.
    final base = backups.first;
    if (!base.isFull) {
      return const ChainValidationResult(
        status: ChainValidationStatus.noBase,
        message: 'Chain does not start with a full or compacted backup.',
      );
    }

    // Validate parent linkage for every subsequent backup.
    for (var i = 1; i < backups.length; i++) {
      final current = backups[i];
      final previous = backups[i - 1];

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
              '${current.parentBackupId}, but expected ${previous.backupId}.',
        );
      }
    }

    return const ChainValidationResult(
      status: ChainValidationStatus.valid,
    );
  }
}
