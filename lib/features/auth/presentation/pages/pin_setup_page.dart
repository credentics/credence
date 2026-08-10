import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/app_lock_service.dart';
import 'package:pass_doc_manager/features/auth/presentation/widgets/auth_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

enum _PinSetupStep { intro, create, confirm }

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({
    super.key,
    required this.onComplete,
    this.showIntro = true,
  });

  final VoidCallback onComplete;
  final bool showIntro;

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  late _PinSetupStep _step;
  String _pin = '';
  String? _firstPin;
  bool _isError = false;
  bool _isSaving = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _step = widget.showIntro ? _PinSetupStep.intro : _PinSetupStep.create;
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await AppLockService.isBiometricAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
  }

  Future<void> _onDigit(String digit) async {
    if (_pin.length >= 6 || _isSaving || _step == _PinSetupStep.intro) return;

    setState(() {
      _pin += digit;
      _isError = false;
    });

    if (_pin.length != 6) return;

    if (_step == _PinSetupStep.create) {
      _firstPin = _pin;
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() {
        _pin = '';
        _step = _PinSetupStep.confirm;
      });
      return;
    }

    if (_pin != _firstPin) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isError = true;
        _pin = '';
      });
      return;
    }

    setState(() => _isSaving = true);
    await AppLockService.setPin(_pin);
    await AppLockService.recordSuccessfulUnlock();

    if (_biometricAvailable && mounted) {
      final enableBio = await _askBiometric();
      if (enableBio) {
        await AppLockService.setBiometricEnabled(true);
      }
    }

    if (!mounted) return;
    widget.onComplete();
  }

  Future<bool> _askBiometric() async {
    final l10n = context.l10n;
    final palette = context.appPalette;

    return await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: false,
          backgroundColor: palette.surface,
          barrierColor: Colors.black.withValues(alpha: 0.38),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          builder: (ctx) => AuthBiometricPrompt(
            title: l10n.authEnableBiometric,
            subtitle:
                '${l10n.authBiometricSubtitle} You can change this later in Settings.',
            primaryLabel: l10n.authBiometricEnable,
            secondaryLabel: l10n.authBiometricSkip,
            onPrimary: () => Navigator.pop(ctx, true),
            onSecondary: () => Navigator.pop(ctx, false),
          ),
        ) ??
        false;
  }

  void _onDelete() {
    if (_pin.isEmpty || _isSaving) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _isError = false;
    });
  }

  void _startCreate() {
    setState(() {
      _step = _PinSetupStep.create;
      _pin = '';
      _firstPin = null;
      _isError = false;
    });
  }

  void _showRestoreInfo() {
    final palette = context.appPalette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.strokeStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const AuthLockShield(icon: Icons.restore_rounded),
              const SizedBox(height: 14),
              Text(
                'Restore from backup',
                style: TextStyle(
                  fontFamily: authDisplayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your local PIN first, then use Backup & restore to import an encrypted archive with files, images, icons, and settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: authDisplayFont,
                  fontSize: 12.5,
                  height: 1.45,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AuthActionButton(
                label: 'Create PIN first',
                onTap: () {
                  Navigator.pop(ctx);
                  _startCreate();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthReferenceShell(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_step) {
          _PinSetupStep.intro => _IntroView(
            key: const ValueKey('intro'),
            onCreate: _startCreate,
            onRestore: _showRestoreInfo,
          ),
          _PinSetupStep.create || _PinSetupStep.confirm => _PinEntryView(
            key: ValueKey(_step),
            step: _step,
            pinValue: _pin,
            pinLength: _pin.length,
            isError: _isError,
            isSaving: _isSaving,
            onCancel: widget.showIntro
                ? () => setState(() => _step = _PinSetupStep.intro)
                : null,
            onDigit: _onDigit,
            onDelete: _onDelete,
          ),
        },
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({
    super.key,
    required this.onCreate,
    required this.onRestore,
  });

  final VoidCallback onCreate;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      children: [
        const SizedBox(height: 10),
        const Center(child: AuthLockShield()),
        const SizedBox(height: 14),
        Text(
          'Set up your vault.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: authDisplayFont,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
            height: 1.15,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A private place for credentials, identity papers, and recursive collections. Encrypted on this device.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: authDisplayFont,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        AuthOnboardingCard(
          icon: Icons.add_rounded,
          title: 'Create new vault',
          description:
              'Choose a passcode, then set up backup protection later. About 90 seconds.',
          onTap: onCreate,
          primary: true,
        ),
        const SizedBox(height: 8),
        AuthOnboardingCard(
          icon: Icons.restore_rounded,
          title: 'Restore from backup',
          description:
              'Already have a Credence backup? Bring back credentials, files, collection icons, and settings.',
          onTap: onRestore,
        ),
        const SizedBox(height: 22),
        Text(
          "WHAT YOU'LL CREATE",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: authMonoFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(
              child: _IntroFact(value: 'PIN', label: 'UNLOCK'),
            ),
            SizedBox(width: 6),
            Expanded(
              child: _IntroFact(value: 'FACE', label: 'BIOMETRIC'),
            ),
            SizedBox(width: 6),
            Expanded(
              child: _IntroFact(value: 'KEY', label: 'BACKUP'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'LOCAL · ENCRYPTED · NO ACCOUNT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: authMonoFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _IntroFact extends StatelessWidget {
  const _IntroFact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.stroke),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: authDisplayFont,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: authMonoFont,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.45,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinEntryView extends StatelessWidget {
  const _PinEntryView({
    super.key,
    required this.step,
    required this.pinValue,
    required this.pinLength,
    required this.isError,
    required this.isSaving,
    required this.onCancel,
    required this.onDigit,
    required this.onDelete,
  });

  final _PinSetupStep step;
  final String pinValue;
  final int pinLength;
  final bool isError;
  final bool isSaving;
  final VoidCallback? onCancel;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  bool get _isConfirm => step == _PinSetupStep.confirm;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final title = _isConfirm ? l10n.authConfirmPin : 'Set a 6-digit passcode';
    final subtitle = isError
        ? l10n.authPinMismatch
        : _isConfirm
        ? l10n.authConfirmPinSubtitle
        : 'Used to unlock this device. Different from your backup passphrase.';
    final notSequential =
        pinValue.length < 6 || (pinValue != '123456' && pinValue != '654321');
    final notRepeated =
        pinValue.length < 6 || pinValue.runes.toSet().length > 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            children: [
              Text(
                _isConfirm ? 'STEP 2 OF 3' : 'STEP 1 OF 3 · CREATE',
                style: TextStyle(
                  fontFamily: authMonoFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final filled = _isConfirm ? index < 2 : index == 0;
                    return Container(
                      width: 18,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: filled
                            ? palette.textPrimary
                            : palette.strokeStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
              if (onCancel == null)
                const SizedBox(width: 58)
              else
                InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.commonCancel,
                      style: TextStyle(
                        fontFamily: authMonoFont,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_isConfirm)
          const SizedBox(height: 96)
        else
          const AuthVaultMedallion(),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: authDisplayFont,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: authDisplayFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.48,
                  color: isError ? palette.danger : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AuthPinDots(filled: pinLength, error: isError, ok: isSaving),
        const SizedBox(height: 12),
        Text(
          isSaving
              ? 'MATCH · PASSCODE SET'
              : '${pinLength.clamp(0, 6)} OF 6 · ${6 - pinLength.clamp(0, 6)} TO GO',
          style: TextStyle(
            fontFamily: authMonoFont,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: isSaving ? palette.success : palette.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        if (!_isConfirm)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              AuthRulePill(label: 'Not 123456', met: notSequential),
              AuthRulePill(label: 'Not repeated', met: notRepeated),
            ],
          ),
        const Spacer(),
        IgnorePointer(
          ignoring: isSaving,
          child: Opacity(
            opacity: isSaving ? 0.45 : 1,
            child: AuthNumpad(onDigit: onDigit, onDelete: onDelete),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
