import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/password_tools/repositories/password_tools_repository.dart';

class SaveGeneratedPasswordHistoryEntry
    implements UseCase<void, SaveGeneratedPasswordHistoryEntryParams> {
  SaveGeneratedPasswordHistoryEntry(this._repository);

  final PasswordToolsRepository _repository;

  @override
  Future<void> call(SaveGeneratedPasswordHistoryEntryParams params) {
    return _repository.saveGeneratedPasswordHistoryEntry(
      password: params.password,
      length: params.length,
      score: params.score,
    );
  }
}

class SaveGeneratedPasswordHistoryEntryParams {
  const SaveGeneratedPasswordHistoryEntryParams({
    required this.password,
    required this.length,
    this.score,
  });

  final String password;
  final int length;
  final int? score;
}
