class VaultSyncMergeResultEntity {
  const VaultSyncMergeResultEntity({
    required this.appliedOperations,
    required this.created,
    required this.updated,
    required this.deleted,
    required this.conflicts,
  });

  const VaultSyncMergeResultEntity.empty()
    : appliedOperations = 0,
      created = 0,
      updated = 0,
      deleted = 0,
      conflicts = 0;

  final int appliedOperations;
  final int created;
  final int updated;
  final int deleted;
  final int conflicts;

  bool get hasConflicts => conflicts > 0;
}
