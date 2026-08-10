import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trip_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_expenses_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_trip_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_trip_notes_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_timeline_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_wallet_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelTripDashboardPage extends StatelessWidget {
  const TravelTripDashboardPage({
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
      child: _TravelTripDashboardView(
        tripId: tripId,
        fallbackTripTitle: fallbackTripTitle,
      ),
    );
  }
}

class _TravelTripDashboardView extends StatelessWidget {
  const _TravelTripDashboardView({
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
        final range = detail == null
            ? ''
            : '${DateFormat.MMMd().format(detail.trip.startDate)} - ${DateFormat.MMMd().format(detail.trip.endDate)}, ${detail.trip.endDate.year}';
        final canEditTrip = (detail?.trip.profileDocumentId ?? '')
            .trim()
            .isNotEmpty;

        final palette = context.appPalette;
        return Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _header(
                      context,
                      title: title,
                      subtitle: range,
                      onBack: () => Navigator.of(context).maybePop(),
                      onEdit: !canEditTrip || detail == null
                          ? null
                          : () => _openEditTrip(context, detail),
                    ),
                    Expanded(child: _body(context, state)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onBack,
    VoidCallback? onEdit,
  }) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.stroke)),
      ),
      child: Row(
        children: [
          _headerIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22 / 1.25,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (subtitle.trim().isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7A8CA9),
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            _headerIconButton(
              icon: Icons.edit_outlined,
              onTap: onEdit,
              tooltip: context.l10n.commonEdit,
            )
          else
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, TravelTripDetailState state) {
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        _heroCard(context, detail),
        SizedBox(height: 16),
        Text(
          context.l10n.travelDashboardSectionTitle,
          style: TextStyle(
            fontSize: 34 / 2.2,
            fontWeight: FontWeight.w700,
            color: context.appPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _moduleCard(
          context,
          icon: Icons.calendar_today_rounded,
          title: context.l10n.travelDashboardTimelineTitle,
          subtitle: context.l10n.travelDashboardTimelineCount(
            detail.timelineEvents.length,
          ),
          onTap: () => _openTimeline(context, detail),
        ),
        const SizedBox(height: 10),
        _moduleCard(
          context,
          icon: Icons.description_rounded,
          title: context.l10n.travelDashboardDocumentsTitle,
          subtitle: context.l10n.travelDashboardDocumentsCount(
            detail.walletDocuments.length,
          ),
          onTap: () => _openWallet(context, detail),
        ),
        const SizedBox(height: 10),
        _moduleCard(
          context,
          icon: Icons.account_balance_wallet_rounded,
          title: context.l10n.travelDashboardExpensesTitle,
          subtitle: context.l10n.travelDashboardExpensesSpent(
            _formatCurrency(detail.trip.totalSpent, detail.trip.currencyCode),
          ),
          onTap: () => _openExpenses(context, detail),
        ),
        const SizedBox(height: 10),
        _moduleCard(
          context,
          icon: Icons.credit_card_rounded,
          title: context.l10n.travelDashboardWalletTitle,
          subtitle: context.l10n.travelDashboardWalletSummary(
            detail.walletDocuments.length,
          ),
          onTap: () => _openWallet(context, detail),
        ),
        const SizedBox(height: 10),
        _moduleCard(
          context,
          icon: Icons.notes_rounded,
          title: context.l10n.collectionEntryNotes,
          subtitle: _notesSubtitle(context, detail.trip.notes),
          onTap: () => _openNotes(context, detail),
        ),
        if (detail.upcomingReminderTitle.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: context.appPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appPalette.stroke),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flight_takeoff_rounded,
                  color: context.appPalette.primary,
                  size: 19,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.upcomingReminderTitle,
                        style: TextStyle(
                          fontSize: 16 / 1.18,
                          fontWeight: FontWeight.w700,
                          color: context.appPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail.upcomingReminderSubtitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667A98),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: context.appPalette.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _heroCard(BuildContext context, TravelTripDetailEntity detail) {
    final remainingDays = detail.trip.endDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 999);
    final coverImage = _resolveCoverImageProvider(detail.trip.coverImagePath);
    final destination = detail.trip.destinationSummary.trim().isEmpty
        ? context.l10n.travelDashboardDefaultDestination
        : detail.trip.destinationSummary;
    return TravelSurfaceCard(
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 194,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverImage != null)
                Positioned.fill(
                  child: Image(image: coverImage, fit: BoxFit.cover),
                ),
              if (coverImage == null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2B4D87),
                        const Color(0xFF1A3563).withValues(alpha: 0.95),
                        const Color(0xFF0F223E).withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  child: CustomPaint(painter: _MapPatternPainter()),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: coverImage == null
                          ? [const Color(0x00000000), const Color(0x26000000)]
                          : [const Color(0x33070F21), const Color(0x88070F21)],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 12,
                child: TravelStatusPill(
                  label: context.l10n.travelDashboardDaysLeft(remainingDays),
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  foregroundColor: Colors.white,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.travelDashboardHeroTitle(destination),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 37 / 1.8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC9D8F5),
                      ),
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

  Widget _moduleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appPalette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: const Color(0xFF1F57D4)),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17.5 / 1.13,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14.5 / 1.1,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6F819E),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC1CDE0),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 20,
      icon: Icon(icon, size: 22, color: const Color(0xFF60728E)),
    );
  }

  Future<void> _openEditTrip(
    BuildContext context,
    TravelTripDetailEntity detail,
  ) async {
    final documentId = (detail.trip.profileDocumentId ?? '').trim();
    if (documentId.isEmpty) {
      return;
    }
    final updatedTripId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TravelTripEntryPage(
          editDocumentId: documentId,
          tripId: detail.trip.tripId,
        ),
      ),
    );
    if (!context.mounted || (updatedTripId ?? '').trim().isEmpty) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  Future<void> _openTimeline(
    BuildContext context,
    TravelTripDetailEntity detail,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TravelTimelinePage(
          tripId: detail.trip.tripId,
          fallbackTripTitle: detail.trip.title,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  Future<void> _openExpenses(
    BuildContext context,
    TravelTripDetailEntity detail,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TravelExpensesPage(
          tripId: detail.trip.tripId,
          fallbackTripTitle: detail.trip.title,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  Future<void> _openWallet(
    BuildContext context,
    TravelTripDetailEntity detail,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TravelWalletPage(
          tripId: detail.trip.tripId,
          fallbackTripTitle: detail.trip.title,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  Future<void> _openNotes(
    BuildContext context,
    TravelTripDetailEntity detail,
  ) async {
    final documentId = (detail.trip.profileDocumentId ?? '').trim();
    if (documentId.isEmpty) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TravelTripNotesPage(
          documentId: documentId,
          fallbackTripTitle: detail.trip.title,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  String _notesSubtitle(BuildContext context, String notes) {
    final trimmed = notes.trim();
    if (trimmed.isEmpty) {
      return context.l10n.secureNotesEmpty;
    }
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.length <= 48) {
      return collapsed;
    }
    return '${collapsed.substring(0, 48).trimRight()}...';
  }

  String _formatCurrency(double value, String currencyCode) {
    final formatter = NumberFormat.currency(symbol: '$currencyCode ');
    return formatter.format(value);
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 24; i++) {
      final y = random.nextDouble() * size.height;
      final startX = random.nextDouble() * size.width * 0.3;
      final endX = size.width - (random.nextDouble() * size.width * 0.2);
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y + random.nextDouble() * 16),
        paint,
      );
    }
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (var i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
