import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/generated_password_history_entry_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/repositories/password_tools_repository.dart';

class GetGeneratedPasswordHistory
    implements
        UseCase<
          List<GeneratedPasswordHistoryEntryEntity>,
          GetGeneratedPasswordHistoryParams
        > {
  GetGeneratedPasswordHistory(this._repository);

  final PasswordToolsRepository _repository;

  @override
  Future<List<GeneratedPasswordHistoryEntryEntity>> call(
    GetGeneratedPasswordHistoryParams params,
  ) {
    return _repository.getGeneratedPasswordHistory(limit: params.limit);
  }
}

class GetGeneratedPasswordHistoryParams {
  const GetGeneratedPasswordHistoryParams({this.limit = 24});

  final int limit;
}
