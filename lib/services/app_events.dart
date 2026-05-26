import 'dart:async';

enum AppEvent { accountDataChanged }

class AppEvents {
  static final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  static Stream<AppEvent> get stream => _controller.stream;

  static void emit(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  static void emitAccountDataChanged() {
    emit(AppEvent.accountDataChanged);
  }

  static Future<void> dispose() async {
    await _controller.close();
  }
}
