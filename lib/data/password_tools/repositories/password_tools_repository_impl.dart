import 'dart:math';

import 'package:pass_doc_manager/data/password_tools/datasources/local/password_history_local_data_source.dart';
import 'package:pass_doc_manager/data/password_tools/services/local_password_tools_service.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/generated_password_history_entry_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_generation_policy_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/repositories/password_tools_repository.dart';

class PasswordToolsRepositoryImpl implements PasswordToolsRepository {
  PasswordToolsRepositoryImpl({
    required this.localService,
    this.historyLocalDataSource,
  }) : _random = Random.secure();

  final LocalPasswordToolsService localService;
  final PasswordHistoryLocalDataSource? historyLocalDataSource;
  final Random _random;
  final List<GeneratedPasswordHistoryEntryEntity> _inMemoryHistory = [];

  @override
  Future<String> generatePassword({
    required PasswordGenerationPolicyEntity policy,
  }) {
    return localService.generatePassword(policy: policy);
  }

  @override
  Future<PasswordHealthReportEntity> evaluatePasswordHealth({
    required String password,
    required String username,
    required String serviceName,
    required List<String> existingPasswords,
  }) {
    return localService.evaluatePasswordHealth(
      password: password,
      username: username,
      serviceName: serviceName,
      existingPasswords: existingPasswords,
    );
  }

  @override
  Future<void> saveGeneratedPasswordHistoryEntry({
    required String password,
    required int length,
    int? score,
  }) {
    final dataSource = historyLocalDataSource;
    if (dataSource != null) {
      return dataSource.saveGeneratedPasswordEntry(
        password: password,
        length: length,
        score: score,
      );
    }

    final now = DateTime.now();
    final id =
        'mem_${now.microsecondsSinceEpoch}_${_random.nextInt(999999).toString().padLeft(6, '0')}';
    _inMemoryHistory.insert(
      0,
      GeneratedPasswordHistoryEntryEntity(
        id: id,
        password: password,
        createdAt: now,
        length: length,
        score: score,
      ),
    );
    if (_inMemoryHistory.length > 120) {
      _inMemoryHistory.removeRange(120, _inMemoryHistory.length);
    }
    return Future<void>.value();
  }

  @override
  Future<List<GeneratedPasswordHistoryEntryEntity>>
  getGeneratedPasswordHistory({int limit = 24}) async {
    final dataSource = historyLocalDataSource;
    if (dataSource != null) {
      final rows = await dataSource.getGeneratedPasswordHistory(limit: limit);
      return rows
          .map(
            (row) => GeneratedPasswordHistoryEntryEntity(
              id: row.id,
              password: row.password,
              createdAt:
                  DateTime.tryParse(row.createdAtIso)?.toLocal() ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              length: row.length,
              score: row.score,
            ),
          )
          .toList(growable: false);
    }

    final safeLimit = limit.clamp(1, 120);
    if (_inMemoryHistory.length <= safeLimit) {
      return _inMemoryHistory.toList(growable: false);
    }
    return _inMemoryHistory.take(safeLimit).toList(growable: false);
  }

  @override
  Future<void> clearGeneratedPasswordHistory() {
    final dataSource = historyLocalDataSource;
    if (dataSource != null) {
      return dataSource.clearGeneratedPasswordHistory();
    }
    _inMemoryHistory.clear();
    return Future<void>.value();
  }
}
