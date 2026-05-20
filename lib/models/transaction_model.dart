import 'package:flutter/material.dart';

enum TransactionType { income, expense }

// Categorie possibili
enum TransactionCategory {
  shopping,
  transport,
  food,
  entertainment,
  health,
  travel,
  utilities,
  salary,
  transfer,
  education,
  subscriptions,
  other,
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
        return Icons.shopping_bag;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.health:
        return Icons.medical_services;
      case TransactionCategory.travel:
        return Icons.flight;
      case TransactionCategory.utilities:
        return Icons.bolt;
      case TransactionCategory.salary:
        return Icons.payments;
      case TransactionCategory.transfer:
        return Icons.sync_alt;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.subscriptions:
        return Icons.subscriptions;
      case TransactionCategory.other:
        return Icons.more_horiz;
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
