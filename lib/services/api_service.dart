import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String endpoint;

  ApiService({required this.endpoint});

  // -------------------- GET --------------------
  Future<http.Response> get({Map<String, String>? headers}) async {
    final url = Uri.parse(endpoint);
    final defaultHeaders = {'Content-Type': 'application/json'};
    if (headers != null) defaultHeaders.addAll(headers);

    return await http.get(url, headers: defaultHeaders);
  }

  // -------------------- POST --------------------
  Future<http.Response> post({
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final url = Uri.parse(endpoint);
    final defaultHeaders = {'Content-Type': 'application/json'};
    if (headers != null) defaultHeaders.addAll(headers);

    return await http.post(
      url,
      headers: defaultHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // -------------------- PUT --------------------
  Future<http.Response> put({
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final url = Uri.parse(endpoint);
    final defaultHeaders = {'Content-Type': 'application/json'};
    if (headers != null) defaultHeaders.addAll(headers);

    return await http.put(
      url,
      headers: defaultHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // -------------------- Example: POST with Authorization --------------------
  Future<http.Response> postWithAuth(
    String token, {
    dynamic body,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if (additionalHeaders != null) headers.addAll(additionalHeaders);

    return await post(headers: headers, body: body);
  }

  // -------------------- Example: GET with Authorization --------------------
  Future<http.Response> getWithAuth(
    String token, {
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if (additionalHeaders != null) headers.addAll(additionalHeaders);

    return await get(headers: headers);
  }
}
