import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:morehomesapp/models/api_response_model.dart';
import '../models/user_model.dart';


class UserService {
  final String baseUrl = "http://213.199.45.65:9099";

  Future<ApiResponse<UserModel>> fetchLoggedInUser(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/user/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ApiResponse.fromJson(
        jsonResponse,
        (data) => UserModel.fromJson(data),
      );
    } else {
      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: 'Failed to fetch user',
        statusCode: response.statusCode,
      );
    }
  }

  Future<ApiResponse<UserModel>> updateProfile(
      String accessToken, UserModel user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/user/update/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ApiResponse.fromJson(
        jsonResponse,
        (data) => UserModel.fromJson(data),
      );
    } else {
      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: 'Failed to update user',
        statusCode: response.statusCode,
      );
    }
  }
}
