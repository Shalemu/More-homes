import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/api_response_model.dart';
import '../models/user_model.dart';
import '../config/backend_apis.dart';

class AuthService {
/// LOGIN
Future<ApiResponse<UserModel>> login(String email, String password) async {
final uri = Uri.parse(ApiConstants.login);
final body = {'username': email, 'password': password};


try {
  final response = await http.post(
    uri,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  debugPrint("Login status code: ${response.statusCode}");
  debugPrint("Login body: ${response.body}");

  if (!response.headers['content-type']!.contains("application/json")) {
    throw Exception(
      "Login failed: Server returned non-JSON response:\n${response.body}",
    );
  }

  final decoded = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return ApiResponse<UserModel>.fromJson(
      decoded,
      (data) => UserModel.fromJson(data),
    );
  } else {
    final detail = decoded['detail'] ?? decoded.toString();
    throw Exception("Login failed: $detail");
  }
} catch (e, stackTrace) {
  debugPrint("Login exception: $e\n$stackTrace");
  rethrow;
}


}

Future<List<Map<String, dynamic>>> getRoles() async {
  final uri = Uri.parse(ApiConstants.roles);

  try {
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
    });

    debugPrint("Roles status code: ${response.statusCode}");
    debugPrint("Roles response: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List roles = decoded['data'];
      return roles.map<Map<String, dynamic>>((role) {
        return {
          'id': role['id'],
          'name': role['name'],
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch roles (${response.statusCode})");
    }
  } catch (e) {
    debugPrint("Error fetching roles: $e");
    rethrow;
  }
}


/// REGISTER
Future<ApiResponse<UserModel>> register({required UserModel data}) async {
final uri = Uri.parse(ApiConstants.registration);
final body = {
"username": data.email,
"first_name": data.firstName,
"last_name": data.lastName,
"phone": data.phone,
"email": data.email,
"location": data.location,
"password": data.password,
// "service_charge": data.serviceCharge ?? "0",
"groups": data.groups,
};


debugPrint("Registration body: $body");

try {
  final response = await http.post(
    uri,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  debugPrint("Registration status code: ${response.statusCode}");
  debugPrint("Registration headers: ${response.headers}");
  debugPrint("Registration body: ${response.body}");

  final contentType = response.headers['content-type'] ?? '';
  if (!contentType.contains("application/json")) {
    throw Exception(
      "Server returned non-JSON response! Full response:\n${response.body}",
    );
  }

  final decoded = jsonDecode(response.body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    return ApiResponse<UserModel>.fromJson(
      decoded,
      (data) => UserModel.fromJson(data),
    );
  } else {
    final detail = decoded['detail'] ?? decoded.toString();
    throw Exception("Registration failed: $detail");
  }
} catch (e, stackTrace) {
  debugPrint("Registration exception: $e\n$stackTrace");
  rethrow;
}


}
}
