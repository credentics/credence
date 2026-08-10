import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_vaults.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/property_hub_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/property_hub_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_entry_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class PropertyHubPage extends StatelessWidget {
  const PropertyHubPage({
    super.key,
    GetPropertyVaults? getPropertyVaults,
    this.embeddedDesktop = false,
  }) : _getPropertyVaults = getPropertyVaults;

  final GetPropertyVaults? _getPropertyVaults;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PropertyHubCubit(getPropertyVaults: _getPropertyVaults)..load(),
      child: embeddedDesktop
          ? const _PropertyHubView(embeddedDesktop: true)
          : const _PropertyHubMobileScaffold(),
    );
  }
}

class _PropertyHubMobileScaffold extends StatelessWidget {
  const _PropertyHubMobileScaffold();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        backgroundColor: palette.background,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.propertyHubTitle,
        titleStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
        actionIcon: Icons.add_rounded,
        onActionPressed: () => _openCreateAndRefresh(context),
      ),
      body: const _PropertyHubView(embeddedDesktop: false),
    );
  }
}

class _PropertyHubView extends StatelessWidget {
  const _PropertyHubView({required this.embeddedDesktop});

  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    final horizontal = embeddedDesktop ? 24.0 : 16.0;
    return BlocBuilder<PropertyHubCubit, PropertyHubState>(
      builder: (context, state) {
        if ((state.viewStatus == PropertyHubViewStatus.initial ||
                state.viewStatus == PropertyHubViewStatus.loading) &&
            state.properties.isEmpty) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }

        if (state.viewStatus == PropertyHubViewStatus.error &&
            state.properties.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? context.l10n.propertyHubLoadError,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: context.read<PropertyHubCubit>().load,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        final properties = state.visibleProperties;

        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: embeddedDesktop ? 740 : 620,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  8,
                  horizontal,
                  embeddedDesktop ? 24 : 24,
                ),
                children: [
                  if (embeddedDesktop) ...[
                    _DesktopHeader(
                      onAddTap: () => _openCreateAndRefresh(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _PropertyFilterTabs(
                    selectedFilter: state.filter,
                    onFilterChanged: context.read<PropertyHubCubit>().setFilter,
                  ),
                  const SizedBox(height: 14),
                  if (properties.isEmpty)
                    _emptyCard(context)
                  else
                    ...properties.map(
                      (property) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PropertyCard(
                          property: property,
                          onTap: () => _openDetailAndRefresh(context, property),
                          onEdit: () => _openEditAndRefresh(context, property),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyCard(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.propertyHubEmptyTitle,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.propertyHubEmptySubtitle,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
          SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openCreateAndRefresh(context),
            icon: Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.propertyHubAddAction),
            style: FilledButton.styleFrom(
              backgroundColor: context.appPalette.primary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyFilterTabs extends StatelessWidget {
  const _PropertyFilterTabs({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final PropertyHubFilter selectedFilter;
  final ValueChanged<PropertyHubFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appPalette.stroke)),
      ),
      child: Row(
        children: [
          _PropertyFilterTab(
            label: context.l10n.propertyHubFilterAll,
            selected: selectedFilter == PropertyHubFilter.all,
            onTap: () => onFilterChanged(PropertyHubFilter.all),
          ),
          const SizedBox(width: 18),
          _PropertyFilterTab(
            label: context.l10n.propertyHubFilterOwned,
            selected: selectedFilter == PropertyHubFilter.owned,
            onTap: () => onFilterChanged(PropertyHubFilter.owned),
          ),
          const SizedBox(width: 18),
          _PropertyFilterTab(
            label: context.l10n.propertyHubFilterRented,
            selected: selectedFilter == PropertyHubFilter.rented,
            onTap: () => onFilterChanged(PropertyHubFilter.rented),
          ),
        ],
      ),
    );
  }
}

class _PropertyFilterTab extends StatelessWidget {
  const _PropertyFilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? context.appPalette.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22 / 1.45,
            fontWeight: FontWeight.w700,
            color: selected
                ? context.appPalette.primary
                : context.appPalette.textMuted,
          ),
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.appPalette.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.appPalette.primary,
              size: 20,
            ),
            splashRadius: 18,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.propertyHubTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.appPalette.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: onAddTap,
            icon: Icon(
              Icons.add_rounded,
              color: context.appPalette.primary,
              size: 24,
            ),
            splashRadius: 18,
            tooltip: context.l10n.propertyEntryAddTitle,
          ),
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.onTap,
    required this.onEdit,
  });

  final PropertyVaultEntity property;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final normalizedOwnership = property.ownershipStatusLabel.trim().isEmpty
        ? context.l10n.propertyEntryOwnedLabel
        : property.ownershipStatusLabel;
    final isRental = normalizedOwnership.toLowerCase().contains('rent');
    final chipBg = isRental ? const Color(0xFFE1F3EA) : palette.primarySoft;
    final chipText = isRental ? const Color(0xFF1B9A62) : palette.primary;
    final iconBackground = isRental
        ? const Color(0xFFE2F2EA)
        : palette.primarySoft;
    final updatedLabel = _relativeUpdatedLabel(context, property.lastUpdatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _propertyIconForType(property.propertyTypeLabel),
                      size: 28,
                      color: isRental
                          ? const Color(0xFF18A369)
                          : palette.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                property.propertyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                normalizedOwnership,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: chipText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                size: 20,
                                color: palette.textMuted,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: palette.textSecondary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(context.l10n.commonEdit),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          property.fullAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: palette.stroke),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 17,
                    color: palette.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.documentsCountLabel(property.documentsCount),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.history_rounded,
                    size: 17,
                    color: palette.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    updatedLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 21,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _propertyIconForType(String rawType) {
  final normalized = rawType.trim().toLowerCase();
  if (normalized.contains('office') || normalized.contains('commercial')) {
    return Icons.apartment_rounded;
  }
  if (normalized.contains('house') ||
      normalized.contains('townhouse') ||
      normalized.contains('vacation')) {
    return Icons.house_rounded;
  }
  if (normalized.contains('condo') || normalized.contains('apartment')) {
    return Icons.location_city_rounded;
  }
  if (normalized.contains('land')) {
    return Icons.terrain_rounded;
  }
  return Icons.domain_rounded;
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

Future<void> _openCreateAndRefresh(BuildContext context) async {
  final createdId = await Navigator.of(
    context,
  ).push<String>(MaterialPageRoute(builder: (_) => const PropertyEntryPage()));
  if (!context.mounted || (createdId ?? '').trim().isEmpty) {
    return;
  }
  await context.read<PropertyHubCubit>().load();
}

Future<void> _openDetailAndRefresh(
  BuildContext context,
  PropertyVaultEntity property,
) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PropertyDetailPage(
        propertyId: property.propertyId,
        propertyName: property.propertyName,
      ),
    ),
  );
  if (!context.mounted) {
    return;
  }
  await context.read<PropertyHubCubit>().load();
}

Future<void> _openEditAndRefresh(
  BuildContext context,
  PropertyVaultEntity property,
) async {
  final resultId = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => PropertyEntryPage(propertyToEdit: property),
    ),
  );
  if (!context.mounted || (resultId ?? '').trim().isEmpty) {
    return;
  }
  await context.read<PropertyHubCubit>().load();
}
