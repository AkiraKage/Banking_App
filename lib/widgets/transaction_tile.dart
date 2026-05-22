import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final bool isDark;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final bool withBackground;
  final bool withBorder;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.isDark,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.withBackground = true,
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final amountColor = isIncome
        ? Theme.of(context).colorScheme.secondary
        : const Color(0xFFEF4444);

    final decoration = (withBackground || withBorder)
        ? BoxDecoration(
            color: withBackground
                ? (isDark ? const Color(0xFF1F2937) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: withBorder
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  )
                : null,
          )
        : null;

    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tx.icon, color: amountColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tx.formattedAmount,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
