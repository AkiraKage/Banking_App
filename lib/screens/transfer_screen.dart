import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';

// Schermata per l'esecuzione di un nuovo bonifico bancario.
// Gestisce la validazione dei campi e l'invio della richiesta al server backend.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  // GlobalKey identifica univocamente il form per permetterne la validazione.
  final _formKey = GlobalKey<FormState>();
  final _beneficiaryCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _causaleCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _beneficiaryCtrl.dispose();
    _ibanCtrl.dispose();
    _amountCtrl.dispose();
    _causaleCtrl.dispose();
    super.dispose();
  }

  // Verifica che l'IBAN inserito sia formalmente corretto.
  String? _validateIban(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obbligatorio';
    final cleaned = v.replaceAll(' ', '').toUpperCase();
    if (cleaned.length < 15) return 'IBAN non valido';
    return null;
  }

  // Verifica che l'importo sia un numero positivo valido.
  String? _validateAmount(String? v) {
    if (v == null || v.trim().isEmpty) return 'Inserisci l\'importo';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Importo non valido';
    if (n > 9999999) return 'Importo troppo elevato';
    return null;
  }

  // Esegue l'invio del bonifico previa conferma dell'utente tramite popup.
  Future<void> _submit() async {
    // Valida tutti i campi del form prima di procedere.
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

    // Mostra un dialogo di riepilogo per evitare invii accidentali.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, size: 22),
            SizedBox(width: 10),
            Text('Conferma Bonifico'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow(label: 'Beneficiario', value: _beneficiaryCtrl.text),
            _ConfirmRow(label: 'IBAN', value: _ibanCtrl.text),
            _ConfirmRow(
              label: 'Importo',
              value: '€ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            _ConfirmRow(label: 'Causale', value: _causaleCtrl.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Invia'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Chiama il servizio API per registrare il bonifico sul server.
      await ApiService.createTransfer(
        beneficiary: _beneficiaryCtrl.text.trim(),
        iban: _ibanCtrl.text.trim(),
        amount: amount,
        reason: _causaleCtrl.text.trim(),
      );

      // Emette un evento globale per notificare la necessità di aggiornare il saldo.
      AppEvents.emitAccountDataChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 10),
              Text('Bonifico inviato con successo!'),
            ],
          ),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo Bonifico')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FieldLabel('Beneficiario'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _beneficiaryCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Mario Rossi',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 18),
            _FieldLabel('IBAN'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ibanCtrl,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'IT60 X054 2811 1010 0000 0123 456',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              validator: _validateIban,
            ),
            const SizedBox(height: 18),
            _FieldLabel('Importo (€)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: const InputDecoration(
                hintText: '0,00',
                prefixIcon: Icon(Icons.euro_rounded),
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: 18),
            _FieldLabel('Causale'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _causaleCtrl,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Es. Pagamento fattura n. 001',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.edit_note_rounded),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Inserisci una causale'
                  : null,
            ),
            const SizedBox(height: 32),
            // Bottone che si disabilita durante il caricamento per evitare click doppi.
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Invia Bonifico'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget semplice per visualizzare etichette dei campi uniformi.
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

// Widget per visualizzare una riga di riepilogo nel dialogo di conferma.
class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
