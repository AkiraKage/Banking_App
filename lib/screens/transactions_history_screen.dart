import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionsHistoryScreen extends StatelessWidget {
  final List<TransactionModel> allTransactions;

  const TransactionsHistoryScreen({super.key, required this.allTransactions});

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  // Raggruppa le transazioni per "Mese Anno" o solo "Mese" se è l'anno corrente
  Map<String, List<TransactionModel>> _groupTransactions(
    List<TransactionModel> transactions,
  ) {
    Map<String, List<TransactionModel>> grouped = {};
    final currentYear = DateTime.now().year;

    for (var tx in transactions) {
      String monthName = _getMonthName(tx.date.month);
      // Se non è l'anno corrente, aggiungiamo l'anno al titolo del gruppo
      String groupKey = tx.date.year == currentYear
          ? monthName
          : '$monthName ${tx.date.year}';

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactions(allTransactions);

    return Scaffold(
      appBar: AppBar(title: const Text('Storico Transazioni')),
      body: ListView.builder(
        itemCount: groupedTransactions.length,
        itemBuilder: (context, index) {
          String monthKey = groupedTransactions.keys.elementAt(index);
          List<TransactionModel> monthTransactions =
              groupedTransactions[monthKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titolo del mese
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  monthKey.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              // Generazione della lista delle singole transazioni per quel mese
              ...monthTransactions.map((tx) {
                final amountColor = tx.type == TransactionType.income
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.redAccent;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: amountColor.withValues(alpha: 0.1),
                    child: Icon(tx.getIcon, color: amountColor, size: 20),
                  ),
                  title: Text(
                    tx.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(tx.formattedDate),
                  trailing: Text(
                    tx.formattedAmount,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}
