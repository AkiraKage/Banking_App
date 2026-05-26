import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../widgets/action_card.dart';
import '../widgets/info_row.dart';
import 'transfer_screen.dart';
import 'qr_deposit_screen.dart';

class ActionsTab extends StatefulWidget {
  const ActionsTab({super.key});

  @override
  State<ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends State<ActionsTab> {
  MeData? _me;
  bool _loading = true;
  String? _error;
  StreamSubscription<AppEvent>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _loadMe();
    _eventsSub = AppEvents.stream.listen((event) {
      if (event == AppEvent.accountDataChanged) {
        _loadMe();
      }
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMe() async {
    if (!mounted) return;
    setState(() {
      _loading = _me == null;
      _error = null;
    });
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _me = me;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Formatta IT60POS00000000000001 in "IT60 POS0 0000 0000 0000 01"
  /// (gruppi di 4 dopo i primi 2 caratteri di country code).
  String _formatIban(String iban) {
    if (iban.isEmpty) return '—';
    final cleaned = iban.replaceAll(' ', '').toUpperCase();
    final buf = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(cleaned[i]);
    }
    return buf.toString();
  }

  Future<void> _copyIban() async {
    if (_me == null || _me!.iban.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _me!.iban));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IBAN copiato negli appunti'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operazioni'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMe,
        color: primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 2),
              child: Text(
                'Cosa vuoi fare?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            ActionCard(
              title: 'Bonifico Bancario',
              subtitle: 'Trasferisci denaro verso un IBAN',
              icon: Icons.account_balance_rounded,
              color: primary,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransferScreen()),
              ),
            ),
            const SizedBox(height: 12),
            ActionCard(
              title: 'Versamento QR',
              subtitle: 'Scansiona il QR dell\'esercente',
              icon: Icons.qr_code_scanner_rounded,
              color: secondary,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrDepositScreen()),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(bottom: 14, left: 2),
              child: Text(
                'Info conto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadMe,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              )
            else ...[
              InkWell(
                onTap: _copyIban,
                borderRadius: BorderRadius.circular(8),
                child: InfoRow(
                  label: 'IBAN',
                  value: _formatIban(_me?.iban ?? ''),
                  isDark: isDark,
                ),
              ),
              InfoRow(label: 'BIC/SWIFT', value: 'POSITIT2XXX', isDark: isDark),
              InfoRow(
                label: 'Intestatario',
                value: _me?.name ?? authProvider.userName,
                isDark: isDark,
              ),
              InfoRow(
                label: 'Stato carta',
                value: (_me?.cardActive ?? true) ? 'Attiva' : 'Bloccata',
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Text(
                  'Tocca l\'IBAN per copiarlo.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
