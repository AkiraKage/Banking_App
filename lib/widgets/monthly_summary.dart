import 'package:flutter/material.dart';

// Widget che affianca due schede riassuntive per entrate e uscite mensili.
// Utilizza Expanded per dividere equamente lo spazio orizzontale disponibile.
class MonthlySummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final bool isDark;

  const MonthlySummaryRow({
    super.key,
    required this.income,
    required this.expense,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: 'Entrate',
            amount: income,
            icon: Icons.arrow_downward_rounded,
            color: secondary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            label: 'Uscite',
            amount: expense,
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFFEF4444),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

// Widget per una singola scheda di riepilogo (es. solo entrate o solo uscite).
class SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isDark;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          // Icona con freccia direzionale racchiusa in un box colorato.
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etichetta descrittiva (es. "Entrate").
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                // Valore totale formattato con due decimali.
                Text(
                  '€ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFF9FAFB)
                        : const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
