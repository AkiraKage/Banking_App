import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/action_card.dart';
import '../widgets/info_row.dart';
import 'transfer_screen.dart';
import 'qr_deposit_screen.dart';

class ActionsTab extends StatelessWidget {
  const ActionsTab({super.key});

  // Formatta IBAN in gruppi di 4 per leggibilità
  String _formatIban(String iban) {
    final clean = iban.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final authProvider = Provider.of<AuthProvider>(context);

    final ibanDisplay = authProvider.userIban.isNotEmpty
        ? _formatIban(authProvider.userIban)
        : 'Caricamento...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operazioni'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
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
          InfoRow(label: 'IBAN', value: ibanDisplay, isDark: isDark),
          InfoRow(label: 'BIC/SWIFT', value: 'BLOKIT22', isDark: isDark),
          InfoRow(
            label: 'Intestatario',
            value: '${authProvider.userName} Banking',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}