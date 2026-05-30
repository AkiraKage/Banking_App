import 'dart:async';

// Definisce un sistema di messaggistica interna (Event Bus) per comunicare cambiamenti tra parti diverse dell'app.
// Utilizza uno StreamController broadcast per permettere a più widget di ascoltare gli stessi eventi.
enum AppEvent { accountDataChanged }

class AppEvents {
  static final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  // Fornisce lo stream a cui i widget possono sottoscriversi per ricevere notifiche.
  static Stream<AppEvent> get stream => _controller.stream;

  // Invia un evento generico nello stream.
  static void emit(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  // Metodo di utility per segnalare che i dati del conto (saldo, transazioni) sono cambiati.
  static void emitAccountDataChanged() {
    emit(AppEvent.accountDataChanged);
  }

  // Chiude lo stream quando l'app viene chiusa per liberare le risorse.
  static Future<void> dispose() async {
    await _controller.close();
  }
}
