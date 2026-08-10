import 'package:flutter/services.dart';

/// Clipboard helper for secret values (passwords, recovery codes, …).
///
/// Copies the value and then schedules it to be wiped from the system
/// clipboard after [defaultClearAfter], so a copied password does not linger
/// (and end up in clipboard history / other apps) indefinitely.
class SensitiveClipboard {
  const SensitiveClipboard._();

  /// How long a secret stays on the clipboard before being auto-cleared.
  static const Duration defaultClearAfter = Duration(seconds: 45);

  /// Copies [value] to the clipboard, then clears it after [clearAfter] —
  /// but only if the clipboard still holds exactly [value] at that point, so
  /// we never clobber something the user copied in the meantime.
  ///
  /// Pass `Duration.zero` for [clearAfter] to copy without auto-clearing.
  static Future<void> copy(
    String value, {
    Duration clearAfter = defaultClearAfter,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (clearAfter <= Duration.zero) {
      return;
    }
    Future<void>.delayed(clearAfter, () async {
      try {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == value) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {
        // Clipboard access can fail under platform restrictions; ignore.
      }
    });
  }
}
