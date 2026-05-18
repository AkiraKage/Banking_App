import 'package:flutter/material.dart';

enum TransactionType { income, expense }

// Categorie possibili
enum TransactionCategory {
  shopping,
  travel,
  pharmacy,
  salary,
  transfer,
  utilities,
}

class TransactionModel {
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;

  TransactionModel({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  // Icona in base alla categoria
  IconData get getIcon {
    switch (category) {
      case TransactionCategory.shopping:
        return Icons.shopping_cart;
      case TransactionCategory.travel:
        return Icons.flight_takeoff;
      case TransactionCategory.pharmacy:
        return Icons.local_pharmacy;
      case TransactionCategory.salary:
        return Icons.work;
      case TransactionCategory.transfer:
        return Icons.sync_alt;
      case TransactionCategory.utilities:
        return Icons.bolt;
    }
  }

  String get formattedAmount {
    String prefix = type == TransactionType.income ? '+' : '-';
    return '$prefix € ${amount.toStringAsFixed(2)}';
  }

  // Metodo rapido per formattare data e ora (es. "16/05/2026 - 14:30")
  String get formattedDate {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year - $hour:$minute';
  }
}
