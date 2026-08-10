import 'package:flutter/widgets.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';

extension AppL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
