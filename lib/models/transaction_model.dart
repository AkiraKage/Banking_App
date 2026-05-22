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
    return '$prefix€ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get formattedDate {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $h:$min';
  }

  /// Ritorna solo la data (senza orario)
  String get formattedDateOnly {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }
}
