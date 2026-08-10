import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_expense_category.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_expense_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trip_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_budget_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_expense_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelExpensesPage extends StatelessWidget {
  const TravelExpensesPage({
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
      child: _TravelExpensesView(
        tripId: tripId,
        fallbackTripTitle: fallbackTripTitle,
      ),
    );
  }
}

class _TravelExpensesView extends StatelessWidget {
  const _TravelExpensesView({
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
        final palette = context.appPalette;
        return Scaffold(
          backgroundColor: palette.background,
          appBar: GenericAppBar(
            backgroundColor: palette.surface,
            onBackPressed: () => Navigator.of(context).maybePop(),
            title: context.l10n.travelExpensesTitle,
            titleStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
            actionIcon: Icons.more_horiz_rounded,
            onActionPressed: detail == null
                ? null
                : () => _openBudgetEditor(context, detail.trip.title),
          ),
          body: _body(context, state, tripTitle),
          floatingActionButton: FloatingActionButton(
            onPressed: detail == null
                ? null
                : () => _openAddExpense(context, tripTitle),
            backgroundColor: const Color(0xFF1F57D4),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded, size: 32),
          ),
          bottomNavigationBar: TravelBottomNavStrip(
            items: travelBottomItemsExpenses(),
            activeKey: 'expenses',
          ),
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

    final totalSpent = detail.expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final budgetLimit = detail.budget?.totalBudget ?? (totalSpent * 1.55);
    final remaining = (budgetLimit - totalSpent)
        .clamp(0.0, double.infinity)
        .toDouble();
    final progress = budgetLimit <= 0
        ? 0.0
        : (totalSpent / budgetLimit).clamp(0.0, 1.0).toDouble();
    final currency = detail.budget?.currencyCode ?? detail.trip.currencyCode;
    final grouped = <TravelExpenseCategory, List<TravelExpenseEntity>>{
      for (final category in TravelExpenseCategory.values)
        category: detail.expenses
            .where((item) => item.category == category)
            .toList(growable: false),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                title: context.l10n.travelExpensesTotalSpentTitle,
                value: _formatMoney(totalSpent, currency),
                subtitle: context.l10n.travelExpensesVsLastTrip,
                highlighted: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                context,
                title: context.l10n.travelExpensesRemainingTitle,
                value: _formatMoney(remaining, currency),
                subtitle: context.l10n.travelExpensesBudgetLabel(
                  _formatMoney(budgetLimit, currency),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Text(
              context.l10n.travelExpensesBudgetStatus,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 22 / 1.45,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            backgroundColor: context.appPalette.surfaceSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F57D4)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              context.l10n.travelExpensesSpentLabel(
                _formatMoney(totalSpent, currency),
              ),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              context.l10n.travelExpensesLimitLabel(
                _formatMoney(budgetLimit, currency),
              ),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...TravelExpenseCategory.values
            .where((category) {
              return grouped[category]!.isNotEmpty;
            })
            .map((category) {
              final records = grouped[category]!;
              final categoryTotal = records.fold<double>(
                0,
                (sum, item) => sum + item.amount,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _categorySoftColor(category),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _expenseCategoryIcon(category),
                            size: 17,
                            color: _categoryColor(category),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _expenseCategoryLabel(context, category),
                            style: TextStyle(
                              fontSize: 17 / 1.12,
                              fontWeight: FontWeight.w700,
                              color: context.appPalette.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatMoney(categoryTotal, currency),
                          style: TextStyle(
                            fontSize: 17 / 1.12,
                            fontWeight: FontWeight.w700,
                            color: context.appPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...records
                        .take(3)
                        .map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _expenseRow(context, expense),
                          ),
                        ),
                  ],
                ),
              );
            }),
        if (detail.expenses.isEmpty)
          TravelSurfaceCard(
            child: Column(
              children: [
                Text(
                  context.l10n.travelExpensesEmptyTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.l10n.travelExpensesEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: highlighted ? context.appPalette.primarySoft : context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appPalette.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textMuted,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 28 / 1.45,
              fontWeight: FontWeight.w800,
              color: highlighted ? context.appPalette.primary : context.appPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w600,
              color: highlighted
                  ? const Color(0xFF1E9E63)
                  : context.appPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseRow(BuildContext context, TravelExpenseEntity expense) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17 / 1.2,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, hh:mm a').format(expense.occurredAt),
                  style: TextStyle(
                    fontSize: 14.3,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            '-${_formatMoney(expense.amount, expense.currencyCode)}',
            style: TextStyle(
              fontSize: 18 / 1.2,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddExpense(BuildContext context, String tripTitle) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            TravelExpenseEntryPage(tripId: tripId, tripTitle: tripTitle),
      ),
    );
    if (!context.mounted || created != true) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  Future<void> _openBudgetEditor(BuildContext context, String tripTitle) async {
    final detail = context.read<TravelTripDetailCubit>().state.detail;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TravelBudgetPage(
          tripId: tripId,
          tripTitle: tripTitle,
          initialBudget: detail?.budget,
        ),
      ),
    );
    if (!context.mounted || changed != true) {
      return;
    }
    await context.read<TravelTripDetailCubit>().load(tripId: tripId);
  }

  String _formatMoney(double value, String currencyCode) {
    final symbol = _currencySymbol(currencyCode);
    return '$symbol${value.toStringAsFixed(2)}';
  }
}

String _currencySymbol(String currencyCode) {
  return switch (currencyCode) {
    'EUR' => '€',
    'JPY' => '¥',
    'GBP' => '£',
    _ => '\$',
  };
}

IconData _expenseCategoryIcon(TravelExpenseCategory category) {
  return switch (category) {
    TravelExpenseCategory.foodDining => Icons.restaurant_rounded,
    TravelExpenseCategory.transport => Icons.directions_car_filled_rounded,
    TravelExpenseCategory.activities => Icons.local_activity_rounded,
    TravelExpenseCategory.accommodation => Icons.hotel_rounded,
    TravelExpenseCategory.shopping => Icons.shopping_bag_rounded,
    TravelExpenseCategory.other => Icons.more_horiz_rounded,
  };
}

String _expenseCategoryLabel(
  BuildContext context,
  TravelExpenseCategory category,
) {
  return switch (category) {
    TravelExpenseCategory.foodDining => context.l10n.travelExpensesCategoryFood,
    TravelExpenseCategory.transport =>
      context.l10n.travelExpensesCategoryTransport,
    TravelExpenseCategory.activities =>
      context.l10n.travelExpensesCategoryActivities,
    TravelExpenseCategory.accommodation =>
      context.l10n.travelExpensesCategoryAccommodation,
    TravelExpenseCategory.shopping =>
      context.l10n.travelExpensesCategoryShopping,
    TravelExpenseCategory.other => context.l10n.travelExpensesCategoryOther,
  };
}

Color _categorySoftColor(TravelExpenseCategory category) {
  return switch (category) {
    TravelExpenseCategory.transport => const Color(0xFFEAF0FD),
    TravelExpenseCategory.accommodation => const Color(0xFFF2E9FD),
    TravelExpenseCategory.foodDining => const Color(0xFFFDEFD9),
    TravelExpenseCategory.activities => const Color(0xFFE8F8EE),
    TravelExpenseCategory.shopping => const Color(0xFFFDEAF2),
    TravelExpenseCategory.other => const Color(0xFFF0F3F8),
  };
}

Color _categoryColor(TravelExpenseCategory category) {
  return switch (category) {
    TravelExpenseCategory.transport => const Color(0xFF1F57D4),
    TravelExpenseCategory.accommodation => const Color(0xFF8A3FFC),
    TravelExpenseCategory.foodDining => const Color(0xFFEF7D1A),
    TravelExpenseCategory.activities => const Color(0xFF10A26C),
    TravelExpenseCategory.shopping => const Color(0xFFE91E63),
    TravelExpenseCategory.other => const Color(0xFF64748B),
  };
}
