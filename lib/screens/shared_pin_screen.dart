import 'package:flutter/material.dart';
import '../widgets/pin_boxes_input.dart';

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

  late int _step;
  String _firstPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _step = (widget.action == PinAction.setup) ? 1 : 0;

    // Aggiorniamo la UI ad ogni digitazione per abilitare/disabilitare il bottone "Avanti"
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

  void _handlePinSubmit() {
    final val = _pinController.text;
    if (val.length != 6) return;

    setState(() => _errorMessage = null);

    if (_step == 0) {
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
      setState(() {
        _firstPin = val;
        _step = 2;
        _pinController.clear();
      });
      _focusNode.requestFocus();
    } else if (_step == 2) {
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

  String get _title {
    if (_step == 0) return 'PIN attuale';
    if (_step == 1)
      return widget.action == PinAction.change ? 'Nuovo PIN' : 'Crea un PIN';
    return 'Conferma il PIN';
  }

  String get _subtitle {
    if (_step == 0)
      return 'Inserisci il tuo codice di sicurezza per continuare.';
    if (_step == 1)
      return widget.action == PinAction.change
          ? 'Scegli un nuovo codice a 6 cifre.'
          : 'Questo codice a 6 cifre servirà per accedere all\'app in modo sicuro.';
    return 'Digita nuovamente per confermare il codice.';
  }

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

              PinBoxesInput(
                controller: _pinController,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: (_) => setState(() => _errorMessage = null),
                // onCompleted rimosso: l'utente deve premere il bottone avanti
              ),

              const SizedBox(height: 32),

              // Bottone Avanti Manuale
              ElevatedButton(
                onPressed: _pinController.text.length == 6
                    ? _handlePinSubmit
                    : null,
                child: Text(_step == 2 ? 'Conferma' : 'Avanti'),
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
            ],
          ),
        ),
      ),
    );
  }
}
