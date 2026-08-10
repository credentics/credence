import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pass_doc_manager/app/presentation/pages/app_root_page.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/app/theme/app_typography.dart';
import 'package:pass_doc_manager/app/theme/theme_controller.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/app_lock_service.dart';
import 'package:pass_doc_manager/features/collections/presentation/services/reminder_notification_service.dart';
import 'package:pass_doc_manager/features/documents/infrastructure/services/document_expiry_service.dart';
import 'package:pass_doc_manager/features/tasks/infrastructure/services/task_notification_service.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/features/auth/presentation/pages/lock_screen_page.dart';
import 'package:pass_doc_manager/features/auth/presentation/pages/pin_setup_page.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/shared_backup_cubit.dart';
import 'package:pass_doc_manager/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';

/// App launch flow:
/// 1. Loading (checking state)
/// 2. Onboarding (first launch only)
/// 3. PIN setup (after onboarding, if no PIN yet)
/// 4. Lock screen (on every launch if PIN is configured)
/// 5. App root (unlocked)
enum _AppGateState { loading, onboarding, pinSetup, locked, unlocked }

class CredenceApp extends StatefulWidget {
  const CredenceApp({super.key});

  @override
  State<CredenceApp> createState() => _CredenceAppState();
}

class _CredenceAppState extends State<CredenceApp> with WidgetsBindingObserver {
  static const _onboardingKey = 'onboarding_completed';
  // Don't re-check auto-backup more often than this. Even if `shouldAutoBackup`
  // is fast, the trigger threshold (daily/weekly/monthly) means a check can
  // legitimately return true every resume between the due-date and the next
  // `recordBackupCompleted()` — without this guard, a user backgrounding and
  // resuming many times can stack auto-backup runs.
  static const _autoBackupMinInterval = Duration(minutes: 30);
  // Wait this long after resume before kicking off auto-backup so the resume
  // animation, lock-screen unlock, and home rebuild have all settled.
  static const _autoBackupResumeDelay = Duration(seconds: 5);

  _AppGateState _gate = _AppGateState.loading;
  DateTime? _backgroundedAt;
  DateTime? _lastAutoBackupCheck;
  bool _autoBackupRunning = false;
  Timer? _autoBackupTimer;
  final _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLockService.lockRequests.addListener(_handleLockRequest);
    _themeController.load();
    _resolveGate();
  }

  @override
  void dispose() {
    _autoBackupTimer?.cancel();
    _themeController.dispose();
    AppLockService.lockRequests.removeListener(_handleLockRequest);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleLockRequest() {
    if (!mounted || _gate != _AppGateState.unlocked) return;
    setState(() => _gate = _AppGateState.locked);
  }

  Future<void> _resolveGate() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    // 1. Check onboarding
    final onboardingDone = await storage.read(key: _onboardingKey);
    if (onboardingDone == null) {
      if (!mounted) return;
      setState(() => _gate = _AppGateState.onboarding);
      return;
    }

    // 2. Check PIN
    final hasPIN = await AppLockService.isPinConfigured();
    if (!hasPIN) {
      if (!mounted) return;
      setState(() => _gate = _AppGateState.pinSetup);
      return;
    }

    // 3. PIN is set → lock
    if (!mounted) return;
    setState(() => _gate = _AppGateState.locked);
  }

  Future<void> _completeOnboarding() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.write(key: _onboardingKey, value: 'true');
    if (!mounted) return;
    setState(() => _gate = _AppGateState.pinSetup);
  }

  void _completePinSetup() {
    if (!mounted) return;
    _backgroundedAt = null;
    setState(() => _gate = _AppGateState.unlocked);
    _initNotifications();
  }

  void _unlock() {
    if (!mounted) return;
    _backgroundedAt = null;
    setState(() => _gate = _AppGateState.unlocked);
    _initNotifications();
  }

  bool _notificationsInitialized = false;

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;
    try {
      await ReminderNotificationService.instance.init();
      await ReminderNotificationService.instance.requestPermissions();
      await getIt<DocumentExpiryService>().scheduleExpiryNotifications();
      await getIt<TaskNotificationService>().scheduleTaskNotifications();
    } catch (e) {
      debugPrint('[App] Notification init failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      EncryptedHiveBoxFactory.clearCachedKey();
      _backgroundedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      _checkLockAfterResume();
      _scheduleAutoBackupCheck();
    }
  }

  Future<void> _checkLockAfterResume() async {
    if (_gate != _AppGateState.unlocked || _backgroundedAt == null) return;

    final hasPIN = await AppLockService.isPinConfigured();
    if (!mounted || _gate != _AppGateState.unlocked) return;
    if (!hasPIN) return;

    final lockWhenLeaving = await AppLockService.isLockWhenLeavingEnabled();
    if (!mounted || _gate != _AppGateState.unlocked) return;
    if (lockWhenLeaving) {
      if (mounted) setState(() => _gate = _AppGateState.locked);
      _backgroundedAt = null;
      return;
    }

    final timeout = await AppLockService.getLockTimeout();
    if (!mounted || _gate != _AppGateState.unlocked) return;
    if (timeout < 0) {
      _backgroundedAt = null;
      return; // -1 = never lock
    }

    final elapsed = DateTime.now().difference(_backgroundedAt!).inSeconds;
    if (elapsed >= timeout) {
      if (mounted) setState(() => _gate = _AppGateState.locked);
    }
    _backgroundedAt = null;
  }

  void _handleVaultWiped() {
    if (!mounted) return;
    setState(() => _gate = _AppGateState.loading);
    _resolveGate();
  }

  /// Defers the auto-backup check off the resume frame and debounces against
  /// rapid background→foreground cycles, so the streaming mirror write never
  /// competes with the resume animation.
  void _scheduleAutoBackupCheck() {
    // Master kill switch — see `kAutoBackupDisabled` in backup_cubit.dart.
    // Even with the kill switch on, the cubit's `autoBackupIfNeeded` would
    // already short-circuit. Skipping here too avoids spinning a timer and
    // building a cubit on every resume just to early-return.
    if (kAutoBackupDisabled) return;
    if (_autoBackupRunning) return;
    final last = _lastAutoBackupCheck;
    if (last != null &&
        DateTime.now().difference(last) < _autoBackupMinInterval) {
      return;
    }
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer(_autoBackupResumeDelay, () {
      if (!mounted) return;
      unawaited(_checkAutoBackup());
    });
  }

  Future<void> _checkAutoBackup() async {
    if (_autoBackupRunning) return;
    // Never start a silent auto-backup on top of a user-initiated vault
    // operation: it runs on its own cubit and would otherwise write the same
    // local mirror concurrently. The shared cubit is the source of truth for
    // user-driven create/upload/restore.
    final userOp = sharedBackupCubit.state;
    if (userOp.isCreating || userOp.isUploading || userOp.isRestoring) {
      return;
    }
    _autoBackupRunning = true;
    _lastAutoBackupCheck = DateTime.now();
    try {
      final cubit = BackupCubit();
      await cubit.autoBackupIfNeeded();
      await cubit.close();
    } catch (e) {
      debugPrint('[App] Auto-backup check failed: $e');
    } finally {
      _autoBackupRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appTitle,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            AppFlowyEditorLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // Temporarily force light mode while the refreshed UI is being aligned.
          themeMode: ThemeMode.light,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final shortestSide = mediaQuery.size.shortestSide;
            final scale = switch (shortestSide) {
              < 380 => 0.92,
              < 430 => 0.96,
              _ => 1.0,
            };
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: switch (_gate) {
            _AppGateState.loading => const Scaffold(body: SizedBox.shrink()),
            _AppGateState.onboarding => OnboardingPage(
              onComplete: _completeOnboarding,
            ),
            _AppGateState.pinSetup => PinSetupPage(
              onComplete: _completePinSetup,
              showIntro: false,
            ),
            _AppGateState.locked => LockScreenPage(
              onUnlocked: _unlock,
              onVaultWiped: _handleVaultWiped,
            ),
            _AppGateState.unlocked => const AppRootPage(),
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final transitionBuilder = CupertinoPageTransitionsBuilder();
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? const AppPalette.dark() : const AppPalette.light();
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final appTextTheme = AppTypography.build(base.textTheme);
    final manropeTextTheme = appTextTheme.apply(fontFamily: 'Manrope');

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: TargetPlatform.iOS,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
        primary: palette.primary,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        secondary: palette.primaryAccent,
        error: palette.danger,
      ),
      textTheme: manropeTextTheme,
      primaryTextTheme: manropeTextTheme,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: transitionBuilder,
          TargetPlatform.iOS: transitionBuilder,
          TargetPlatform.macOS: transitionBuilder,
          TargetPlatform.windows: transitionBuilder,
          TargetPlatform.linux: transitionBuilder,
        },
      ),
      cardColor: palette.surface,
      dividerColor: palette.strokeStrong,
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(4),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return palette.textMuted;
          }
          if (states.contains(WidgetState.hovered)) {
            return palette.textMuted.withValues(alpha: 0.7);
          }
          return palette.textMuted.withValues(alpha: 0.4);
        }),
      ),
      extensions: [palette],
    );
  }
}
