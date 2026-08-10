import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/import_apply_result_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_document_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_password_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_snapshot_dto.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_merge_strategy.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/portable_data_scope.dart';

class VaultStoreLocalDataSource {
  VaultStoreLocalDataSource._({
    required Box<dynamic> documentsBox,
    required Box<dynamic> credentialsBox,
    required Box<dynamic> legacyPasswordsBox,
  }) : _documentsBox = documentsBox,
       _credentialsBox = credentialsBox,
       _legacyPasswordsBox = legacyPasswordsBox;

  static const _documentsBoxName = 'credence_documents_v1';
  static const _credentialsBoxName = 'credence_credentials_v1';
  static const _legacyPasswordsBoxName = 'credence_passwords_v1';

  final Box<dynamic> _documentsBox;
  final Box<dynamic> _credentialsBox;
  final Box<dynamic> _legacyPasswordsBox;

  static Future<VaultStoreLocalDataSource> create({
    List<VaultDocumentRecordDto> seedDocuments = const [],
    List<VaultPasswordRecordDto> seedPasswords = const [],
    String documentsBoxName = _documentsBoxName,
    String credentialsBoxName = _credentialsBoxName,
    String legacyPasswordsBoxName = _legacyPasswordsBoxName,
    @Deprecated('Use legacyPasswordsBoxName instead.') String? passwordsBoxName,
  }) async {
    final documentsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      documentsBoxName,
    );
    final credentialsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      credentialsBoxName,
    );
    final legacyPasswordsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      passwordsBoxName ?? legacyPasswordsBoxName,
    );

    final dataSource = VaultStoreLocalDataSource._(
      documentsBox: documentsBox,
      credentialsBox: credentialsBox,
      legacyPasswordsBox: legacyPasswordsBox,
    );
    await dataSource._seedIfNeeded(
      documents: seedDocuments,
      passwords: seedPasswords,
    );
    return dataSource;
  }

  Future<VaultSnapshotDto> createSnapshot({
    required PortableDataScope scope,
    required String exportedAtIso,
  }) async {
    final docs = switch (scope) {
      PortableDataScope.documents || PortableDataScope.all => _readDocuments(),
      PortableDataScope.passwords => <VaultDocumentRecordDto>[],
    };

    final passwords = switch (scope) {
      PortableDataScope.passwords || PortableDataScope.all => _readPasswords(),
      PortableDataScope.documents => <VaultPasswordRecordDto>[],
    };

    return VaultSnapshotDto(
      exportedAtIso: exportedAtIso,
      documents: docs,
      passwords: passwords,
    );
  }

  Future<ImportApplyResultDto> applySnapshot({
    required VaultSnapshotDto snapshot,
    required ImportMergeStrategy strategy,
  }) async {
    return switch (strategy) {
      ImportMergeStrategy.replace => _applyReplace(snapshot),
      ImportMergeStrategy.merge => _applyMerge(snapshot),
    };
  }

  Future<ImportApplyResultDto> _applyReplace(VaultSnapshotDto snapshot) async {
    await _documentsBox.clear();
    await _credentialsBox.clear();
    await _legacyPasswordsBox.clear();

    if (snapshot.documents.isNotEmpty) {
      await _documentsBox.putAll({
        for (final item in snapshot.documents) item.id: item.toMap(),
      });
    }
    if (snapshot.passwords.isNotEmpty) {
      await _putPasswords(snapshot.passwords);
    }

    return ImportApplyResultDto(
      importedDocuments: snapshot.documents.length,
      importedPasswords: snapshot.passwords.length,
      updatedDocuments: 0,
      updatedPasswords: 0,
    );
  }

  Future<ImportApplyResultDto> _applyMerge(VaultSnapshotDto snapshot) async {
    var updatedDocuments = 0;
    var updatedPasswords = 0;

    for (final incoming in snapshot.documents) {
      if (_documentsBox.containsKey(incoming.id)) {
        updatedDocuments += 1;
      }
      await _documentsBox.put(incoming.id, incoming.toMap());
    }

    for (final incoming in snapshot.passwords) {
      if (_credentialsBox.containsKey(incoming.id)) {
        updatedPasswords += 1;
      }
      await _credentialsBox.put(
        incoming.id,
        _credentialRowFromPassword(incoming),
      );
      await _legacyPasswordsBox.put(incoming.id, incoming.toMap());
    }

    return ImportApplyResultDto(
      importedDocuments: snapshot.documents.length - updatedDocuments,
      importedPasswords: snapshot.passwords.length - updatedPasswords,
      updatedDocuments: updatedDocuments,
      updatedPasswords: updatedPasswords,
    );
  }

  Future<void> _seedIfNeeded({
    required List<VaultDocumentRecordDto> documents,
    required List<VaultPasswordRecordDto> passwords,
  }) async {
    if (_documentsBox.isEmpty && documents.isNotEmpty) {
      await _documentsBox.putAll({
        for (final item in documents) item.id: item.toMap(),
      });
    }
    if (_credentialsBox.isEmpty && passwords.isNotEmpty) {
      await _credentialsBox.putAll({
        for (final item in passwords) item.id: _credentialRowFromPassword(item),
      });
    }
    if (_legacyPasswordsBox.isEmpty && passwords.isNotEmpty) {
      await _legacyPasswordsBox.putAll({
        for (final item in passwords) item.id: item.toMap(),
      });
    }
  }

  List<VaultDocumentRecordDto> _readDocuments() {
    return _documentsBox.values
        .map(_mapFromRaw)
        .map(VaultDocumentRecordDto.fromMap)
        .toList(growable: false);
  }

  List<VaultPasswordRecordDto> _readPasswords() {
    final credentials = _credentialsBox.values
        .map(_mapFromRaw)
        .map(_passwordFromCredentialRow)
        .toList(growable: false);
    if (credentials.isNotEmpty) {
      return credentials;
    }

    return _legacyPasswordsBox.values
        .map(_mapFromRaw)
        .map(VaultPasswordRecordDto.fromMap)
        .toList(growable: false);
  }

  Future<void> _putPasswords(List<VaultPasswordRecordDto> passwords) async {
    await _credentialsBox.putAll({
      for (final item in passwords) item.id: _credentialRowFromPassword(item),
    });
    await _legacyPasswordsBox.putAll({
      for (final item in passwords) item.id: item.toMap(),
    });
  }

  VaultPasswordRecordDto _passwordFromCredentialRow(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString().trim();
    final serviceName = (row['serviceName'] ?? row['displayName'] ?? '')
        .toString()
        .trim();
    final username = (row['username'] ?? '').toString().trim();
    final secret = (row['password'] ?? row['secret'] ?? '').toString();
    final updatedAtIso = _resolveCredentialUpdatedAtIso(row);
    final isSecure = _asBool(row['isSecure']);
    final hasWarning = _asBool(row['hasWarning']);
    final brandHex = _asInt(row['brandHex']);

    return VaultPasswordRecordDto(
      id: id.isEmpty
          ? 'credential_${DateTime.now().microsecondsSinceEpoch}'
          : id,
      serviceName: serviceName.isEmpty ? 'Credential' : serviceName,
      username: username,
      secret: secret,
      updatedAtIso: updatedAtIso,
      displayName: (row['displayName'] ?? '').toString().trim().isEmpty
          ? null
          : row['displayName'].toString(),
      accountLabel: (row['accountLabel'] ?? '').toString().trim().isEmpty
          ? null
          : row['accountLabel'].toString(),
      categoryKey: (row['category'] ?? '').toString().trim().isEmpty
          ? null
          : row['category'].toString(),
      url: (row['url'] ?? '').toString().trim().isEmpty
          ? null
          : row['url'].toString(),
      notes: (row['notes'] ?? '').toString().trim().isEmpty
          ? null
          : row['notes'].toString(),
      lastSecurityUpdate:
          (row['lastSecurityUpdate'] ?? '').toString().trim().isEmpty
          ? null
          : row['lastSecurityUpdate'].toString(),
      mfaRecovery: (row['mfaRecovery'] ?? '').toString().trim().isEmpty
          ? null
          : row['mfaRecovery'].toString(),
      isSecure: isSecure,
      hasWarning: hasWarning,
      brandHex: brandHex,
      logoPath: (row['logoPath'] ?? '').toString().trim().isEmpty
          ? null
          : row['logoPath'].toString(),
      lastUsedAtIso: (row['lastUsedAtIso'] ?? '').toString().trim().isEmpty
          ? null
          : row['lastUsedAtIso'].toString(),
    );
  }

  Map<String, dynamic> _credentialRowFromPassword(VaultPasswordRecordDto item) {
    final isSecure = item.isSecure ?? !(item.hasWarning ?? false);
    final hasWarning = item.hasWarning ?? !isSecure;
    return <String, dynamic>{
      'id': item.id,
      'displayName': item.displayName ?? item.serviceName,
      'serviceName': item.serviceName,
      'accountLabel': item.accountLabel ?? 'Imported Account',
      'username': item.username,
      'category': item.categoryKey ?? 'general',
      'password': item.secret,
      'url': item.url ?? '',
      'notes': item.notes ?? '',
      'lastSecurityUpdate':
          item.lastSecurityUpdate ??
          _formatDate(_parseIsoOrNow(item.updatedAtIso)),
      'mfaRecovery': item.mfaRecovery ?? 'Not set',
      'isSecure': isSecure,
      'hasWarning': hasWarning,
      'brandHex': item.brandHex ?? 0xFF2A1464,
      'logoPath': item.logoPath,
      'lastUsedAtIso': item.lastUsedAtIso ?? item.updatedAtIso,
      'updatedAtIso': item.updatedAtIso,
    };
  }

  String _resolveCredentialUpdatedAtIso(Map<String, dynamic> row) {
    final candidates = <String?>[
      row['updatedAtIso'] as String?,
      row['lastUsedAtIso'] as String?,
    ];
    for (final candidate in candidates) {
      final value = candidate?.trim() ?? '';
      if (value.isEmpty) {
        continue;
      }
      if (DateTime.tryParse(value) != null) {
        return value;
      }
    }
    return DateTime.now().toUtc().toIso8601String();
  }

  DateTime _parseIsoOrNow(String input) {
    final parsed = DateTime.tryParse(input)?.toLocal();
    return parsed ?? DateTime.now();
  }

  String _formatDate(DateTime date) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }

  bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true') {
      return true;
    }
    if (text == 'false') {
      return false;
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString().trim() ?? '');
  }

  Map<String, dynamic> _mapFromRaw(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw StateError('Invalid vault row format in encrypted store.');
  }
}
