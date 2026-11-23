import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../models/cash_advance.dart';
import '../models/pay_type.dart';
import '../models/transaction_all.dart';

/// All HTTP calls to the backend. List calls return `null` when the request fails.
class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions);

  /// Shared instance used by the pages. Tests can replace it with a fake.
  static ApiService instance = ApiService();

  /// Without timeouts a dead server leaves the page spinning forever.
  /// Writes get a long receive timeout: a timeout after the server has already
  /// posted to accounting would make users retry and post twice.
  static final _defaultOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  );

  final Dio _dio;

  /// Pay types rarely change; both tabs share one successful request.
  Future<List<PayType>?>? _payTypes;

  /// Pay-advance rows for one booking date.
  Future<List<CashAdvance>?> fetchPayAdvance({required String bookDate}) => _postList(
        ApiConfig.marketingUrl,
        {'param': 'cashadvance', 'bookdate': bookDate},
        CashAdvance.fromJsonList,
      );

  /// Credit and pay-advance rows for a date range.
  Future<List<CashAdvance>?> fetchCreditRange({required String startDate, required String endDate}) => _postList(
        ApiConfig.marketingUrl,
        {'param': 'cashadvanceall', 'startdate': startDate, 'enddate': endDate},
        CashAdvance.fromJsonList,
      );

  /// Account code → pay type names. Cached after the first success.
  Future<List<PayType>?> fetchPayTypes() {
    return _payTypes ??=
        _postList(ApiConfig.marketingUrl, {'param': 'listtypepay'}, PayType.fromJsonList).then((result) {
      if (result == null || result.isEmpty) _payTypes = null; // allow a retry
      return result;
    });
  }

  /// Per-cashier transaction summary for one day (e.g. `2025-02-10`).
  Future<List<TransactionAll>?> fetchTransactions({required String showDate}) => _postList(
        ApiConfig.ticketingUrl,
        {'param': 'reportpaymentall', 'showdate': showDate},
        TransactionAll.fromJsonList,
      );

  /// Sets a row's `activeflag` (see `ActiveFlag`) and posts it to accounting.
  /// Throws when the request fails.
  Future<void> updateActiveFlag({
    required CashAdvance item,
    required String flag,
    required String docDate,
    required String refNo,
  }) async {
    final formData = FormData.fromMap({
      'param': 'up_activeflag',
      'id': item.id,
      'activeflag': flag,
      'accode': item.accode,
      'customercode': item.agentcode,
      'person_id': item.userid,
      'docdate': docDate,
      'damt': item.amount,
      'refno': refNo,
      'paytype': item.paytype, // 2 = credit, 4 = pay advance
      'rsvn': item.rsvn,
    });
    await _dio.post(ApiConfig.marketingUrl, data: formData);
  }

  Future<List<T>?> _postList<T>(
    String url,
    Map<String, dynamic> fields,
    List<T> Function(List) parse,
  ) async {
    try {
      final response = await _dio.post(url, data: FormData.fromMap(fields));
      if (response.statusCode == 200) {
        return parse(_asList(response.data));
      }
      debugPrint('API ${fields['param']} returned ${response.statusCode}');
    } catch (e) {
      debugPrint('API ${fields['param']} failed: $e');
    }
    return null;
  }

  /// PHP endpoints sometimes answer `null`, an empty body, or JSON sent as
  /// `text/html` (which Dio leaves as a string). All of those mean "no rows"
  /// or need decoding rather than being treated as a failure.
  static List _asList(dynamic data) {
    if (data is String) {
      final text = data.trim();
      if (text.isEmpty || text == 'null') return const [];
      data = jsonDecode(text);
    }
    if (data == null) return const [];
    if (data is List) return data;
    throw FormatException('Expected a JSON list, got ${data.runtimeType}');
  }
}
