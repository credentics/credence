import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/theme_preference.dart';

class ThemeController extends ChangeNotifier {
  ThemeController([ThemeMode initial = ThemeMode.system]) : _mode = initial;

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    _mode = await ThemePreference.load();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await ThemePreference.save(mode);
  }

  static ThemeController of(BuildContext context) {
    return _ThemeControllerScope.of(context);
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);
}

class _ThemeControllerScope {
  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    return scope!.notifier!;
  }
}
