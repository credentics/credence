import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';

class BackupRetentionManager {
  static const int maxFullSnapshots = 3;
  static const int maxTotalBackups = 30;
  static const Duration emergencyRetention = Duration(days: 30);

  /// Returns backup IDs that should be pruned based on retention policy.
  List<String> computePrunableBackups(List<BackupManifest> allBackups) {
    if (allBackups.length <= maxFullSnapshots) return const [];

    final sorted = allBackups.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final now = DateTime.now().toUtc();

    // Simplified approach: keep newest maxFullSnapshots fulls + their chains,
    // prune everything else.
    final keptIds = <String>{};
    var kept = 0;
    for (final backup in sorted) {
      if (backup.isFull && kept < maxFullSnapshots) {
        keptIds.add(backup.backupId);
        _collectChainIds(backup.backupId, sorted, keptIds);
        kept++;
      }
    }

    // Also keep recent emergency backups
    for (final backup in sorted) {
      if (backup.isEmergencyBackup &&
          now.difference(backup.createdAt) < emergencyRetention) {
        keptIds.add(backup.backupId);
      }
    }

    final prunable = <String>[];
    for (final backup in sorted) {
      if (!keptIds.contains(backup.backupId)) {
        prunable.add(backup.backupId);
      }
    }

    // Also enforce max total
    if (sorted.length - prunable.length > maxTotalBackups) {
      final remaining =
          sorted.where((b) => !prunable.contains(b.backupId)).toList();
      for (var i = maxTotalBackups; i < remaining.length; i++) {
        prunable.add(remaining[i].backupId);
      }
    }

    return prunable;
  }

  void _collectChainIds(
    String backupId,
    List<BackupManifest> all,
    Set<String> ids,
  ) {
    ids.add(backupId);
    // Find deltas that have this as parent
    for (final b in all) {
      if (b.parentBackupId == backupId && !ids.contains(b.backupId)) {
        _collectChainIds(b.backupId, all, ids);
      }
    }
  }
}
