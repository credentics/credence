import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/share_position_origin.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/features/bundles/infrastructure/services/bundle_export_service.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/bundles_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class BundleExportPage extends StatefulWidget {
  const BundleExportPage({super.key, required this.bundle});

  final BundleEntity bundle;

  @override
  State<BundleExportPage> createState() => _BundleExportPageState();
}

class _BundleExportPageState extends State<BundleExportPage> {
  final _passphraseController = TextEditingController();

  bool _encrypt = false;
  bool _exporting = false;
  BundleExportResult? _result;
  String? _error;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _export({required bool shareAfter}) async {
    if (_encrypt && _passphraseController.text.trim().isEmpty) {
      setState(() => _error = context.l10n.bundleExportPassphraseRequired);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _exporting = true;
      _error = null;
      _result = null;
    });

    try {
      final service = getIt<BundleExportService>();
      final result = await service.export(
        BundleExportRequest(
          bundle: widget.bundle,
          encrypt: _encrypt,
          passphrase: _encrypt ? _passphraseController.text.trim() : null,
        ),
      );
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _result = result;
      });
      if (shareAfter) {
        await _shareResult(result);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _error = context.l10n.bundleExportError;
      });
    }
  }

  Future<void> _shareResult(BundleExportResult result) async {
    try {
      await Share.shareXFiles(
        [XFile(result.filePath)],
        subject: widget.bundle.title,
        sharePositionOrigin: resolveSharePositionOrigin(context),
      );
    } on MissingPluginException {
      if (!mounted) return;
      _showShareError();
    } on PlatformException {
      if (!mounted) return;
      _showShareError();
    }
  }

  void _showShareError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.documentUnableShareFile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return BundleReferencePage(
      maxWidth: 560,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _exporting
            ? _ExportProgressView(bundle: widget.bundle)
            : result != null
            ? _ExportSuccessView(
                bundle: widget.bundle,
                result: result,
                onShare: () => _shareResult(result),
              )
            : _ExportReviewView(
                bundle: widget.bundle,
                encrypt: _encrypt,
                error: _error,
                passphraseController: _passphraseController,
                onEncryptChanged: (value) => setState(() => _encrypt = value),
                onCancel: () => Navigator.of(context).maybePop(),
                onShare: () => _export(shareAfter: true),
                onSave: () => _export(shareAfter: false),
              ),
      ),
    );
  }
}

class _ExportReviewView extends StatelessWidget {
  const _ExportReviewView({
    required this.bundle,
    required this.encrypt,
    required this.error,
    required this.passphraseController,
    required this.onEncryptChanged,
    required this.onCancel,
    required this.onShare,
    required this.onSave,
  });

  final BundleEntity bundle;
  final bool encrypt;
  final String? error;
  final TextEditingController passphraseController;
  final ValueChanged<bool> onEncryptChanged;
  final VoidCallback onCancel;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    final exportableItems = _exportableItems(bundle);
    final skippedCount = (bundle.itemCount - exportableItems.length).clamp(
      0,
      bundle.itemCount,
    );
    return ListView(
      key: const ValueKey('bundle-export-review'),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        BundleRefHeader(
          title: l10n.bundleExportTitle,
          meta: bundle.title.toUpperCase(),
          leading: _HeaderTextButton(label: 'Cancel', onTap: onCancel),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: _ExportModeToggle(
            encrypt: encrypt,
            onChanged: onEncryptChanged,
          ),
        ),
        if (encrypt) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _PassphraseField(controller: passphraseController),
          ),
        ],
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _ExportFileList(
            items: exportableItems,
            totalItems: bundle.itemCount,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _RealFilesBanner(skippedCount: skippedCount),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              error!,
              style: TextStyle(
                fontFamily: bundleFontBody,
                color: palette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: BundlePrimaryButton(
            label: 'Share…',
            icon: _shareIcon(context),
            onPressed: exportableItems.isEmpty ? null : onShare,
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: exportableItems.isEmpty ? null : onSave,
          child: Text(
            'Export without sharing',
            style: TextStyle(
              fontFamily: bundleFontBody,
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportProgressView extends StatelessWidget {
  const _ExportProgressView({required this.bundle});

  final BundleEntity bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return ListView(
      key: const ValueKey('bundle-export-progress'),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        BundleRefHeader(
          title: 'Exporting...',
          meta: bundle.title.toUpperCase(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: _ProgressHero(bundle: bundle),
        ),
        const SizedBox(height: 18),
        BundleSectionLabel(label: 'Phases · 5'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              _PhaseRow(
                title: 'Validate bundle',
                subtitle:
                    '${bundle.itemCount} items · source references checked',
                state: _PhaseState.done,
              ),
              _PhaseRow(
                title: 'Resolve filenames',
                subtitle: 'Clean readable names · collision-safe',
                state: _PhaseState.done,
              ),
              const _PhaseRow(
                title: 'Copy real files',
                subtitle: 'PDFs and images only · no metadata placeholders',
                state: _PhaseState.active,
              ),
              const _PhaseRow(
                title: 'Build archive',
                subtitle: 'ZIP folder structure · local device',
                state: _PhaseState.queued,
              ),
              const _PhaseRow(
                title: 'Hand off to share sheet',
                subtitle: 'Ready to share or save to your device',
                state: _PhaseState.queued,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'CANCELLING ROLLS BACK · NO PARTIAL FOLDER CREATED',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: bundleFontMono,
            color: palette.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _ExportSuccessView extends StatelessWidget {
  const _ExportSuccessView({
    required this.bundle,
    required this.result,
    required this.onShare,
  });

  final BundleEntity bundle;
  final BundleExportResult result;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    final exportedAt = DateFormat.yMMMd().add_Hm().format(result.exportedAt);
    return ListView(
      key: const ValueKey('bundle-export-success'),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        BundleRefHeader(
          title: 'Done',
          meta: 'EXPORTED · ${_formatSize(result.sizeBytes)}',
          trailing: _HeaderTextButton(
            label: 'Done',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: _SuccessCard(result: result),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _OutputSummary(
            bundle: bundle,
            result: result,
            exportedAt: exportedAt,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primary,
                    side: BorderSide(
                      color: palette.primary.withValues(alpha: 0.28),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: bundleFontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BundlePrimaryButton(
                  label: l10n.bundleExportShare,
                  icon: _shareIcon(context),
                  height: 40,
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'STATUS UPDATED TO EXPORTED · LOGGED IN HISTORY',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: bundleFontMono,
            color: palette.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  const _HeaderTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: bundleFontBody,
              color: context.appPalette.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportModeToggle extends StatelessWidget {
  const _ExportModeToggle({required this.encrypt, required this.onChanged});

  final bool encrypt;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              active: !encrypt,
              label: 'PLAIN ZIP',
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              active: encrypt,
              icon: Icons.lock_rounded,
              label: 'ENCRYPTED ZIP',
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.active,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = active ? palette.surface : palette.textMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? palette.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassphraseField extends StatelessWidget {
  const _PassphraseField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(
        fontFamily: bundleFontBody,
        color: palette.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: context.l10n.bundleExportPassphraseLabel,
        hintText: context.l10n.bundleExportPassphraseHint,
        labelStyle: TextStyle(
          fontFamily: bundleFontMono,
          color: palette.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.75,
        ),
        hintStyle: TextStyle(
          fontFamily: bundleFontBody,
          color: palette.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: palette.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ExportFileList extends StatelessWidget {
  const _ExportFileList({required this.items, required this.totalItems});

  final List<BundleItemRef> items;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final visible = items.take(6).toList(growable: false);
    final more = items.length - visible.length;
    final skipped = totalItems - items.length;
    final fileWord = items.length == 1 ? 'FILE' : 'FILES';
    final countLabel = skipped > 0
        ? '${items.length} OF $totalItems ITEMS'
        : '${items.length} $fileWord';
    return BundleCardShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'FILES TO EXPORT',
                    style: TextStyle(
                      fontFamily: bundleFontMono,
                      color: palette.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.75,
                    ),
                  ),
                ),
                Text(
                  countLabel,
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              child: Text(
                'No file-backed documents were found in this bundle yet.',
                style: TextStyle(
                  fontFamily: bundleFontBody,
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...[
            for (final item in visible) _ExportFileRow(item: item),
            if (more > 0)
              _CollapsedFileRow(
                label: '+ $more more files...',
                subtitle: 'All remaining real files will be included',
              ),
          ],
        ],
      ),
    );
  }
}

class _ExportFileRow extends StatelessWidget {
  const _ExportFileRow({required this.item});

  final BundleItemRef item;

  @override
  Widget build(BuildContext context) {
    final isImage = _looksLikeImage(item);
    final kindLabel = _exportKindLabel(item);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: [
          _FileKindBadge(label: kindLabel, isImage: isImage),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cleanExportFileName(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: context.appPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle?.trim().isNotEmpty == true
                      ? item.subtitle!.trim()
                      : _typeLabel(item.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: context.appPalette.textMuted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isImage ? 'IMAGE' : 'FILE',
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: context.appPalette.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedFileRow extends StatelessWidget {
  const _CollapsedFileRow({required this.label, required this.subtitle});

  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Opacity(
      opacity: 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Row(
          children: [
            const _FileKindBadge(label: '+', isImage: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: bundleFontBody,
                      color: palette.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: bundleFontBody,
                      color: palette.textMuted,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileKindBadge extends StatelessWidget {
  const _FileKindBadge({required this.label, required this.isImage});

  final String label;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = label == 'COL'
        ? palette.primary
        : isImage
        ? palette.primary
        : palette.danger;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: bundleFontMono,
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _RealFilesBanner extends StatelessWidget {
  const _RealFilesBanner({required this.skippedCount});

  final int skippedCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final skippedNote = skippedCount <= 0
        ? null
        : skippedCount == 1
        ? '1 bundle item is not a file (like a password or note) and stays out of this export.'
        : '$skippedCount bundle items are not files (like passwords or notes) and stay out of this export.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.success.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, color: palette.success, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Only your documents',
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.success,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Each entry is a real PDF or image from your vault, with a '
                  'clean, readable name — never metadata.',
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.textMuted,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (skippedNote != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    skippedNote,
                    style: TextStyle(
                      fontFamily: bundleFontBody,
                      color: palette.textMuted,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.bundle});

  final BundleEntity bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'STEP 3 OF 5 · LOCAL EXPORT',
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.surface.withValues(alpha: 0.62),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.75,
                  ),
                ),
              ),
              Text(
                '62%',
                style: TextStyle(
                  fontFamily: bundleFontMono,
                  color: palette.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Copying your files',
            style: TextStyle(
              fontFamily: bundleFontDisplay,
              color: palette.surface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: 0.62,
              backgroundColor: palette.surface.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(palette.surface),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${bundle.itemCount} BUNDLE ITEMS · PDFs AND IMAGES · CLEAN NAMES',
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: palette.surface.withValues(alpha: 0.68),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PhaseState { done, active, queued }

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final _PhaseState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = switch (state) {
      _PhaseState.done => palette.success,
      _PhaseState.active => palette.textPrimary,
      _PhaseState.queued => palette.textMuted,
    };
    return BundleCardShell(
      padding: const EdgeInsets.all(10),
      borderColor: Colors.transparent,
      backgroundColor: palette.surface,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: state == _PhaseState.active ? 1 : 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              state == _PhaseState.done
                  ? Icons.check_rounded
                  : state == _PhaseState.active
                  ? Icons.sync_rounded
                  : Icons.circle_outlined,
              color: state == _PhaseState.active ? palette.surface : color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: state == _PhaseState.active
                        ? palette.textPrimary
                        : palette.textMuted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            switch (state) {
              _PhaseState.done => 'DONE',
              _PhaseState.active => 'ACTIVE',
              _PhaseState.queued => '·',
            },
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.result});

  final BundleExportResult result;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.success.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.success,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.check_rounded, color: palette.surface, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.bundleExportSuccess,
            style: TextStyle(
              fontFamily: bundleFontDisplay,
              color: palette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${result.itemCount} files · ${_formatSize(result.sizeBytes)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: bundleFontBody,
              color: palette.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputSummary extends StatelessWidget {
  const _OutputSummary({
    required this.bundle,
    required this.result,
    required this.exportedAt,
  });

  final BundleEntity bundle;
  final BundleExportResult result;
  final String exportedAt;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BundleCardShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'OUTPUT',
                    style: TextStyle(
                      fontFamily: bundleFontMono,
                      color: palette.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.75,
                    ),
                  ),
                ),
                Text(
                  'ZIP · ${_formatSize(result.sizeBytes)}',
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
              ],
            ),
          ),
          _OutputRow(
            title: _lastPathSegment(result.filePath),
            subtitle: '${result.itemCount} files · exported $exportedAt',
            trailing: _formatSize(result.sizeBytes),
          ),
          _OutputRow(
            title: '${_safeLabel(bundle.title)}/',
            subtitle: 'Archive source · bundle snapshot',
            trailing: 'LOCAL',
            inset: true,
          ),
          _OutputRow(
            title: 'documents/',
            subtitle: 'PDFs and images from your documents',
            trailing: '${result.itemCount}',
            inset: true,
          ),
        ],
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  const _OutputRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.inset = false,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset ? 28 : 14, 8, 14, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.textPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.folder_zip_rounded,
              color: palette.textPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.textMuted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: palette.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isApplePlatform(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

/// The system share glyph — Apple's box-and-arrow on iOS/macOS, the generic
/// share node elsewhere — so the affordance reads natively on every platform.
IconData _shareIcon(BuildContext context) =>
    _isApplePlatform(context) ? Icons.ios_share_rounded : Icons.share_rounded;

List<BundleItemRef> _exportableItems(BundleEntity bundle) {
  return bundle.items
      .where(
        (item) =>
            item.type == BundleItemType.document ||
            item.type == BundleItemType.identityCard ||
            item.type == BundleItemType.collection,
      )
      .toList(growable: false);
}

bool _looksLikeImage(BundleItemRef item) {
  final value = '${item.displayName} ${item.subtitle ?? ''}'.toLowerCase();
  return value.contains('.jpg') ||
      value.contains('.jpeg') ||
      value.contains('.png') ||
      value.contains('image') ||
      value.contains('photo');
}

String _cleanExportFileName(BundleItemRef item) {
  final raw = item.displayName.trim().isEmpty ? item.refId : item.displayName;
  if (item.type == BundleItemType.collection) {
    return '${_safeLabel(raw)}/';
  }
  final hasExtension = RegExp(r'\.[A-Za-z0-9]{2,5}$').hasMatch(raw);
  final extension = _looksLikeImage(item) ? '.jpg' : '.pdf';
  return _safeLabel(hasExtension ? raw : '$raw$extension');
}

String _exportKindLabel(BundleItemRef item) {
  if (item.type == BundleItemType.collection) {
    return 'COL';
  }
  return _looksLikeImage(item) ? 'IMG' : 'PDF';
}

String _safeLabel(String value) {
  final sanitized = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._\-\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
  return sanitized.isEmpty ? 'bundle_export' : sanitized;
}

String _typeLabel(BundleItemType type) {
  switch (type) {
    case BundleItemType.credential:
      return 'Credential';
    case BundleItemType.document:
      return 'Document';
    case BundleItemType.note:
      return 'Note';
    case BundleItemType.identityCard:
      return 'Identity';
    case BundleItemType.collection:
      return 'Collection';
  }
}

String _lastPathSegment(String path) {
  final parts = path.split(RegExp(r'[/\\]')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
