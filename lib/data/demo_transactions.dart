import '../models/transaction_model.dart';

// Lista demo per testare tutte le categorie e le icone
final List<TransactionModel> demoTransactions = [
  TransactionModel(
    title: 'LIDL',
    amount: 84.50,
    date: DateTime.now().subtract(const Duration(hours: 2)),
    type: TransactionType.expense,
    category: TransactionCategory.shopping,
  ),
  TransactionModel(
    title: 'Acconto Stipendio',
    amount: 1500.00,
    date: DateTime.now().subtract(const Duration(days: 1)),
    type: TransactionType.income,
    category: TransactionCategory.salary,
  ),
  TransactionModel(
    title: 'Italo Treno',
    amount: 24.90,
    date: DateTime.now().subtract(const Duration(days: 5)),
    type: TransactionType.expense,
    category: TransactionCategory.travel,
  ),
  TransactionModel(
    title: 'Bonifico in entrata',
    amount: 150.00,
    date: DateTime.now().subtract(const Duration(days: 15)),
    type: TransactionType.income,
    category: TransactionCategory.transfer,
  ),
  TransactionModel(
    title: 'Bolletta Luce',
    amount: 65.00,
    date: DateTime.now().subtract(const Duration(days: 20)),
    type: TransactionType.expense,
    category: TransactionCategory.utilities,
  ),
  TransactionModel(
    title: 'Pizzeria',
    amount: 22.00,
    date: DateTime.now().subtract(const Duration(days: 35)),
    type: TransactionType.expense,
    category: TransactionCategory.shopping,
  ),
  TransactionModel(
    title: 'Rimborso Spese',
    amount: 45.00,
    date: DateTime.now().subtract(const Duration(days: 40)),
    type: TransactionType.income,
    category: TransactionCategory.transfer,
  ),
  TransactionModel(
    title: 'Farmacia',
    amount: 15.00,
    date: DateTime.now().subtract(const Duration(days: 45)),
    type: TransactionType.expense,
    category: TransactionCategory.pharmacy,
  ),
];
