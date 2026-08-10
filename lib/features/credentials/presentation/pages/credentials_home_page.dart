import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_security_status.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_list_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_list_state.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/company_logo_avatar.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

typedef HomeProfileLoader = Future<ProfileEntity?> Function();
typedef HomeCredentialDetailOpener =
    Future<void> Function(BuildContext context, String credentialId);

class CredentialsHomePage extends StatefulWidget {
  const CredentialsHomePage({
    super.key,
    required this.horizontalPadding,
    required this.onOpenCredentialsTap,
    required this.onOpenCredentialDetail,
    required this.loadProfile,
  });

  final double horizontalPadding;
  final VoidCallback onOpenCredentialsTap;
  final HomeCredentialDetailOpener onOpenCredentialDetail;
  final HomeProfileLoader loadProfile;

  @override
  State<CredentialsHomePage> createState() => _CredentialsHomePageState();
}

class _CredentialsHomePageState extends State<CredentialsHomePage> {
  ProfileEntity? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.loadProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
      });
    } catch (_) {
      // Keep default fallback header when profile is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final firstName = _profile?.firstName.trim() ?? '';
    final lastName = _profile?.lastName.trim() ?? '';
    final fullName = '$firstName $lastName'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final hasName = fullName.isNotEmpty;
    final avatarImage = resolveLocalFileImageProvider(_profile?.photoPath);
    final welcomeBackLabel = _welcomeBackFallbackLabel(l10n.homeWelcomeBack);

    return BlocBuilder<CredentialListCubit, CredentialListState>(
      builder: (context, state) {
        if (state.status == CredentialListStatus.loading ||
            state.status == CredentialListStatus.initial) {
          return Center(child: CupertinoActivityIndicator(radius: 12));
        }

        if (state.status == CredentialListStatus.error) {
          return Center(
            child: Text(
              state.errorMessage ?? l10n.credentialsUnableLoadVaultOverview,
              style: TextStyle(
                color: context.appPalette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final items = state.items;
        final warningItem = items.cast<CredentialSummaryEntity?>().firstWhere(
          (item) => item?.status == CredentialSecurityStatus.warning,
          orElse: () => null,
        );
        final byRecentUsage = [...items]
          ..sort((a, b) {
            final aTime = a.lastUsedAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.lastUsedAt?.millisecondsSinceEpoch ?? 0;
            final byTime = bTime.compareTo(aTime);
            if (byTime != 0) {
              return byTime;
            }
            return a.displayName.compareTo(b.displayName);
          });
        final frequentItems = byRecentUsage.take(3).toList(growable: false);
        final recentItems = byRecentUsage.take(4).toList(growable: false);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            widget.horizontalPadding,
            12,
            widget.horizontalPadding,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDEC7),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appPalette.stroke),
                    ),
                    alignment: Alignment.center,
                    child: avatarImage == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 21,
                          )
                        : ClipOval(
                            child: Image(
                              image: avatarImage,
                              fit: BoxFit.cover,
                              width: 52,
                              height: 52,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasName) ...[
                          Text(
                            l10n.homeWelcomeBack,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6E7E95),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            fullName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.appPalette.textPrimary,
                              height: 1.0,
                            ),
                          ),
                        ] else
                          Text(
                            welcomeBackLabel,
                            style: TextStyle(
                              fontSize: 32 / 1.55,
                              fontWeight: FontWeight.w700,
                              color: context.appPalette.textPrimary,
                              height: 1.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: widget.onOpenCredentialsTap,
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.appPalette.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.appPalette.stroke),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF8A98AD),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.homeSearchVaultDocuments,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF95A4BA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.homeActionRequired,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appPalette.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              if (warningItem != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.appPalette.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.appPalette.stroke),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: context.appPalette.surfaceSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF29918),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              warningItem.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 30 / 1.7,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF172033),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.homeSecurityCheckRecommended,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E8EA7),
                              ),
                            ),
                            SizedBox(height: 9),
                            TextButton(
                              onPressed: () =>
                                  _openDetail(context, warningItem.id),
                              style: TextButton.styleFrom(
                                foregroundColor: context.appPalette.primary,
                                backgroundColor: context.appPalette.primarySoft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                l10n.homeReviewNow,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.appPalette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.appPalette.stroke),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF2DBA7C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.homeAllCredentialsSecure,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5C6D84),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    l10n.homeFrequentlyUsed,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 116,
                child: frequentItems.isEmpty
                    ? _MobileHomeEmptyCard(
                        label: l10n.homeNoQuickItemsYet,
                        onTap: widget.onOpenCredentialsTap,
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: frequentItems.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = frequentItems[index];
                          final relativeTime = _relativeTimeLabel(
                            context,
                            item.lastUsedAt,
                          );
                          return _MobileHomeQuickItem(
                            item: item,
                            subtitle: relativeTime,
                            onTap: () => _openDetail(context, item.id),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    l10n.homeRecentItems,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onOpenCredentialsTap,
                    child: Text(
                      l10n.commonViewAll,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (recentItems.isEmpty)
                _MobileHomeEmptyCard(
                  label: l10n.homeRecentActivityPlaceholder,
                  onTap: widget.onOpenCredentialsTap,
                )
              else
                ...recentItems.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == recentItems.length - 1 ? 0 : 10,
                    ),
                    child: _MobileHomeRecentItem(
                      item: entry.value,
                      subtitle: _recentItemSubtitle(context, entry.value),
                      onTap: () => _openDetail(context, entry.value.id),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _welcomeBackFallbackLabel(String rawValue) {
    final sanitized = rawValue.replaceAll(RegExp(r'[\s,.;:!?]+$'), '').trim();
    return sanitized.isEmpty ? rawValue.trim() : sanitized;
  }

  String _relativeTimeLabel(BuildContext context, DateTime? value) {
    final l10n = context.l10n;
    if (value == null) {
      return '';
    }
    final now = DateTime.now();
    var delta = now.difference(value);
    if (delta.isNegative) {
      delta = Duration.zero;
    }
    if (delta.inSeconds < 60) {
      return l10n.homeRelativeJustNow;
    }
    if (delta.inMinutes < 60) {
      return l10n.homeRelativeMinutesAgo(delta.inMinutes);
    }
    if (delta.inHours < 24) {
      return l10n.homeRelativeHoursAgo(delta.inHours);
    }
    if (delta.inDays == 1) {
      return l10n.homeRelativeYesterday;
    }
    if (delta.inDays < 7) {
      return l10n.homeRelativeDaysAgo(delta.inDays);
    }
    if (delta.inDays < 30) {
      return l10n.homeRelativeWeeksAgo((delta.inDays / 7).floor());
    }
    return l10n.homeRelativeMonthsAgo((delta.inDays / 30).floor());
  }

  String _recentItemSubtitle(
    BuildContext context,
    CredentialSummaryEntity item,
  ) {
    final relativeTime = _relativeTimeLabel(context, item.lastUsedAt);
    if (relativeTime.isEmpty) {
      return '';
    }
    final username = item.username.trim();
    if (username.isEmpty) {
      return relativeTime;
    }
    return context.l10n.homeLastUsedWithTime(username, relativeTime);
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    await widget.onOpenCredentialDetail(context, id);
    if (!context.mounted) {
      return;
    }
    await context.read<CredentialListCubit>().load();
  }
}

class _MobileHomeQuickItem extends StatelessWidget {
  const _MobileHomeQuickItem({
    required this.item,
    required this.subtitle,
    required this.onTap,
  });

  final CredentialSummaryEntity item;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: 110,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.appPalette.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: CompanyLogoAvatar(
                serviceName: item.displayName,
                serviceUrl: _deriveServiceUrl(item.displayName),
                localImagePath: item.logoPath,
                size: 26,
                borderRadius: BorderRadius.circular(999),
                fallbackColor: Color(item.brandHex),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2438),
              ),
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8F9FB5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileHomeRecentItem extends StatelessWidget {
  const _MobileHomeRecentItem({
    required this.item,
    required this.subtitle,
    required this.onTap,
  });

  final CredentialSummaryEntity item;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.appPalette.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: CompanyLogoAvatar(
                serviceName: item.displayName,
                serviceUrl: _deriveServiceUrl(item.displayName),
                localImagePath: item.logoPath,
                size: 31,
                borderRadius: BorderRadius.circular(12),
                fallbackColor: Color(item.brandHex),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF71839F),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: Color(0xFFC4CFDE),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileHomeEmptyCard extends StatelessWidget {
  const _MobileHomeEmptyCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E9DB4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

String _deriveServiceUrl(String serviceName) {
  final normalized = serviceName.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '',
  );
  if (normalized.isEmpty) {
    return 'www.account.com';
  }
  return 'www.$normalized.com';
}
