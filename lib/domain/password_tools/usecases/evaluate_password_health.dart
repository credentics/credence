import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/repositories/password_tools_repository.dart';

class EvaluatePasswordHealth
    implements
        UseCase<PasswordHealthReportEntity, EvaluatePasswordHealthParams> {
  EvaluatePasswordHealth(this._repository);

  final PasswordToolsRepository _repository;

  @override
  Future<PasswordHealthReportEntity> call(EvaluatePasswordHealthParams params) {
    return _repository.evaluatePasswordHealth(
      password: params.password,
      username: params.username,
      serviceName: params.serviceName,
      existingPasswords: params.existingPasswords,
    );
  }
}

class EvaluatePasswordHealthParams {
  const EvaluatePasswordHealthParams({
    required this.password,
    this.username = '',
    this.serviceName = '',
    this.existingPasswords = const [],
  });

  final String password;
  final String username;
  final String serviceName;
  final List<String> existingPasswords;
}
