import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';
import 'package:pass_doc_manager/domain/secure_share/usecases/create_share_link.dart';
import 'package:pass_doc_manager/features/secure_share/presentation/cubit/secure_share_cubit.dart';
import 'package:pass_doc_manager/features/secure_share/presentation/cubit/secure_share_state.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class SecureSharePage extends StatelessWidget {
  const SecureSharePage({
    super.key,
    required this.itemName,
    required this.itemType,
    required this.availableFields,
    this.onCloseRequested,
  });

  final String itemName;
  final ShareItemType itemType;
  final Map<String, String> availableFields;
  final VoidCallback? onCloseRequested;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SecureShareCubit(getIt<CreateShareLink>())
            ..toggleFieldSelection(availableFields.keys.first),
      child: _SecureShareContent(
        itemName: itemName,
        itemType: itemType,
        availableFields: availableFields,
        onCloseRequested: onCloseRequested,
      ),
    );
  }
}

class _SecureShareContent extends StatefulWidget {
  const _SecureShareContent({
    required this.itemName,
    required this.itemType,
    required this.availableFields,
    this.onCloseRequested,
  });

  final String itemName;
  final ShareItemType itemType;
  final Map<String, String> availableFields;
  final VoidCallback? onCloseRequested;

  @override
  State<_SecureShareContent> createState() => _SecureShareContentState();
}

class _SecureShareContentState extends State<_SecureShareContent> {
  ShareTtl _selectedTtl = ShareTtl.oneDay;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onCloseRequested?.call();
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(context.l10n.shareTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: BlocListener<SecureShareCubit, SecureShareState>(
          listener: (context, state) {
            if (state.status == SecureShareStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item being shared section
              _buildItemSection(context),
              const SizedBox(height: 32),

              // Fields selection section
              _buildFieldsSection(context),
              const SizedBox(height: 32),

              // Passphrase section
              _buildPassphraseSection(context),
              const SizedBox(height: 32),

              // TTL selector section
              _buildTtlSection(context),
              const SizedBox(height: 40),

              // Generate or Share section
              BlocBuilder<SecureShareCubit, SecureShareState>(
                builder: (context, state) {
                  if (state.status == SecureShareStatus.success &&
                      state.shareLink != null) {
                    return _buildShareResultSection(context, state);
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: state.status == SecureShareStatus.loading
                          ? null
                          : () => _generateShareLink(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        disabledBackgroundColor: palette.stroke,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state.status == SecureShareStatus.loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              context.l10n.shareGenerateLink,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemSection(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        border: Border.all(color: palette.stroke),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sharing:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.itemName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsSection(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select fields to share:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<SecureShareCubit, SecureShareState>(
          builder: (context, state) {
            return Column(
              children: widget.availableFields.entries.map((entry) {
                final isSelected = state.selectedFields.contains(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) {
                      context.read<SecureShareCubit>().toggleFieldSelection(
                        entry.key,
                      );
                    },
                    title: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                    subtitle: entry.value.length > 50
                        ? Text(
                            '${entry.value.substring(0, 47)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                    activeColor: palette.primary,
                    checkColor: palette.surface,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPassphraseSection(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.sharePassphraseHint,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<SecureShareCubit, SecureShareState>(
          builder: (context, state) {
            return Column(
              children: [
                TextField(
                  controller: TextEditingController(text: state.passphrase),
                  onChanged: (value) {
                    context.read<SecureShareCubit>().updatePassphrase(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter or generate a passphrase',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context
                          .read<SecureShareCubit>()
                          .generateRandomPassphrase();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Generate Random Passphrase'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.primary,
                      side: BorderSide(color: palette.stroke),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTtlSection(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.shareTtlLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: palette.stroke),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<ShareTtl>(
            value: _selectedTtl,
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTtl = value;
                });
              }
            },
            items: [
              DropdownMenuItem(
                value: ShareTtl.oneHour,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(context.l10n.shareTtl1Hour),
                ),
              ),
              DropdownMenuItem(
                value: ShareTtl.oneDay,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(context.l10n.shareTtl1Day),
                ),
              ),
              DropdownMenuItem(
                value: ShareTtl.sevenDays,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(context.l10n.shareTtl7Days),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Anyone with this link and its passphrase can open it until it '
          'expires. The link cannot be recalled once shared.',
          style: TextStyle(fontSize: 12, color: palette.textSecondary),
        ),
      ],
    );
  }

  Widget _buildShareResultSection(
    BuildContext context,
    SecureShareState state,
  ) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFE7F5E7),
            border: Border.all(color: palette.success),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: palette.success, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Share link generated!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Passphrase reminder
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(color: palette.warning),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.sharePassphraseReminder,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      state.passphrase,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Share link
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(color: palette.stroke),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  state.shareLink!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Expiry info
              Text(
                'Expires: ${state.expiresAt?.toLocal().toString().split('.')[0] ?? 'Unknown'}',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: state.shareLink!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.shareCopyLink),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appPalette.primary,
                  side: BorderSide(color: context.appPalette.stroke),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Share.share(
                    'Secure share link: ${state.shareLink}\n\nPassphrase: ${state.passphrase}',
                    subject: 'Secure Share from Credence',
                  );
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.appPalette.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<SecureShareCubit>().resetState();
              setState(() {
                _selectedTtl = ShareTtl.oneDay;
              });
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Create Another Share Link'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appPalette.textSecondary,
              side: BorderSide(color: context.appPalette.stroke),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _generateShareLink(BuildContext context) {
    context.read<SecureShareCubit>().createShareLink(
      itemName: widget.itemName,
      itemType: widget.itemType,
      availableFields: widget.availableFields,
      ttl: _selectedTtl,
    );
  }
}
