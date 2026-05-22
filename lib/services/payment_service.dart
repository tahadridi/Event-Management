import 'dart:convert';

import 'package:http/http.dart' as http;

class PaymentService {
  static String? _extractStripeErrorMessage(dynamic decoded) {
    if (decoded is Map) {
      final error = decoded['error'];
      if (error is Map) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>> createPaymentIntent({
    required String secretKey,
    required double amount,
    String currency = 'usd',
    String description = 'Event payment',
  }) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': (amount * 100).round().toString(),
        'currency': currency,
        'description': description,
        'automatic_payment_methods[enabled]': 'true',
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = _extractStripeErrorMessage(decoded);
      throw Exception(errorMessage ?? 'Stripe error ${response.statusCode}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid Stripe response');
    }

    return decoded;
  }
}