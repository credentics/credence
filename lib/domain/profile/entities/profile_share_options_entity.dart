import 'package:pass_doc_manager/domain/profile/entities/profile_share_attribute.dart';

class ProfileShareOptionsEntity {
  const ProfileShareOptionsEntity({
    required this.enabledAttributes,
    required this.linkExpirationHours,
  });

  final Set<ProfileShareAttribute> enabledAttributes;
  final int linkExpirationHours;

  bool isEnabled(ProfileShareAttribute attribute) {
    return enabledAttributes.contains(attribute);
  }

  ProfileShareOptionsEntity copyWith({
    Set<ProfileShareAttribute>? enabledAttributes,
    int? linkExpirationHours,
  }) {
    return ProfileShareOptionsEntity(
      enabledAttributes: enabledAttributes ?? this.enabledAttributes,
      linkExpirationHours: linkExpirationHours ?? this.linkExpirationHours,
    );
  }

  static const defaults = ProfileShareOptionsEntity(
    enabledAttributes: {
      ProfileShareAttribute.fullName,
      ProfileShareAttribute.email,
      ProfileShareAttribute.socialLinks,
    },
    linkExpirationHours: 24,
  );
}
