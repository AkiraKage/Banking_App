import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class BalanceData {
  final double balance;
  final double incomeMonth;
  final double expenseMonth;

  const BalanceData({
    required this.balance,
    required this.incomeMonth,
    required this.expenseMonth,
  });
}

class QrDetails {
  final double amount;
  final String merchantName;

  const QrDetails({required this.amount, required this.merchantName});
}

class MeData {
  final int id;
  final String name;
  final String username;
  final double balance;
  final String iban;
  final bool cardActive;

  const MeData({
    required this.id,
    required this.name,
    required this.username,
    required this.balance,
    required this.iban,
    required this.cardActive,
  });
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  // Header base condivisi: include ngrok-skip-browser-warning per evitare
  // l'interstitial HTML di ngrok che rompe il parsing JSON
  static Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Map<String, String> _authHeaders(String token) => {
    ..._baseHeaders,
    'Authorization': 'Bearer $token',
  };

  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL']?.trim();
    final raw = (envUrl != null && envUrl.isNotEmpty)
        ? envUrl
        : const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:5000',
          );
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static Uri _uri(String path) {
    final fixedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$fixedPath');
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static Future<Map<String, dynamic>> _decodeResponse(http.Response res) async {
    if (res.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Risposta non JSON (es. interstitial HTML): trattiamo come vuota
    }
    return {};
  }

  static Future<bool> _refreshAccessToken() async {
    final refresh = await StorageService.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    final res = await http
        .post(
          _uri('/api/refresh'),
          headers: _baseHeaders,
          body: jsonEncode({'refresh_token': refresh}),
        )
        .timeout(_timeout);

    if (res.statusCode >= 400) return false;

    final data = await _decodeResponse(res);
    final accessToken = data['token']?.toString();
    final newRefresh = data['refresh_token']?.toString();

    if (accessToken == null || newRefresh == null) return false;

    await StorageService.saveAuthToken(accessToken);
    await StorageService.saveRefreshToken(newRefresh);
    return true;
  }

  static Future<http.Response> _authedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    final token = await StorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Sessione non valida. Effettua il login.');
    }

    var res = await request(token).timeout(_timeout);

    if (res.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await StorageService.clearSession();
        throw ApiException(
          'Sessione scaduta. Effettua nuovamente il login.',
          statusCode: 401,
        );
      }
      final newToken = await StorageService.getAuthToken();
      if (newToken == null || newToken.isEmpty) {
        await StorageService.clearSession();
        throw ApiException(
          'Sessione scaduta. Effettua nuovamente il login.',
          statusCode: 401,
        );
      }
      res = await request(newToken).timeout(_timeout);
    }

    return res;
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await http
        .post(
          _uri('/api/login'),
          headers: _baseHeaders,
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_timeout);

    final data = await _decodeResponse(res);
    if (res.statusCode >= 400 || data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ?? 'Login fallito',
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  static Future<void> logout() async {
    final token = await StorageService.getAuthToken();
    final refresh = await StorageService.getRefreshToken();

    if (token != null && token.isNotEmpty) {
      try {
        await http
            .post(
              _uri('/api/logout'),
              headers: _authHeaders(token),
              body: jsonEncode({'refresh_token': refresh}),
            )
            .timeout(_timeout);
      } catch (_) {}
    }
  }

  static Future<MeData> getMe() async {
    final res = await _authedRequest((token) {
      return http.get(_uri('/api/me'), headers: _authHeaders(token));
    });

    final data = await _decodeResponse(res);
    if (res.statusCode >= 400) {
      throw ApiException(
        data['message']?.toString() ?? 'Errore profilo',
        statusCode: res.statusCode,
      );
    }
    return MeData(
      id: (data['id'] is num)
          ? (data['id'] as num).toInt()
          : int.tryParse(data['id'].toString()) ?? 0,
      name: (data['name'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      balance: _toDouble(data['balance']),
      iban: (data['iban'] ?? '').toString(),
      cardActive: data['card_active'] == true,
    );
  }

  static Future<BalanceData> getBalance() async {
    final res = await _authedRequest((token) {
      return http.get(_uri('/api/balance'), headers: _authHeaders(token));
    });

    if (res.statusCode >= 400) {
      final data = await _decodeResponse(res);
      throw ApiException(
        data['message']?.toString() ?? 'Errore saldo',
        statusCode: res.statusCode,
      );
    }

    final data = await _decodeResponse(res);
    return BalanceData(
      balance: _toDouble(data['balance']),
      incomeMonth: _toDouble(data['income_month']),
      expenseMonth: _toDouble(data['expense_month']),
    );
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final res = await _authedRequest((token) {
      return http.get(_uri('/api/transactions'), headers: _authHeaders(token));
    });

    if (res.statusCode >= 400) {
      final data = await _decodeResponse(res);
      throw ApiException(
        data['message']?.toString() ?? 'Errore transazioni',
        statusCode: res.statusCode,
      );
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<QrDetails> getQrDetails(String qrToken) async {
    final res = await _authedRequest((token) {
      return http.get(_uri('/api/qr/$qrToken'), headers: _authHeaders(token));
    });

    final data = await _decodeResponse(res);
    if (res.statusCode >= 400) {
      throw ApiException(
        data['message']?.toString() ?? 'QR non valido',
        statusCode: res.statusCode,
      );
    }

    return QrDetails(
      amount: _toDouble(data['amount']),
      merchantName: (data['merchant_name'] ?? 'Esercente').toString(),
    );
  }

  static Future<Map<String, dynamic>> confirmQr(String qrToken) async {
    final res = await _authedRequest((token) {
      return http.post(
        _uri('/api/qr/confirm'),
        headers: _authHeaders(token),
        body: jsonEncode({'qr_token': qrToken}),
      );
    });

    final data = await _decodeResponse(res);
    if (res.statusCode >= 400 || data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ?? 'Conferma QR fallita',
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> createTransfer({
    required String beneficiary,
    required String iban,
    required double amount,
    required String reason,
  }) async {
    final res = await _authedRequest((token) {
      return http.post(
        _uri('/api/transfer'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'beneficiary': beneficiary,
          'iban': iban,
          'amount': amount,
          'reason': reason,
        }),
      );
    });

    final data = await _decodeResponse(res);
    if (res.statusCode >= 400 || data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ?? 'Bonifico fallito',
        statusCode: res.statusCode,
      );
    }
    return data;
  }
}
