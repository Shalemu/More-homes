import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/models/plans_model.dart';

class PaymentService {
  final http.Client _client = http.Client();

  // =========================
  // GET PLANS
  // =========================
  Future<List<PlanModel>> getPlans(String token) async {
    final res = await _client.get(
      Uri.parse(ApiConstants.plans),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(body["detail"] ?? "Failed to load plans");
    }

    final List list = body["data"] ?? [];

    return list.map((e) => PlanModel.fromJson(e)).toList();
  }

  // =========================
  // CHECK ELIGIBILITY
  // =========================
  Future<Map<String, dynamic>> checkEligibility(String token) async {
    final res = await _client.get(
      Uri.parse(ApiConstants.checkEligibility),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    final body = jsonDecode(res.body);

    return {"status": res.statusCode, "data": body};
  }

  // =========================
  // SUBSCRIBE TO PLAN (FIXED LOGIC)
  // =========================
  Future<Map<String, dynamic>> subscribe({
    required String token,
    required String planUuid,
  }) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.subscribe(planUuid)),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    final body = jsonDecode(res.body);

    final int statusCode = body["status_code"] ?? res.statusCode;
    final String message = (body["detail"] ?? body["message"] ?? "").toString();

    // =========================
    // SUCCESS
    // =========================
    if (res.statusCode == 200 && statusCode == 200) {
      return {
        "success": true,
        "invoice_uuid": body["invoice_uuid"] ?? body["data"]?["uuid"],
        "message": message,
      };
    }

    // =========================
    // ACTIVE SUBSCRIPTION
    // =========================
    if (message.toLowerCase().contains("active subscription")) {
      return {
        "success": false,
        "already_subscribed": true,
        "message": message,
        "data": body,
      };
    }

    // =========================
    // ERROR
    // =========================
    return {
      "success": false,
      "message": message.isNotEmpty ? message : "Subscription failed",
      "data": body,
    };
  }

  // =========================
  // GET INVOICE DETAIL
  // =========================
  Future<Map<String, dynamic>> getInvoice(
    String token,
    String invoiceUuid,
  ) async {
    final res = await _client.get(
      Uri.parse(ApiConstants.invoiceDetail(invoiceUuid)),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(body["detail"] ?? "Failed to load invoice");
    }

    return body;
  }

  // =========================
  // MAKE PAYMENT (M-PESA / MOBILE MONEY)
  // =========================
  Future<Map<String, dynamic>> makePayment({
    required String token,
    required String invoiceUuid,
    required String phone,
  }) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.makePayment(invoiceUuid)),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"phone": phone}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return {"success": true, "data": body};
    }

    throw Exception(body["message"] ?? "Payment failed");
  }

  // =========================
  // DISPOSE
  // =========================
  void dispose() {
    _client.close();
  }
}
