import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/generate_password.dart';
import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_draft_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credentials_reference_ui.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/password_health_controller.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/app_lock_service.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

enum CredentialEditorMode { edit, create }

enum CredentialSheetPresentation { modal, embedded }

class CredentialEditorResult {
  const CredentialEditorResult({
    required this.serviceName,
    required this.accountLabel,
    required this.username,
    required this.category,
    required this.password,
    required this.url,
    required this.notes,
    required this.brandHex,
    this.logoPath,
  });

  final String serviceName;
  final String accountLabel;
  final String username;
  final CredentialCategory category;
  final String password;
  final String url;
  final String notes;
  final int brandHex;
  final String? logoPath;

  CredentialDraftEntity toDraftEntity() {
    return CredentialDraftEntity(
      serviceName: serviceName,
      accountLabel: accountLabel,
      username: username,
      category: category,
      password: password,
      url: url,
      notes: notes,
      brandHex: brandHex,
      logoPath: logoPath,
    );
  }
}

class CredentialEditSheet extends StatefulWidget {
  const CredentialEditSheet.edit({
    super.key,
    required this.detail,
    required this.searchCompanyBrands,
    required this.downloadCompanyLogoToLocal,
    required this.evaluatePasswordHealth,
    this.onPasswordUsed,
    this.onSave,
    this.onCloseRequested,
    this.startInEdit = false,
    this.presentation = CredentialSheetPresentation.modal,
  }) : mode = CredentialEditorMode.edit;

  const CredentialEditSheet.create({
    super.key,
    required this.searchCompanyBrands,
    required this.downloadCompanyLogoToLocal,
    required this.evaluatePasswordHealth,
    this.onPasswordUsed,
    this.onSave,
    this.onCloseRequested,
    this.startInEdit = false,
    this.presentation = CredentialSheetPresentation.modal,
  }) : detail = null,
       mode = CredentialEditorMode.create;

  final CredentialEditorMode mode;
  final CredentialDetailEntity? detail;
  final SearchCompanyBrands searchCompanyBrands;
  final DownloadCompanyLogoToLocal downloadCompanyLogoToLocal;
  final EvaluatePasswordHealth evaluatePasswordHealth;
  final Future<void> Function()? onPasswordUsed;
  final Future<void> Function(CredentialEditorResult result)? onSave;
  final VoidCallback? onCloseRequested;
  final bool startInEdit;
  final CredentialSheetPresentation presentation;

  bool get isCreate => mode == CredentialEditorMode.create;

  @override
  State<CredentialEditSheet> createState() => _CredentialEditSheetState();
}

class _CredentialEditSheetState extends State<CredentialEditSheet> {
  late final ScrollController _scrollController;
  late final TextEditingController _serviceController;
  late final TextEditingController _accountLabelController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _urlController;
  late final TextEditingController _notesController;
  late final FocusNode _accountLabelFocusNode;
  late final FocusNode _usernameFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _urlFocusNode;
  late final FocusNode _notesFocusNode;

  late bool _isEditing;
  bool _isPasswordVisible = false;
  Timer? _serviceSearchDebounce;
  bool _isSearchingBrands = false;
  bool _isDownloadingLogo = false;
  bool _isUsernameCopied = false;
  bool _isPasswordCopied = false;
  Timer? _usernameCopiedTimer;
  Timer? _passwordCopiedTimer;
  late final PasswordHealthController _passwordHealthController;
  List<CompanyBrandSearchResultEntity> _serviceSuggestions = const [];
  String _selectedBrandIconUrl = '';
  String _selectedLocalLogoPath = '';
  CredentialCategory _selectedCategory = CredentialCategory.general;
  final GlobalKey _accountLabelFieldKey = GlobalKey();
  final GlobalKey _usernameFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _urlFieldKey = GlobalKey();
  final GlobalKey _notesFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    final detail = widget.detail;
    _serviceController = TextEditingController(text: detail?.serviceName ?? '');
    _accountLabelController = TextEditingController(
      text: detail?.accountLabel ?? '',
    );
    _usernameController = TextEditingController(text: detail?.username ?? '');
    _passwordController = TextEditingController(text: detail?.password ?? '');
    _urlController = TextEditingController(text: detail?.url ?? '');
    _notesController = TextEditingController(text: detail?.notes ?? '');
    _accountLabelFocusNode = FocusNode();
    _usernameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _urlFocusNode = FocusNode();
    _notesFocusNode = FocusNode();

    _isEditing = widget.isCreate || widget.startInEdit;
    _selectedLocalLogoPath = detail?.logoPath ?? '';
    _selectedCategory = detail?.category ?? CredentialCategory.general;
    _passwordHealthController = PasswordHealthController(
      evaluatePasswordHealth: widget.evaluatePasswordHealth,
    );
    _bindFocusScroll(_accountLabelFocusNode, _accountLabelFieldKey);
    _bindFocusScroll(_usernameFocusNode, _usernameFieldKey);
    _bindFocusScroll(_passwordFocusNode, _passwordFieldKey);
    _bindFocusScroll(_urlFocusNode, _urlFieldKey);
    _bindFocusScroll(_notesFocusNode, _notesFieldKey);
    _refreshPasswordHealth(immediate: true);
  }

  @override
  void dispose() {
    _serviceSearchDebounce?.cancel();
    _usernameCopiedTimer?.cancel();
    _passwordCopiedTimer?.cancel();
    _passwordHealthController.dispose();
    _scrollController.dispose();
    _serviceController.dispose();
    _accountLabelController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    _accountLabelFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _urlFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final shell = CredentialsReferenceTheme(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CredentialsReferenceColors.bg,
          borderRadius: widget.presentation == CredentialSheetPresentation.modal
              ? const BorderRadius.vertical(top: Radius.circular(30))
              : BorderRadius.zero,
        ),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Column(
              children: [
                if (widget.presentation == CredentialSheetPresentation.modal)
                  Container(
                    width: 34,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: CredentialsReferenceColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                _referenceHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(22, 8, 22, 18 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.isCreate &&
                            (widget.detail?.breachedCount ?? 0) > 0) ...[
                          CredentialsBreachBanner(
                            count: widget.detail!.breachedCount,
                            onGenerate: _generatePassword,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _referenceServiceCard(),
                        if (_isDownloadingLogo) ...[
                          const SizedBox(height: 8),
                          _logoSavingRow(),
                        ],
                        if (_serviceSuggestions.isNotEmpty ||
                            _isSearchingBrands) ...[
                          const SizedBox(height: 10),
                          _referenceLogoSuggestions(),
                        ],
                        const SizedBox(height: 14),
                        CredentialsSectionLabel(
                          widget.isCreate ? 'New login' : 'Credential fields',
                        ),
                        const SizedBox(height: 8),
                        _referenceFieldGroup(),
                        const SizedBox(height: 12),
                        _referenceStrengthCard(),
                        const SizedBox(height: 12),
                        _referenceCategoryCard(),
                        const SizedBox(height: 12),
                        _referenceNotesField(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.presentation == CredentialSheetPresentation.embedded) {
      return shell;
    }

    return FractionallySizedBox(heightFactor: 0.95, child: shell);
  }

  Widget _referenceHeader(BuildContext context) {
    final canSave =
        _serviceController.text.trim().isNotEmpty &&
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        !_isDownloadingLogo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Row(
        children: [
          CredentialsTextButton(
            label: context.l10n.commonCancel,
            onTap: _close,
            color: CredentialsReferenceColors.muted,
          ),
          Expanded(
            child: Text(
              widget.isCreate ? 'New credential' : 'Edit credential',
              textAlign: TextAlign.center,
              style: credentialsBodyStyle(size: 16, weight: FontWeight.w700),
            ),
          ),
          CredentialsTextButton(
            label: _primaryActionLabel,
            onTap: canSave ? _onPrimaryActionPressed : null,
            color: canSave
                ? CredentialsReferenceColors.fg
                : CredentialsReferenceColors.muted.withValues(alpha: 0.55),
            weight: canSave ? FontWeight.w700 : FontWeight.w600,
          ),
        ],
      ),
    );
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.onCloseRequested != null) {
      widget.onCloseRequested!.call();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _referenceServiceCard() {
    final service = _serviceController.text.trim();
    final url = _urlController.text.trim();
    final title = service.isEmpty ? 'Service' : service;
    final subtitle = [
      if (url.isNotEmpty) _prettyHost(url),
      if (_selectedLocalLogoPath.isNotEmpty) 'saved locally',
      'change icon',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CredentialsSectionLabel('Service'),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSearchingBrands || _isDownloadingLogo
                ? null
                : _searchBrandByWebsiteOrService,
            borderRadius: BorderRadius.circular(18),
            child: CredentialsCard(
              padding: const EdgeInsets.all(14),
              radius: 18,
              child: Row(
                children: [
                  CredentialsBrandAvatar(
                    serviceName: title,
                    serviceUrl: url,
                    imageUrl: _selectedBrandIconUrl,
                    logoPath: _selectedLocalLogoPath,
                    brandHex: widget.detail?.brandHex ?? _deriveBrandHex(title),
                    size: 56,
                    radius: 15,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: credentialsBodyStyle(
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: credentialsBodyStyle(
                            size: 12.5,
                            color: CredentialsReferenceColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: CredentialsReferenceColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoSavingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
        const SizedBox(width: 8),
        Text('Saving icon locally', style: credentialsMonoStyle(size: 10)),
      ],
    );
  }

  Widget _referenceLogoSuggestions() {
    return CredentialsCard(
      padding: const EdgeInsets.all(14),
      color: CredentialsReferenceColors.blue,
      borderColor: Colors.transparent,
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                _isSearchingBrands
                    ? 'SEARCHING BRAND DIRECTORY'
                    : '${_serviceSuggestions.length} RESULTS · BRAND DIRECTORY',
                style: credentialsMonoStyle(
                  size: 9.5,
                  color: const Color(0xFF526476),
                ),
              ),
              const Spacer(),
              if (_selectedBrandIconUrl.isNotEmpty ||
                  _selectedLocalLogoPath.isNotEmpty)
                GestureDetector(
                  onTap: _clearBrandSelection,
                  child: Text(
                    context.l10n.credentialsResetIcon,
                    style: credentialsBodyStyle(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: CredentialsReferenceColors.fg,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isSearchingBrands)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _serviceSuggestions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final item = _serviceSuggestions[index];
                final selected = item.iconUrl == _selectedBrandIconUrl;
                return GestureDetector(
                  onTap: () => unawaited(_applySuggestion(item)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? Border.all(
                                  color: CredentialsReferenceColors.fg,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: CredentialsBrandAvatar(
                          serviceName: item.name,
                          serviceUrl: item.domain,
                          imageUrl: item.iconUrl,
                          brandHex: _deriveBrandHex(item.name),
                          size: 48,
                          radius: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: credentialsBodyStyle(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: selected
                              ? CredentialsReferenceColors.fg
                              : CredentialsReferenceColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 10),
          Text(
            'Saved icon is kept locally and persists across restore. Switching the icon never clears other fields.',
            style: credentialsBodyStyle(
              size: 11.5,
              color: const Color(0xFF526476),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceFieldGroup() {
    return CredentialsCard(
      padding: const EdgeInsets.all(10),
      radius: 16,
      child: Column(
        children: [
          CredentialsInputField(
            label: 'URL',
            controller: _urlController,
            focusNode: _urlFocusNode,
            hint: 'notion.so/login',
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            actions: [
              CredentialsFieldAction(
                icon: Icons.travel_explore_rounded,
                onTap: _searchBrandByWebsiteOrService,
              ),
              CredentialsFieldAction(icon: Icons.copy_rounded, onTap: _copyUrl),
            ],
          ),
          const SizedBox(height: 8),
          CredentialsInputField(
            label: 'Service',
            controller: _serviceController,
            hint: context.l10n.credentialEditServicePlaceholder,
            onChanged: _onServiceChanged,
            focused: _serviceController.text.trim().isEmpty,
          ),
          const SizedBox(height: 8),
          CredentialsInputField(
            key: _accountLabelFieldKey,
            label: 'Account label',
            controller: _accountLabelController,
            focusNode: _accountLabelFocusNode,
            hint: 'Personal, work, billing...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          CredentialsInputField(
            key: _usernameFieldKey,
            label: 'Email · Username',
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            hint: 'maya@northwind.studio',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              setState(() {});
              _refreshPasswordHealth();
            },
            actions: [
              CredentialsFieldAction(
                icon: _isUsernameCopied
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                active: _isUsernameCopied,
                onTap: _usernameController.text.trim().isEmpty
                    ? null
                    : _copyUsername,
              ),
            ],
          ),
          const SizedBox(height: 8),
          CredentialsInputField(
            key: _passwordFieldKey,
            label: 'Password',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hint: 'Use a unique password',
            obscureText: !_isPasswordVisible,
            focused: true,
            onChanged: (_) {
              setState(() {});
              _refreshPasswordHealth();
            },
            actions: [
              CredentialsFieldAction(
                icon: Icons.auto_awesome_rounded,
                onTap: _generatePassword,
              ),
              CredentialsFieldAction(
                icon: _isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                onTap: () async {
                  if (_isPasswordVisible) {
                    setState(() => _isPasswordVisible = false);
                    return;
                  }
                  final ok = await _authenticateForReveal();
                  if (!mounted || !ok) {
                    return;
                  }
                  setState(() => _isPasswordVisible = true);
                },
              ),
              CredentialsFieldAction(
                icon: _isPasswordCopied
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                active: _isPasswordCopied,
                onTap: _passwordController.text.isEmpty ? null : _copyPassword,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referenceStrengthCard() {
    return AnimatedBuilder(
      animation: _passwordHealthController,
      builder: (context, _) {
        final report = _passwordHealthController.report;
        final isEmpty = _passwordController.text.trim().isEmpty;
        return CredentialsCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          radius: 16,
          child: CredentialsStrengthMeter(
            score: isEmpty ? 0 : (report?.score ?? 0),
            label: isEmpty
                ? 'No password yet'
                : _passwordHealthLabel(context, report?.level),
            caption: _passwordHealthCaption(report),
          ),
        );
      },
    );
  }

  Widget _referenceCategoryCard() {
    return CredentialsCard(
      padding: const EdgeInsets.all(10),
      radius: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.credentialsCategory.toUpperCase(),
                        style: credentialsMonoStyle(size: 9.5),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<CredentialCategory>(
                          value: _selectedCategory,
                          isDense: true,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: CredentialsReferenceColors.muted,
                          ),
                          dropdownColor: CredentialsReferenceColors.surface,
                          style: credentialsBodyStyle(
                            size: 15,
                            weight: FontWeight.w600,
                          ),
                          items: credentialCategoryValues
                              .map(
                                (item) => DropdownMenuItem<CredentialCategory>(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceNotesField() {
    return CredentialsInputField(
      key: _notesFieldKey,
      label: 'Notes',
      controller: _notesController,
      focusNode: _notesFocusNode,
      hint: '2FA, recovery codes, context...',
      maxLines: 5,
      onChanged: (_) => setState(() {}),
    );
  }

  String _prettyHost(String rawUrl) {
    final text = rawUrl.trim();
    if (text.isEmpty) {
      return '';
    }
    final candidate = text.startsWith('http://') || text.startsWith('https://')
        ? text
        : 'https://$text';
    final host = Uri.tryParse(candidate)?.host ?? text;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _passwordHealthLabel(
    BuildContext context,
    PasswordHealthLevel? level,
  ) {
    final l10n = context.l10n;
    return switch (level) {
      PasswordHealthLevel.weak => l10n.passwordHealthWeak,
      PasswordHealthLevel.fair => l10n.passwordHealthFair,
      PasswordHealthLevel.strong => l10n.passwordHealthStrong,
      PasswordHealthLevel.excellent => l10n.passwordHealthExcellent,
      null =>
        _passwordHealthController.isEvaluating
            ? l10n.passwordHealthChecking
            : l10n.passwordHealthWeak,
    };
  }

  String _passwordHealthCaption(PasswordHealthReportEntity? report) {
    if (_passwordController.text.trim().isEmpty) {
      return 'Type a password to score it';
    }
    if (_passwordHealthController.isEvaluating) {
      return 'Checking password quality';
    }
    if (report == null) {
      return '${_passwordController.text.length} chars';
    }
    final parts = <String>[
      '${_passwordController.text.length} chars',
      '${report.entropyBits.toStringAsFixed(0)} bits',
      if (report.issues.isNotEmpty) '${report.issues.length} issues',
      if (report.estimatedCrackTime.trim().isNotEmpty)
        report.estimatedCrackTime,
    ];
    return parts.join(' · ');
  }

  String get _primaryActionLabel {
    final l10n = context.l10n;
    if (widget.isCreate || _isEditing) {
      return l10n.commonSave;
    }
    return l10n.commonEdit;
  }

  Future<void> _onPrimaryActionPressed() async {
    if (_isDownloadingLogo) {
      _toast(context.l10n.credentialsLogoSavingInProgress);
      return;
    }

    if (widget.isCreate || _isEditing) {
      final result = _buildEditorResult();
      if (result == null) {
        return;
      }

      if (widget.onSave != null) {
        await widget.onSave!.call(result);
        if (!mounted || widget.isCreate) {
          return;
        }
        setState(() {
          _isEditing = false;
        });
        return;
      }

      Navigator.of(context).pop(result);
      return;
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  CredentialEditorResult? _buildEditorResult() {
    final service = _serviceController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (service.isEmpty || username.isEmpty || password.isEmpty) {
      _toast(context.l10n.credentialsRequiredFieldsMissing);
      return null;
    }

    return CredentialEditorResult(
      serviceName: service,
      accountLabel: _accountLabelController.text.trim(),
      username: username,
      category: _selectedCategory,
      password: password,
      url: _urlController.text.trim(),
      notes: _notesController.text.trim(),
      brandHex: _deriveBrandHex(service),
      logoPath: _selectedLocalLogoPath.isEmpty ? null : _selectedLocalLogoPath,
    );
  }

  void _refreshPasswordHealth({bool immediate = false}) {
    _passwordHealthController.refresh(
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      serviceName: _serviceController.text.trim(),
      existingPasswords: const [],
      immediate: immediate,
    );
  }

  void _onServiceChanged(String value) {
    setState(() {
      _selectedBrandIconUrl = '';
      _selectedLocalLogoPath = '';
    });
    _refreshPasswordHealth();
    _serviceSearchDebounce?.cancel();

    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _isSearchingBrands = false;
        _serviceSuggestions = const [];
      });
      return;
    }

    _serviceSearchDebounce = Timer(const Duration(milliseconds: 260), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearchingBrands = true;
      });

      final snapshotQuery = query;
      final results = await widget.searchCompanyBrands(query: snapshotQuery);
      if (!mounted || _serviceController.text.trim() != snapshotQuery) {
        return;
      }

      setState(() {
        _isSearchingBrands = false;
        _serviceSuggestions = results;
      });
    });
  }

  Future<void> _searchBrandByWebsiteOrService() async {
    final query =
        _extractBrandQueryFromUrl(_urlController.text) ??
        _serviceController.text.trim();
    if (query.length < 2) {
      _toast(context.l10n.credentialsSearchEnterServiceOrWebsite);
      return;
    }

    setState(() {
      _isSearchingBrands = true;
    });

    try {
      final results = await widget.searchCompanyBrands(query: query);
      if (!mounted) {
        return;
      }
      setState(() {
        _serviceSuggestions = results;
        _isSearchingBrands = false;
      });
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
      if (!mounted) {
        return;
      }
      if (results.isEmpty) {
        _toast(context.l10n.credentialsNoMatchingIconFound);
      } else {
        _toast(context.l10n.credentialsSelectSuggestedBrand);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearchingBrands = false;
      });
      _toast(context.l10n.credentialsUnableSearchBrands);
    }
  }

  Future<void> _applySuggestion(CompanyBrandSearchResultEntity item) async {
    _serviceController
      ..text = item.name
      ..selection = TextSelection.collapsed(offset: item.name.length);
    _urlController
      ..text = 'https://${item.domain}'
      ..selection = TextSelection.collapsed(
        offset: 'https://${item.domain}'.length,
      );
    _refreshPasswordHealth(immediate: true);

    setState(() {
      _serviceSuggestions = const [];
      _isSearchingBrands = false;
      _selectedBrandIconUrl = item.iconUrl;
      _isDownloadingLogo = true;
    });
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final localPath = await widget.downloadCompanyLogoToLocal(
        iconUrl: item.iconUrl,
        domain: item.domain,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedLocalLogoPath = localPath ?? '';
      });
      if ((localPath ?? '').trim().isEmpty) {
        _toast(context.l10n.credentialsLogoPreviewLoadedLocalSaveFailed);
      }
      if (kDebugMode) {
        debugPrint('[Brandfetch] logo local path=$_selectedLocalLogoPath');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _toast(context.l10n.credentialsUnableSaveLogoLocally);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingLogo = false;
        });
      }
    }
  }

  String? _extractBrandQueryFromUrl(String rawUrl) {
    final text = rawUrl.trim();
    if (text.isEmpty) {
      return null;
    }
    final candidate = text.startsWith('http://') || text.startsWith('https://')
        ? text
        : 'https://$text';
    final uri = Uri.tryParse(candidate);
    final host = uri?.host.trim().toLowerCase() ?? '';
    if (host.isEmpty) {
      return null;
    }
    final noWww = host.startsWith('www.') ? host.substring(4) : host;
    final firstLabel = noWww.split('.').first.trim();
    if (firstLabel.length < 2) {
      return noWww;
    }
    return firstLabel;
  }

  void _clearBrandSelection() {
    setState(() {
      _selectedBrandIconUrl = '';
      _selectedLocalLogoPath = '';
      _serviceSuggestions = const [];
    });
  }

  int _deriveBrandHex(String serviceName) {
    final normalized = serviceName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 0xFF5E5CE6;
    }

    final hash = normalized.codeUnits.fold<int>(0, (acc, c) => acc + c * 31);
    final r = 90 + (hash & 0x3F);
    final g = 90 + ((hash >> 2) & 0x3F);
    final b = 90 + ((hash >> 4) & 0x3F);

    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    _toast(message);
  }

  Future<void> _copyUsername() async {
    await _copy(_usernameController.text, context.l10n.credentialsEmailCopied);
    if (!mounted) {
      return;
    }
    _usernameCopiedTimer?.cancel();
    setState(() {
      _isUsernameCopied = true;
    });
    _usernameCopiedTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUsernameCopied = false;
      });
    });
  }

  Future<void> _generatePassword() async {
    try {
      final generator = getIt<GeneratePassword>();
      final result = await generator(const GeneratePasswordParams());
      if (!mounted) return;
      setState(() {
        _passwordController.text = result;
        _isPasswordVisible = true;
      });
      _refreshPasswordHealth(immediate: true);
    } catch (e) {
      debugPrint('[CredentialEdit] Password generation failed: $e');
    }
  }

  Future<void> _copyPassword() async {
    await _copy(
      _passwordController.text,
      context.l10n.credentialsPasswordCopied,
    );
    if (widget.onPasswordUsed != null) {
      try {
        await widget.onPasswordUsed!.call();
      } catch (e) {
        debugPrint('[CredentialEdit] onPasswordUsed callback failed: $e');
      }
    }
    if (!mounted) {
      return;
    }
    _passwordCopiedTimer?.cancel();
    setState(() {
      _isPasswordCopied = true;
    });
    _passwordCopiedTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPasswordCopied = false;
      });
    });
  }

  Future<void> _copyUrl() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      _toast(context.l10n.credentialsNoUrlToCopy);
      return;
    }
    await _copy(text, context.l10n.credentialsWebsiteCopied);
  }

  Future<bool> _authenticateForReveal() async {
    // Try biometric first if enabled
    final biometricEnabled = await AppLockService.isBiometricEnabled();
    if (biometricEnabled) {
      final biometricAvailable = await AppLockService.isBiometricAvailable();
      if (biometricAvailable) {
        final success = await AppLockService.authenticateWithBiometrics(
          reason: 'Authenticate to reveal password',
        );
        if (success) return true;
      }
    }

    // Fall back to PIN dialog
    if (!mounted) return false;
    return await _showRevealPinDialog();
  }

  Future<bool> _showRevealPinDialog() async {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.revealAuthPinTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.revealAuthPinHint,
            hintStyle: TextStyle(color: palette.textMuted),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final valid = await AppLockService.verifyPin(controller.text);
              if (ctx.mounted) Navigator.pop(ctx, valid);
            },
            child: Text(
              l10n.commonSave,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != true && mounted) {
      _toast(l10n.revealAuthFailed);
    }
    return result == true;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _bindFocusScroll(FocusNode focusNode, GlobalKey fieldKey) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        return;
      }
      _scrollFieldIntoView(fieldKey);
    });
  }

  void _scrollFieldIntoView(GlobalKey fieldKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) {
          return;
        }
        final targetContext = fieldKey.currentContext;
        if (targetContext == null || !targetContext.mounted) {
          return;
        }
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.18,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }
}
