import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/models/api_response_model.dart';
import '../models/user_model.dart';

class UserService {
  final http.Client _client = http.Client();

  // Fetch Logged-in User
  Future<ApiResponse<UserModel>> fetchLoggedInUser(String accessToken) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.user),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      final data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(
          data,
          (json) => UserModel.fromJson(json),
        );
      }

      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: data['detail'] ?? 'Failed to fetch user',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: 'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }


  // Update Profile
  // ==============================
  Future<ApiResponse<UserModel>> updateProfile(
      String accessToken, UserModel user) async {
    try {
      final response = await _client.put(
        Uri.parse(ApiConstants.user),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      );

      final data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(
          data,
          (json) => UserModel.fromJson(json),
        );
      }

      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: data['detail'] ?? 'Failed to update user',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: 'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

 
}