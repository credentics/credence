import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_document_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/repositories/vault_portability_repository_impl.dart';

VaultDocumentRecordDto _doc(String id, {String category = 'general'}) =>
    VaultDocumentRecordDto(
      id: id,
      title: id,
      category: category,
      updatedAtIso: '2026-01-01T00:00:00Z',
    );

void main() {
  final docs = [
    _doc('d1', category: 'identity'),
    _doc('d2', category: 'work'),
    _doc('d3', category: 'general'), // standalone, not in any collection
  ];

  group('selectExportDocuments', () {
    test('FULL export (no filters) returns EVERY document, even standalone', () {
      final result = selectExportDocuments(
        documents: docs,
        selectedCategoryKeys: const {},
        selectedCollectionIds: const {},
        // A full export loads all collections, so links are non-empty — this
        // must NOT drop d3 (the regression being guarded).
        linkedDocumentIds: const {'d1', 'd2'},
      );
      expect(result.map((d) => d.id), ['d1', 'd2', 'd3']);
    });

    test('category filter keeps matching docs + collection-linked docs', () {
      final result = selectExportDocuments(
        documents: docs,
        selectedCategoryKeys: const {'identity'},
        selectedCollectionIds: const {},
        linkedDocumentIds: const {'d2'}, // d2 linked by a collection
      );
      expect(result.map((d) => d.id), ['d1', 'd2']);
    });

    test('specific-collection filter keeps only its linked docs', () {
      final result = selectExportDocuments(
        documents: docs,
        selectedCategoryKeys: const {},
        selectedCollectionIds: const {'col-1'},
        linkedDocumentIds: const {'d3'},
      );
      expect(result.map((d) => d.id), ['d3']);
    });
  });
}
