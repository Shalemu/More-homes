import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/models/plans_model.dart';

class PaymentService {
  final http.Client _client = http.Client();

  // =========================
  // SAFE JSON PARSER
  // =========================
  Map<String, dynamic> _parseResponse(http.Response res) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return {};
    }
  }

  String _getMessage(Map<String, dynamic> body) {
    return (body["detail"] ?? body["message"] ?? "").toString();
  }

  // =========================
  // GET PLANS
  // =========================
  Future<List<PlanModel>> getPlans(String token) async {
    final res = await _client.get(
      Uri.parse(ApiConstants.plans),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final body = _parseResponse(res);

    if (res.statusCode != 200) {
      throw Exception(_getMessage(body).isNotEmpty
          ? _getMessage(body)
          : "Failed to load plans");
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
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final body = _parseResponse(res);

    return {
      "success": res.statusCode == 200,
      "status": res.statusCode,
      "data": body,
      "message": _getMessage(body),
    };
  }

  // =========================
  // SUBSCRIBE
  // =========================
  Future<Map<String, dynamic>> subscribe({
    required String token,
    required String planUuid,
  }) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.subscribe(planUuid)),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final body = _parseResponse(res);

    final int statusCode = body["status_code"] ?? res.statusCode;
    final String message = _getMessage(body).toLowerCase();

 
    if (res.statusCode == 200 && statusCode == 200) {
      return {
        "success": true,
        "invoice_uuid": body["invoice_uuid"] ?? body["data"]?["uuid"],
        "message": message,
        "data": body,
      };
    }


    if (message.contains("active subscription")) {
      return {
        "success": false,
        "already_subscribed": true,
        "message": message,
        "data": body,
      };
    }


    if (message.contains("invoice cancelled")) {
      return {
        "success": false,
        "cancelled": true,
        "message": message,
        "data": body,
      };
    }


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
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final body = _parseResponse(res);

    if (res.statusCode != 200) {
      throw Exception(_getMessage(body).isNotEmpty
          ? _getMessage(body)
          : "Failed to load invoice");
    }

    return body;
  }

  // =========================
  // MAKE PAYMENT
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

    final body = _parseResponse(res);
    final String message = _getMessage(body).toLowerCase();

    
    if (res.statusCode == 200 || res.statusCode == 201) {
      return {
        "success": true,
        "message": message,
        "data": body,
      };
    }


    if (message.contains("invoice cancelled")) {
      return {
        "success": false,
        "cancelled": true,
        "message": message,
        "data": body,
      };
    }

 
    return {
      "success": false,
      "message": message.isNotEmpty ? message : "Payment failed",
      "data": body,
    };
  }


  void dispose() {
    _client.close();
  }
}