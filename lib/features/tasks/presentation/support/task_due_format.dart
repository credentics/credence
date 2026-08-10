import 'package:intl/intl.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';

/// Formats a due date as short text relative to today, falling back to
/// an absolute date when the delta is more than a week out.
///
/// [dayDelta] is the number of full days between today and the due date
/// (negative = overdue, 0 = today, 1 = tomorrow, …). Pre-computed by the
/// caller so we don't recalculate DateTime math on every rebuild.
String formatDueLabel(
  DateTime due,
  AppLocalizations l10n, {
  required int dayDelta,
}) {
  if (dayDelta < 0) {
    return l10n.taskDueOverdueBy(dayDelta.abs());
  }
  if (dayDelta == 0) {
    return l10n.taskDueToday;
  }
  if (dayDelta == 1) {
    return l10n.taskDueTomorrow;
  }
  if (dayDelta < 7) {
    return l10n.taskDueInDays(dayDelta);
  }
  return DateFormat.yMMMd().format(due.toLocal());
}
