import '../models/payment_record_model.dart';
import 'api_client.dart';

class PaymentService {
  final ApiClient _api = ApiClient();

  /// Returns the payment history for a user (newest first).
  /// Throws on network/API errors so callers can show proper error state.
  Future<List<PaymentRecord>> getPaymentHistory(String userId) async {
    final response = await _api.get('/payments/user/$userId');
    if (response is List) {
      return response
          .map((json) => PaymentRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Registers one or more monthly payments for a user.
  /// Returns true on success.
  Future<bool> registerPayment(
    String userId, {
    double? amount,
    String? method,
    String? notes,
    int periodMonths = 1,
  }) async {
    final body = <String, dynamic>{
      'periodMonths': periodMonths,
      if (amount != null) 'amount': amount,
      if (method != null && method.isNotEmpty) 'method': method,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      await _api.post('/payments/user/$userId', body);
      return true;
    } catch (e) {
      return false;
    }
  }
}
