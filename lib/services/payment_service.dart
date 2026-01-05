import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/backend_apis.dart';

class PaymentService {
  /// Fetch user payment info
  static Future<Map<String, dynamic>> getUserPaymentStatus(String token) async {
    final uri = Uri.parse(ApiConstants.paymentUrl);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Expect structure like your example
        if (decoded['data'] != null && decoded['data'] is List && decoded['data'].isNotEmpty) {
          final order = decoded['data'][0];
          return {
            'isPaid': order['is_paid'] ?? false,
            'paymentUrl': order['payment_gateway_url'] ?? '',
            'amount': order['amount'] ?? '',
            'orderId': order['order_id'] ?? '',
          };
        } else {
          // No active order
          return {
            'isPaid': false,
            'paymentUrl': null,
            'amount': null,
            'orderId': null,
          };
        }
      } else {
        throw Exception("Failed to fetch payment info (${response.statusCode})");
      }
    } catch (e) {
      rethrow;
    }
  }
}
