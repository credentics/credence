import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/core/utils/sensitive_clipboard.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/delete_credential.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/mark_credential_used.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/toggle_credential_favorite.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/update_credential.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_state.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credential_edit_sheet.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credentials_reference_ui.dart';
// TODO: Re-enable when Secure Share is ready
// import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';
// import 'package:pass_doc_manager/features/secure_share/presentation/pages/secure_share_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class CredentialDetailPage extends StatelessWidget {
  CredentialDetailPage({
    super.key,
    MarkCredentialUsed? markCredentialUsed,
    UpdateCredential? updateCredential,
    ToggleCredentialFavorite? toggleCredentialFavorite,
    SearchCompanyBrands? searchCompanyBrands,
    DownloadCompanyLogoToLocal? downloadCompanyLogoToLocal,
    EvaluatePasswordHealth? evaluatePasswordHealth,
  }) : markCredentialUsed = markCredentialUsed ?? getIt(),
       updateCredential = updateCredential ?? getIt(),
       toggleCredentialFavorite = toggleCredentialFavorite ?? getIt(),
       searchCompanyBrands = searchCompanyBrands ?? getIt(),
       downloadCompanyLogoToLocal = downloadCompanyLogoToLocal ?? getIt(),
       evaluatePasswordHealth = evaluatePasswordHealth ?? getIt();

  final MarkCredentialUsed markCredentialUsed;
  final UpdateCredential updateCredential;
  final ToggleCredentialFavorite toggleCredentialFavorite;
  final SearchCompanyBrands searchCompanyBrands;
  final DownloadCompanyLogoToLocal downloadCompanyLogoToLocal;
  final EvaluatePasswordHealth evaluatePasswordHealth;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CredentialDetailCubit, CredentialDetailState>(
      builder: (context, state) {
        if (state.status == CredentialDetailStatus.initial ||
            state.status == CredentialDetailStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == CredentialDetailStatus.error ||
            state.detail == null) {
          return Scaffold(
            body: Center(
              child: Text(
                state.errorMessage ?? context.l10n.credentialsUnableLoadSingle,
              ),
            ),
          );
        }

        return _DetailScene(
          detail: state.detail!,
          markCredentialUsed: markCredentialUsed,
          updateCredential: updateCredential,
          toggleCredentialFavorite: toggleCredentialFavorite,
          searchCompanyBrands: searchCompanyBrands,
          downloadCompanyLogoToLocal: downloadCompanyLogoToLocal,
          evaluatePasswordHealth: evaluatePasswordHealth,
        );
      },
    );
  }
}

class _DetailScene extends StatefulWidget {
  const _DetailScene({
    required this.detail,
    required this.markCredentialUsed,
    required this.updateCredential,
    required this.toggleCredentialFavorite,
    required this.searchCompanyBrands,
    required this.downloadCompanyLogoToLocal,
    required this.evaluatePasswordHealth,
  });

  final CredentialDetailEntity detail;
  final MarkCredentialUsed markCredentialUsed;
  final UpdateCredential updateCredential;
  final ToggleCredentialFavorite toggleCredentialFavorite;
  final SearchCompanyBrands searchCompanyBrands;
  final DownloadCompanyLogoToLocal downloadCompanyLogoToLocal;
  final EvaluatePasswordHealth evaluatePasswordHealth;

  @override
  State<_DetailScene> createState() => _DetailSceneState();
}

class _DetailSceneState extends State<_DetailScene> {
  bool _isSaving = false;
  bool _isPasswordVisible = false;
  bool _showCopyToast = false;
  Timer? _copyToastTimer;

  @override
  void dispose() {
    _copyToastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1080;
        return CredentialsReferencePage(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 760 : double.infinity,
                  ),
                  child: Stack(
                    children: [
                      _detail(context, isDesktop: isDesktop),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 26,
                        child: IgnorePointer(
                          ignoring: !_showCopyToast,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _showCopyToast ? 1 : 0,
                            child: const Center(
                              child: CredentialsCopyToast(
                                message: 'Password copied · clears in 30 s',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detail(BuildContext context, {required bool isDesktop}) {
    final detail = widget.detail;
    final serviceUrl = _normalizeCredentialUrl(detail.url);
    final accountMeta = [
      detail.category.label.toUpperCase(),
      if (detail.accountLabel.trim().isNotEmpty)
        detail.accountLabel.trim().toUpperCase(),
    ].join(' · ');
    final score = detail.isSecure ? 96 : 44;
    final strength = detail.isSecure ? 'Strong' : 'Weak';

    return Column(
      children: [
        CredentialsHeader(
          title: detail.serviceName,
          centerTitle: true,
          leading: CredentialsIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CredentialsIconButton(
                icon: detail.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                onTap: _toggleFavorite,
              ),
              const SizedBox(width: 8),
              CredentialsIconButton(
                icon: Icons.more_horiz_rounded,
                onTap: _showMoreActions,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
            children: [
              CredentialsCard(
                color: CredentialsReferenceColors.blue,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CredentialsBrandAvatar(
                          serviceName: detail.serviceName,
                          serviceUrl: serviceUrl,
                          logoPath: detail.logoPath,
                          brandHex: detail.brandHex,
                          size: 56,
                          radius: 14,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                accountMeta.isEmpty ? 'LOGIN' : accountMeta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: credentialsMonoStyle(
                                  size: 10,
                                  color: const Color(0xFF526476),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                detail.serviceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: credentialsDisplayStyle(size: 22),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${serviceUrl.isEmpty ? 'No URL' : serviceUrl} · ${detail.lastSecurityUpdate}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: credentialsMonoStyle(
                                  size: 11,
                                  color: const Color(0xFF526476),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        CredentialsPill(
                          label: '$strength · $score/100',
                          tone: detail.isSecure
                              ? CredentialsPillTone.ok
                              : CredentialsPillTone.risk,
                        ),
                        CredentialsPill(
                          label: detail.breachedCount > 0
                              ? '${detail.breachedCount} breach'
                              : 'Not breached',
                          tone: detail.breachedCount > 0
                              ? CredentialsPillTone.risk
                              : CredentialsPillTone.ghost,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Column(
                children: [
                  CredentialsField(
                    label: 'Email · username',
                    value: detail.username,
                    actions: [
                      CredentialsFieldAction(
                        icon: Icons.copy_rounded,
                        onTap: () => _copy(detail.username, 'Username copied.'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CredentialsField(
                    label: 'Password',
                    focused: true,
                    value: _isPasswordVisible
                        ? detail.password
                        : _obscured(detail.password),
                    valueStyle: credentialsMonoStyle(
                      size: 15,
                      weight: FontWeight.w500,
                      color: CredentialsReferenceColors.fg,
                      letterSpacing: _isPasswordVisible ? 0.2 : 1.4,
                    ),
                    actions: [
                      CredentialsFieldAction(
                        icon: _isPasswordVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        onTap: _togglePasswordVisibility,
                      ),
                      CredentialsFieldAction(
                        icon: Icons.copy_rounded,
                        onTap: () => _copyPassword(detail.password),
                        active: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CredentialsField(
                    label: 'URL',
                    value: serviceUrl.isEmpty ? 'No URL saved' : serviceUrl,
                    valueStyle: credentialsMonoStyle(
                      size: 13.5,
                      weight: FontWeight.w500,
                      color: serviceUrl.isEmpty
                          ? CredentialsReferenceColors.muted
                          : CredentialsReferenceColors.fg,
                      letterSpacing: 0,
                    ),
                    actions: [
                      if (serviceUrl.isNotEmpty)
                        CredentialsFieldAction(
                          icon: Icons.open_in_new_rounded,
                          onTap: () => _openUrl(serviceUrl),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const CredentialsSectionLabel('Actions'),
              const SizedBox(height: 8),
              CredentialsListGroup(
                children: [
                  CredentialsQuickAction(
                    icon: Icons.open_in_new_rounded,
                    label: serviceUrl.isEmpty
                        ? 'No website saved'
                        : 'Open ${Uri.tryParse(serviceUrl)?.host ?? serviceUrl}',
                    meta: serviceUrl.isEmpty ? null : 'Safari',
                    onTap: serviceUrl.isEmpty
                        ? null
                        : () => _openUrl(serviceUrl),
                  ),
                  CredentialsQuickAction(
                    icon: Icons.favorite_border_rounded,
                    label: detail.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onTap: _toggleFavorite,
                  ),
                  CredentialsQuickAction(
                    icon: Icons.edit_rounded,
                    label: 'Edit credential',
                    onTap: _openEdit,
                  ),
                  CredentialsQuickAction(
                    icon: Icons.delete_outline_rounded,
                    label: context.l10n.credentialDeleteAction,
                    meta: 'undoable 5 s',
                    danger: true,
                    onTap: () => _deleteCredential(context),
                  ),
                ],
              ),
              if (detail.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const CredentialsSectionLabel('Notes'),
                const SizedBox(height: 8),
                Text(
                  detail.notes.trim(),
                  style: credentialsBodyStyle(
                    size: 13.5,
                    color: CredentialsReferenceColors.fg.withValues(
                      alpha: 0.84,
                    ),
                    height: 1.55,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCredential(BuildContext context) async {
    final palette = context.appPalette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Credential?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete "${widget.detail.serviceName}". This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: palette.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final deleteUseCase = getIt<DeleteCredential>();
      await deleteUseCase(DeleteCredentialParams(id: widget.detail.id));
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.credentialDeleteFailed)),
      );
    }
  }

  Future<void> _saveChanges(CredentialEditorResult result) async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.updateCredential(
        credentialId: widget.detail.id,
        draft: result.toDraftEntity(),
      );
      if (!mounted) {
        return;
      }
      await context.read<CredentialDetailCubit>().load(
        credentialId: widget.detail.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.credentialsUpdated)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.credentialsUnableUpdate)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openEdit() async {
    if (_isSaving) {
      return;
    }

    CredentialEditorResult? result;
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    if (isDesktop) {
      result = await showDialog<CredentialEditorResult>(
        context: context,
        builder: (_) => Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 860),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CredentialEditSheet.edit(
                detail: widget.detail,
                startInEdit: true,
                searchCompanyBrands: widget.searchCompanyBrands,
                downloadCompanyLogoToLocal: widget.downloadCompanyLogoToLocal,
                evaluatePasswordHealth: widget.evaluatePasswordHealth,
                presentation: CredentialSheetPresentation.embedded,
                onPasswordUsed: () =>
                    widget.markCredentialUsed(credentialId: widget.detail.id),
              ),
            ),
          ),
        ),
      );
    } else {
      result = await showModalBottomSheet<CredentialEditorResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => CredentialEditSheet.edit(
          detail: widget.detail,
          startInEdit: true,
          searchCompanyBrands: widget.searchCompanyBrands,
          downloadCompanyLogoToLocal: widget.downloadCompanyLogoToLocal,
          evaluatePasswordHealth: widget.evaluatePasswordHealth,
          onPasswordUsed: () =>
              widget.markCredentialUsed(credentialId: widget.detail.id),
        ),
      );
    }

    if (result == null) {
      return;
    }
    await _saveChanges(result);
  }

  Future<void> _copy(String value, String message) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: trimmed));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyPassword(String password) async {
    await SensitiveClipboard.copy(password);
    try {
      await widget.markCredentialUsed(credentialId: widget.detail.id);
    } catch (_) {
      // Copy should still succeed even if updating last-used metadata fails.
    }
    if (!mounted) {
      return;
    }
    await context.read<CredentialDetailCubit>().load(
      credentialId: widget.detail.id,
    );
    if (!mounted) {
      return;
    }
    _copyToastTimer?.cancel();
    setState(() {
      _showCopyToast = true;
    });
    _copyToastTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showCopyToast = false;
      });
    });
  }

  Future<void> _toggleFavorite() async {
    await widget.toggleCredentialFavorite(credentialId: widget.detail.id);
    if (!mounted) {
      return;
    }
    await context.read<CredentialDetailCubit>().load(
      credentialId: widget.detail.id,
    );
  }

  Future<void> _togglePasswordVisibility() async {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
    if (_isPasswordVisible) {
      try {
        await widget.markCredentialUsed(credentialId: widget.detail.id);
      } catch (_) {}
    }
  }

  Future<void> _openUrl(String raw) async {
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showMoreActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CredentialsReferenceTheme(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          decoration: const BoxDecoration(
            color: CredentialsReferenceColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CredentialsReferenceColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                CredentialsListGroup(
                  children: [
                    CredentialsQuickAction(
                      icon: Icons.edit_rounded,
                      label: 'Edit credential',
                      onTap: () {
                        Navigator.of(context).pop();
                        _openEdit();
                      },
                    ),
                    CredentialsQuickAction(
                      icon: Icons.delete_outline_rounded,
                      label: context.l10n.credentialDeleteAction,
                      danger: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        _deleteCredential(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _obscured(String value) {
    final count = value.length.clamp(8, 18);
    return List.filled(count, '•').join();
  }
}

String _normalizeCredentialUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return '';
  }
  return value.replaceFirst(RegExp(r'^https?://'), '');
}
