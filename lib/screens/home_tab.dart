import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../data/demo_transactions.dart';
import '../widgets/bank_card.dart';
import '../widgets/monthly_summary.dart';
import '../widgets/transaction_tile.dart';
import 'transactions_history_screen.dart';
import 'card_nfc_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _balanceVisible = true;

  static const double _balance = 2450.00;
  static const double _incomeMonth = 2620.00;
  static const double _expenseMonth = 1170.27;

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);

    final sorted = List<TransactionModel>.from(demoTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(8).toList();
    final hasMore = sorted.length > 8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il mio Conto'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Tema chiaro' : 'Tema scuro',
            onPressed: themeProvider.toggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 2),
              child: Text(
                'Bentornato, ${authProvider.userName}.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFF111827),
                ),
              ),
            ),
            BankCard(
              balance: _balance,
              balanceVisible: _balanceVisible,
              onToggleVisibility: () =>
                  setState(() => _balanceVisible = !_balanceVisible),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardNfcScreen()),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 12,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tocca per pagare contactless',
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
            MonthlySummaryRow(
              income: _incomeMonth,
              expense: _expenseMonth,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Movimenti Recenti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (hasMore)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionsHistoryScreen(
                          allTransactions: demoTransactions,
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Vedi tutto',
                      style: TextStyle(
                        color: primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...recent.map((tx) => TransactionTile(tx: tx, isDark: isDark)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
