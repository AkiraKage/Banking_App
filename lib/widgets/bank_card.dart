import 'package:flutter/material.dart';

class BankCard extends StatelessWidget {
  final double balance;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onTap;
  final bool isDark;
  final String cardholderName;
  final String lastFour;

  const BankCard({
    super.key,
    required this.balance,
    required this.balanceVisible,
    required this.onToggleVisibility,
    required this.onTap,
    required this.isDark,
    required this.cardholderName,
    required this.lastFour,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDark
        ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]
        : [const Color(0xFF1A56DB), const Color(0xFF1D4ED8)];

    final displayName = cardholderName.isEmpty
        ? '—'
        : cardholderName.toUpperCase();
    final displayLast = lastFour.isEmpty ? '0000' : lastFour;

    return Card(
      elevation: 12,
      shadowColor: const Color(0xFF1A56DB).withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
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
                  Row(
                    children: [
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
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.contactless_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ],
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
      ),
    );
  }
}
