import 'package:flutter/material.dart';
import '../widgets/pin_boxes_input.dart';

// Schermata versatile per la gestione del PIN: supporta creazione, verifica e modifica.
// Viene utilizzata come componente condiviso per diverse operazioni di sicurezza.
enum PinAction { setup, verify, change }

class SharedPinScreen extends StatefulWidget {
  final PinAction action;
  final String? currentPin;

  const SharedPinScreen({super.key, required this.action, this.currentPin});

  @override
  State<SharedPinScreen> createState() => _SharedPinScreenState();
}

class _SharedPinScreenState extends State<SharedPinScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  // Rappresenta la fase attuale del processo (0: verifica attuale, 1: inserimento nuovo, 2: conferma).
  late int _step;
  String _firstPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Inizializza lo step in base all'azione richiesta: setup parte direttamente dalla creazione.
    _step = (widget.action == PinAction.setup) ? 1 : 0;

    // Aggiorna l'interfaccia ad ogni cifra inserita per gestire lo stato del bottone.
    _pinController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Gestisce la logica di avanzamento tra i vari passaggi dell'operazione PIN.
  void _handlePinSubmit() {
    final val = _pinController.text;
    if (val.length != 6) return;

    setState(() => _errorMessage = null);

    if (_step == 0) {
      // Fase di verifica del PIN esistente (per modifiche o accessi sensibili).
      if (val == widget.currentPin) {
        if (widget.action == PinAction.verify) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _step = 1;
            _pinController.clear();
          });
          _focusNode.requestFocus();
        }
      } else {
        setState(() {
          _errorMessage = 'PIN attuale errato. Riprova.';
          _pinController.clear();
        });
        _focusNode.requestFocus();
      }
    } else if (_step == 1) {
      // Fase di acquisizione del nuovo PIN.
      setState(() {
        _firstPin = val;
        _step = 2;
        _pinController.clear();
      });
      _focusNode.requestFocus();
    } else if (_step == 2) {
      // Fase di conferma finale del nuovo PIN.
      if (val == _firstPin) {
        Navigator.pop(context, val);
      } else {
        setState(() {
          _errorMessage = 'I PIN non corrispondono. Ricominciamo.';
          _step = 1;
          _firstPin = '';
          _pinController.clear();
        });
        _focusNode.requestFocus();
      }
    }
  }

  // Restituisce il titolo dinamico in base allo stato del processo.
  String get _title {
    if (_step == 0) return 'PIN attuale';
    if (_step == 1)
      return widget.action == PinAction.change ? 'Nuovo PIN' : 'Crea un PIN';
    return 'Conferma il PIN';
  }

  // Restituisce il sottotitolo informativo in base allo stato del processo.
  String get _subtitle {
    if (_step == 0)
      return 'Inserisci il tuo codice di sicurezza per continuare.';
    if (_step == 1)
      return widget.action == PinAction.change
          ? 'Scegli un nuovo codice a 6 cifre.'
          : 'Questo codice a 6 cifre servirà per accedere all\'app in modo sicuro.';
    return 'Digita nuovamente per confermare il codice.';
  }

  // Seleziona l'icona appropriata per il passaggio corrente.
  IconData get _icon {
    if (_step == 0) return Icons.lock_person_rounded;
    if (_step == 1) return Icons.lock_outline_rounded;
    return Icons.lock_reset_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icona dinamica con animazione di transizione tra i vari step.
              Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _icon,
                    key: ValueKey(_step),
                    size: 38,
                    color: primary,
                  ),
                ),
              ),
              // Titolo e testo di guida animati.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(_step),
                  children: [
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Campo di input per il PIN a 6 cifre.
              PinBoxesInput(
                controller: _pinController,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: (_) => setState(() => _errorMessage = null),
              ),

              const SizedBox(height: 32),

              // Pulsante di conferma manuale dell'inserimento.
              ElevatedButton(
                onPressed: _pinController.text.length == 6
                    ? _handlePinSubmit
                    : null,
                child: Text(_step == 2 ? 'Conferma' : 'Avanti'),
              ),

              const SizedBox(height: 20),

              // Banner per la visualizzazione di eventuali errori di validazione o digitazione.
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
            ],
          ),
        ),
      ),
    );
  }
}
