import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/storage_keys.dart';
import '../widgets/pin_boxes_input.dart';
import 'main_layout.dart';

// Schermata per la configurazione iniziale del PIN di sicurezza dell'utente.
// Gestisce il processo di doppia immissione (creazione e conferma) e l'attivazione della biometria.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  // FlutterSecureStorage garantisce che il PIN venga salvato in modo criptato sul dispositivo.
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  bool _isConfirming = false;
  String _firstPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Richiede automaticamente il focus sul campo PIN appena la schermata è pronta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_pinFocusNode);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // Elabora l'input del PIN distinguendo tra prima immissione e conferma.
  Future<void> _handlePinInput(String val) async {
    if (!_isConfirming) {
      // Fase 1: Memorizza il primo PIN e passa alla fase di conferma.
      await _animController.reverse();
      setState(() {
        _firstPin = val;
        _isConfirming = true;
        _errorMessage = null;
        _pinController.clear();
      });
      _animController.forward();
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_pinFocusNode);
    } else {
      // Fase 2: Verifica che il PIN di conferma sia identico al primo.
      if (val == _firstPin) {
        await _storage.write(key: StorageKeys.userPin, value: val);
        if (!mounted) return;
        _promptBiometrics();
      } else {
        setState(() {
          _errorMessage = 'I PIN non corrispondono. Riprova.';
          _pinController.clear();
        });
        FocusScope.of(context).requestFocus(_pinFocusNode);
      }
    }
  }

  // Propone all'utente di abilitare i sensori biometrici del dispositivo (impronta/viso).
  Future<void> _promptBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!mounted) return;

    if (!canCheck) {
      await _storage.write(key: StorageKeys.useBiometrics, value: 'false');
      _goToHome();
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint_rounded, size: 26),
            SizedBox(width: 10),
            Text('Accesso biometrico'),
          ],
        ),
        content: const Text(
          'Vuoi usare impronta digitale o Face ID per accedere più velocemente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, grazie'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Attiva'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      try {
        final ok = await _localAuth.authenticate(
          localizedReason: 'Conferma la biometria per abilitarla',
          biometricOnly: true,
        );
        await _storage.write(
          key: StorageKeys.useBiometrics,
          value: ok ? 'true' : 'false',
        );
      } catch (_) {
        await _storage.write(key: StorageKeys.useBiometrics, value: 'false');
      }
    } else {
      await _storage.write(key: StorageKeys.useBiometrics, value: 'false');
    }

    if (mounted) _goToHome();
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icona decorativa che cambia in base allo stato del processo.
                Container(
                  width: 72,
                  height: 72,
                  margin: const EdgeInsets.only(bottom: 28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isConfirming
                        ? Icons.lock_reset_rounded
                        : Icons.lock_person_rounded,
                    size: 38,
                    color: primary,
                  ),
                ),

                // Titoli animati per guidare l'utente nei passaggi.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _isConfirming
                        ? 'Conferma il PIN'
                        : 'Crea un PIN di sicurezza',
                    key: ValueKey(_isConfirming),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isConfirming
                      ? 'Inserisci nuovamente il PIN per confermarlo'
                      : 'Questo codice a 6 cifre proteggerà il tuo conto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 48),

                // Widget personalizzato per l'immissione del PIN in caselle separate.
                PinBoxesInput(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  autofocus: true,
                  onChanged: (_) => setState(() => _errorMessage = null),
                  onCompleted: _handlePinInput,
                ),

                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_isConfirming) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isConfirming = false;
                        _firstPin = '';
                        _errorMessage = null;
                        _pinController.clear();
                      });
                      FocusScope.of(context).requestFocus(_pinFocusNode);
                    },
                    child: Text(
                      'Ricomincia',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
