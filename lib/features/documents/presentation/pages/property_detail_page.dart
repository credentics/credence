import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_summary_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/property_detail_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/property_detail_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_asset_records_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_document_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_entry_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class PropertyDetailPage extends StatelessWidget {
  const PropertyDetailPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    GetPropertyDetail? getPropertyDetail,
  }) : _getPropertyDetail = getPropertyDetail;

  final String propertyId;
  final String propertyName;
  final GetPropertyDetail? _getPropertyDetail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PropertyDetailCubit(getPropertyDetail: _getPropertyDetail)
            ..load(propertyId: propertyId),
      child: _PropertyDetailView(
        propertyId: propertyId,
        propertyName: propertyName,
      ),
    );
  }
}

class _PropertyDetailView extends StatelessWidget {
  const _PropertyDetailView({
    required this.propertyId,
    required this.propertyName,
  });

  final String propertyId;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyDetailCubit, PropertyDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        final title = detail?.propertyName.trim().isNotEmpty == true
            ? detail!.propertyName
            : propertyName;
        return Scaffold(
          backgroundColor: context.appPalette.background,
          appBar: GenericAppBar(
            backgroundColor: context.appPalette.surface,
            onBackPressed: () => Navigator.of(context).maybePop(),
            title: title,
            titleStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                child: _TopSquareAction(
                  icon: Icons.edit_rounded,
                  onTap: detail == null
                      ? null
                      : () => _openEditAndRefresh(context, detail),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                child: _TopSquareAction(
                  icon: Icons.add_rounded,
                  onTap: detail == null
                      ? null
                      : () => _openAddDocumentAndRefresh(context, detail),
                ),
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PropertyDetailState state) {
    final detail = state.detail;
    if ((state.viewStatus == PropertyDetailViewStatus.initial ||
            state.viewStatus == PropertyDetailViewStatus.loading) &&
        detail == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }
    if (state.viewStatus == PropertyDetailViewStatus.error && detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? context.l10n.propertyDetailLoadError,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<PropertyDetailCubit>().load(
                propertyId: propertyId,
              ),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    if (detail == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              _overviewCard(context, detail),
              SizedBox(height: 14),
              Text(
                context.l10n.propertyDetailAssetsTitle,
                style: TextStyle(
                  fontSize: 34 / 2.3,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textMuted,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              ...detail.assetSummaries.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _assetTile(
                    context,
                    item,
                    onTap: () => _openAssetRecordsAndRefresh(
                      context,
                      detail,
                      assetType: item.assetType,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewCard(BuildContext context, PropertyDetailEntity detail) {
    final palette = context.appPalette;
    final occupancyChip = detail.occupancyStatusLabel.trim().isEmpty
        ? context.l10n.propertyEntryOwnedLabel
        : detail.occupancyStatusLabel.trim();
    final subtitle = detail.propertyTypeLabel.trim().isNotEmpty
        ? context.l10n.propertyDetailTypeSubtitle(detail.propertyTypeLabel)
        : context.l10n.propertyDetailSubtitleFallback;
    final secondaryChip = detail.monthlyAmountLabel.trim().isNotEmpty
        ? detail.monthlyAmountLabel
        : detail.ownershipStatusLabel.trim().isEmpty
        ? context.l10n.propertyEntryOwnedLabel
        : detail.ownershipStatusLabel;
    final showSecondaryChip =
        secondaryChip.trim().isNotEmpty &&
        !_isSameStatusLabel(secondaryChip, occupancyChip);
    final address = detail.fullAddress.trim();
    final relative = _relativeUpdatedLabel(context, detail.lastUpdatedAt);
    final totalItems = detail.assetSummaries.fold<int>(
      0,
      (sum, item) => sum + item.itemsCount,
    );
    final footerText =
        '${context.l10n.documentsCountLabel(totalItems)} • ${context.l10n.workHubUpdatedCompact(relative)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.apartment_rounded,
                  size: 28,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.propertyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 21 / 1.1,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: palette.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                label: occupancyChip,
                background: palette.primarySoft,
                foreground: palette.primary,
              ),
              if (showSecondaryChip)
                _chip(
                  label: secondaryChip,
                  background: palette.surfaceSoft,
                  foreground: palette.textSecondary,
                ),
              if (detail.monthlyAmountLabel.trim().isNotEmpty)
                _chip(
                  label: detail.monthlyAmountLabel.trim(),
                  background: const Color(0xFFE6F4ED),
                  foreground: const Color(0xFF18825C),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            footerText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetTile(
    BuildContext context,
    PropertyAssetSummaryEntity summary, {
    required VoidCallback onTap,
  }) {
    final visual = _assetVisual(summary.assetType);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appPalette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: visual.iconBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(visual.icon, size: 27, color: visual.iconColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visual.title(context),
                      style: TextStyle(
                        fontSize: 18 / 1.15,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      visual.countLabel(context, summary.itemsCount),
                      style: TextStyle(
                        fontSize: 16 / 1.17,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: context.appPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddDocumentAndRefresh(
    BuildContext context,
    PropertyDetailEntity detail, {
    PropertyAssetType? initialAssetType,
  }) async {
    final resultId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PropertyDocumentEntryPage(
          propertyId: detail.propertyId,
          propertyName: detail.propertyName,
          initialAssetType: initialAssetType,
        ),
      ),
    );
    if (!context.mounted || (resultId ?? '').trim().isEmpty) {
      return;
    }
    await context.read<PropertyDetailCubit>().load(propertyId: propertyId);
  }

  Future<void> _openAssetRecordsAndRefresh(
    BuildContext context,
    PropertyDetailEntity detail, {
    required PropertyAssetType assetType,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PropertyAssetRecordsPage(
          propertyId: detail.propertyId,
          propertyName: detail.propertyName,
          assetType: assetType,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<PropertyDetailCubit>().load(propertyId: propertyId);
  }

  Future<void> _openEditAndRefresh(
    BuildContext context,
    PropertyDetailEntity detail,
  ) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PropertyEntryPage(
          propertyToEdit: PropertyVaultEntity(
            propertyId: detail.propertyId,
            propertyName: detail.propertyName,
            propertyTypeLabel: detail.propertyTypeLabel,
            ownershipStatusLabel: detail.ownershipStatusLabel,
            fullAddress: detail.fullAddress,
            addressSuggestionJson: detail.addressSuggestionJson,
            lastUpdatedAt: detail.lastUpdatedAt,
            documentsCount: detail.assetSummaries.fold<int>(
              0,
              (sum, item) => sum + item.itemsCount,
            ),
            profileDocumentId: detail.profileDocumentId,
          ),
        ),
      ),
    );
    if (!context.mounted || (result ?? '').trim().isEmpty) {
      return;
    }
    await context.read<PropertyDetailCubit>().load(propertyId: propertyId);
  }

  Widget _chip({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15 / 1.2,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _AssetVisual {
  const _AssetVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.countLabel,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String Function(BuildContext context) title;
  final String Function(BuildContext context, int count) countLabel;
}

class _TopSquareAction extends StatelessWidget {
  const _TopSquareAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.appPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 24, color: context.appPalette.textPrimary),
          ),
        ),
      ),
    );
  }
}

_AssetVisual _assetVisual(PropertyAssetType type) {
  return switch (type) {
    PropertyAssetType.documents => _AssetVisual(
      icon: Icons.folder_rounded,
      iconColor: const Color(0xFF2B5ED9),
      iconBackground: const Color(0xFFE8EEFB),
      title: (context) => context.l10n.propertyDetailAssetDocuments,
      countLabel: (context, count) =>
          context.l10n.propertyDetailFilesCount(count),
    ),
    PropertyAssetType.contracts => _AssetVisual(
      icon: Icons.description_rounded,
      iconColor: const Color(0xFFDD8700),
      iconBackground: const Color(0xFFF9F1DF),
      title: (context) => context.l10n.propertyDetailAssetContracts,
      countLabel: (context, count) =>
          context.l10n.propertyDetailFilesCount(count),
    ),
    PropertyAssetType.insurance => _AssetVisual(
      icon: Icons.verified_user_rounded,
      iconColor: const Color(0xFF9E46DA),
      iconBackground: const Color(0xFFF1E7F8),
      title: (context) => context.l10n.propertyDetailAssetInsurance,
      countLabel: (context, count) =>
          context.l10n.propertyDetailFilesCount(count),
    ),
    PropertyAssetType.payments => _AssetVisual(
      icon: Icons.payments_rounded,
      iconColor: const Color(0xFF169A66),
      iconBackground: const Color(0xFFE1F4EB),
      title: (context) => context.l10n.propertyDetailAssetPayments,
      countLabel: (context, count) =>
          context.l10n.propertyDetailRecordsCount(count),
    ),
    PropertyAssetType.maintenance => _AssetVisual(
      icon: Icons.handyman_rounded,
      iconColor: const Color(0xFFE93A62),
      iconBackground: const Color(0xFFFBE9ED),
      title: (context) => context.l10n.propertyDetailAssetMaintenance,
      countLabel: (context, count) =>
          context.l10n.propertyDetailActiveRequestsCount(count),
    ),
    PropertyAssetType.others => _AssetVisual(
      icon: Icons.more_horiz_rounded,
      iconColor: const Color(0xFF6B7C97),
      iconBackground: const Color(0xFFEFF2F8),
      title: (context) => context.l10n.propertyDetailAssetOthers,
      countLabel: (context, count) =>
          context.l10n.propertyDetailFilesCount(count),
    ),
  };
}

String _relativeUpdatedLabel(BuildContext context, DateTime updatedAt) {
  final diff = DateTime.now().difference(updatedAt);
  if (diff.inDays >= 30) {
    final months = math.max(1, diff.inDays ~/ 30);
    return context.l10n.homeRelativeMonthsAgo(months);
  }
  if (diff.inDays >= 7) {
    final weeks = math.max(1, diff.inDays ~/ 7);
    return context.l10n.homeRelativeWeeksAgo(weeks);
  }
  if (diff.inDays >= 1) {
    return context.l10n.homeRelativeDaysAgo(diff.inDays);
  }
  if (diff.inHours >= 1) {
    return context.l10n.homeRelativeHoursAgo(diff.inHours);
  }
  final minutes = math.max(1, diff.inMinutes);
  return context.l10n.homeRelativeMinutesAgo(minutes);
}

bool _isSameStatusLabel(String left, String right) {
  final leftNormalized = left.trim().toLowerCase();
  final rightNormalized = right.trim().toLowerCase();
  if (leftNormalized == rightNormalized) {
    return true;
  }
  const rentalTokens = <String>{'rent', 'rental', 'rented', 'leased', 'lease'};
  final leftIsRental = rentalTokens.any(leftNormalized.contains);
  final rightIsRental = rentalTokens.any(rightNormalized.contains);
  if (leftIsRental && rightIsRental) {
    return true;
  }
  const ownedTokens = <String>{'own', 'owned', 'occup', 'resident'};
  final leftIsOwned = ownedTokens.any(leftNormalized.contains);
  final rightIsOwned = ownedTokens.any(rightNormalized.contains);
  return leftIsOwned && rightIsOwned;
}
