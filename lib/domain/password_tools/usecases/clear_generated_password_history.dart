import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/password_tools/repositories/password_tools_repository.dart';

class ClearGeneratedPasswordHistory
    implements UseCase<void, ClearGeneratedPasswordHistoryParams> {
  ClearGeneratedPasswordHistory(this._repository);

  final PasswordToolsRepository _repository;

  @override
  Future<void> call(ClearGeneratedPasswordHistoryParams params) {
    return _repository.clearGeneratedPasswordHistory();
  }
}

class ClearGeneratedPasswordHistoryParams {
  const ClearGeneratedPasswordHistoryParams();
}
