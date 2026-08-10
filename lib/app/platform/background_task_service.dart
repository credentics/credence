import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundTaskService {
  const BackgroundTaskService._();

  static const _channel = MethodChannel('pass_doc_manager/background_task');
  static int _screenAwakeDepth = 0;

  static Future<BackgroundTaskLease> protect(String reason) async {
    final id = await begin(reason);
    await keepScreenAwake(true);
    return BackgroundTaskLease._(id);
  }

  static Future<int?> begin(String reason) async {
    if (kIsWeb) {
      return null;
    }
    try {
      return await _channel.invokeMethod<int>('begin', <String, Object?>{
        'reason': reason,
      });
    } on MissingPluginException {
      return null;
    } catch (error) {
      debugPrint('[BackgroundTask] begin failed: $error');
      return null;
    }
  }

  static Future<void> end(int? id) async {
    if (kIsWeb || id == null) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('end', <String, Object?>{'id': id});
    } on MissingPluginException {
      return;
    } catch (error) {
      debugPrint('[BackgroundTask] end failed: $error');
    }
  }

  static Future<void> keepScreenAwake(bool enabled) async {
    if (kIsWeb) {
      return;
    }
    if (enabled) {
      _screenAwakeDepth += 1;
      if (_screenAwakeDepth > 1) {
        return;
      }
    } else {
      if (_screenAwakeDepth == 0) {
        return;
      }
      _screenAwakeDepth -= 1;
      if (_screenAwakeDepth > 0) {
        return;
      }
    }

    try {
      await _channel.invokeMethod<void>('setScreenAwake', <String, Object?>{
        'enabled': enabled,
      });
    } on MissingPluginException {
      return;
    } catch (error) {
      debugPrint('[BackgroundTask] setScreenAwake failed: $error');
    }
  }
}

class BackgroundTaskLease {
  BackgroundTaskLease._(this._id);

  final int? _id;
  bool _closed = false;

  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await BackgroundTaskService.keepScreenAwake(false);
    await BackgroundTaskService.end(_id);
  }
}
