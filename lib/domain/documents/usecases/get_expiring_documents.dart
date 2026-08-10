import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_expiry_item_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetExpiringDocuments
    implements UseCase<List<DocumentExpiryItemEntity>, GetExpiringDocumentsParams> {
  GetExpiringDocuments(this._repository);

  final DocumentRepository _repository;

  @override
  Future<List<DocumentExpiryItemEntity>> call(
    GetExpiringDocumentsParams params,
  ) async {
    final vaultDocuments = await _repository.getVaultDocuments();

    final now = DateTime.now();
    final expiringDocs = <DocumentExpiryItemEntity>[];

    for (final doc in vaultDocuments) {
      if (doc.expiryDate == null) {
        continue;
      }

      final expiryDate = doc.expiryDate!;
      final daysRemaining = expiryDate.difference(now).inDays;

      final urgency = _calculateUrgency(expiryDate, now);

      // Only include documents within the specified months ahead
      final monthsAheadDate = DateTime(
        now.year,
        now.month + params.monthsAhead,
        now.day,
      );

      if (expiryDate.isBefore(monthsAheadDate) &&
          expiryDate.isAfter(now.subtract(const Duration(days: 1)))) {
        expiringDocs.add(
          DocumentExpiryItemEntity(
            documentId: doc.documentId,
            title: doc.documentName,
            documentType: doc.documentTypeLabel,
            expiryDate: expiryDate,
            urgency: urgency,
            daysRemaining: daysRemaining,
          ),
        );
      }
    }

    // Sort by expiry date
    expiringDocs.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return expiringDocs;
  }

  ExpiryUrgency _calculateUrgency(DateTime expiryDate, DateTime now) {
    final daysRemaining = expiryDate.difference(now).inDays;

    if (daysRemaining < 0) {
      return ExpiryUrgency.expired;
    } else if (daysRemaining < 30) {
      return ExpiryUrgency.critical;
    } else if (daysRemaining < 90) {
      return ExpiryUrgency.warning;
    } else {
      return ExpiryUrgency.safe;
    }
  }
}

class GetExpiringDocumentsParams {
  const GetExpiringDocumentsParams({this.monthsAhead = 12});

  final int monthsAhead;
}
