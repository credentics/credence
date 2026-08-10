import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

enum DocumentRemovalDecision { archive, delete }

Future<DocumentRemovalDecision?> showDocumentRemovalPrompt({
  required BuildContext context,
  required String title,
}) {
  return showAdaptiveModal<DocumentRemovalDecision>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appPalette.strokeStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  context.l10n.documentRemoveTitle(title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  context.l10n.documentRemoveDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.archive_outlined,
                  color: context.appPalette.primary,
                ),
                title: Text(
                  context.l10n.documentRemoveArchive,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(context.l10n.documentRemoveArchiveSubtitle),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(DocumentRemovalDecision.archive),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: context.appPalette.danger,
                ),
                title: Text(
                  context.l10n.documentRemoveDelete,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.danger,
                  ),
                ),
                subtitle: Text(context.l10n.documentRemoveDeleteSubtitle),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(DocumentRemovalDecision.delete),
              ),
              const Divider(height: 1),
              ListTile(
                title: Center(
                  child: Text(
                    context.l10n.commonCancel,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
