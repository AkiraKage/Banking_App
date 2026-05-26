import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
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

class _HomeTabState extends State<HomeTab> with WidgetsBindingObserver {
  bool _balanceVisible = true;
  bool _loading = true;
  String? _error;

  double _balance = 0.0;
  double _incomeMonth = 0.0;
  double _expenseMonth = 0.0;
  List<TransactionModel> _transactions = const [];
  MeData? _me;

  StreamSubscription<AppEvent>? _eventsSub;
  Timer? _pollTimer;

  // Polling ogni 30s per riflettere pagamenti POS fisici (caso missing 1)
  static const _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboard();
    _eventsSub = AppEvents.stream.listen((event) {
      if (event == AppEvent.accountDataChanged) {
        _loadDashboard();
      }
    });
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventsSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _loadDashboard();
    } else {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _silentRefresh());
  }

  /// Refresh in background: non mostra loader, ignora errori per non disturbare l'utente.
  Future<void> _silentRefresh() async {
    try {
      final balanceData = await ApiService.getBalance();
      final txs = await ApiService.getTransactions();
      if (!mounted) return;
      setState(() {
        _balance = balanceData.balance;
        _incomeMonth = balanceData.incomeMonth;
        _expenseMonth = balanceData.expenseMonth;
        _transactions = txs;
      });
    } catch (_) {}
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getBalance(),
        ApiService.getTransactions(),
        ApiService.getMe(),
      ]);

      final balanceData = results[0] as BalanceData;
      final txs = results[1] as List<TransactionModel>;
      final me = results[2] as MeData;

      if (!mounted) return;
      setState(() {
        _balance = balanceData.balance;
        _incomeMonth = balanceData.incomeMonth;
        _expenseMonth = balanceData.expenseMonth;
        _transactions = txs;
        _me = me;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() => _loadDashboard();

  String _lastFour() {
    final iban = _me?.iban ?? '';
    if (iban.length < 4) return '0000';
    return iban.substring(iban.length - 4);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);

    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(8).toList();
    final hasMore = sorted.length > 8;

    final cardholder = (_me?.name ?? authProvider.userName).toUpperCase();

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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
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
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  BankCard(
                    balance: _balance,
                    balanceVisible: _balanceVisible,
                    cardholderName: cardholder,
                    lastFour: _lastFour(),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasMore)
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionsHistoryScreen(
                                allTransactions: _transactions,
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
                  if (recent.isEmpty)
                    Text(
                      'Nessuna transazione disponibile.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                    )
                  else
                    ...recent.map(
                      (tx) => TransactionTile(tx: tx, isDark: isDark),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }
}
