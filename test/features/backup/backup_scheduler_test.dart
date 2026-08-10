import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_local_data_source.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_scheduler.dart';

/// Guards the interval gate that decides whether a resume-time auto-backup
/// actually runs. Now that auto-backup is re-enabled, a wrong answer here means
/// either a backup on every resume (battery/jank) or one that never fires.
void main() {
  BackupScheduler schedulerWith(Map<String, dynamic>? state) =>
      BackupScheduler(localDataSource: _FakeBackupLocalDataSource(state));

  String ago(Duration d) =>
      DateTime.now().toUtc().subtract(d).toIso8601String();

  group('shouldAutoBackup', () {
    test('false when there is no chain state yet', () async {
      expect(await schedulerWith(null).shouldAutoBackup(), isFalse);
    });

    test('false for manual frequency', () async {
      expect(
        await schedulerWith({'backup_frequency': 'manual'}).shouldAutoBackup(),
        isFalse,
      );
    });

    test('true for daily with no prior backup', () async {
      expect(
        await schedulerWith({'backup_frequency': 'daily'}).shouldAutoBackup(),
        isTrue,
      );
    });

    test('false for daily when the last backup is recent', () async {
      expect(
        await schedulerWith({
          'backup_frequency': 'daily',
          'last_backup_at': ago(const Duration(hours: 1)),
        }).shouldAutoBackup(),
        isFalse,
      );
    });

    test('true for daily once a full day has elapsed', () async {
      expect(
        await schedulerWith({
          'backup_frequency': 'daily',
          'last_backup_at': ago(const Duration(hours: 25)),
        }).shouldAutoBackup(),
        isTrue,
      );
    });

    test('weekly waits the full seven days', () async {
      expect(
        await schedulerWith({
          'backup_frequency': 'weekly',
          'last_backup_at': ago(const Duration(days: 6)),
        }).shouldAutoBackup(),
        isFalse,
      );
      expect(
        await schedulerWith({
          'backup_frequency': 'weekly',
          'last_backup_at': ago(const Duration(days: 8)),
        }).shouldAutoBackup(),
        isTrue,
      );
    });

    test(
      'true when the stored timestamp is unparseable (fail toward backing up)',
      () async {
        expect(
          await schedulerWith({
            'backup_frequency': 'daily',
            'last_backup_at': 'not-a-date',
          }).shouldAutoBackup(),
          isTrue,
        );
      },
    );
  });

  test('recordBackupCompleted stamps last_backup_at', () async {
    final ds = _FakeBackupLocalDataSource({'backup_frequency': 'daily'});
    await BackupScheduler(localDataSource: ds).recordBackupCompleted();
    expect(ds.state!['last_backup_at'], isNotNull);
    expect(DateTime.tryParse('${ds.state!['last_backup_at']}'), isNotNull);
  });
}

class _FakeBackupLocalDataSource implements BackupLocalDataSource {
  _FakeBackupLocalDataSource(this.state);

  Map<String, dynamic>? state;

  @override
  Future<Map<String, dynamic>?> getChainState() async => state;

  @override
  Future<void> updateChainState(Map<String, dynamic> next) async =>
      state = next;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}
