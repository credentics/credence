import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_timeline_event_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/trip_event_category.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trip_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_event_entry_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelTimelinePage extends StatelessWidget {
  const TravelTimelinePage({
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
      child: _TravelTimelineView(
        tripId: tripId,
        fallbackTripTitle: fallbackTripTitle,
      ),
    );
  }
}

class _TravelTimelineView extends StatelessWidget {
  const _TravelTimelineView({
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
        final title = detail?.trip.title.trim().isNotEmpty == true
            ? detail!.trip.title
            : fallbackTripTitle;
        final palette = context.appPalette;
        return Scaffold(
          backgroundColor: palette.background,
          appBar: GenericAppBar(
            backgroundColor: palette.background,
            showDivider: false,
            onBackPressed: () => Navigator.of(context).maybePop(),
            title: context.l10n.travelTimelineTitle(title),
            titleStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          body: _body(context, state),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openAddEvent(context),
            backgroundColor: palette.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, TravelTripDetailState state) {
    final detail = state.detail;
    final palette = context.appPalette;
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
                color: palette.textSecondary,
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
    if (detail.timelineEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.timeline_rounded,
                  size: 34,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.travelTimelineEmptyTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.travelTimelineEmptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<TravelTimelineEventEntity>>{};
    for (final event in detail.timelineEvents) {
      final key = DateFormat('MMMM yyyy').format(event.startAt);
      grouped.putIfAbsent(key, () => <TravelTimelineEventEntity>[]).add(event);
    }
    final keys = grouped.keys.toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        for (final key in keys) ...[
          _monthHeader(context, key),
          const SizedBox(height: 16),
          ...grouped[key]!.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == grouped[key]!.length - 1;
            return _eventRow(context, event, isLast: isLast);
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _monthHeader(BuildContext context, String label) {
    final palette = context.appPalette;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  palette.stroke,
                  palette.stroke.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventRow(
    BuildContext context,
    TravelTimelineEventEntity event, {
    required bool isLast,
  }) {
    final palette = context.appPalette;
    final visual = _eventVisual(event.category);
    final hasDocuments = event.documentsCount > 0;
    final hasMapAction = event.locationLabel.trim().isNotEmpty;
    final linkUrl = _extractFirstLink(event);
    final hasLinkAction = (linkUrl ?? '').trim().isNotEmpty;
    final imageProvider = _resolvePreviewImageProvider(event.previewImagePath);
    final hasImagePreview = imageProvider != null;
    final hasConfirmation = event.confirmationCode.trim().isNotEmpty;
    final showConfirmedPill =
        hasConfirmation && event.category == TripEventCategory.travel;
    final showReservationTag = hasConfirmation && !showConfirmedPill;
    final hasActionRow = hasDocuments || hasMapAction || hasLinkAction;
    final subtitle = _eventSubtitle(event);
    final isPrimary = event.category == TripEventCategory.travel;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Node circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimary ? palette.primary : palette.surface,
                    border: isPrimary
                        ? null
                        : Border.all(color: palette.primary, width: 2),
                    boxShadow: isPrimary
                        ? [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    visual.icon,
                    size: 20,
                    color: isPrimary ? Colors.white : palette.primary,
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            palette.primary.withValues(alpha: 0.4),
                            palette.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Event card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openEditEvent(context, event),
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            if (showConfirmedPill) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primarySoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  context.l10n.travelTimelineConfirmed,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: palette.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.textMuted,
                          ),
                        ),
                        // Action chips
                        if (hasActionRow) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (hasDocuments)
                                _actionChip(
                                  context,
                                  icon: Icons.description_outlined,
                                  label: context.l10n
                                      .travelTimelineDocumentsCount(
                                        event.documentsCount,
                                      ),
                                ),
                              if (hasMapAction)
                                _actionChip(
                                  context,
                                  icon: Icons.map_outlined,
                                  label: context.l10n.travelTimelineOpenMap,
                                  accent: true,
                                  onTap: () => _copyMapLink(
                                    context,
                                    event.locationLabel,
                                  ),
                                ),
                              if (hasLinkAction)
                                _actionChip(
                                  context,
                                  icon: Icons.link_rounded,
                                  label: 'Link',
                                  onTap: () => _copyLink(context, linkUrl!),
                                ),
                            ],
                          ),
                        ],
                        // Image preview
                        if (hasImagePreview) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image(
                              image: imageProvider,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                        // Reservation tag
                        if (showReservationTag) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 14,
                                  color: Color(0xFFEA7A1B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  event.confirmationCode,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEA7A1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool accent = false,
    VoidCallback? onTap,
  }) {
    final palette = context.appPalette;
    final color = accent ? palette.primary : palette.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent ? palette.primarySoft : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddEvent(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            TravelEventEntryPage(tripId: tripId, tripTitle: fallbackTripTitle),
      ),
    );
    if (!context.mounted || created != true) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  Future<void> _openEditEvent(
    BuildContext context,
    TravelTimelineEventEntity event,
  ) async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TravelEventEntryPage(
          tripId: tripId,
          tripTitle: fallbackTripTitle,
          editDocumentId: event.eventId,
        ),
      ),
    );
    if (!context.mounted || edited != true) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  String _eventSubtitle(TravelTimelineEventEntity event) {
    final dateLabel = DateFormat('MMM d, hh:mm a').format(event.startAt);
    final location = event.locationLabel.trim();
    if (location.isEmpty) {
      return dateLabel;
    }
    return '$dateLabel  •  $location';
  }

  String? _extractFirstLink(TravelTimelineEventEntity event) {
    final sources = [event.notes, event.providerLabel, event.confirmationCode];
    for (final source in sources) {
      final candidate = _firstUrlFromText(source);
      if (candidate != null) {
        return candidate;
      }
    }
    return null;
  }

  String? _firstUrlFromText(String text) {
    final match = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    return match.group(0)?.replaceAll(RegExp(r'[),.;]+$'), '');
  }

  ImageProvider<Object>? _resolvePreviewImageProvider(String? rawPath) {
    final path = rawPath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    final localProvider = resolveLocalFileImageProvider(path);
    if (localProvider != null) {
      return localProvider;
    }
    final uri = Uri.tryParse(path);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(path);
    }
    return null;
  }

  Future<void> _copyMapLink(BuildContext context, String location) async {
    final query = location.trim();
    if (query.isEmpty) {
      return;
    }
    final mapUrl = 'https://maps.google.com/?q=${Uri.encodeComponent(query)}';
    await _copyToClipboard(
      context,
      value: mapUrl,
      successMessage: 'Map link copied',
    );
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await _copyToClipboard(context, value: url, successMessage: 'Link copied');
  }

  Future<void> _copyToClipboard(
    BuildContext context, {
    required String value,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

_TimelineEventVisual _eventVisual(TripEventCategory category) {
  return switch (category) {
    TripEventCategory.travel => const _TimelineEventVisual(
      icon: Icons.flight_rounded,
    ),
    TripEventCategory.stay => const _TimelineEventVisual(
      icon: Icons.hotel_rounded,
    ),
    TripEventCategory.dining => const _TimelineEventVisual(
      icon: Icons.restaurant_rounded,
    ),
    TripEventCategory.activity => const _TimelineEventVisual(
      icon: Icons.local_activity_rounded,
    ),
    TripEventCategory.reservation => const _TimelineEventVisual(
      icon: Icons.confirmation_number_rounded,
    ),
  };
}

class _TimelineEventVisual {
  const _TimelineEventVisual({required this.icon});

  final IconData icon;
}
