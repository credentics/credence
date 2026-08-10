import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_local_data_source.dart';

enum BackupFrequency {
  manual,
  daily,
  weekly,
  monthly,
}

extension BackupFrequencyX on BackupFrequency {
  String get key => switch (this) {
    BackupFrequency.manual => 'manual',
    BackupFrequency.daily => 'daily',
    BackupFrequency.weekly => 'weekly',
    BackupFrequency.monthly => 'monthly',
  };

  String get label => switch (this) {
    BackupFrequency.manual => 'Manual only',
    BackupFrequency.daily => 'Daily',
    BackupFrequency.weekly => 'Weekly',
    BackupFrequency.monthly => 'Monthly',
  };

  Duration? get interval => switch (this) {
    BackupFrequency.manual => null,
    BackupFrequency.daily => const Duration(hours: 24),
    BackupFrequency.weekly => const Duration(days: 7),
    BackupFrequency.monthly => const Duration(days: 30),
  };

  static BackupFrequency fromKey(String? key) => switch (key) {
    // 'manual' MUST map back to manual — otherwise a user who chose "Manual
    // only" is silently treated as daily and gets auto-backups they opted out
    // of. An absent/unknown key still defaults to daily.
    'manual' => BackupFrequency.manual,
    'daily' => BackupFrequency.daily,
    'weekly' => BackupFrequency.weekly,
    'monthly' => BackupFrequency.monthly,
    _ => BackupFrequency.daily,
  };
}

class BackupScheduler {
  const BackupScheduler({required this.localDataSource});
  final BackupLocalDataSource localDataSource;

  Future<bool> shouldAutoBackup() async {
    final chainState = await localDataSource.getChainState();
    if (chainState == null) return false;

    final frequency = BackupFrequencyX.fromKey(
      chainState['backup_frequency'] as String?,
    );
    final interval = frequency.interval;
    if (interval == null) return false; // Manual only

    final lastBackupIso = chainState['last_backup_at'] as String?;
    if (lastBackupIso == null) return true;

    final lastBackup = DateTime.tryParse(lastBackupIso);
    if (lastBackup == null) return true;

    final elapsed = DateTime.now().toUtc().difference(lastBackup);
    return elapsed >= interval;
  }

  Future<void> recordBackupCompleted() async {
    final state = await localDataSource.getChainState() ?? {};
    state['last_backup_at'] = DateTime.now().toUtc().toIso8601String();
    await localDataSource.updateChainState(state);
  }

  Future<BackupFrequency> getFrequency() async {
    final state = await localDataSource.getChainState();
    return BackupFrequencyX.fromKey(state?['backup_frequency'] as String?);
  }

  Future<void> setFrequency(BackupFrequency frequency) async {
    final state = await localDataSource.getChainState() ?? {};
    state['backup_frequency'] = frequency.key;
    await localDataSource.updateChainState(state);
  }
}
