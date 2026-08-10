import 'package:pass_doc_manager/domain/profile/entities/profile_activity_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';

class ProfileDashboardEntity {
  const ProfileDashboardEntity({
    required this.profile,
    required this.activities,
  });

  final ProfileEntity profile;
  final List<ProfileActivityEntity> activities;
}
