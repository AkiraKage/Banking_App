import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Widget che visualizza graficamente la carta bancaria dell'utente.
// Essendo uno StatelessWidget, non gestisce internamente il proprio stato,
// ma riceve i dati necessari tramite il costruttore.
class BankCard extends StatelessWidget {
  final double balance;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;
  final bool isDark;
  final String cardholderName;
  final String lastFour;
  final String iban;

  const BankCard({
    super.key,
    required this.balance,
    required this.balanceVisible,
    required this.onToggleVisibility,
    required this.isDark,
    required this.cardholderName,
    required this.lastFour,
    required this.iban,
  });

  // Formatta la stringa dell'IBAN aggiungendo uno spazio ogni 4 caratteri per leggibilità.
  String _formatIban(String value) {
    final clean = value.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  // Copia l'IBAN negli appunti del sistema e mostra una notifica (SnackBar).
  Future<void> _copyIban(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IBAN copiato negli appunti'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisce i colori del gradiente in base al tema attuale (chiaro o scuro).
    final gradientColors = isDark
        ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]
        : [const Color(0xFF1A56DB), const Color(0xFF1D4ED8)];

    final displayName = cardholderName.isEmpty
        ? '—'
        : cardholderName.toUpperCase();
    final displayLast = lastFour.isEmpty ? '0000' : lastFour;
    final cleanIban = iban.trim();
    final displayIban = cleanIban.isEmpty ? '—' : _formatIban(cleanIban);

    return Container(
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
            color: const Color(0xFF1A56DB).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Disponibile',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: balanceVisible
                        ? Text(
                            '€ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                            key: const ValueKey('visible'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          )
                        : const Text(
                            '€ ••••••',
                            key: ValueKey('hidden'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onToggleVisibility,
                child: Icon(
                  balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          Text(
            '••••  ••••  ••••  $displayLast',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                'POS IoT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'IBAN $displayIban',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: cleanIban.isEmpty
                    ? null
                    : () => _copyIban(context, cleanIban),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text(
                  'Copia',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
