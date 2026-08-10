import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_chain.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';

class ValidateChain
    implements UseCase<ChainValidationResult, ValidateChainParams> {
  ValidateChain(this._repository);
  final BackupRepository _repository;

  @override
  Future<ChainValidationResult> call(ValidateChainParams params) {
    return _repository.validateChain();
  }
}

class ValidateChainParams {
  const ValidateChainParams();
}
