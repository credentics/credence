import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';

class DocumentLocalDataSource {
  DocumentLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _documentsBoxName = 'credence_documents_v1';
  static const _legacySeedIds = {
    'doc_passport_us',
    'doc_passport_tn',
    'doc_passport_fr',
    'doc_passport_es',
    'doc_passport_tr',
    'doc_passport_ae',
    'doc_driver_ca',
    'doc_national_id_eu',
    'doc_residence_permit',
    'doc_employment_contract',
    'doc_payslip_jan',
    'doc_lease_agreement',
    'doc_property_insurance',
    'doc_vehicle_registration',
    'doc_vehicle_inspection',
    'doc_health_insurance',
    'doc_vaccination_record',
    'doc_degree_certificate',
    'doc_course_certificate',
  };
  final Box<dynamic> _box;

  static Future<DocumentLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(
      _documentsBoxName,
    );
    final dataSource = DocumentLocalDataSource._(box: box);
    await dataSource._seedIfNeeded();
    await dataSource._migratePathsToPortableFormatIfNeeded();
    return dataSource;
  }

  Future<List<DocumentRecordDto>> getDocuments() async {
    await LocalAssetPathResolver.getAppSupportPath();
    final rows =
        _box.values
            .map(_rowFromRaw)
            .map(_resolveRuntimePathRow)
            .map(DocumentRecordDto.fromMap)
            .where(
              (row) => row.id.trim().isNotEmpty && row.title.trim().isNotEmpty,
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aTime =
                DateTime.tryParse(a.updatedAtIso)?.millisecondsSinceEpoch ?? 0;
            final bTime =
                DateTime.tryParse(b.updatedAtIso)?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

    return rows;
  }

  Future<DocumentRecordDto?> getDocumentById({required String id}) async {
    final raw = _box.get(id);
    if (raw == null) {
      return null;
    }
    await LocalAssetPathResolver.getAppSupportPath();
    return DocumentRecordDto.fromMap(_resolveRuntimePathRow(_rowFromRaw(raw)));
  }

  Future<void> saveDocument(DocumentRecordDto document) async {
    await _box.put(document.id, _toStoredPortableRow(document.toMap()));
    await _box.flush();
  }

  Future<void> replaceDocuments(List<DocumentRecordDto> documents) async {
    await _box.clear();
    for (final document in documents) {
      if (document.id.trim().isEmpty || document.title.trim().isEmpty) {
        continue;
      }
      await _box.put(document.id, _toStoredPortableRow(document.toMap()));
    }
    await _box.flush();
  }

  Future<void> deleteDocumentById({required String id}) async {
    await _box.delete(id);
    await _box.flush();
  }

  String nextDocumentId({required String prefix}) {
    final normalized = prefix
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = normalized.isEmpty ? 'doc' : normalized;

    var index = 1;
    var candidate = 'doc_${base}_$index';
    while (_box.containsKey(candidate)) {
      index += 1;
      candidate = 'doc_${base}_$index';
    }
    return candidate;
  }

  Future<void> _seedIfNeeded() async {
    final removableIds = <dynamic>[];
    for (final id in _legacySeedIds) {
      if (_box.containsKey(id)) {
        removableIds.add(id);
      }
    }
    if (removableIds.isNotEmpty) {
      await _box.deleteAll(removableIds);
    }
  }

  Future<void> _migratePathsToPortableFormatIfNeeded() async {
    final keys = _box.keys.toList(growable: false);
    var migrated = false;
    for (final key in keys) {
      final raw = _box.get(key);
      if (raw == null) {
        continue;
      }
      final row = _rowFromRaw(raw);
      final normalized = _toStoredPortableRow(row);
      if (jsonEncode(row) == jsonEncode(normalized)) {
        continue;
      }
      await _box.put(key, normalized);
      migrated = true;
    }
    if (migrated) {
      await _box.flush();
    }
  }

  Map<String, dynamic> _rowFromRaw(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw StateError('Invalid document row format in encrypted store.');
  }

  Map<String, dynamic> _toStoredPortableRow(Map<String, dynamic> row) {
    final copy = Map<String, dynamic>.from(row);
    copy['structuredFields'] = _transformStructuredFields(
      copy['structuredFields'],
      (label, value) {
        if (_isReferenceAssetsJsonLabel(label)) {
          return _transformReferenceAssetsJson(
            value,
            LocalAssetPathResolver.toStoredPortablePath,
          );
        }
        if (_isPathLikeLabel(label)) {
          return LocalAssetPathResolver.toStoredPortablePath(value);
        }
        return value;
      },
    );
    return copy;
  }

  Map<String, dynamic> _resolveRuntimePathRow(Map<String, dynamic> row) {
    final copy = Map<String, dynamic>.from(row);
    copy['structuredFields'] = _transformStructuredFields(
      copy['structuredFields'],
      (label, value) {
        if (_isReferenceAssetsJsonLabel(label)) {
          return _transformReferenceAssetsJson(value, _resolveRuntimePath);
        }
        if (_isPathLikeLabel(label)) {
          return _resolveRuntimePath(value);
        }
        return value;
      },
    );
    return copy;
  }

  List<Map<String, String>> _transformStructuredFields(
    dynamic rawFields,
    String Function(String label, String value) transform,
  ) {
    if (rawFields is! List) {
      return const <Map<String, String>>[];
    }

    return rawFields
        .whereType<Map>()
        .map((field) => Map<String, dynamic>.from(field))
        .map((field) {
          final label = '${field['label'] ?? ''}'.trim();
          final value = '${field['value'] ?? ''}'.trim();
          if (label.isEmpty || value.isEmpty) {
            return <String, String>{'label': label, 'value': value};
          }
          return <String, String>{
            'label': label,
            'value': transform(label, value),
          };
        })
        .where(
          (field) =>
              (field['label'] ?? '').trim().isNotEmpty &&
              (field['value'] ?? '').trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  String _transformReferenceAssetsJson(
    String rawValue,
    String Function(String path) transformPath,
  ) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List) {
        return rawValue;
      }
      final transformed = decoded
          .map((item) {
            if (item is! Map) {
              return item;
            }
            final map = Map<String, dynamic>.from(item);
            final path = '${map['path'] ?? ''}'.trim();
            if (path.isNotEmpty) {
              map['path'] = transformPath(path);
            }
            return map;
          })
          .toList(growable: false);
      return jsonEncode(transformed);
    } catch (_) {
      return rawValue;
    }
  }

  String _resolveRuntimePath(String value) {
    return LocalAssetPathResolver.resolveRuntimePathSync(value);
  }

  bool _isPathLikeLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return normalized.contains('path');
  }

  bool _isReferenceAssetsJsonLabel(String label) {
    return label.trim().toLowerCase() ==
        DocumentMetadataFieldLabels.referenceAssetsJson.toLowerCase();
  }
}
