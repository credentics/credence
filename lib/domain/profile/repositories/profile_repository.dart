import 'package:pass_doc_manager/domain/profile/entities/generated_profile_share_link_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_dashboard_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_options_entity.dart';

abstract class ProfileRepository {
  Future<ProfileDashboardEntity> getDashboard();

  Future<ProfileEntity> saveProfile(ProfileEntity profile);

  Future<ProfileShareOptionsEntity> getShareOptions();

  Future<ProfileShareOptionsEntity> saveShareOptions(
    ProfileShareOptionsEntity options,
  );

  Future<GeneratedProfileShareLinkEntity> generateSecureShareLink(
    ProfileShareOptionsEntity options,
  );
}
