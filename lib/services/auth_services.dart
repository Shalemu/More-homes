import 'dart:convert';
import 'dart:io';
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
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    debugPrint("Login status code: ${response.statusCode}");
    debugPrint("Login body: ${response.body}");

    if (response.body.isEmpty) {
      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: "Empty response from server",
        statusCode: response.statusCode,
      );
    }



    final decoded = jsonDecode(response.body);

   
    return ApiResponse<UserModel>.fromJson(
      decoded,
      (data) => UserModel.fromJson(data),
    );
  } catch (e) {
    debugPrint("Login exception: $e");

   
    return ApiResponse<UserModel>(
      totalItem: 0,
      detail: e.toString(),
      statusCode: 500,
    );
  }
}
  Future<List<Map<String, dynamic>>> getRoles() async {
    final uri = Uri.parse(ApiConstants.roles);

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      debugPrint("Roles status code: ${response.statusCode}");
      debugPrint("Roles response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List roles = decoded['data'];
        return roles.map<Map<String, dynamic>>((role) {
          return {'id': role['id'], 'name': role['name']};
        }).toList();
      } else {
        throw Exception("Failed to fetch roles (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Error fetching roles: $e");
      rethrow;
    }
  }

  // REGISTER
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
      "groups": data.groups,
    };

    debugPrint("Registration body: $body");

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
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


  /// The server only accepts .jpg/.jpeg/.png, but the picker can hand back
  /// files with odd extensions (e.g. ".cr2"). Sniff the real format and
  /// return a copy with a matching extension.
  Future<File> _withValidImageExtension(File source) async {
    final lower = source.path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
      return source;
    }

    final raf = await source.open();
    final header = await raf.read(8);
    await raf.close();

    final isPng = header.length >= 4 &&
        header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47;
    final isJpeg = header.length >= 3 &&
        header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;

    if (!isPng && !isJpeg) {
      throw Exception('Selected file is not a JPG or PNG image.');
    }

    final ext = isPng ? 'png' : 'jpg';
    return source.copy('${source.parent.path}/profile_upload.$ext');
  }

  /// UPDATE PROFILE (multipart/form-data — the endpoint rejects
  /// application/json since it accepts a profile picture file)
  Future<ApiResponse<UserModel>> updateProfile({
    required String token,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? location,
    File? profileImage,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(ApiConstants.updateProfile),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['first_name'] = firstName
        ..fields['last_name'] = lastName
        ..fields['phone'] = phone
        ..fields['email'] = email;

      if (location != null) {
        request.fields['location'] = location;
      }

      if (profileImage != null) {
        final uploadFile = await _withValidImageExtension(profileImage);
        debugPrint(
          "Update profile: attaching image ${uploadFile.path} (${await uploadFile.length()} bytes)",
        );
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', uploadFile.path),
        );
      }

      debugPrint("Update profile: PATCH ${ApiConstants.updateProfile}");
      debugPrint("Update profile: fields ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Update profile status code: ${response.statusCode}");
      debugPrint("Update profile body: ${response.body}");

      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userJson = (decoded is Map && decoded['data'] != null)
            ? decoded['data']
            : decoded;

        return ApiResponse<UserModel>(
          totalItem: 0,
          detail: (decoded is Map ? (decoded['detail'] ?? decoded['msg']) : null) ??
              'Profile updated successfully',
          statusCode: response.statusCode,
          data: UserModel.fromJson(userJson),
        );
      }

      String errorMessage = 'Failed to update profile';
      if (decoded is Map) {
        if (decoded['detail'] != null) {
          errorMessage = decoded['detail'].toString();
        } else if (decoded['msg'] != null) {
          errorMessage = decoded['msg'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        } else if (decoded.isNotEmpty) {
          errorMessage = decoded.values
              .map((e) => e is List ? e.join(", ") : e.toString())
              .join("\n");
        }
      }

      debugPrint("Update profile failed (${response.statusCode}): $errorMessage");

      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint("Update profile exception: $e");
      return ApiResponse<UserModel>(
        totalItem: 0,
        detail: 'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<void>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.changePassword),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          totalItem: 0,
          detail: data['detail'] ?? 'Password changed successfully',
          statusCode: 200,
        );
      }

      String errorMessage = data['detail'] ?? 'Failed to change password';

      if (!data.containsKey('detail')) {
        errorMessage = data.values
            .map((e) => e is List ? e.join(", ") : e.toString())
            .join("\n");
      }

      return ApiResponse<void>(
        totalItem: 0,
        detail: errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        totalItem: 0,
        detail: 'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }
}
