import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:morehomesapp/models/property_model.dart';

class PropertyService {
  static const String baseUrl = 'http://213.199.45.65:9099/homes';

  // Upload property (JSON only)
  static Future<bool> uploadProperty(Map<String, dynamic> propertyData, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(propertyData),
      );

      debugPrint('UPLOAD STATUS: ${response.statusCode}');
      debugPrint('UPLOAD RESPONSE: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error uploading property: $e');
      return false;
    }
  }

  // Fetch all properties
  static Future<List<Map<String, dynamic>>> fetchProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('FETCH STATUS: ${response.statusCode}');
      debugPrint('FETCH RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> propertyList = jsonResponse['data'] ?? [];
        return List<Map<String, dynamic>>.from(propertyList);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      return [];
    }
  }

  // Fetch properties uploaded by the logged-in user
  static Future<List<PropertyModel>> fetchUploaderProperties(String token) async {
    const String url = "$baseUrl/uploader-properties/";
    final List<PropertyModel> uploaderProperties = [];

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Uploader Properties STATUS: ${response.statusCode}');
      debugPrint('Uploader Properties BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        uploaderProperties.addAll(data.map((e) => PropertyModel.fromJson(e)));
        debugPrint('Fetched ${uploaderProperties.length} uploader properties.');
      } else {
        debugPrint('Failed to fetch uploader properties.');
      }
    } catch (e) {
      debugPrint('Error fetching uploader properties: $e');
    }

    return uploaderProperties;
  }

  // Delete property
  static Future<bool> deleteProperty({required String token, required String uuid}) async {
    final String url = "$baseUrl/properties/$uuid/";

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('DELETE STATUS: ${response.statusCode}');
      debugPrint('DELETE RESPONSE: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting property: $e');
      return false;
    }
  }
}
