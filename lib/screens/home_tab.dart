import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/theme_provider.dart';
import '../data/demo_transactions.dart';
import 'login_screen.dart';
import 'transactions_history_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  void _handleLogout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ordina le transazioni per data decrescente per mostrare i movimenti più recenti
    final sortedTransactions = List<TransactionModel>.from(demoTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final displayTransactions = sortedTransactions.take(8).toList();
    final bool hasMoreTransactions = sortedTransactions.length > 8;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardGradientColors = isDark
        ? [const Color(0xFF1E3A8A), const Color(0xFF172554)]
        : [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(255),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Il mio Conto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'theme') {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).toggleTheme();
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6),
                    SizedBox(width: 12),
                    Text('Cambia Tema'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Impostazioni'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Esci',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Text(
            'Bentornato, Alok.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primary,
            elevation: 8,
            shadowColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cardGradientColors,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Disponibile',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '€ 2.450,00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'IT02 L1234 56789 000000123456',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Movimenti Recenti',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Rendering transazioni
          ...displayTransactions.map(
            (tx) => _buildDynamicTransactionItem(context, tx, isDark),
          ),
          if (hasMoreTransactions)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionsHistoryScreen(
                      allTransactions: demoTransactions,
                    ),
                  ),
                );
              },
              child: const Text(
                'Vedi tutte le transazioni',
                style: TextStyle(fontSize: 16),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget dinamico transazioni
  Widget _buildDynamicTransactionItem(
    BuildContext context,
    TransactionModel transaction,
    bool isDark,
  ) {
    final amountColor = transaction.type == TransactionType.income
        ? Theme.of(context).colorScheme.secondary
        : Colors.redAccent;

    final iconBgColor = transaction.type == TransactionType.income
        ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
        : Colors.redAccent.withValues(alpha: 0.1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(transaction.getIcon, color: amountColor, size: 22),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          transaction.formattedDate,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        trailing: Text(
          transaction.formattedAmount,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
