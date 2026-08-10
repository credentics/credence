import 'package:pass_doc_manager/domain/password_tools/entities/generated_password_history_entry_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_generation_policy_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';

abstract class PasswordToolsRepository {
  Future<String> generatePassword({
    required PasswordGenerationPolicyEntity policy,
  });

  Future<PasswordHealthReportEntity> evaluatePasswordHealth({
    required String password,
    required String username,
    required String serviceName,
    required List<String> existingPasswords,
  });

  Future<void> saveGeneratedPasswordHistoryEntry({
    required String password,
    required int length,
    int? score,
  });

  Future<List<GeneratedPasswordHistoryEntryEntity>>
  getGeneratedPasswordHistory({int limit = 24});

  Future<void> clearGeneratedPasswordHistory();
}
