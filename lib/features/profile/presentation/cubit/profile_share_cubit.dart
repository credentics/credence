import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_attribute.dart';
import 'package:pass_doc_manager/domain/profile/usecases/generate_secure_profile_link.dart';
import 'package:pass_doc_manager/domain/profile/usecases/get_profile_share_options.dart';
import 'package:pass_doc_manager/domain/profile/usecases/save_profile_share_options.dart';
import 'package:pass_doc_manager/features/profile/presentation/cubit/profile_share_state.dart';

class ProfileShareCubit extends Cubit<ProfileShareState> {
  ProfileShareCubit({
    required GetProfileShareOptions getProfileShareOptions,
    required SaveProfileShareOptions saveProfileShareOptions,
    required GenerateSecureProfileLink generateSecureProfileLink,
  }) : _getProfileShareOptions = getProfileShareOptions,
       _saveProfileShareOptions = saveProfileShareOptions,
       _generateSecureProfileLink = generateSecureProfileLink,
       super(const ProfileShareState.initial());

  final GetProfileShareOptions _getProfileShareOptions;
  final SaveProfileShareOptions _saveProfileShareOptions;
  final GenerateSecureProfileLink _generateSecureProfileLink;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileShareStatus.loading, clearError: true));

    try {
      final options = await _getProfileShareOptions(
        const GetProfileShareOptionsParams(),
      );
      emit(
        state.copyWith(
          status: ProfileShareStatus.ready,
          options: options,
          clearGeneratedLink: true,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[ProfileShare] Failed to load sharing options');
      emit(
        state.copyWith(
          status: ProfileShareStatus.error,
          errorMessage: null, // UI uses l10n.profileErrorShareOptions
        ),
      );
    }
  }

  void toggleAttribute(ProfileShareAttribute attribute, bool enabled) {
    final nextAttributes = state.options.enabledAttributes.toSet();
    if (enabled) {
      nextAttributes.add(attribute);
    } else {
      nextAttributes.remove(attribute);
    }

    if (nextAttributes.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        options: state.options.copyWith(enabledAttributes: nextAttributes),
        clearGeneratedLink: true,
      ),
    );
  }

  void setExpirationHours(int hours) {
    emit(
      state.copyWith(
        options: state.options.copyWith(linkExpirationHours: hours),
        clearGeneratedLink: true,
      ),
    );
  }

  Future<void> generate() async {
    emit(
      state.copyWith(
        status: ProfileShareStatus.saving,
        clearGeneratedLink: true,
        clearError: true,
      ),
    );

    try {
      final savedOptions = await _saveProfileShareOptions(
        SaveProfileShareOptionsParams(options: state.options),
      );
      final link = await _generateSecureProfileLink(
        GenerateSecureProfileLinkParams(options: savedOptions),
      );
      emit(
        state.copyWith(
          status: ProfileShareStatus.ready,
          options: savedOptions,
          generatedLink: link,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[ProfileShare] Failed to generate vCard');
      emit(
        state.copyWith(
          status: ProfileShareStatus.error,
          errorMessage: null, // UI uses l10n.profileErrorVCard
        ),
      );
    }
  }

  Future<void> persistCurrentOptions() async {
    try {
      final saved = await _saveProfileShareOptions(
        SaveProfileShareOptionsParams(options: state.options),
      );
      emit(state.copyWith(options: saved));
    } catch (_) {
      // ignore persistence errors on background save
    }
  }
}
