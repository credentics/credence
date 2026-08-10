enum BackupType {
  full,
  delta,
  compacted,
}

extension BackupTypeX on BackupType {
  String get key {
    return switch (this) {
      BackupType.full => 'full',
      BackupType.delta => 'delta',
      BackupType.compacted => 'compacted',
    };
  }

  String get label {
    return switch (this) {
      BackupType.full => 'Full Snapshot',
      BackupType.delta => 'Incremental',
      BackupType.compacted => 'Compacted',
    };
  }

  static BackupType fromKey(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'full' => BackupType.full,
      'delta' => BackupType.delta,
      'compacted' => BackupType.compacted,
      _ => BackupType.full,
    };
  }
}
