import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:morehousesapp/config/backend_apis.dart';
import '../models/api_response_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  /// LOGIN
  Future<ApiResponse<UserModel>> login(String username, String password) async {
    debugPrint(ApiConstants.login);
    final apiRequest = ApiService(endpoint: ApiConstants.login);

    final body = {'username': username, 'password': password};
    final response = await apiRequest.post(body: body);

    // Send POST request
    debugPrint(response.body);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return ApiResponse<UserModel>.fromJson(
        decoded,
        (data) => UserModel.fromJson(data),
      );
    } else {
      debugPrint("error");
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

  /// REGISTER
  Future<ApiResponse<UserModel>> register({required dynamic data}) async {
    final apiRequest = ApiService(endpoint: ApiConstants.registration);
    Map<String, dynamic> body;
    if (data is UserModel) {
      body = data.toJson();
    } else if (data is Map<String, dynamic>) {
      body = data;
    } else {
      throw Exception('Invalid data type for registration');
    }

    final response = await apiRequest.post(body: body);
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return ApiResponse<UserModel>.fromJson(
        body,
        (data) => UserModel.fromJson(data),
      );
    } else {
      throw Exception(responseBody['detail'] ?? 'Something went wrong');
    }
  }
}
