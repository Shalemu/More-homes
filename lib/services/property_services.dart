import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/core/helpers/api_handler.dart';
import 'package:morehomesapp/models/property_model.dart';
import 'package:morehomesapp/main.dart'; // for navigatorKey

class PropertyService {
  
  /// UPLOAD PROPERTY
  static Future<bool> uploadProperty(
    Map<String, dynamic> propertyData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.uploaderProperties),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(propertyData),
      );

      final decoded = jsonDecode(response.body);

      debugPrint('UPLOAD STATUS: ${response.statusCode}');
      debugPrint('UPLOAD RESPONSE: ${response.body}');

      if (decoded is Map<String, dynamic>) {
        ApiHandler.handle(navigatorKey.currentContext!, decoded);
      }

      /// SUCCESS CHECK
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error uploading property: $e');
      return false;
    }
  }

  // FETCH ALL PROPERTIES

  static Future<List<Map<String, dynamic>>> fetchProperties() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getProperties),
        headers: {'Content-Type': 'application/json'},
      );

      final decoded = jsonDecode(response.body);

      debugPrint('FETCH STATUS: ${response.statusCode}');
      debugPrint('FETCH RESPONSE: ${response.body}');

      if (decoded is Map<String, dynamic>) {
        ApiHandler.handle(navigatorKey.currentContext!, decoded);
      }

      /// VALID RESPONSE
      if (response.statusCode == 200 && decoded is Map) {
        final List<dynamic> list = decoded['data'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      return [];
    }
  }

  // FETCH USER PROPERTIES

  static Future<List<PropertyModel>> fetchUploaderProperties(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getUploaderProperties),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final decoded = jsonDecode(response.body);

      debugPrint('UPLOADER STATUS: ${response.statusCode}');
      debugPrint('UPLOADER BODY: ${response.body}');

      if (decoded is Map<String, dynamic>) {
        ApiHandler.handle(navigatorKey.currentContext!, decoded);
      }

      /// SUCCESS
      if (response.statusCode == 200 && decoded is Map) {
        final List data = decoded['data'] ?? [];
        return data.map((e) => PropertyModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching uploader properties: $e');
      return [];
    }
  }

  // DELETE PROPERTY

  static Future<bool> deleteProperty({
    required String token,
    required String uuid,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiConstants.uploaderProperties}$uuid/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final decoded = jsonDecode(response.body);

      debugPrint('DELETE STATUS: ${response.statusCode}');
      debugPrint('DELETE RESPONSE: ${response.body}');

      if (decoded is Map<String, dynamic>) {
        ApiHandler.handle(navigatorKey.currentContext!, decoded);
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting property: $e');
      return false;
    }
  }
}
