import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../widgets/pin_boxes_input.dart';
import 'main_layout.dart';
import 'shared_pin_screen.dart';

// Gestisce la schermata di accesso, supportando login standard (username/password),
// login tramite PIN e autenticazione biometrica.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// L'uso di SingleTickerProviderStateMixin permette di gestire le animazioni fluide.
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controller per gestire l'input di testo nei vari campi.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  // Variabili per gestire le animazioni di entrata della schermata.
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  String? _errorMessage;
  bool _isPasswordObscured = true;
  bool _isLoading = true;

  bool _isPinMode = false;
  bool _isPinPromptActive = false;

  bool _isSubmitting = false;
  String? _savedPin;
  bool _useBiometrics = false;
  String _savedDisplayName = 'Bentornato';

  @override
  void initState() {
    super.initState();
    // Configura i parametri delle animazioni al caricamento del widget.
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Gestisce i cambiamenti nel controller dei PIN.
    _pinController.addListener(() {
      if (mounted) setState(() {});
    });

    // Controlla se l'utente ha già configurato un PIN per mostrare la modalità corretta.
    _checkInitialState();
  }

  @override
  void dispose() {
    // Libera le risorse per evitare sprechi di memoria.
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // Recupera i dati di sessione salvati per decidere se mostrare il login con PIN.
  Future<void> _checkInitialState() async {
    _savedPin = await StorageService.getPin();
    _useBiometrics = await StorageService.getBiometrics();
    _savedDisplayName = await StorageService.getDisplayName() ?? 'Bentornato';

    if (!mounted) return;

    setState(() {
      _isPinMode = _savedPin != null;
      _isLoading = false;
    });

    _animController.forward();
  }

  // Completa il login rapido e aggiorna lo stato dell'applicazione.
  Future<void> _completePinLogin() async {
    final name = await StorageService.getDisplayName() ?? _savedDisplayName;
    if (!mounted) return;
    context.read<AuthProvider>().loginWithPin(name);
    _navigateToHome();
  }

  // Avvia la procedura di sblocco, provando prima con la biometria se attiva.
  void _startUnlockProcess() {
    setState(() {
      _isPinPromptActive = true;
      _errorMessage = null;
    });

    if (_useBiometrics) {
      _authenticateBiometrics();
    } else {
      FocusScope.of(context).requestFocus(_pinFocusNode);
    }
  }

  // Gestisce la verifica dell'impronta digitale o Face ID tramite il servizio dedicato.
  Future<void> _authenticateBiometrics() async {
    final ok = await BiometricService.authenticate(
      'Usa la biometria per accedere al conto',
    );
    if (!mounted) return;

    if (ok) {
      await _completePinLogin();
    } else {
      FocusScope.of(context).requestFocus(_pinFocusNode);
    }
  }

  // Verifica che il PIN inserito corrisponda a quello salvato localmente.
  Future<void> _verifyPin() async {
    if (_pinController.text == _savedPin) {
      HapticFeedback.lightImpact();
      await _completePinLogin();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PIN errato. Riprova.';
        _pinController.clear();
      });
      FocusScope.of(context).requestFocus(_pinFocusNode);
    }
  }

  // Gestisce il login classico inviando le credenziali al server.
  void _handleStandardLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Inserisci username e password.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    final success = await context.read<AuthProvider>().login(
      username,
      password,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Dopo il primo login, se il PIN non esiste, guida l'utente a configurarlo.
      final existingPin = await StorageService.getPin();
      if (existingPin == null) {
        final newPin = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => const SharedPinScreen(action: PinAction.setup),
          ),
        );

        if (newPin != null && mounted) {
          await StorageService.savePin(newPin);
          await _promptBiometricsSetup();
          _navigateToHome();
        }
      } else {
        _navigateToHome();
      }
    } else {
      final providerError = context.read<AuthProvider>().lastError;
      setState(
        () => _errorMessage = providerError ?? 'Credenziali non valide.',
      );
    }
  }

  // Chiede all'utente se desidera attivare l'accesso biometrico per il futuro.
  Future<void> _promptBiometricsSetup() async {
    final canCheck = await BiometricService.canCheckBiometrics();
    if (!mounted || !canCheck) return;

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
          'Vuoi usare l\'impronta o Face ID per accedere più velocemente?',
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

    if (result == true) {
      final ok = await BiometricService.authenticate(
        'Conferma per abilitare la biometria',
      );
      await StorageService.setBiometrics(ok);
    }
  }

  // Naviga alla dashboard principale sostituendo la schermata corrente nello stack.
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  // Consente di tornare alla modalità di login classica se il PIN è attivo.
  void _switchToPasswordMode() {
    setState(() {
      _isPinMode = false;
      _isPinPromptActive = false;
      _errorMessage = null;
      _pinController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Tema chiaro' : 'Tema scuro',
            onPressed: themeProvider.toggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        // Utilizza transizioni per un'interfaccia utente più curata e professionale.
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Benvenuto in',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IoT Banking.',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: primary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Visualizza condizionalmente i campi PIN o Username/Password.
                    if (_isPinMode) ...[
                      if (!_isPinPromptActive) ...[
                        ElevatedButton.icon(
                          onPressed: _startUnlockProcess,
                          icon: const Icon(Icons.lock_open_rounded),
                          label: Text('Sblocca $_savedDisplayName'),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _switchToPasswordMode,
                            child: Text(
                              'Accedi con un altro account',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Inserisci il PIN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PinBoxesInput(
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          autofocus: !_useBiometrics,
                          onChanged: (_) =>
                              setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _pinController.text.length == 6
                              ? _verifyPin
                              : null,
                          child: const Text('Accedi'),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorBanner(),
                        ],
                        if (_useBiometrics) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: _authenticateBiometrics,
                              icon: const Icon(Icons.fingerprint, size: 24),
                              label: const Text('Usa biometria'),
                            ),
                          ),
                        ],
                      ],
                    ] else ...[
                      TextField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nome utente',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        onChanged: (_) => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleStandardLogin(),
                        onChanged: (_) => setState(() => _errorMessage = null),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _isPasswordObscured = !_isPasswordObscured,
                            ),
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleStandardLogin,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Accedi'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper per visualizzare gli errori in modo evidente ma elegante.
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    );
  }
}
