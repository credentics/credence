import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';
import 'package:pass_doc_manager/features/home/domain/repositories/home_repository.dart';

class SaveHomePreferences implements UseCase<void, SaveHomePreferencesParams> {
  SaveHomePreferences(this._repository);
  final HomeRepository _repository;

  @override
  Future<void> call(SaveHomePreferencesParams params) {
    return _repository.savePreferences(params.preferences);
  }
}

class SaveHomePreferencesParams {
  const SaveHomePreferencesParams({required this.preferences});
  final HomePreferencesEntity preferences;
}
