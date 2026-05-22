import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:app_settings/app_settings.dart';

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
  bool _isCheckingNfc = true; // evita il flash "NFC non disponibile" prima del check

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final av = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    setState(() {
      _nfcAvailable = av == NfcAvailability.enabled;
      _isCheckingNfc = false;
    });
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

    setState(() => _isPaying = true);

    NfcManager.instance
        .startSession(
          pollingOptions: {
            NfcPollingOption.iso14443,
            NfcPollingOption.iso15693,
          },
          onDiscovered: (tag) async {
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
          },
        )
        .catchError((_) {
          if (!mounted) return;
          setState(() => _isPaying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Errore NFC: avvicina meglio il dispositivo.')),
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
                    // Card
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
                                    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const Icon(Icons.contactless_rounded,
                                  color: Colors.white70, size: 26),
                            ],
                          ),
                          const Text(
                            '4532  ••••  ••••  3456',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ALOK',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('SCADENZA',
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 8,
                                          letterSpacing: 1)),
                                  Text('12/30',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 56),

                    if (!_nfcAvailable) ...[
                      const Icon(Icons.nfc_rounded, size: 64, color: Color(0xFFDC2626)),
                      const SizedBox(height: 16),
                      const Text('NFC non disponibile',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626))),
                      const SizedBox(height: 8),
                      Text(
                        "Attiva l'NFC dalle impostazioni del dispositivo.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await AppSettings.openAppSettings(
                              type: AppSettingsType.nfc);
                          await Future.delayed(const Duration(seconds: 1));
                          if (mounted) _checkNfc();
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Impostazioni NFC'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else if (_isSuccess) ...[
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF059669), size: 80),
                      const SizedBox(height: 16),
                      const Text('Pagamento Autorizzato!',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669))),
                    ] else if (_isPaying) ...[
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Icon(Icons.contactless_rounded,
                            size: 80, color: primary),
                      ),
                      const SizedBox(height: 16),
                      const Text('Pronto per pagare',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        'Avvicina il telefono al POS',
                        style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          NfcManager.instance.stopSession();
                          setState(() => _isPaying = false);
                        },
                        child: const Text('Annulla',
                            style: TextStyle(color: Color(0xFFDC2626))),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _startNfcPayment,
                        icon: const Icon(Icons.nfc_rounded),
                        label: const Text('Attiva Pagamento NFC'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(220, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
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
