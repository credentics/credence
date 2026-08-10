import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class CancelCollectionBlockReminder
    implements UseCase<void, CancelCollectionBlockReminderParams> {
  CancelCollectionBlockReminder(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<void> call(CancelCollectionBlockReminderParams params) {
    return _repository.cancelBlockReminder(blockId: params.blockId);
  }
}

class CancelCollectionBlockReminderParams {
  const CancelCollectionBlockReminderParams({required this.blockId});

  final String blockId;
}
