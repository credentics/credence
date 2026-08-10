import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/app_lock_service.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/vault_wipe_service.dart';
import 'package:pass_doc_manager/features/auth/presentation/widgets/auth_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({
    super.key,
    required this.onUnlocked,
    required this.onVaultWiped,
  });

  final VoidCallback onUnlocked;
  final VoidCallback onVaultWiped;

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  String _enteredPin = '';
  bool _isError = false;
  bool _isVerifying = false;
  bool _biometricAvailable = false;
  bool _isLockedOut = false;
  int _lockoutRemaining = 0;
  int _failedAttempts = 0;
  DateTime? _lastUnlockedAt;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _hydrateState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _hydrateState() async {
    await Future.wait([
      _checkLockoutState(),
      _checkBiometric(),
      _loadLastUnlockedAt(),
    ]);
  }

  Future<void> _loadLastUnlockedAt() async {
    final value = await AppLockService.lastUnlockedAt();
    if (!mounted) return;
    setState(() => _lastUnlockedAt = value);
  }

  Future<void> _checkLockoutState() async {
    final remaining = await AppLockService.lockoutRemainingSeconds();
    final attempts = await AppLockService.failedAttemptCount;
    if (!mounted) return;
    setState(() {
      _failedAttempts = attempts;
      _lockoutRemaining = remaining;
      _isLockedOut = remaining > 0;
    });
    if (remaining > 0) _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }
      setState(() {
        _lockoutRemaining--;
        if (_lockoutRemaining <= 0) {
          _isLockedOut = false;
          _isError = false;
          _lockoutRemaining = 0;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  Future<void> _checkBiometric() async {
    final available = await AppLockService.isBiometricAvailable();
    final enabled = await AppLockService.isBiometricEnabled();
    if (!mounted) return;
    setState(() => _biometricAvailable = available && enabled);

    if (available && enabled) {
      unawaited(_attemptBiometric());
    }
  }

  Future<void> _attemptBiometric() async {
    if (_isLockedOut || _isVerifying) return;
    final success = await AppLockService.authenticateWithBiometrics(
      reason: 'Unlock your Credence vault',
    );
    if (!success || !mounted) return;
    await AppLockService.recordSuccessfulUnlock();
    widget.onUnlocked();
  }

  Future<void> _onDigit(String digit) async {
    if (_isVerifying || _enteredPin.length >= 6 || _isLockedOut) return;

    setState(() {
      _enteredPin += digit;
      _isError = false;
    });

    if (_enteredPin.length != 6) return;

    setState(() => _isVerifying = true);

    final lockedOut = await AppLockService.isLockedOut();
    if (lockedOut) {
      await _checkLockoutState();
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _enteredPin = '';
      });
      return;
    }

    final valid = await AppLockService.verifyPin(_enteredPin);
    if (!mounted) return;

    if (valid) {
      await AppLockService.recordSuccessfulUnlock();
      widget.onUnlocked();
      return;
    }

    HapticFeedback.heavyImpact();
    final attempts = await AppLockService.recordFailedAttempt();
    final wipeAfterFive = await AppLockService.isWipeAfterFiveAttemptsEnabled();
    if (wipeAfterFive && attempts >= 5) {
      await VaultWipeService.wipeLocalVault();
      if (mounted) widget.onVaultWiped();
      return;
    }

    final remaining = await AppLockService.lockoutRemainingSeconds();
    if (!mounted) return;

    setState(() {
      _failedAttempts = attempts;
      _isError = true;
      _isVerifying = false;
      _enteredPin = '';
      if (remaining > 0) {
        _isLockedOut = true;
        _lockoutRemaining = remaining;
        _startCountdown();
      }
    });
  }

  void _onDelete() {
    if (_enteredPin.isEmpty || _isVerifying || _isLockedOut) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _isError = false;
    });
  }

  String _formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _lastUnlockLabel() {
    final value = _lastUnlockedAt;
    if (value == null) return 'Last unlocked · first secure session';
    final now = DateTime.now();
    final isToday =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return isToday
        ? 'Last unlocked · today, $hour:$minute'
        : 'Last unlocked · ${value.month}/${value.day}/${value.year}';
  }

  int _attemptsUntilNextLockout() {
    const thresholds = [5, 10, 15];
    for (final t in thresholds) {
      if (_failedAttempts < t) return t - _failedAttempts;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final isWarningState = _isLockedOut || _isError;
    final subtitle = _isLockedOut
        ? l10n.lockScreenTryAgainIn(_formatCountdown(_lockoutRemaining))
        : _isError
        ? l10n.lockScreenAttemptsRemaining(_attemptsUntilNextLockout())
        : _lastUnlockLabel();

    return AuthReferenceShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 760;
          final topPadding = compact ? 10.0 : 22.0;
          final showFaceCta = _biometricAvailable && !_isLockedOut && !compact;

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, topPadding, 18, 4),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 360,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CREDENCE · LOCKED',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: authMonoFont,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: isWarningState
                                  ? const AuthLockShield(
                                      icon: Icons.lock_outline_rounded,
                                      warn: true,
                                      size: 68,
                                    )
                                  : const AuthVaultMedallion(large: true),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _isLockedOut
                                  ? l10n.lockScreenTooManyAttempts
                                  : _isError
                                  ? 'Incorrect passcode'
                                  : 'Unlock vault',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: authDisplayFont,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.45,
                                color: isWarningState
                                    ? palette.danger
                                    : palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _isError || _isLockedOut
                                    ? authDisplayFont
                                    : authMonoFont,
                                fontSize: _isError || _isLockedOut ? 12.5 : 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: _isError || _isLockedOut
                                    ? 0
                                    : 1.1,
                                color: _isError || _isLockedOut
                                    ? palette.danger
                                    : palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (isWarningState)
                              const AuthPinDots(filled: 6, error: true)
                            else
                              AuthPinDots(filled: _enteredPin.length),
                            const SizedBox(height: 12),
                            Text(
                              _isLockedOut
                                  ? 'SOFT LOCK ACTIVE'
                                  : _isVerifying
                                  ? 'VERIFYING'
                                  : _isError
                                  ? 'WRONG PASSCODE'
                                  : '${_enteredPin.length} OF 6',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: authMonoFont,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: isWarningState
                                    ? palette.danger
                                    : palette.textMuted,
                              ),
                            ),
                            if (_failedAttempts > 0) ...[
                              const SizedBox(height: 14),
                              _AttemptMeter(
                                failedAttempts: _failedAttempts,
                                isLockedOut: _isLockedOut,
                              ),
                            ],
                            if (_isError && !_isLockedOut) ...[
                              const SizedBox(height: 12),
                              const _WrongPinNotice(),
                            ],
                            if (showFaceCta) ...[
                              const SizedBox(height: 16),
                              _FaceIdCta(onTap: _attemptBiometric),
                              const SizedBox(height: 10),
                              _MonoDivider(label: 'OR TYPE PASSCODE'),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: _isLockedOut || _isVerifying,
                child: Opacity(
                  opacity: _isLockedOut ? 0.3 : 1,
                  child: AuthNumpad(onDigit: _onDigit, onDelete: _onDelete),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

class _FaceIdCta extends StatelessWidget {
  const _FaceIdCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.stroke),
            gradient: LinearGradient(
              colors: [
                palette.surface,
                palette.primarySoft.withValues(alpha: 0.55),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.textPrimary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.face_retouching_natural_rounded,
                  color: palette.surface,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock with Face ID',
                      style: TextStyle(
                        fontFamily: authDisplayFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.14,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SECURE ENCLAVE · PIN FALLBACK',
                      style: TextStyle(
                        fontFamily: authMonoFont,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.55,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: palette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.stroke),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonoDivider extends StatelessWidget {
  const _MonoDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Row(
      children: [
        Expanded(child: Divider(color: palette.stroke)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: authMonoFont,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: palette.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: palette.stroke)),
      ],
    );
  }
}

class _AttemptMeter extends StatelessWidget {
  const _AttemptMeter({
    required this.failedAttempts,
    required this.isLockedOut,
  });

  final int failedAttempts;
  final bool isLockedOut;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final used = failedAttempts.clamp(0, 5);
    final remaining = (5 - used).clamp(0, 5);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              width: 22,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index < used ? palette.danger : palette.strokeStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          isLockedOut
              ? 'PIN entry paused after repeated failures'
              : '$used of 5 attempts · $remaining left before 60s lock',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: authDisplayFont,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WrongPinNotice extends StatelessWidget {
  const _WrongPinNotice();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.danger.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: palette.danger,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wipe after wrong PIN is off',
                  style: TextStyle(
                    fontFamily: authDisplayFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Repeated failures create a temporary lock. Your vault data stays on device.',
                  style: TextStyle(
                    fontFamily: authDisplayFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
