import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:app_settings/app_settings.dart';
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
  bool _nfcAvailable = false;
  bool _isCheckingNfc = true;

  MeData? _me;
  double? _pendingAmount;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkNfc();
    _loadMe();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _loadMe() async {
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() => _me = me);
    } catch (_) {
      // Se /api/me fallisce, la UI mostra placeholder ma il pagamento funziona comunque
    }
  }

  Future<void> _checkNfc() async {
    final av = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    setState(() {
      _nfcAvailable = av == NfcAvailability.enabled;
      _isCheckingNfc = false;
    });
  }

  String _extractTokenFromTag(NfcTag tag) {
    final data = tag.data.toString();
    return data.hashCode.toString();
  }

  /// Ultime 4 cifre dell'IBAN, oppure "0000" se non disponibile.
  String _lastFourFromIban() {
    final iban = _me?.iban ?? '';
    if (iban.length < 4) return '0000';
    return iban.substring(iban.length - 4);
  }

  String _cardholderName() {
    final raw = _me?.name ?? context.read<AuthProvider>().userName;
    return raw.toUpperCase();
  }

  /// Mostra un bottom sheet per scegliere l'importo da pagare via NFC.
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: SizedBox(
                      width: 40,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Importo da pagare',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inserisci la cifra che vuoi addebitare sulla tua carta.',
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
                          ),
                          child: const Text('Annulla'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final raw = ctrl.text.replaceAll(',', '.').trim();
                            final value = double.tryParse(raw);
                            if (value == null || value <= 0) {
                              setLocal(() => error = 'Importo non valido');
                              return;
                            }
                            if (value > 9999999) {
                              setLocal(() => error = 'Importo troppo elevato');
                              return;
                            }
                            Navigator.pop(ctx, value);
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Continua'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _startNfcPayment() async {
    await _checkNfc();
    if (!mounted) return;

    if (!_nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NFC disattivato o non supportato.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final amount = await _askAmount();
    if (amount == null || !mounted) return;

    setState(() {
      _pendingAmount = amount;
      _isPaying = true;
      _isSuccess = false;
    });

    NfcManager.instance
        .startSession(
          pollingOptions: {
            NfcPollingOption.iso14443,
            NfcPollingOption.iso15693,
          },
          onDiscovered: (tag) async {
            try {
              final nfcToken = _extractTokenFromTag(tag);

              await ApiService.nfcPay(
                nfcToken: nfcToken,
                merchantName: 'POS Contactless',
                amount: _pendingAmount ?? 0,
              );

              AppEvents.emitAccountDataChanged();

              await NfcManager.instance.stopSession();
              if (!mounted) return;

              setState(() {
                _isPaying = false;
                _isSuccess = true;
              });

              await Future.delayed(const Duration(seconds: 2));
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } catch (e) {
              await NfcManager.instance.stopSession();
              if (!mounted) return;
              setState(() => _isPaying = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            }
          },
        )
        .catchError((_) {
          if (!mounted) return;
          setState(() => _isPaying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore NFC: avvicina meglio il dispositivo.'),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final gradientColors = isDark
        ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]
        : [const Color(0xFF1A56DB), const Color(0xFF1D4ED8)];

    final last4 = _lastFourFromIban();
    final cardholder = _cardholderName();

    return Scaffold(
      appBar: AppBar(title: const Text('Paga con NFC')),
      body: _isCheckingNfc
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            '••••  ••••  ••••  $last4',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cardholder,
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
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                    if (!_nfcAvailable) ...[
                      const Icon(
                        Icons.nfc_rounded,
                        size: 64,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NFC non disponibile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Attiva l'NFC dalle impostazioni del dispositivo.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await AppSettings.openAppSettings(
                            type: AppSettingsType.nfc,
                          );
                          await Future.delayed(const Duration(seconds: 1));
                          if (mounted) _checkNfc();
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Impostazioni NFC'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ] else if (_isSuccess) ...[
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
                      if (_pendingAmount != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '€ ${_pendingAmount!.toStringAsFixed(2).replaceAll('.', ',')}',
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
                      Text(
                        _pendingAmount == null
                            ? 'Pronto per pagare'
                            : 'Paga € ${_pendingAmount!.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Avvicina il telefono al POS',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          NfcManager.instance.stopSession();
                          setState(() {
                            _isPaying = false;
                            _pendingAmount = null;
                          });
                        },
                        child: const Text(
                          'Annulla',
                          style: TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _startNfcPayment,
                        icon: const Icon(Icons.nfc_rounded),
                        label: const Text('Attiva Pagamento NFC'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(220, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
