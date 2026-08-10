import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trips.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trips_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trips_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_trip_dashboard_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_trip_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelTripsPage extends StatelessWidget {
  const TravelTripsPage({
    super.key,
    GetTravelTrips? getTravelTrips,
    this.embeddedDesktop = false,
  }) : _getTravelTrips = getTravelTrips;

  final GetTravelTrips? _getTravelTrips;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TravelTripsCubit(getTravelTrips: _getTravelTrips)..load(),
      child: embeddedDesktop
          ? const _TravelTripsView(embeddedDesktop: true)
          : const _TravelTripsScaffold(),
    );
  }
}

class _TravelTripsScaffold extends StatelessWidget {
  const _TravelTripsScaffold();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        backgroundColor: palette.surface,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        centerTitle: false,
        title: context.l10n.travelTripsTitle,
        titleSpacing: 16,
        titleStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
        ),
        actions: const [SizedBox(width: 6)],
      ),
      body: const _TravelTripsView(embeddedDesktop: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _TravelTripsView._openCreateAndRefresh(context),
        backgroundColor: const Color(0xFF1F57D4),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 34),
      ),
    );
  }
}

class _TravelTripsView extends StatelessWidget {
  const _TravelTripsView({required this.embeddedDesktop});

  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelTripsCubit, TravelTripsState>(
      builder: (context, state) {
        if ((state.viewStatus == TravelTripsViewStatus.initial ||
                state.viewStatus == TravelTripsViewStatus.loading) &&
            state.trips.isEmpty) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }
        if (state.viewStatus == TravelTripsViewStatus.error &&
            state.trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.travelTripsLoadError,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: context.read<TravelTripsCubit>().load,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        final trips = state.visibleTrips;
        return SafeArea(
          top: embeddedDesktop,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: embeddedDesktop ? 760 : 520,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
                children: [
                  if (embeddedDesktop) ...[
                    Row(
                      children: [
                        Text(
                          context.l10n.travelTripsTitle,
                          style: TextStyle(
                            fontSize: 38 / 1.55,
                            fontWeight: FontWeight.w800,
                            color: context.appPalette.textPrimary,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  _filterRow(context, state),
                  const SizedBox(height: 12),
                  if (trips.isEmpty)
                    _emptyState(context)
                  else ...[
                    ...trips.map(
                      (trip) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _tripCard(context, trip),
                      ),
                    ),
                    _startTripCard(context),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterRow(BuildContext context, TravelTripsState state) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appPalette.stroke)),
      ),
      child: Row(
        children: [
          _filterTab(
            context,
            label: context.l10n.travelTripsFilterUpcoming,
            active: state.filter == TravelTripsFilter.upcoming,
            onTap: () => context.read<TravelTripsCubit>().setFilter(
              TravelTripsFilter.upcoming,
            ),
          ),
          const SizedBox(width: 18),
          _filterTab(
            context,
            label: context.l10n.travelTripsFilterPast,
            active: state.filter == TravelTripsFilter.past,
            onTap: () => context.read<TravelTripsCubit>().setFilter(
              TravelTripsFilter.past,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? context.appPalette.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22 / 1.45,
            fontWeight: FontWeight.w700,
            color: active
                ? context.appPalette.primary
                : context.appPalette.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _tripCard(BuildContext context, TravelTripEntity trip) {
    final palette = context.appPalette;
    final now = DateTime.now();
    final radius = BorderRadius.circular(24);
    final dateRange =
        '${DateFormat.MMMd().format(trip.startDate)} — ${DateFormat.MMMd().format(trip.endDate)}';
    final daysToStart = trip.startDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final cover = _resolveCoverImageProvider(trip.coverImagePath);
    final hasCover = cover != null;
    final statusLabel = daysToStart > 0
        ? context.l10n.travelTripsStatusInDays(daysToStart)
        : context.l10n.travelTripsStatusPlanned;
    final expenseValue = _formatCurrency(trip.totalSpent, trip.currencyCode);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: () => _openDashboard(context, trip),
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: radius,
            border: Border.all(color: palette.stroke),
            boxShadow: const [
              BoxShadow(
                color: travelCardShadowColor,
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCover)
                AspectRatio(
                  aspectRatio: 2.1,
                  child: Image(image: cover, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 26 / 1.35,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        TravelStatusPill(
                          label: statusLabel,
                          backgroundColor: const Color(0xFFEAF0FD),
                          foregroundColor: context.appPalette.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFF7286A4),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            trip.destinationSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20 / 1.35,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF61738F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: palette.stroke),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _tripInfoMetric(
                            label: context.l10n.travelTripsDatesLabel,
                            value: dateRange,
                            valueColor: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _tripInfoMetric(
                            label: context.l10n.travelDashboardExpensesTitle
                                .toUpperCase(),
                            value: expenseValue,
                            valueColor: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: palette.stroke),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 17,
                          color: const Color(0xFF8FA0BA),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.travelTripsDocumentsCount(
                            trip.documentsCount,
                          ),
                          style: const TextStyle(
                            fontSize: 15 / 1.1,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8FA0BA),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: Color(0xFFB8C7DC),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripInfoMetric({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
            color: Color(0xFF90A0B7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18 / 1.08,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value, String currencyCode) {
    final symbol = switch (currencyCode.toUpperCase()) {
      'EUR' => '€',
      'JPY' => '¥',
      'GBP' => '£',
      _ => '\$',
    };
    return '$symbol${value.toStringAsFixed(2)}';
  }

  ImageProvider<Object>? _resolveCoverImageProvider(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final localProvider = resolveLocalFileImageProvider(trimmed);
    if (localProvider != null) {
      return localProvider;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(trimmed);
    }
    return null;
  }

  Widget _startTripCard(BuildContext context) {
    return InkWell(
      onTap: () => _openCreateAndRefresh(context),
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: const _TripStartDashedPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF0F4FB),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: Color(0xFF9BADCA),
                ),
              ),
              SizedBox(height: 10),
              Text(
                context.l10n.travelTripsStartNewTripTitle,
                style: TextStyle(
                  fontSize: 17.5 / 1.15,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.travelTripsStartNewTripSubtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8FA0BA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TravelSurfaceCard(
        child: Column(
          children: [
            Text(
              context.l10n.travelTripsEmptyTitle,
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
            SizedBox(height: 5),
            Text(
              context.l10n.travelTripsEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: context.appPalette.textSecondary,
              ),
            ),
            SizedBox(height: 12),
            FilledButton(
              onPressed: () => _openCreateAndRefresh(context),
              style: FilledButton.styleFrom(
                backgroundColor: context.appPalette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(context.l10n.travelTripsCreateFirstAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDashboard(
    BuildContext context,
    TravelTripEntity trip,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TravelTripDashboardPage(
          tripId: trip.tripId,
          fallbackTripTitle: trip.title,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<TravelTripsCubit>().load();
  }

  static Future<void> _openCreateAndRefresh(BuildContext context) async {
    final createdTripId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const TravelTripEntryPage()),
    );
    if (!context.mounted || (createdTripId ?? '').trim().isEmpty) {
      return;
    }
    await context.read<TravelTripsCubit>().load();
  }
}

class _TripStartDashedPainter extends CustomPainter {
  const _TripStartDashedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD2DDEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
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
