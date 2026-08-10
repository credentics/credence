import 'dart:math';

import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_activity_record_dto.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_record_dto.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_share_options_dto.dart';
import 'package:pass_doc_manager/domain/profile/entities/generated_profile_share_link_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_activity_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_dashboard_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_attribute.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_options_entity.dart';
import 'package:pass_doc_manager/domain/profile/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.localDataSource});

  final ProfileLocalDataSource localDataSource;

  static const _maxActivities = 24;

  @override
  Future<ProfileDashboardEntity> getDashboard() async {
    final profileRecord = await localDataSource.readProfile();
    final activities = await localDataSource.readActivities();

    final mappedActivities =
        activities.map(_activityFromDto).toList(growable: false)
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return ProfileDashboardEntity(
      profile: _profileFromDto(profileRecord),
      activities: mappedActivities,
    );
  }

  @override
  Future<ProfileEntity> saveProfile(ProfileEntity profile) async {
    final now = DateTime.now().toUtc();
    final importedPhotoPath = await localDataSource.importProfilePhoto(
      profile.photoPath,
    );

    final next = profile.copyWith(
      photoPath: importedPhotoPath.isEmpty
          ? profile.photoPath
          : importedPhotoPath,
      updatedAt: now,
    );
    await localDataSource.writeProfile(_profileToDto(next));

    await _prependActivity(
      title: 'Profile Updated',
      subtitle: 'Account details updated',
      highlighted: false,
      occurredAt: now,
    );

    final refreshed = await localDataSource.readProfile();
    return _profileFromDto(refreshed);
  }

  @override
  Future<ProfileShareOptionsEntity> getShareOptions() async {
    final dto = await localDataSource.readShareOptions();
    return _shareOptionsFromDto(dto);
  }

  @override
  Future<ProfileShareOptionsEntity> saveShareOptions(
    ProfileShareOptionsEntity options,
  ) async {
    await localDataSource.writeShareOptions(_shareOptionsToDto(options));
    final refreshed = await localDataSource.readShareOptions();
    return _shareOptionsFromDto(refreshed);
  }

  @override
  Future<GeneratedProfileShareLinkEntity> generateSecureShareLink(
    ProfileShareOptionsEntity options,
  ) async {
    final profile = await localDataSource.readProfile();
    final profileEntity = _profileFromDto(profile);
    final generatedAt = DateTime.now().toUtc();
    final expiresAt = generatedAt.add(
      Duration(hours: options.linkExpirationHours),
    );
    final vCard = _buildVCard(profileEntity, options.enabledAttributes);
    final fileName = _vCardFileName(profileEntity);

    await _prependActivity(
      title: 'Profile vCard Generated',
      subtitle: 'Selected profile fields exported',
      highlighted: true,
      occurredAt: generatedAt,
    );

    return GeneratedProfileShareLinkEntity(
      vCard: vCard,
      fileName: fileName,
      expiresAt: expiresAt,
      includedAttributes: options.enabledAttributes,
    );
  }

  String _buildVCard(
    ProfileEntity profile,
    Set<ProfileShareAttribute> attributes,
  ) {
    final generatedAtUtc = DateTime.now().toUtc();
    final includeFullName = attributes.contains(ProfileShareAttribute.fullName);
    final includeEmail = attributes.contains(ProfileShareAttribute.email);
    final includePhone = attributes.contains(ProfileShareAttribute.phone);
    final includeAddress = attributes.contains(
      ProfileShareAttribute.homeAddress,
    );
    final includeSocialLinks = attributes.contains(
      ProfileShareAttribute.socialLinks,
    );

    final fullName = includeFullName
        ? profile.fullName.trim()
        : 'Shared Vault Contact';
    final firstName = includeFullName ? profile.firstName.trim() : '';
    final lastName = includeFullName ? profile.lastName.trim() : '';

    final resolvedFullName = fullName.isEmpty
        ? 'Shared Vault Contact'
        : fullName;
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'PRODID:-//Credence//Pass Docs Manager//EN',
      'FN:${_escapeVCardValue(resolvedFullName)}',
      'N:${_escapeVCardValue(lastName)};${_escapeVCardValue(firstName)};;;',
    ];

    final email = profile.email.trim();
    if (includeEmail && email.isNotEmpty) {
      lines.add('EMAIL;TYPE=INTERNET,HOME:${_escapeVCardValue(email)}');
    }

    final phone = profile.phone.trim();
    if (includePhone && phone.isNotEmpty) {
      lines.add('TEL;TYPE=CELL:${_escapeVCardValue(phone)}');
    }

    final address = profile.address.trim();
    if (includeAddress && address.isNotEmpty) {
      lines.add('ADR;TYPE=HOME:;;${_escapeVCardValue(address)};;;;');
    }

    final socialLinks = profile.socialLinks.trim();
    if (includeSocialLinks && socialLinks.isNotEmpty) {
      lines.add('URL:${_escapeVCardValue(socialLinks)}');
    }

    lines.add('REV:${_formatVCardTimestamp(generatedAtUtc)}');
    lines.add('END:VCARD');

    return '${lines.join('\r\n')}\r\n';
  }

  String _escapeVCardValue(String input) {
    return input
        .replaceAll('\\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
  }

  String _vCardFileName(ProfileEntity profile) {
    final base = profile.fullName.trim().isEmpty
        ? 'vault_profile'
        : profile.fullName.trim();
    final slug = base
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final normalized = slug.isEmpty ? 'vault_profile' : slug;
    return '${normalized}_contact.vcf';
  }

  String _formatVCardTimestamp(DateTime value) {
    final utc = value.toUtc();
    String two(int raw) => raw.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  Future<void> _prependActivity({
    required String title,
    required String subtitle,
    required bool highlighted,
    required DateTime occurredAt,
  }) async {
    final existing = await localDataSource.readActivities();
    final next = <ProfileActivityRecordDto>[
      ProfileActivityRecordDto(
        id: 'activity_${DateTime.now().toUtc().microsecondsSinceEpoch}_${_nonce()}',
        title: title,
        subtitle: subtitle,
        occurredAtIso: occurredAt.toIso8601String(),
        highlighted: highlighted,
      ),
      ...existing,
    ];

    final trimmed = next.take(_maxActivities).toList(growable: false);
    await localDataSource.writeActivities(trimmed);
  }

  String _nonce() {
    final random = Random.secure().nextInt(0xFFFFFFFF);
    return random.toRadixString(16).padLeft(8, '0');
  }

  ProfileEntity _profileFromDto(ProfileRecordDto dto) {
    final updatedAt =
        DateTime.tryParse(dto.updatedAtIso)?.toLocal() ?? DateTime.now();
    return ProfileEntity(
      firstName: dto.firstName,
      lastName: dto.lastName,
      email: dto.email,
      phone: dto.phone,
      address: dto.address,
      socialLinks: dto.socialLinks,
      photoPath: dto.photoPath,
      updatedAt: updatedAt,
    );
  }

  ProfileRecordDto _profileToDto(ProfileEntity entity) {
    return ProfileRecordDto(
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      socialLinks: entity.socialLinks,
      photoPath: entity.photoPath,
      updatedAtIso: entity.updatedAt.toUtc().toIso8601String(),
    );
  }

  ProfileActivityEntity _activityFromDto(ProfileActivityRecordDto dto) {
    return ProfileActivityEntity(
      id: dto.id,
      title: dto.title,
      subtitle: dto.subtitle,
      occurredAt:
          DateTime.tryParse(dto.occurredAtIso)?.toLocal() ?? DateTime.now(),
      highlighted: dto.highlighted,
    );
  }

  ProfileShareOptionsEntity _shareOptionsFromDto(ProfileShareOptionsDto dto) {
    final parsed = dto.enabledAttributeKeys
        .map(parseProfileShareAttribute)
        .whereType<ProfileShareAttribute>()
        .toSet();
    final fallback = parsed.isEmpty
        ? ProfileShareOptionsEntity.defaults.enabledAttributes
        : parsed;

    return ProfileShareOptionsEntity(
      enabledAttributes: fallback,
      linkExpirationHours: dto.linkExpirationHours <= 0
          ? ProfileShareOptionsEntity.defaults.linkExpirationHours
          : dto.linkExpirationHours,
    );
  }

  ProfileShareOptionsDto _shareOptionsToDto(ProfileShareOptionsEntity entity) {
    return ProfileShareOptionsDto(
      enabledAttributeKeys: entity.enabledAttributes
          .map((item) => item.storageKey)
          .toList(growable: false),
      linkExpirationHours: entity.linkExpirationHours,
    );
  }
}
