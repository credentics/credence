import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';
import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';

class GetCredentialSummaries
    implements UseCase<List<CredentialSummaryEntity>, NoParams> {
  GetCredentialSummaries(this._repository);

  final CredentialRepository _repository;

  @override
  Future<List<CredentialSummaryEntity>> call(NoParams params) {
    return _repository.getCredentialSummaries();
  }
}

class NoParams {
  const NoParams();
}
