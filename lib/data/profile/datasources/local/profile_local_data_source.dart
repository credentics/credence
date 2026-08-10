import 'dart:io';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_activity_record_dto.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_record_dto.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_share_options_dto.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';

class ProfileLocalDataSource {
  ProfileLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _boxName = 'credence_profile_v1';
  static const _profileKey = 'profile_record';
  static const _shareOptionsKey = 'profile_share_options';
  static const _activitiesKey = 'profile_activities';
  static const _activitiesCleanupVersionKey =
      'profile_activities_cleanup_version';
  static const _activitiesCleanupVersion = 1;
  static const _photoFolder = 'profile_images';

  final Box<dynamic> _box;

  static Future<ProfileLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
    final dataSource = ProfileLocalDataSource._(box: box);
    await dataSource._seedIfNeeded();
    return dataSource;
  }

  Future<ProfileRecordDto> readProfile() async {
    final raw = _box.get(_profileKey);
    if (raw is! Map) {
      final now = DateTime.now().toUtc();
      final defaults = ProfileRecordDto.defaults(now);
      await writeProfile(defaults);
      return defaults;
    }

    var dto = ProfileRecordDto.fromMap(Map<String, dynamic>.from(raw));
    if (_isLegacySeedProfile(dto)) {
      dto = ProfileRecordDto.defaults(DateTime.now().toUtc());
      await writeProfile(dto);
    }
    final resolvedPath = await _resolveRuntimePhotoPath(dto.photoPath);
    if (resolvedPath == dto.photoPath) {
      return dto;
    }
    return ProfileRecordDto(
      firstName: dto.firstName,
      lastName: dto.lastName,
      email: dto.email,
      phone: dto.phone,
      address: dto.address,
      socialLinks: dto.socialLinks,
      photoPath: resolvedPath,
      updatedAtIso: dto.updatedAtIso,
    );
  }

  Future<void> writeProfile(ProfileRecordDto dto) async {
    final portablePhotoPath = await _toStoredPortablePhotoPath(dto.photoPath);
    await _box.put(
      _profileKey,
      ProfileRecordDto(
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: dto.email,
        phone: dto.phone,
        address: dto.address,
        socialLinks: dto.socialLinks,
        photoPath: portablePhotoPath,
        updatedAtIso: dto.updatedAtIso,
      ).toMap(),
    );
  }

  Future<List<ProfileActivityRecordDto>> readActivities() async {
    final raw = _box.get(_activitiesKey);
    if (raw is! List) {
      await writeActivities(const <ProfileActivityRecordDto>[]);
      return const <ProfileActivityRecordDto>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              ProfileActivityRecordDto.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> writeActivities(
    List<ProfileActivityRecordDto> activities,
  ) async {
    final payload = activities
        .map((item) => item.toMap())
        .toList(growable: false);
    await _box.put(_activitiesKey, payload);
  }

  Future<ProfileShareOptionsDto> readShareOptions() async {
    final raw = _box.get(_shareOptionsKey);
    if (raw is! Map) {
      await writeShareOptions(ProfileShareOptionsDto.defaults);
      return ProfileShareOptionsDto.defaults;
    }
    return ProfileShareOptionsDto.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> writeShareOptions(ProfileShareOptionsDto dto) async {
    await _box.put(_shareOptionsKey, dto.toMap());
  }

  Future<String> importProfilePhoto(String sourcePath) async {
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final source = File(trimmed);
    if (!source.existsSync()) {
      return trimmed;
    }

    final appSupport = await getApplicationSupportDirectory();
    final photoDir = Directory('${appSupport.path}/$_photoFolder');
    if (!photoDir.existsSync()) {
      await photoDir.create(recursive: true);
    }

    final ext = _fileExtension(trimmed).toLowerCase();
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final fileName =
        'profile_${DateTime.now().microsecondsSinceEpoch}_${_randomSuffix()}$safeExt';
    final destination = File('${photoDir.path}/$fileName');
    await source.copy(destination.path);

    return '$_photoFolder/$fileName';
  }

  Future<void> _seedIfNeeded() async {
    if (!_box.containsKey(_profileKey)) {
      final defaults = ProfileRecordDto.defaults(DateTime.now().toUtc());
      await writeProfile(defaults);
    }

    if (!_box.containsKey(_shareOptionsKey)) {
      await writeShareOptions(ProfileShareOptionsDto.defaults);
    }

    if (!_box.containsKey(_activitiesKey)) {
      await writeActivities(const <ProfileActivityRecordDto>[]);
    }

    await _cleanupLegacySeedActivitiesIfNeeded();
  }

  String _randomSuffix() {
    final random = Random.secure().nextInt(0xFFFFFF);
    return random.toRadixString(16).padLeft(6, '0');
  }

  bool _isPortablePhotoPath(String value) {
    final normalized = value.trim();
    return normalized.startsWith('$_photoFolder/');
  }

  Future<String> _resolveRuntimePhotoPath(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }

    if (_isPortablePhotoPath(normalized)) {
      final appSupport = await getApplicationSupportDirectory();
      return '${appSupport.path}/$normalized';
    }

    final file = File(normalized);
    if (file.existsSync()) {
      return normalized;
    }

    final marker = '/$_photoFolder/';
    final index = normalized.lastIndexOf(marker);
    if (index == -1) {
      return normalized;
    }
    final suffix = normalized.substring(index + marker.length);
    if (suffix.trim().isEmpty) {
      return normalized;
    }

    final appSupport = await getApplicationSupportDirectory();
    final migrated = '${appSupport.path}/$_photoFolder/$suffix';
    return File(migrated).existsSync() ? migrated : normalized;
  }

  Future<String> _toStoredPortablePhotoPath(String rawValue) async {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return '';
    }

    if (_isPortablePhotoPath(value)) {
      return value;
    }

    final marker = '/$_photoFolder/';
    final markerIndex = value.lastIndexOf(marker);
    if (markerIndex != -1) {
      final relative = value.substring(markerIndex + 1);
      if (relative.trim().isNotEmpty) {
        return relative;
      }
    }

    final source = File(value);
    if (!source.existsSync()) {
      return value;
    }

    return importProfilePhoto(value);
  }

  String _fileExtension(String path) {
    final normalized = path.trim();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      return '';
    }
    return normalized.substring(dotIndex);
  }

  bool _isLegacySeedProfile(ProfileRecordDto dto) {
    return dto.firstName == 'Alex' &&
        dto.lastName == 'Sterling' &&
        dto.email == 'alex.sterling@vault-secure.com' &&
        dto.phone == '+1 (555) 012-3456' &&
        dto.address == '742 Evergreen Terrace' &&
        dto.socialLinks == 'LinkedIn, Twitter, Portfolio' &&
        dto.photoPath.isEmpty;
  }

  Future<void> _cleanupLegacySeedActivitiesIfNeeded() async {
    final appliedVersion = _box.get(_activitiesCleanupVersionKey);
    if (appliedVersion is int && appliedVersion >= _activitiesCleanupVersion) {
      return;
    }

    final rawActivities = _box.get(_activitiesKey);
    if (rawActivities is List) {
      final cleaned = rawActivities
          .whereType<Map>()
          .map(
            (item) =>
                ProfileActivityRecordDto.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((item) => !_isLegacySeedActivity(item))
          .map((item) => item.toMap())
          .toList(growable: false);
      await _box.put(_activitiesKey, cleaned);
    }

    await _box.put(_activitiesCleanupVersionKey, _activitiesCleanupVersion);
  }

  bool _isLegacySeedActivity(ProfileActivityRecordDto dto) {
    final id = dto.id.trim().toLowerCase();
    if (id.startsWith('seed_') || id.startsWith('mock_') || id.startsWith('sample_')) {
      return true;
    }

    final title = _normalizeText(dto.title);
    final subtitle = _normalizeText(dto.subtitle);
    if (_legacySeedTitles.contains(title)) {
      return true;
    }

    final signature = '$title|$subtitle';
    return _legacySeedSignatures.any(signature.contains);
  }

  String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static const Set<String> _legacySeedTitles = {
    'passport document scanned',
    'master password updated',
    'new device login',
  };

  static const Set<String> _legacySeedSignatures = {
    "passport document scanned|added to 'travel' collection",
    'master password updated|security audit completed',
    'new device login|iphone 15 pro, london uk',
  };
}
