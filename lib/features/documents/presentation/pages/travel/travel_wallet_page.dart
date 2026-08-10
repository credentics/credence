import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_timeline_event_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/vault_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trip_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_vault_document_picker_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_wallet_document_entry_page.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelWalletPage extends StatelessWidget {
  const TravelWalletPage({
    super.key,
    required this.tripId,
    required this.fallbackTripTitle,
    GetTravelTripDetail? getTripDetail,
  }) : _getTripDetail = getTripDetail;

  final String tripId;
  final String fallbackTripTitle;
  final GetTravelTripDetail? _getTripDetail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TravelTripDetailCubit(getTravelTripDetail: _getTripDetail)
            ..load(tripId: tripId),
      child: _TravelWalletView(
        tripId: tripId,
        fallbackTripTitle: fallbackTripTitle,
      ),
    );
  }
}

class _TravelWalletView extends StatelessWidget {
  const _TravelWalletView({
    required this.tripId,
    required this.fallbackTripTitle,
  });

  final String tripId;
  final String fallbackTripTitle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelTripDetailCubit, TravelTripDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        final tripTitle = detail?.trip.title.trim().isNotEmpty == true
            ? detail!.trip.title
            : fallbackTripTitle;
        return Scaffold(
          backgroundColor: context.appPalette.background,
          appBar: GenericAppBar(
            onBackPressed: () => Navigator.of(context).maybePop(),
            title: context.l10n.travelWalletTitle,
            titleStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
            actionIcon: Icons.add_rounded,
            onActionPressed: detail == null
                ? null
                : () => _openAddDocument(context, tripTitle),
          ),
          body: _body(context, state, tripTitle),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    TravelTripDetailState state,
    String tripTitle,
  ) {
    final detail = state.detail;
    if ((state.viewStatus == TravelTripDetailViewStatus.initial ||
            state.viewStatus == TravelTripDetailViewStatus.loading) &&
        detail == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }
    if (state.viewStatus == TravelTripDetailViewStatus.error &&
        detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.travelTripDetailLoadError,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<TravelTripDetailCubit>().load(tripId: tripId),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    if (detail == null) {
      return const SizedBox.shrink();
    }

    final grouped = <String, List<TravelDocumentEntity>>{};
    for (final doc in detail.walletDocuments) {
      final key = doc.documentTypeLabel.trim().isEmpty
          ? context.l10n.travelWalletSectionOther
          : doc.documentTypeLabel;
      grouped.putIfAbsent(key, () => <TravelDocumentEntity>[]).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
      children: [
        if (detail.walletDocuments.isEmpty)
          TravelSurfaceCard(
            child: Column(
              children: [
                Text(
                  context.l10n.travelWalletEmptyTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.l10n.travelWalletEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                SizedBox(height: 10),
                FilledButton(
                  onPressed: () => _openAddDocument(context, tripTitle),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appPalette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(context.l10n.travelWalletAddDocumentAction),
                ),
              ],
            ),
          )
        else
          ...grouped.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _documentGroup(context, entry.key, entry.value),
            ),
          ),
        InkWell(
          onTap: () => _openAddDocument(context, tripTitle),
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: const _WalletAddDashedPainter(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.appPalette.stroke,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: Color(0xFF8AA0C2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.travelWalletAddDocumentAction,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8AA0C2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentGroup(
    BuildContext context,
    String sectionTitle,
    List<TravelDocumentEntity> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              color: context.appPalette.surfaceSoft,
              child: Text(
                sectionTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF90A0BA),
                ),
              ),
            ),
            for (var index = 0; index < items.length; index++) ...[
              _documentRow(context, items[index]),
              if (index != items.length - 1)
                Divider(height: 1, color: context.appPalette.stroke),
            ],
          ],
        ),
      ),
    );
  }

  Widget _documentRow(BuildContext context, TravelDocumentEntity item) {
    return InkWell(
      onTap: () => _openDocument(context, item.documentId),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFCEFEF),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 30,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18 / 1.2,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.fileName} • ${item.fileSizeLabel} • ${DateFormat.yMMMd().format(item.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8495B0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.remove_red_eye_rounded,
              size: 28,
              color: Color(0xFF97A8C3),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddDocument(BuildContext context, String tripTitle) async {
    final action = await _pickAddDocumentAction(context);
    if (action == null || !context.mounted) {
      return;
    }
    final detail = context.read<TravelTripDetailCubit>().state.detail;
    final List<TravelTimelineEventEntity> timelineEvents =
        detail?.timelineEvents ?? const <TravelTimelineEventEntity>[];
    bool changed;
    switch (action) {
      case _TravelWalletAddAction.uploadNew:
        if (!context.mounted) {
          return;
        }
        changed = await _openUploadNewDocument(
          context,
          tripTitle,
          timelineEvents,
        );
        break;
      case _TravelWalletAddAction.chooseFromVault:
        if (!context.mounted) {
          return;
        }
        changed = await _attachFromVault(context);
        break;
    }
    if (!context.mounted || !changed) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  Future<bool> _openUploadNewDocument(
    BuildContext context,
    String tripTitle,
    List<TravelTimelineEventEntity> timelineEvents,
  ) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TravelWalletDocumentEntryPage(
          tripId: tripId,
          tripTitle: tripTitle,
          events: timelineEvents,
        ),
      ),
    );
    return created == true;
  }

  Future<bool> _attachFromVault(BuildContext context) async {
    final selected = await Navigator.of(context).push<VaultDocumentEntity>(
      MaterialPageRoute(builder: (_) => const TravelVaultDocumentPickerPage()),
    );
    if (selected == null || !context.mounted) {
      return false;
    }
    try {
      final getDocumentDetail = getIt<GetDocumentDetail>();
      final createDocument = getIt<CreateScannedDocument>();
      final source = await getDocumentDetail(
        GetDocumentDetailParams(documentId: selected.documentId),
      );
      final sourceFilePath = _firstClaimValue(source, const [
        DocumentMetadataFieldLabels.referenceAssetPath,
        DocumentMetadataFieldLabels.frontImagePath,
        DocumentMetadataFieldLabels.previewImagePath,
      ]);
      final sourceFileName = _firstNonEmptyString([
        _firstClaimValue(source, const [
          DocumentMetadataFieldLabels.referenceAssetName,
        ]),
        source.fileName,
        selected.documentName,
      ]);
      final sourceFileMime = sourceFilePath.trim().isEmpty
          ? ''
          : sourceFilePath.inferMimeType();
      final issueDate = DateFormat('yyyy-MM-dd').format(source.uploadDate);
      final title = selected.documentName.trim().isEmpty
          ? source.screenTitle
          : selected.documentName;

      final structuredFields = <Map<String, String>>[
        {'label': 'Trip ID', 'value': tripId},
        {'label': 'Record Type', 'value': _travelRecordTypeWalletDocument},
        {'label': 'Document Type', 'value': selected.documentTypeLabel},
        {'label': 'Document Title', 'value': title},
        {'label': 'Issue Date', 'value': issueDate},
        {'label': 'Linked Source Document ID', 'value': source.id},
        {'label': 'File Name', 'value': sourceFileName},
        {'label': 'File Mime', 'value': sourceFileMime},
        {'label': DocumentMetadataFieldLabels.travelTripId, 'value': tripId},
        {
          'label': DocumentMetadataFieldLabels.travelRecordType,
          'value': _travelRecordTypeWalletDocument,
        },
        {
          'label': DocumentMetadataFieldLabels.travelDocumentType,
          'value': selected.documentTypeLabel,
        },
        {
          'label': DocumentMetadataFieldLabels.referenceAssetName,
          'value': sourceFileName,
        },
      ];
      if (sourceFilePath.trim().isNotEmpty) {
        structuredFields.addAll([
          {
            'label': DocumentMetadataFieldLabels.referenceAssetPath,
            'value': sourceFilePath,
          },
          {
            'label': DocumentMetadataFieldLabels.frontImagePath,
            'value': sourceFilePath,
          },
          {
            'label': DocumentMetadataFieldLabels.previewImagePath,
            'value': sourceFilePath,
          },
        ]);
      }
      final sanitizedFields = structuredFields
          .where((item) => (item['value'] ?? '').trim().isNotEmpty)
          .toList(growable: false);
      final tags = <String>{...source.tags, 'Travel', 'Document'};

      await createDocument(
        CreateScannedDocumentParams(
          type: DocumentType.other,
          source: source.captureSource,
          scanPagesCount: math.max(1, source.scanPagesCount),
          categoryOverride: DocumentCategoryType.travel,
          documentTypeKeyOverride: 'travel_$_travelRecordTypeWalletDocument',
          issuerOverride: title,
          identifierLabelOverride: 'Trip ID',
          identifierValueOverride: tripId,
          expiryDateOverride: selected.expiryDate ?? source.expiryDate,
          tagsOverride: tags.toList(growable: false),
          structuredFieldsOverride: sanitizedFields,
        ),
      );
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.travelWalletDocumentLinkedSuccess)),
      );
      return true;
    } catch (_) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.idEntryUnableSaveDocument)),
      );
      return false;
    }
  }

  Future<_TravelWalletAddAction?> _pickAddDocumentAction(BuildContext context) {
    return showAdaptiveModal<_TravelWalletAddAction>(
      context: context,
      backgroundColor: context.appPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.travelWalletAddDocumentAction,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _addDocumentOptionTile(
                  context,
                  icon: Icons.upload_file_rounded,
                  label: context.l10n.travelWalletUploadNewDocumentOption,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_TravelWalletAddAction.uploadNew),
                ),
                const SizedBox(height: 8),
                _addDocumentOptionTile(
                  context,
                  icon: Icons.folder_copy_outlined,
                  label: context.l10n.travelWalletChooseFromMyDocumentsOption,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_TravelWalletAddAction.chooseFromVault),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _addDocumentOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: context.appPalette.primary),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFFB9C7DB),
            ),
          ],
        ),
      ),
    );
  }

  String _firstClaimValue(DocumentDetailEntity detail, List<String> claimKeys) {
    for (final key in claimKeys) {
      for (final field in detail.structuredFields) {
        final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
          field.label,
        );
        if (canonical != key) {
          continue;
        }
        final value = field.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  String _firstNonEmptyString(List<String?> values) {
    for (final value in values) {
      if ((value ?? '').trim().isNotEmpty) {
        return value!.trim();
      }
    }
    return '';
  }

  Future<void> _openDocument(BuildContext context, String documentId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(documentId: documentId),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }
}

enum _TravelWalletAddAction { uploadNew, chooseFromVault }

const String _travelRecordTypeWalletDocument = 'wallet_document';

class _WalletAddDashedPainter extends CustomPainter {
  const _WalletAddDashedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D7F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 8).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
