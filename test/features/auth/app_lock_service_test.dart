// @Tags(['integration'])
// These tests require FlutterSecureStorage which needs a platform channel.
// In a pure `flutter test` environment the secure storage calls will throw
// MissingPluginException. Run with `flutter test --tags integration` on a
// real device/emulator, or use `flutter drive` / integration_test.
//
// The tests are structured so they compile and document expected behaviour
// even when skipped in CI.

import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockService — PIN authentication', () {
    setUp(() async {
      try {
        await AppLockService.wipeAll();
      } catch (_) {
        // FlutterSecureStorage unavailable in unit test environment.
      }
    });

    test(
      'isPinConfigured returns false when no PIN set',
      () async {
        final configured = await AppLockService.isPinConfigured();
        expect(configured, isFalse);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'setPin and verifyPin with correct PIN returns true',
      () async {
        await AppLockService.setPin('1234');
        final result = await AppLockService.verifyPin('1234');
        expect(result, isTrue);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'verifyPin with incorrect PIN returns false',
      () async {
        await AppLockService.setPin('1234');
        final result = await AppLockService.verifyPin('9999');
        expect(result, isFalse);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'clearPin removes the PIN',
      () async {
        await AppLockService.setPin('5678');
        await AppLockService.clearPin();
        final configured = await AppLockService.isPinConfigured();
        expect(configured, isFalse);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );
  });

  group('AppLockService — brute-force lockout', () {
    setUp(() async {
      try {
        await AppLockService.wipeAll();
      } catch (_) {}
    });

    test(
      'recordFailedAttempt increments attempt count',
      () async {
        final count = await AppLockService.recordFailedAttempt();
        expect(count, 1);
        final count2 = await AppLockService.recordFailedAttempt();
        expect(count2, 2);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'isLockedOut returns false before 5 attempts',
      () async {
        for (var i = 0; i < 4; i++) {
          await AppLockService.recordFailedAttempt();
        }
        final locked = await AppLockService.isLockedOut();
        expect(locked, isFalse);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'isLockedOut returns true after 5 failed attempts',
      () async {
        for (var i = 0; i < 5; i++) {
          await AppLockService.recordFailedAttempt();
        }
        final locked = await AppLockService.isLockedOut();
        expect(locked, isTrue);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'resetAttempts clears lockout state',
      () async {
        for (var i = 0; i < 5; i++) {
          await AppLockService.recordFailedAttempt();
        }
        await AppLockService.resetAttempts();
        final locked = await AppLockService.isLockedOut();
        expect(locked, isFalse);
        final count = await AppLockService.failedAttemptCount;
        expect(count, 0);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'lockoutRemainingSeconds returns > 0 when locked out',
      () async {
        for (var i = 0; i < 5; i++) {
          await AppLockService.recordFailedAttempt();
        }
        final remaining = await AppLockService.lockoutRemainingSeconds();
        expect(remaining, greaterThan(0));
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );
  });

  group('AppLockService — lock timeout', () {
    setUp(() async {
      try {
        await AppLockService.wipeAll();
      } catch (_) {}
    });

    test(
      'getLockTimeout returns default 30 when not set',
      () async {
        final timeout = await AppLockService.getLockTimeout();
        expect(timeout, 30);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );

    test(
      'setLockTimeout persists value',
      () async {
        await AppLockService.setLockTimeout(120);
        final timeout = await AppLockService.getLockTimeout();
        expect(timeout, 120);
      },
      skip: 'Requires platform channel (FlutterSecureStorage)',
    );
  });
}
