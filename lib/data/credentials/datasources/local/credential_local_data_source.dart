import 'dart:io';

import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_create_dto.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_detail_dto.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_summary_dto.dart';
import 'package:pass_doc_manager/data/password_tools/services/local_password_tools_service.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:path_provider/path_provider.dart';

class CredentialLocalDataSource {
  CredentialLocalDataSource._({
    required Box<dynamic> box,
    LocalPasswordToolsService? passwordToolsService,
  }) : _box = box,
       _passwordToolsService =
           passwordToolsService ?? LocalPasswordToolsService();

  static const _credentialsBoxName = 'credence_credentials_v1';

  final Box<dynamic> _box;
  final LocalPasswordToolsService _passwordToolsService;

  static Future<CredentialLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(
      _credentialsBoxName,
    );
    final dataSource = CredentialLocalDataSource._(box: box);
    await dataSource._migrateLogoPathsToPortableFormatIfNeeded();
    return dataSource;
  }

  Future<List<CredentialSummaryDto>> getCredentialSummaries() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final appSupportPath = await _appSupportPath();

    final rows = _box.values
        .map(_rowFromRaw)
        .map((raw) => _resolveRuntimeLogoPath(raw, appSupportPath))
        .toList(growable: false);

    final passwordCounts = <String, int>{};
    for (final row in rows) {
      final password = '${row['password'] ?? ''}'.trim();
      if (password.isEmpty) {
        continue;
      }
      passwordCounts[password] = (passwordCounts[password] ?? 0) + 1;
    }

    final summaryRows =
        rows
            .map((raw) {
              final row = Map<String, dynamic>.from(raw);
              final password = '${row['password'] ?? ''}'.trim();
              row['isReused'] =
                  password.isNotEmpty && (passwordCounts[password] ?? 0) > 1;
              row['isMissingUrl'] = '${row['url'] ?? ''}'.trim().isEmpty;
              return row;
            })
            .toList(growable: false)
          ..sort(_sortByLastUsedDescThenName);

    return summaryRows
        .map((raw) => CredentialSummaryDto.fromMap(raw))
        .toList(growable: false);
  }

  Future<CredentialDetailDto> getCredentialDetailById({
    required String id,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final appSupportPath = await _appSupportPath();

    final raw = _box.get(id);
    if (raw == null) {
      throw StateError('Credential not found for id: $id');
    }

    return CredentialDetailDto.fromMap(
      _resolveRuntimeLogoPath(_rowFromRaw(raw), appSupportPath),
    );
  }

  Future<CredentialDetailDto> createCredential({
    required CredentialCreateDto draft,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final appSupportPath = await _appSupportPath();

    final id = _nextCredentialId(draft.serviceName);
    final existingPasswords = _box.values
        .map(_rowFromRaw)
        .map((row) => row['password'])
        .whereType<String>()
        .toList(growable: false);
    final health = await _passwordToolsService.evaluatePasswordHealth(
      password: draft.password,
      username: draft.username.trim(),
      serviceName: draft.serviceName.trim(),
      existingPasswords: existingPasswords,
    );
    final isSecure = health.isHealthy;

    final now = DateTime.now();
    final row = <String, dynamic>{
      'id': id,
      'displayName': _displayNameFromServiceName(draft.serviceName),
      'serviceName': draft.serviceName.trim(),
      'accountLabel': draft.accountLabel.trim().isEmpty
          ? 'Personal Account'
          : draft.accountLabel.trim(),
      'username': draft.username.trim(),
      'category': draft.categoryKey,
      'password': draft.password,
      'url': draft.url.trim(),
      'notes': draft.notes.trim(),
      'lastSecurityUpdate': _formatDate(now),
      'createdAtIso': now.toUtc().toIso8601String(),
      'updatedAtIso': now.toUtc().toIso8601String(),
      'mfaRecovery': 'Not set',
      'isSecure': isSecure,
      'hasWarning': !isSecure,
      'brandHex': draft.brandHex,
      'logoPath': _toStoredLogoPath(draft.logoPath),
      'breachedCount': 0,
      'isFavorite': false,
    };

    await _box.put(id, row);
    return CredentialDetailDto.fromMap(
      _resolveRuntimeLogoPath(row, appSupportPath),
    );
  }

  Future<CredentialDetailDto> updateCredentialById({
    required String id,
    required CredentialCreateDto draft,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final appSupportPath = await _appSupportPath();

    final raw = _box.get(id);
    if (raw == null) {
      throw StateError('Credential not found for id: $id');
    }

    final current = _rowFromRaw(raw);
    final existingPasswords = _box.values
        .map(_rowFromRaw)
        .where((row) => (row['id'] as String?) != id)
        .map((row) => row['password'])
        .whereType<String>()
        .toList(growable: false);
    final health = await _passwordToolsService.evaluatePasswordHealth(
      password: draft.password,
      username: draft.username.trim(),
      serviceName: draft.serviceName.trim(),
      existingPasswords: existingPasswords,
    );
    final isSecure = health.isHealthy;
    final now = DateTime.now();

    final updated = <String, dynamic>{
      ...current,
      'id': id,
      'displayName': _displayNameFromServiceName(draft.serviceName),
      'serviceName': draft.serviceName.trim(),
      'accountLabel': draft.accountLabel.trim().isEmpty
          ? 'Personal Account'
          : draft.accountLabel.trim(),
      'username': draft.username.trim(),
      'category': draft.categoryKey,
      'password': draft.password,
      'url': draft.url.trim(),
      'notes': draft.notes.trim(),
      'lastSecurityUpdate': _formatDate(now),
      'updatedAtIso': now.toUtc().toIso8601String(),
      'isSecure': isSecure,
      'hasWarning': !isSecure || ((current['breachedCount'] as int?) ?? 0) > 0,
      'brandHex': draft.brandHex,
      'logoPath': _toStoredLogoPath(draft.logoPath),
      'isFavorite': (current['isFavorite'] as bool?) ?? false,
    };

    await _box.put(id, updated);
    return CredentialDetailDto.fromMap(
      _resolveRuntimeLogoPath(updated, appSupportPath),
    );
  }

  Future<void> deleteCredentialById({required String id}) async {
    await _box.delete(id);
  }

  Future<void> replaceCredentialRows(List<Map<String, dynamic>> rows) async {
    await _box.clear();
    for (final row in rows) {
      final normalized = _normalizeStoredRow(row);
      final id = (normalized['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) {
        continue;
      }
      normalized['logoPath'] = _toStoredLogoPath(
        normalized['logoPath'] as String?,
      );
      await _box.put(id, normalized);
    }
    await _box.flush();
  }

  Future<List<Map<String, dynamic>>> readCredentialRows() async {
    return _box.values
        .map(_rowFromRaw)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<void> markCredentialUsedById({required String id}) async {
    final raw = _box.get(id);
    if (raw == null) {
      return;
    }
    final row = _rowFromRaw(raw);
    final nowIso = DateTime.now().toUtc().toIso8601String();
    row['lastUsedAtIso'] = nowIso;
    row['updatedAtIso'] = nowIso;
    await _box.put(id, row);
  }

  Future<void> toggleFavorite({required String id}) async {
    final raw = _box.get(id);
    if (raw == null) {
      return;
    }
    final row = _rowFromRaw(raw);
    final current = (row['isFavorite'] as bool?) ?? false;
    row['isFavorite'] = !current;
    row['updatedAtIso'] = DateTime.now().toUtc().toIso8601String();
    await _box.put(id, row);
  }

  Future<void> updateBreachedCount({
    required String id,
    required int breachedCount,
  }) async {
    final raw = _box.get(id);
    if (raw == null) {
      return;
    }
    final row = _rowFromRaw(raw);
    row['breachedCount'] = breachedCount;
    row['updatedAtIso'] = DateTime.now().toUtc().toIso8601String();
    if (breachedCount > 0) {
      row['hasWarning'] = true;
    }
    await _box.put(id, row);
  }

  String _nextCredentialId(String serviceName) {
    final base = serviceName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final normalized = base.isEmpty ? 'credential' : base;

    var counter = 1;
    var candidate = normalized;
    while (_box.containsKey(candidate)) {
      counter += 1;
      candidate = '${normalized}_$counter';
    }

    return candidate;
  }

  String _displayNameFromServiceName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Credential';
    }
    return trimmed;
  }

  String _formatDate(DateTime date) {
    const monthNames = [
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

  Map<String, dynamic> _rowFromRaw(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw StateError('Invalid credential row format in encrypted store.');
  }

  Map<String, dynamic> _normalizeStoredRow(Map<String, dynamic> raw) {
    final serviceName = '${raw['serviceName'] ?? raw['displayName'] ?? ''}'
        .trim();
    final breachedCount = (raw['breachedCount'] as int?) ?? 0;
    final isSecure = (raw['isSecure'] as bool?) ?? false;
    return <String, dynamic>{
      ...raw,
      'id': '${raw['id'] ?? ''}'.trim(),
      'displayName': ('${raw['displayName'] ?? serviceName}').trim().isEmpty
          ? 'Credential'
          : ('${raw['displayName'] ?? serviceName}').trim(),
      'serviceName': serviceName.isEmpty ? 'Credential' : serviceName,
      'accountLabel': ('${raw['accountLabel'] ?? ''}').trim().isEmpty
          ? 'Personal Account'
          : '${raw['accountLabel']}'.trim(),
      'username': '${raw['username'] ?? ''}'.trim(),
      'category': ('${raw['category'] ?? ''}').trim().isEmpty
          ? 'general'
          : '${raw['category']}'.trim(),
      'password': '${raw['password'] ?? ''}',
      'url': '${raw['url'] ?? ''}'.trim(),
      'notes': '${raw['notes'] ?? ''}'.trim(),
      if (raw['createdAtIso'] != null) 'createdAtIso': raw['createdAtIso'],
      if (raw['updatedAtIso'] != null) 'updatedAtIso': raw['updatedAtIso'],
      'lastSecurityUpdate':
          ('${raw['lastSecurityUpdate'] ?? ''}').trim().isEmpty
          ? _formatDate(DateTime.now())
          : '${raw['lastSecurityUpdate']}'.trim(),
      'mfaRecovery': ('${raw['mfaRecovery'] ?? ''}').trim().isEmpty
          ? 'Not set'
          : '${raw['mfaRecovery']}'.trim(),
      'isSecure': isSecure,
      'hasWarning':
          (raw['hasWarning'] as bool?) ?? (!isSecure || breachedCount > 0),
      'brandHex': (raw['brandHex'] as int?) ?? 0xFF7C5CFF,
      'logoPath': raw['logoPath'] as String?,
      'breachedCount': breachedCount,
      'isFavorite': (raw['isFavorite'] as bool?) ?? false,
      if (raw['lastUsedAtIso'] != null) 'lastUsedAtIso': raw['lastUsedAtIso'],
    };
  }

  Future<void> _migrateLogoPathsToPortableFormatIfNeeded() async {
    final keys = _box.keys.toList(growable: false);
    for (final key in keys) {
      final raw = _box.get(key);
      if (raw == null) {
        continue;
      }

      final row = _rowFromRaw(raw);
      final existing = row['logoPath'] as String?;
      final normalized = _toStoredLogoPath(existing);
      if (normalized == existing) {
        continue;
      }

      row['logoPath'] = normalized;
      await _box.put(key, row);
    }
  }

  Future<String> _appSupportPath() async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Map<String, dynamic> _resolveRuntimeLogoPath(
    Map<String, dynamic> row,
    String appSupportPath,
  ) {
    final copy = Map<String, dynamic>.from(row);
    final value = (copy['logoPath'] as String?)?.trim();
    if (value == null || value.isEmpty) {
      return copy;
    }

    if (_isPortableLogoPath(value)) {
      copy['logoPath'] = '$appSupportPath/$value';
      return copy;
    }

    // Backward compatibility for old absolute-path values across container-id changes.
    final existing = File(value);
    if (existing.existsSync()) {
      return copy;
    }

    final portable = _extractPortableLogoPath(value);
    if (portable == null) {
      return copy;
    }

    final resolved = '$appSupportPath/$portable';
    if (File(resolved).existsSync()) {
      copy['logoPath'] = resolved;
    }
    return copy;
  }

  String? _toStoredLogoPath(String? rawValue) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (_isPortableLogoPath(value)) {
      return value;
    }

    return _extractPortableLogoPath(value) ?? value;
  }

  String? _extractPortableLogoPath(String rawPath) {
    final marker = '/company_logos/';
    final index = rawPath.lastIndexOf(marker);
    if (index == -1) {
      return null;
    }

    final filePart = rawPath.substring(index + marker.length).trim();
    if (filePart.isEmpty) {
      return null;
    }

    return 'company_logos/$filePart';
  }

  bool _isPortableLogoPath(String path) {
    return path.startsWith('company_logos/');
  }

  int _sortByLastUsedDescThenName(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    // Favorites always come first.
    final aFav = ((a['isFavorite'] as bool?) ?? false) ? 1 : 0;
    final bFav = ((b['isFavorite'] as bool?) ?? false) ? 1 : 0;
    final byFav = bFav.compareTo(aFav);
    if (byFav != 0) {
      return byFav;
    }

    final aTime = DateTime.tryParse(
      (a['lastUsedAtIso'] as String?) ?? '',
    )?.millisecondsSinceEpoch;
    final bTime = DateTime.tryParse(
      (b['lastUsedAtIso'] as String?) ?? '',
    )?.millisecondsSinceEpoch;
    final byTime = (bTime ?? 0).compareTo(aTime ?? 0);
    if (byTime != 0) {
      return byTime;
    }
    return (a['displayName'] as String).compareTo(b['displayName'] as String);
  }
}
