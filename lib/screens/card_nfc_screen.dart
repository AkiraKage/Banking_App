import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';

class CardNfcScreen extends StatefulWidget {
  const CardNfcScreen({super.key});

  @override
  State<CardNfcScreen> createState() => _CardNfcScreenState();
}

class _CardNfcScreenState extends State<CardNfcScreen>
    with SingleTickerProviderStateMixin {
  bool _isPaying = false;
  bool _isSuccess = false;
  double? _paidAmount;

  MeData? _me;
  bool _loadingMe = true;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadMe();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _me = me;
        _loadingMe = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMe = false);
    }
  }

  String _lastFour() {
    final iban = _me?.iban ?? '';
    if (iban.length < 4) return '0000';
    return iban.substring(iban.length - 4);
  }

  String _cardholder() {
    final raw = _me?.name ?? context.read<AuthProvider>().userName;
    return raw.toUpperCase();
  }

  // Mostra bottom sheet per inserire importo
  Future<double?> _askAmount() async {
    final ctrl = TextEditingController();
    String? error;

    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Importo da pagare',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Inserisci la cifra da addebitare sulla tua carta.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0,00',
                    prefixIcon: const Icon(Icons.euro_rounded),
                    errorText: error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final raw =
                          ctrl.text.replaceAll(',', '.').trim();
                          final value = double.tryParse(raw);
                          if (value == null || value <= 0) {
                            setLocal(() => error = 'Importo non valido');
                            return;
                          }
                          if (value > 9999999) {
                            setLocal(
                                  () => error = 'Importo troppo elevato',
                            );
                            return;
                          }
                          Navigator.pop(ctx, value);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Paga'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pay() async {
    final amount = await _askAmount();
    if (amount == null || !mounted) return;

    setState(() => _isPaying = true);

    try {
      // Usa l'IBAN come token identificativo della sessione NFC
      final nfcToken = _me?.iban ?? 'nfc-${DateTime.now().millisecondsSinceEpoch}';

      await ApiService.nfcPay(
        nfcToken: nfcToken,
        merchantName: 'POS Contactless',
        amount: amount,
      );

      AppEvents.emitAccountDataChanged();

      if (!mounted) return;
      setState(() {
        _isPaying = false;
        _isSuccess = true;
        _paidAmount = amount;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore imprevisto. Riprova.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final gradientColors = isDark
        ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]
        : [const Color(0xFF1A56DB), const Color(0xFF1D4ED8)];

    return Scaffold(
      appBar: AppBar(title: const Text('Paga con NFC')),
      body: _loadingMe
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Carta virtuale
              Container(
                height: 210,
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFD97706),
                                Color(0xFFFBBF24),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 26,
                        ),
                      ],
                    ),
                    Text(
                      '••••  ••••  ••••  ${_lastFour()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _cardholder(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.end,
                          children: [
                            Text(
                              'POS IoT',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 8,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'CONTACTLESS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 56),

              // Stato pagamento
              if (_isSuccess) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pagamento Autorizzato!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
                if (_paidAmount != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '€ ${_paidAmount!.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ] else if (_isPaying) ...[
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Icon(
                    Icons.contactless_rounded,
                    size: 80,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Elaborazione in corso...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Attendi la conferma',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _pay,
                  icon: const Icon(Icons.nfc_rounded),
                  label: const Text('Paga con NFC'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(220, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Il pagamento viene addebitato direttamente sul conto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}