import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LiveActivityService {
  const LiveActivityService._();

  static const MethodChannel _channel = MethodChannel(
    'pass_doc_manager/live_activity',
  );

  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (error) {
      debugPrint('[LiveActivity] Availability check failed: $error');
      return false;
    }
  }

  static Future<void> start({
    required String operation,
    required String provider,
    required String message,
    String detail = '',
    double progress = 0,
  }) {
    return _invoke(
      'start',
      operation: operation,
      provider: provider,
      message: message,
      detail: detail,
      progress: progress,
      status: 'running',
    );
  }

  static Future<void> update({
    required String operation,
    required String provider,
    required String message,
    String detail = '',
    double progress = 0,
  }) {
    return _invoke(
      'update',
      operation: operation,
      provider: provider,
      message: message,
      detail: detail,
      progress: progress,
      status: 'running',
    );
  }

  static Future<void> complete({
    required String operation,
    required String provider,
    required String message,
    String detail = '',
  }) {
    return _invoke(
      'end',
      operation: operation,
      provider: provider,
      message: message,
      detail: detail,
      progress: 1,
      status: 'success',
    );
  }

  static Future<void> fail({
    required String operation,
    required String provider,
    required String message,
    String detail = '',
    double progress = 0,
  }) {
    return _invoke(
      'end',
      operation: operation,
      provider: provider,
      message: message,
      detail: detail,
      progress: progress,
      status: 'failure',
    );
  }

  static Future<void> _invoke(
    String method, {
    required String operation,
    required String provider,
    required String message,
    required String detail,
    required double progress,
    required String status,
  }) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<Object?>(method, {
        'operation': operation,
        'provider': provider,
        'message': message,
        'detail': detail,
        'progress': progress.clamp(0, 1),
        'status': status,
      });
    } catch (error) {
      debugPrint('[LiveActivity] $method failed: $error');
    }
  }
}
