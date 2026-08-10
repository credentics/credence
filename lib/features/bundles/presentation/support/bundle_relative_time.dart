import 'package:intl/intl.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';

/// Formats [at] as a short relative phrase ("just now", "2 min ago",
/// "yesterday", "3 days ago"). Anything older than 7 days falls back to
/// a localized absolute date. Future timestamps are clamped to "just now".
String formatBundleRelative(
  DateTime at,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(at);

  if (diff.isNegative || diff.inSeconds < 45) {
    return l10n.bundleTimeJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.bundleTimeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.bundleTimeHoursAgo(diff.inHours);
  }
  if (diff.inDays < 2) {
    return l10n.bundleTimeYesterday;
  }
  if (diff.inDays < 7) {
    return l10n.bundleTimeDaysAgo(diff.inDays);
  }
  return DateFormat.yMMMd().format(at.toLocal());
}
