import 'dart:async';

class VaultDataRefreshSignal {
  VaultDataRefreshSignal._();

  static final StreamController<int> _controller =
      StreamController<int>.broadcast();
  static int _generation = 0;

  static Stream<int> get changes => _controller.stream;
  static int get generation => _generation;

  static void notifyRestoreCompleted() {
    _generation += 1;
    _controller.add(_generation);
  }
}
