import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_tile.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  final List<TransactionModel> allTransactions;

  const TransactionsHistoryScreen({super.key, required this.allTransactions});

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  TransactionType? _filter;

  static const _months = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];

  String _groupKey(TransactionModel tx) {
    final now = DateTime.now();
    final name = _months[tx.date.month - 1];
    return tx.date.year == now.year ? name : '$name ${tx.date.year}';
  }

  Map<String, List<TransactionModel>> _grouped(List<TransactionModel> txs) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in txs) {
      final key = _groupKey(tx);
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  double _monthTotal(List<TransactionModel> txs) {
    return txs.fold(0.0, (sum, tx) {
      return sum + (tx.type == TransactionType.income ? tx.amount : -tx.amount);
    });
  }

  List<TransactionModel> get _filtered {
    final sorted = List<TransactionModel>.from(widget.allTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (_filter == null) return sorted;
    return sorted.where((tx) => tx.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final grouped = _grouped(_filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Transazioni'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tutti',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Entrate',
                  selected: _filter == TransactionType.income,
                  onTap: () => setState(() => _filter = TransactionType.income),
                  isDark: isDark,
                  primary: secondary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Uscite',
                  selected: _filter == TransactionType.expense,
                  onTap: () => setState(() => _filter = TransactionType.expense),
                  isDark: isDark,
                  primary: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? Center(
              child: Text(
                'Nessuna transazione',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            )
                : ListView.builder(
              itemCount: grouped.length,
              itemBuilder: (context, i) {
                final key = grouped.keys.elementAt(i);
                final txs = grouped[key]!;
                final total = _monthTotal(txs);
                final isPositive = total >= 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: primary,
                            ),
                          ),
                          Text(
                            '${isPositive ? '+' : ''}€ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isPositive
                                  ? secondary
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...txs.map(
                          (tx) => TransactionTile(
                        tx: tx,
                        isDark: isDark,
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        withBackground: false,
                        withBorder: false,
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF3F4F6),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primary;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.12)
              : isDark
              ? const Color(0xFF1F2937)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primary
                : isDark
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? primary
                : isDark
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}