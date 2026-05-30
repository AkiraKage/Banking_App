import 'package:flutter/material.dart';

enum TransactionType { income, expense }

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

// Rappresenta una transazione finanziaria nell'applicazione.
class TransactionModel {
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;

  const TransactionModel({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  // Factory constructor: crea un'istanza del modello a partire da dati in formato JSON (mappa).
  // Utile per convertire le risposte ricevute dal server in oggetti Dart.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? 'expense').toString().toLowerCase();
    final catRaw = (json['category'] ?? 'other').toString().toLowerCase();

    final tType = typeRaw == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    // Utilizza il pattern matching di Dart 3 per mappare stringhe alle categorie.
    final tCategory = switch (catRaw) {
      'shopping' => TransactionCategory.shopping,
      'transport' => TransactionCategory.transport,
      'food' => TransactionCategory.food,
      'entertainment' => TransactionCategory.entertainment,
      'health' => TransactionCategory.health,
      'travel' => TransactionCategory.travel,
      'utilities' => TransactionCategory.utilities,
      'salary' => TransactionCategory.salary,
      'transfer' => TransactionCategory.transfer,
      'education' => TransactionCategory.education,
      'subscriptions' => TransactionCategory.subscriptions,
      _ => TransactionCategory.other,
    };

    final amountRaw = json['amount'];
    final parsedAmount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw.toString()) ?? 0.0;

    return TransactionModel(
      title: (json['title'] ?? 'Transazione').toString(),
      amount: parsedAmount.abs(),
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      type: tType,
      category: tCategory,
    );
  }

  // Getter: restituisce l'icona Flutter corrispondente alla categoria della transazione.
  IconData get icon {
    return switch (category) {
      TransactionCategory.shopping => Icons.shopping_bag_outlined,
      TransactionCategory.transport => Icons.directions_car_outlined,
      TransactionCategory.food => Icons.restaurant_outlined,
      TransactionCategory.entertainment => Icons.movie_outlined,
      TransactionCategory.health => Icons.medical_services_outlined,
      TransactionCategory.travel => Icons.flight_outlined,
      TransactionCategory.utilities => Icons.bolt_outlined,
      TransactionCategory.salary => Icons.payments_outlined,
      TransactionCategory.transfer => Icons.sync_alt_rounded,
      TransactionCategory.education => Icons.school_outlined,
      TransactionCategory.subscriptions => Icons.subscriptions_outlined,
      TransactionCategory.other => Icons.more_horiz_rounded,
    };
  }

  String get formattedAmount {
    final prefix = type == TransactionType.income ? '+' : '-';
    return '$prefix €${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get formattedDate {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $h:$min';
  }

  String get formattedDateOnly {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }
}
