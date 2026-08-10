import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class ScheduleCollectionBlockReminder
    implements UseCase<void, ScheduleCollectionBlockReminderParams> {
  ScheduleCollectionBlockReminder(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<void> call(ScheduleCollectionBlockReminderParams params) {
    return _repository.scheduleBlockReminder(
      blockId: params.blockId,
      title: params.title,
      body: params.body,
      scheduledAt: params.scheduledAt,
      repeatInterval: params.repeatInterval,
    );
  }
}

class ScheduleCollectionBlockReminderParams {
  const ScheduleCollectionBlockReminderParams({
    required this.blockId,
    required this.title,
    this.body,
    required this.scheduledAt,
    this.repeatInterval,
  });

  final String blockId;
  final String title;
  final String? body;
  final DateTime scheduledAt;
  final String? repeatInterval;
}
