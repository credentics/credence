import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class DocumentFilePreviewPage extends StatefulWidget {
  const DocumentFilePreviewPage({
    super.key,
    required this.filePath,
    required this.title,
    this.fileName,
    this.mimeType,
  });

  final String filePath;
  final String title;
  final String? fileName;
  final String? mimeType;

  @override
  State<DocumentFilePreviewPage> createState() =>
      _DocumentFilePreviewPageState();
}

class _DocumentFilePreviewPageState extends State<DocumentFilePreviewPage> {
  String get _normalizedPath =>
      LocalAssetPathResolver.resolveRuntimePathSync(widget.filePath);

  bool get _isPdf {
    final mime = (widget.mimeType ?? '').trim().toLowerCase();
    if (mime == LocalFileMimeTypes.pdf) {
      return true;
    }
    return _normalizedPath.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _isPdf
        ? null
        : resolveLocalFileImageProvider(_normalizedPath);
    final hasValidImage = _isPdf || imageProvider != null;

    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.surface,
        centerTitle: false,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: widget.title.trim().isEmpty
            ? context.l10n.identityYourDocumentsTitle
            : widget.title,
        titleStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
        actionIcon: Icons.share_outlined,
        actionTooltip: context.l10n.commonShare,
        onActionPressed: _shareCurrentFile,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isPdf)
            PdfViewer.file(
              _normalizedPath,
              params: PdfViewerParams(
                backgroundColor: Colors.black,
                margin: 0,
                pageDropShadow: null,
                pageAnchor: PdfPageAnchor.center,
                pageAnchorEnd: PdfPageAnchor.center,
                calculateInitialZoom:
                    (document, controller, fitZoom, coverZoom) {
                      return coverZoom;
                    },
              ),
            )
          else if (hasValidImage)
            InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: SizedBox.expand(
                child: Image(
                  image: imageProvider!,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          context.l10n.documentUnableRenderImagePreview,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.appPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _normalizedPath.inferFileTypeLabel(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.appPalette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _normalizedPath.split('/').last,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.documentPreviewNotAvailable,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _shareCurrentFile,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(context.l10n.commonShare),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _shareCurrentFile() async {
    final l10n = context.l10n;
    final file = File(_normalizedPath);
    if (!file.existsSync()) {
      _showSnack(l10n.documentFileUnavailable);
      return;
    }

    final xFile = XFile(
      _normalizedPath,
      name: (widget.fileName ?? '').trim().isNotEmpty
          ? widget.fileName!.trim()
          : _normalizedPath.split('/').last,
      mimeType: widget.mimeType ?? _normalizedPath.inferMimeType(),
    );

    try {
      final anchor = context.findRenderObject() as RenderBox?;
      final shareOrigin = anchor != null
          ? anchor.localToGlobal(Offset.zero) & anchor.size
          : null;
      await Share.shareXFiles(
        [xFile],
        subject: widget.title,
        sharePositionOrigin: shareOrigin,
      );
    } on MissingPluginException {
      _showSnack(l10n.documentSharingUnavailableBuild);
    } on PlatformException catch (error) {
      _showSnack(_shareErrorMessage(error));
    } catch (_) {
      _showSnack(l10n.documentUnableShareFile);
    }
  }

  String _shareErrorMessage(PlatformException error) {
    final message = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (message.contains('not found') ||
        message.contains('no such file') ||
        message.contains('does not exist')) {
      return context.l10n.documentShareErrorFileNotFound;
    }
    if (message.contains('permission') || message.contains('denied')) {
      return context.l10n.documentShareErrorPermissionDenied;
    }
    if (message.contains('unavailable') || message.contains('not available')) {
      return context.l10n.documentShareErrorUnavailable;
    }
    return context.l10n.documentUnableShareFile;
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
