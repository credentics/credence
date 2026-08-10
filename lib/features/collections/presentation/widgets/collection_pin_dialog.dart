import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

/// Shows a dialog to verify a collection PIN.
/// Returns `true` if the entered PIN matches the stored [pinHash].
Future<bool> showCollectionPinVerifyDialog({
  required BuildContext context,
  required String pinHash,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CollectionPinDialog(
      pinHash: pinHash,
      isSetup: false,
    ),
  );
  return result == true;
}

/// Shows a dialog to set a new collection PIN.
/// Returns the SHA-256 hash of the entered PIN, or `null` if cancelled.
Future<String?> showCollectionPinSetupDialog({
  required BuildContext context,
}) async {
  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CollectionPinDialog(
      pinHash: null,
      isSetup: true,
    ),
  );
}

/// Hashes a PIN using SHA-256 with a fixed salt (stored alongside the hash
/// inside the collection record, so we use the PIN itself as the salt domain).
Future<String> hashCollectionPin(String pin) async {
  final sha256 = Sha256();
  final hash = await sha256.hash(utf8.encode('collection_pin:$pin'));
  return base64.encode(hash.bytes);
}

class _CollectionPinDialog extends StatefulWidget {
  const _CollectionPinDialog({
    required this.pinHash,
    required this.isSetup,
  });

  final String? pinHash;
  final bool isSetup;

  @override
  State<_CollectionPinDialog> createState() => _CollectionPinDialogState();
}

class _CollectionPinDialogState extends State<_CollectionPinDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _verifying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.length != 4) {
      setState(() => _error = context.l10n.collectionPinHint);
      return;
    }

    if (widget.isSetup) {
      // Return the hash of the new PIN.
      final hash = await hashCollectionPin(pin);
      if (!mounted) return;
      Navigator.of(context).pop(hash);
      return;
    }

    // Verify against stored hash.
    setState(() => _verifying = true);
    final hash = await hashCollectionPin(pin);
    if (!mounted) return;

    if (hash == widget.pinHash) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _verifying = false;
        _error = context.l10n.collectionPinIncorrect;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(
        widget.isSetup ? l10n.collectionPinSetTitle : l10n.collectionPinLockTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
              color: palette.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.collectionPinHint,
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
                letterSpacing: 0,
              ),
              counterText: '',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.isSetup ? null : false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _verifying ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: palette.primary,
          ),
          child: _verifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isSetup ? l10n.commonSave : 'Unlock'),
        ),
      ],
    );
  }
}
