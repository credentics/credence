import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';
import 'package:pass_doc_manager/domain/profile/usecases/generate_secure_profile_link.dart';
import 'package:pass_doc_manager/domain/profile/usecases/get_profile_dashboard.dart';
import 'package:pass_doc_manager/domain/profile/usecases/get_profile_share_options.dart';
import 'package:pass_doc_manager/domain/profile/usecases/save_profile.dart';
import 'package:pass_doc_manager/domain/profile/usecases/save_profile_share_options.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/pages/credential_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/profile/presentation/cubit/profile_dashboard_cubit.dart';
import 'package:pass_doc_manager/features/profile/presentation/cubit/profile_dashboard_state.dart';
import 'package:pass_doc_manager/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:pass_doc_manager/features/profile/presentation/pages/share_profile_page.dart';
import 'package:pass_doc_manager/features/settings/presentation/pages/vault_sync_settings_page.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/cubit/vault_health_cubit.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/pages/vault_health_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const _profileFontDisplay = 'Manrope';
const _profileFontMono = 'JetBrains Mono';

class ProfilePage extends StatefulWidget {
  ProfilePage({
    super.key,
    GetProfileDashboard? getProfileDashboard,
    SaveProfile? saveProfile,
    GetProfileShareOptions? getProfileShareOptions,
    SaveProfileShareOptions? saveProfileShareOptions,
    GenerateSecureProfileLink? generateSecureProfileLink,
  }) : getProfileDashboard = getProfileDashboard ?? getIt(),
       saveProfile = saveProfile ?? getIt(),
       getProfileShareOptions = getProfileShareOptions ?? getIt(),
       saveProfileShareOptions = saveProfileShareOptions ?? getIt(),
       generateSecureProfileLink = generateSecureProfileLink ?? getIt();

  final GetProfileDashboard getProfileDashboard;
  final SaveProfile saveProfile;
  final GetProfileShareOptions getProfileShareOptions;
  final SaveProfileShareOptions saveProfileShareOptions;
  final GenerateSecureProfileLink generateSecureProfileLink;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ProfileDashboardCubit(
      getProfileDashboard: widget.getProfileDashboard,
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
      child: BlocBuilder<ProfileDashboardCubit, ProfileDashboardState>(
        builder: (context, state) {
          final l10n = context.l10n;
          final palette = context.appPalette;
          final profile = state.profile;

          if (state.status == ProfileDashboardStatus.loading &&
              profile == null) {
            return ColoredBox(
              color: palette.background,
              child: const Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          if (state.status == ProfileDashboardStatus.error && profile == null) {
            return ColoredBox(
              color: palette.background,
              child: VaultErrorState(
                icon: Icons.person_off_rounded,
                message: state.errorMessage ?? l10n.profileUnableLoad,
                onRetry: _cubit.load,
              ),
            );
          }

          if (profile == null) {
            return ColoredBox(
              color: palette.background,
              child: _ErrorState(
                message: l10n.profileUnableLoad,
                onRetry: _cubit.load,
              ),
            );
          }

          final isDesktop =
              DesktopPlatform.isDesktop ||
              MediaQuery.sizeOf(context).width >=
                  DesktopPlatform.sidebarBreakpoint;

          return ColoredBox(
            color: palette.background,
            child: SafeArea(
              top: isDesktop,
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _cubit.load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ProfileContent(
                        profile: profile,
                        isDesktop: isDesktop,
                        onEdit: () => _openEditProfile(profile),
                        onShare: () => _openShareProfile(profile),
                        onVaultHealth: _openVaultHealth,
                        onSettings: _openSettings,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openVaultHealth() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: getIt<VaultHealthCubit>(),
          child: VaultHealthPage(
            onNavigateToCredential: (ctx, credentialId) {
              Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        CredentialDetailCubit()
                          ..load(credentialId: credentialId),
                    child: CredentialDetailPage(),
                  ),
                ),
              );
            },
            onNavigateToDocument: (ctx, documentId) {
              Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => DocumentDetailPage(documentId: documentId),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openEditProfile(ProfileEntity profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditProfilePage(
          initialProfile: profile,
          saveProfile: widget.saveProfile,
        ),
      ),
    );

    if (updated == true) {
      await _cubit.load();
    }
  }

  Future<void> _openShareProfile(ProfileEntity profile) async {
    if (!_hasAccountDetails(profile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileAddAccountDetailsFirst)),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ShareProfilePage(
          profile: profile,
          getProfileShareOptions: widget.getProfileShareOptions,
          saveProfileShareOptions: widget.saveProfileShareOptions,
          generateSecureProfileLink: widget.generateSecureProfileLink,
        ),
      ),
    );

    await _cubit.load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => VaultSyncSettingsPage()),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isDesktop,
    required this.onEdit,
    required this.onShare,
    required this.onVaultHealth,
    required this.onSettings,
  });

  final ProfileEntity profile;
  final bool isDesktop;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onVaultHealth;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final maxWidth = isDesktop ? 560.0 : double.infinity;
    final palette = context.appPalette;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 14,
            isDesktop ? 12 : 0,
            isDesktop ? 24 : 14,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileTopBar(
                isDesktop: isDesktop,
                onSettings: onSettings,
                onEdit: onEdit,
              ),
              const SizedBox(height: 12),
              _ProfileHero(profile: profile, onEdit: onEdit),
              const SizedBox(height: 18),
              _ProfileGroupHeader('YOUR DETAILS'),
              const SizedBox(height: 8),
              _ProfileDetailsCard(profile: profile, onEdit: onEdit),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Credence does not have an account system. These details stay local and are only used when you choose to share a profile card.',
                  style: TextStyle(
                    fontFamily: _profileFontDisplay,
                    fontSize: 10.5,
                    height: 1.45,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _ProfileGroupHeader('SHARE'),
              const SizedBox(height: 8),
              _ShareCard(
                hasShareableDetails: _hasAccountDetails(profile),
                onShare: onShare,
              ),
              const SizedBox(height: 18),
              _ProfileGroupHeader('DEVICES'),
              const SizedBox(height: 8),
              _DevicesCard(profile: profile),
              const SizedBox(height: 18),
              _ProfileGroupHeader('SECURITY'),
              const SizedBox(height: 8),
              _SecurityCard(onVaultHealth: onVaultHealth),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.isDesktop,
    required this.onSettings,
    required this.onEdit,
  });

  final bool isDesktop;
  final VoidCallback onSettings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final canPop = Navigator.of(context).canPop();

    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: isDesktop
                ? const SizedBox(width: 88)
                : TextButton(
                    onPressed: canPop
                        ? () => Navigator.of(context).pop()
                        : onSettings,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textSecondary,
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontFamily: _profileFontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(canPop ? '‹ Settings' : 'Settings'),
                  ),
          ),
          Text(
            'Profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _profileFontDisplay,
              color: palette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: palette.textPrimary,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: _profileFontDisplay,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onEdit});

  final ProfileEntity profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final image = resolveLocalFileImageProvider(profile.photoPath);
    final subtitle = _profileSubtitle(profile);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF211A34), Color(0xFF25231F)]
              : const [Color(0xFFEDE3FA), Color(0xFFF8F1D6)],
        ),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? palette.stroke
              : Colors.white.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onEdit,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF51465B), Color(0xFF201D29)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: image == null
                        ? Center(
                            child: Text(
                              _initials(profile),
                              style: const TextStyle(
                                fontFamily: _profileFontDisplay,
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                          )
                        : Image(image: image, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: palette.textPrimary,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _profileFontDisplay,
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _profileFontMono,
              color: palette.textSecondary,
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGroupHeader extends StatelessWidget {
  const _ProfileGroupHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: _profileFontMono,
          color: palette.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.65,
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.profile, required this.onEdit});

  final ProfileEntity profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = [
      _DetailRowData(label: 'DISPLAY NAME', value: profile.fullName),
      _DetailRowData(
        label: 'EMAIL · LOCAL ONLY',
        value: profile.email.trim().isEmpty
            ? l10n.profileNotProvided
            : profile.email.trim(),
        muted: profile.email.trim().isEmpty,
      ),
      _DetailRowData(
        label: 'PHONE · LOCAL ONLY',
        value: profile.phone.trim().isEmpty
            ? l10n.profileNotProvided
            : profile.phone.trim(),
        muted: profile.phone.trim().isEmpty,
      ),
      _DetailRowData(
        label: 'ADDRESS',
        value: profile.address.trim().isEmpty
            ? l10n.profileNotProvided
            : profile.address.trim(),
        muted: profile.address.trim().isEmpty,
      ),
      _DetailRowData(
        label: 'SOCIAL LINKS',
        value: profile.socialLinks.trim().isEmpty
            ? l10n.profileNotProvided
            : profile.socialLinks.trim(),
        muted: profile.socialLinks.trim().isEmpty,
      ),
    ];

    return _SetCard(
      children: [
        for (final row in rows)
          _ReferenceInfoRow(
            label: row.label,
            value: row.value,
            muted: row.muted,
            onTap: onEdit,
          ),
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.hasShareableDetails, required this.onShare});

  final bool hasShareableDetails;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return _SetCard(
      children: [
        _ReferenceNavRow(
          icon: Icons.ios_share_rounded,
          title: 'Generate secure profile card',
          subtitle: hasShareableDetails
              ? 'Receiver sees only the fields you toggle on.'
              : 'Add a name, email or phone before sharing.',
          trailing: const _OptInToggle(isOn: false),
          onTap: hasShareableDetails ? onShare : null,
        ),
        _ReferenceNavRow(
          icon: Icons.share_rounded,
          title: 'AirDrop my profile card',
          subtitle: 'vCard with selected details. No vault data is included.',
          onTap: hasShareableDetails ? onShare : null,
        ),
      ],
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return _SetCard(
      children: [
        _ReferenceNavRow(
          icon: Icons.phone_iphone_rounded,
          title: 'This device',
          subtitle:
              'Profile updated ${_formatDate(context, profile.updatedAt)}',
          badge: 'PRIMARY',
          showChevron: false,
        ),
        const _ReferenceNavRow(
          icon: Icons.laptop_mac_rounded,
          title: 'Restored devices',
          subtitle: 'Devices appear only after encrypted restore.',
          badge: 'LOCAL',
          showChevron: false,
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.onVaultHealth});

  final VoidCallback onVaultHealth;

  @override
  Widget build(BuildContext context) {
    return _SetCard(
      children: [
        _ReferenceNavRow(
          icon: Icons.health_and_safety_rounded,
          title: context.l10n.vaultHealthPageTitle,
          subtitle: 'Review weak passwords, reused items, and expiring docs.',
          badge: 'CHECK',
          onTap: onVaultHealth,
        ),
        const _ReferenceNavRow(
          icon: Icons.lock_rounded,
          title: 'Local profile storage',
          subtitle: 'No cloud account. No automatic profile sharing.',
          badge: 'PRIVATE',
          showChevron: false,
        ),
      ],
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.stroke),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) Divider(height: 1, color: palette.stroke),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _ReferenceInfoRow extends StatelessWidget {
  const _ReferenceInfoRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: _profileFontMono,
                  color: palette.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _profileFontDisplay,
                  color: muted ? palette.textMuted : palette.textPrimary,
                  fontSize: 14.5,
                  height: 1.22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.05,
                  fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceNavRow extends StatelessWidget {
  const _ReferenceNavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.badge,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? badge;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: palette.textPrimary, size: 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _profileFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _profileFontDisplay,
                        color: palette.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                trailing!
              else if (badge != null)
                Text(
                  badge!,
                  style: TextStyle(
                    fontFamily: _profileFontMono,
                    color: badge == 'PRIMARY' || badge == 'PRIVATE'
                        ? palette.success
                        : palette.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.textMuted,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptInToggle extends StatelessWidget {
  const _OptInToggle({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: 42,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isOn ? palette.primary : palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.stroke),
      ),
      child: Align(
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: palette.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;
}

bool _hasAccountDetails(ProfileEntity? profile) {
  if (profile == null) {
    return false;
  }
  final hasName =
      profile.firstName.trim().isNotEmpty || profile.lastName.trim().isNotEmpty;
  return hasName ||
      profile.email.trim().isNotEmpty ||
      profile.phone.trim().isNotEmpty;
}

String _profileSubtitle(ProfileEntity profile) {
  final parts = <String>[];
  if (profile.email.trim().isNotEmpty) {
    parts.add(profile.email.trim());
  }
  if (profile.phone.trim().isNotEmpty) {
    parts.add(profile.phone.trim());
  }
  parts.add('Local profile');
  return parts.join(' · ').toUpperCase();
}

String _initials(ProfileEntity profile) {
  final first = profile.firstName.trim();
  final last = profile.lastName.trim();
  final firstInitial = first.isEmpty ? '' : first.characters.first;
  final lastInitial = last.isEmpty ? '' : last.characters.first;
  final value = (firstInitial + lastInitial).trim();
  return value.isEmpty ? 'V' : value.toUpperCase();
}

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 52, color: palette.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
