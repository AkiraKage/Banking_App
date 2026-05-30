import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';

// Schermata per effettuare un versamento tramite scansione di un QR code.
// Gestisce i permessi della fotocamera e l'elaborazione del codice scansionato.
class QrDepositScreen extends StatefulWidget {
  const QrDepositScreen({super.key});

  @override
  State<QrDepositScreen> createState() => _QrDepositScreenState();
}

class _QrDepositScreenState extends State<QrDepositScreen>
    with WidgetsBindingObserver {
  // Controller per gestire l'avvio e l'arresto della fotocamera.
  final _scannerCtrl = MobileScannerController();

  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Verifica i permessi all'apertura della schermata.
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Se l'utente torna nell'app dopo aver dato i permessi nelle impostazioni di sistema.
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _isCheckingPermission = true);
      _checkPermission();
    }
  }

  // Controlla se l'utente ha già concesso l'uso della fotocamera.
  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _isCheckingPermission = false;
    });
  }

  // Richiede esplicitamente il permesso di usare la fotocamera.
  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isPermanentlyDenied) await openAppSettings();
    await _checkPermission();
  }

  // Estrae il token identificativo dall'URL o dalla stringa contenuta nel QR.
  String _extractQrToken(String raw) {
    final cleaned = raw.trim();
    if (cleaned.contains('/pay/')) {
      final token = cleaned
          .split('/pay/')
          .last
          .split('/')
          .first
          .split('?')
          .first;
      return token;
    }
    return cleaned;
  }

  Future<void> _showError(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFDC2626)),
    );
  }

  // Funzione chiamata quando la fotocamera rileva un codice QR.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    setState(() => _isProcessing = true);
    // Ferma lo scanner per evitare letture multiple dello stesso codice.
    await _scannerCtrl.stop();

    final raw = barcodes.first.rawValue!;
    final qrToken = _extractQrToken(raw);

    try {
      // Recupera i dettagli del versamento (importo ed esercente) dal server.
      final details = await ApiService.getQrDetails(qrToken);
      if (!mounted) return;

      // Chiede conferma all'utente prima di procedere con l'accredito.
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.qr_code_rounded, size: 22),
              SizedBox(width: 10),
              Text('Conferma Ricarica'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Esercente: ${details.merchantName}'),
              const SizedBox(height: 10),
              const Text('Importo da accreditare'),
              Text(
                '€ ${details.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Approva'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Invia la conferma definitiva al server.
        final result = await ApiService.confirmQr(qrToken);
        AppEvents.emitAccountDataChanged();

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ricarica completata: +€ ${(result['amount'] as num).toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        // Se l'utente annulla, riavvia lo scanner per una nuova lettura.
        if (!mounted) return;
        setState(() => _isProcessing = false);
        await _scannerCtrl.start();
      }
    } catch (e) {
      await _showError(e.toString());
      if (!mounted) return;
      setState(() => _isProcessing = false);
      await _scannerCtrl.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Versamento QR')),
      body: _isCheckingPermission
          ? const Center(child: CircularProgressIndicator())
          : _hasPermission
          ? Stack(
              children: [
                // Visualizzazione della fotocamera a tutto schermo.
                MobileScanner(controller: _scannerCtrl, onDetect: _onDetect),
                // Overlay scuro con un "buco" centrale per guidare l'utente.
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Disegna gli angoli del mirino sopra la fotocamera.
                Center(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _ScannerCornerPainter(color: secondary),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Inquadra il QR dell\'esercente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildPermissionDenied(isDark), // Mostra la richiesta di permessi se negati.
    );
  }

  // Interfaccia visualizzata quando i permessi della fotocamera non sono concessi.
  Widget _buildPermissionDenied(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                size: 60,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permesso fotocamera negato',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Per scansionare i QR è necessario consentire l\'accesso alla fotocamera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Consenti fotocamera'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pittore personalizzato per disegnare i quattro angoli del mirino dello scanner.
class _ScannerCornerPainter extends CustomPainter {
  final Color color;

  const _ScannerCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const length = 28.0;
    const radius = 16.0;

    // Disegna l'angolo in alto a sinistra.
    canvas.drawLine(const Offset(radius, 0), const Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, radius), const Offset(0, length), paint);
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      3.14,
      1.57,
      false,
      paint,
    );

    // Disegna l'angolo in alto a destra.
    final tr = Offset(size.width, 0);
    canvas.drawLine(
      Offset(tr.dx - radius, tr.dy),
      Offset(tr.dx - length, tr.dy),
      paint,
    );
    canvas.drawLine(
      Offset(tr.dx, tr.dy + radius),
      Offset(tr.dx, tr.dy + length),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(tr.dx - radius * 2, tr.dy, radius * 2, radius * 2),
      -1.57,
      1.57,
      false,
      paint,
    );

    // Disegna l'angolo in basso a sinistra.
    final bl = Offset(0, size.height);
    canvas.drawLine(
      Offset(bl.dx + radius, bl.dy),
      Offset(bl.dx + length, bl.dy),
      paint,
    );
    canvas.drawLine(
      Offset(bl.dx, bl.dy - radius),
      Offset(bl.dx, bl.dy - length),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(bl.dx, bl.dy - radius * 2, radius * 2, radius * 2),
      1.57,
      1.57,
      false,
      paint,
    );

    // Disegna l'angolo in basso a destra.
    final br = Offset(size.width, size.height);
    canvas.drawLine(
      Offset(br.dx - radius, br.dy),
      Offset(br.dx - length, br.dy),
      paint,
    );
    canvas.drawLine(
      Offset(br.dx, br.dy - radius),
      Offset(br.dx, br.dy - length),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        br.dx - radius * 2,
        br.dy - radius * 2,
        radius * 2,
        radius * 2,
      ),
      0,
      1.57,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScannerCornerPainter old) => old.color != color;
}

