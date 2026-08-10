class BackupJournalEntry {
  const BackupJournalEntry({
    required this.journalId,
    required this.sequenceNumber,
    required this.deviceId,
    required this.timestamp,
    required this.operation,
    required this.entityId,
    required this.entityType,
    this.previousRevision,
    this.newRevision,
    this.previousContentHash,
    this.newContentHash,
    this.affectedFileIds = const [],
    this.metadata = const {},
  });

  final String journalId;
  final int sequenceNumber;
  final String deviceId;
  final DateTime timestamp;
  final JournalOperation operation;
  final String entityId;
  final String entityType;
  final int? previousRevision;
  final int? newRevision;
  final String? previousContentHash;
  final String? newContentHash;
  final List<String> affectedFileIds;
  final Map<String, String> metadata;
}

enum JournalOperation {
  create,
  update,
  delete,
  move,
  restore,
}

extension JournalOperationX on JournalOperation {
  String get key {
    return switch (this) {
      JournalOperation.create => 'create',
      JournalOperation.update => 'update',
      JournalOperation.delete => 'delete',
      JournalOperation.move => 'move',
      JournalOperation.restore => 'restore',
    };
  }

  static JournalOperation fromKey(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'create' => JournalOperation.create,
      'update' => JournalOperation.update,
      'delete' => JournalOperation.delete,
      'move' => JournalOperation.move,
      'restore' => JournalOperation.restore,
      _ => JournalOperation.update,
    };
  }
}
