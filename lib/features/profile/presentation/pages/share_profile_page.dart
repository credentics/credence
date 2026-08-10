import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/profile/entities/generated_profile_share_link_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_attribute.dart';
import 'package:pass_doc_manager/domain/profile/usecases/generate_secure_profile_link.dart';
import 'package:pass_doc_manager/domain/profile/usecases/get_profile_share_options.dart';
import 'package:pass_doc_manager/domain/profile/usecases/save_profile_share_options.dart';
import 'package:pass_doc_manager/features/profile/presentation/cubit/profile_share_cubit.dart';
import 'package:pass_doc_manager/features/profile/presentation/cubit/profile_share_state.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

const String _profileShareFontDisplay = 'Manrope';
const String _profileShareFontBody = 'Manrope';
const String _profileShareFontMono = 'JetBrains Mono';

class ShareProfilePage extends StatefulWidget {
  const ShareProfilePage({
    super.key,
    required this.profile,
    required this.getProfileShareOptions,
    required this.saveProfileShareOptions,
    required this.generateSecureProfileLink,
  });

  final ProfileEntity profile;
  final GetProfileShareOptions getProfileShareOptions;
  final SaveProfileShareOptions saveProfileShareOptions;
  final GenerateSecureProfileLink generateSecureProfileLink;

  @override
  State<ShareProfilePage> createState() => _ShareProfilePageState();
}

class _ShareProfilePageState extends State<ShareProfilePage> {
  late final ProfileShareCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ProfileShareCubit(
      getProfileShareOptions: widget.getProfileShareOptions,
      saveProfileShareOptions: widget.saveProfileShareOptions,
      generateSecureProfileLink: widget.generateSecureProfileLink,
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ProfileShareCubit, ProfileShareState>(
        listener: (context, state) {
          if (state.status == ProfileShareStatus.error &&
              state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final l10n = context.l10n;
          final palette = context.appPalette;
          return Scaffold(
            backgroundColor: palette.background,
            bottomNavigationBar: _ShareBottomAction(
              isBusy: state.isBusy,
              onShare: () => _shareSelectedProfile(context),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ShareTopBar(
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 28),
                          _ProfileShareHero(profile: widget.profile),
                          const SizedBox(height: 28),
                          Text(
                            l10n.profileShareAttributesSection,
                            style: TextStyle(
                              fontFamily: _profileShareFontMono,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ShareAttributesCard(
                            children: [
                              for (final attribute
                                  in ProfileShareAttribute.values)
                                _ShareAttributeTile(
                                  attribute: attribute,
                                  value: _valueForAttribute(attribute),
                                  enabled: state.options.isEnabled(attribute),
                                  onChanged: state.isBusy
                                      ? null
                                      : (enabled) => _cubit.toggleAttribute(
                                          attribute,
                                          enabled,
                                        ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ShareInfoCard(
                            title: l10n.profileShareOptInTitle,
                            subtitle: l10n.profileShareOptInSubtitle,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l10n.profileSharePoweredByEncryption,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _profileShareFontMono,
                              fontSize: 9.5,
                              letterSpacing: 1.35,
                              color: palette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareSelectedProfile(BuildContext context) async {
    await _cubit.generate();
    if (!mounted || !context.mounted) return;

    final shareData = _cubit.state.generatedLink;
    if (shareData == null || shareData.vCard.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.profileErrorVCard)));
      return;
    }

    await _shareVCard(shareData);
  }

  Future<void> _shareVCard(GeneratedProfileShareLinkEntity shareData) async {
    final l10n = context.l10n;
    try {
      final tempDirectory = await getTemporaryDirectory();
      final normalizedName = _normalizeVCardFileName(shareData.fileName);
      final output = File('${tempDirectory.path}/$normalizedName');
      await output.parent.create(recursive: true);
      await output.writeAsString(shareData.vCard, flush: true);

      if (!mounted) {
        return;
      }
      final anchor = context.findRenderObject() as RenderBox?;
      final shareOrigin = anchor != null
          ? anchor.localToGlobal(Offset.zero) & anchor.size
          : null;

      await Share.shareXFiles(
        [XFile(output.path, name: normalizedName, mimeType: 'text/x-vcard')],
        subject: normalizedName,
        text: l10n.profileShareSecureLink,
        sharePositionOrigin: shareOrigin,
      );
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.documentUnableShareFile)));
    } on PlatformException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.documentUnableShareFile)));
    } on FileSystemException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.documentUnableShareFile)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.documentUnableShareFile)));
    }
  }

  String _normalizeVCardFileName(String rawFileName) {
    final trimmed = rawFileName.trim();
    if (trimmed.isEmpty) {
      return 'vault_profile.vcf';
    }
    if (trimmed.toLowerCase().endsWith('.vcf')) {
      return trimmed;
    }
    return '$trimmed.vcf';
  }

  String _valueForAttribute(ProfileShareAttribute attribute) {
    return switch (attribute) {
      ProfileShareAttribute.fullName => widget.profile.fullName,
      ProfileShareAttribute.email => widget.profile.email,
      ProfileShareAttribute.phone => widget.profile.phone,
      ProfileShareAttribute.homeAddress => widget.profile.address,
      ProfileShareAttribute.socialLinks => widget.profile.socialLinks,
    };
  }
}

class _ShareTopBar extends StatelessWidget {
  const _ShareTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.stroke),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 21,
                color: palette.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileShareHero extends StatelessWidget {
  const _ProfileShareHero({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileShareTitle,
          style: TextStyle(
            fontFamily: _profileShareFontDisplay,
            fontSize: 42,
            height: 0.98,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.profileShareSubtitle,
          style: TextStyle(
            fontFamily: _profileShareFontBody,
            fontSize: 17,
            height: 1.42,
            fontWeight: FontWeight.w500,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _profileInitials(profile),
                  style: TextStyle(
                    fontFamily: _profileShareFontMono,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _profileShareFontDisplay,
                        fontSize: 18,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.profileShareSecureLink,
                      style: TextStyle(
                        fontFamily: _profileShareFontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 22,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareAttributesCard extends StatelessWidget {
  const _ShareAttributesCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: palette.stroke.withValues(alpha: 0.58),
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _ShareInfoCard extends StatelessWidget {
  const _ShareInfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.stroke),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: _profileShareFontDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: _profileShareFontBody,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareBottomAction extends StatelessWidget {
  const _ShareBottomAction({required this.isBusy, required this.onShare});

  final bool isBusy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.appPalette;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
        decoration: BoxDecoration(
          color: palette.background,
          border: Border(
            top: BorderSide(color: palette.stroke.withValues(alpha: 0.72)),
          ),
        ),
        child: SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: isBusy ? null : onShare,
            icon: isBusy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.background,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded, size: 21),
            label: Text(
              isBusy ? l10n.profileShareGenerating : l10n.profileShareAction,
              style: TextStyle(
                fontFamily: _profileShareFontDisplay,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.textPrimary,
              foregroundColor: palette.background,
              disabledBackgroundColor: palette.textMuted.withValues(
                alpha: 0.25,
              ),
              disabledForegroundColor: palette.background.withValues(
                alpha: 0.62,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareAttributeTile extends StatelessWidget {
  const _ShareAttributeTile({
    required this.attribute,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final ProfileShareAttribute attribute;
  final String value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_iconFor(attribute), color: palette.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _attributeTitle(context, attribute),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _profileShareFontDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.trim().isEmpty
                      ? context.l10n.profileShareEmptyAttributeValue
                      : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _profileShareFontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Switch.adaptive(
            value: enabled,
            activeTrackColor: palette.textPrimary,
            activeThumbColor: Colors.white,
            inactiveTrackColor: palette.strokeStrong.withValues(alpha: 0.42),
            inactiveThumbColor: palette.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ProfileShareAttribute attribute) {
    return switch (attribute) {
      ProfileShareAttribute.fullName => Icons.person_rounded,
      ProfileShareAttribute.email => Icons.mail_rounded,
      ProfileShareAttribute.phone => Icons.phone_rounded,
      ProfileShareAttribute.homeAddress => Icons.location_on_rounded,
      ProfileShareAttribute.socialLinks => Icons.link_rounded,
    };
  }
}

String _attributeTitle(BuildContext context, ProfileShareAttribute attribute) {
  final l10n = context.l10n;
  return switch (attribute) {
    ProfileShareAttribute.fullName => l10n.profileFullName,
    ProfileShareAttribute.email => l10n.profileEmailAddress,
    ProfileShareAttribute.phone => l10n.profilePhoneNumber,
    ProfileShareAttribute.homeAddress => l10n.profileHomeAddress,
    ProfileShareAttribute.socialLinks => l10n.profileSocialLinks,
  };
}

String _profileInitials(ProfileEntity profile) {
  final parts = profile.fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'VO';
  }
  final first = parts.first.characters.first;
  final second = parts.length > 1 ? parts.last.characters.first : '';
  return '$first$second'.toUpperCase();
}
