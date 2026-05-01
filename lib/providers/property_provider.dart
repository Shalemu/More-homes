import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/backend_apis.dart';
import '../models/property_model.dart';

class PropertyProvider with ChangeNotifier {
  List<PropertyModel> _properties = [];
  List<PropertyModel> _favorites = [];
  bool _isLoading = false;

  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get favorites => _favorites;
  bool get isLoading => _isLoading;

  void toggleFavorite(PropertyModel property) {
    if (_favorites.contains(property)) {
      _favorites.remove(property);
    } else {
      _favorites.add(property);
    }
    notifyListeners();
  }

  bool isFavorite(PropertyModel property) => _favorites.contains(property);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch all public properties
Future<void> fetchProperties(String token) async {
  _setLoading(true);
  try {
    final response = await http.get(
      Uri.parse(ApiConstants.getProperties),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'] ?? [];
      _properties = data.map((e) => PropertyModel.fromJson(e)).toList();
    } 
    else if (response.statusCode == 401) {
      throw Exception("unauthorized");
    } 
    else {
      _properties = [];
      debugPrint('Failed: ${response.body}');
    }
  } catch (e) {
    _properties = [];
    rethrow; 
  }

  _setLoading(false);
}

  /// Fetch properties uploaded by logged-in user
  Future<void> fetchUploaderProperties(String token) async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getUploaderProperties),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        _properties = data.map((e) => PropertyModel.fromJson(e)).toList();
      } else {
        _properties = [];
        debugPrint('Failed to fetch uploader properties: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching uploader properties: $e');
      _properties = [];
    }
    _setLoading(false);
  }

  /// Upload new property
  Future<bool> postProperty(Map<String, dynamic> propertyData, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.uploaderProperties),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(propertyData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUploaderProperties(token); // Refresh list after posting
        return true;
      } else {
        debugPrint('Failed to post property: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error posting property: $e');
      return false;
    }
  }

Future<bool> updateProperty({
  required String token,
  required PropertyModel property,
  required List<File> newImages,
  required List<String> existingImages, // URLs of existing images
}) async {
  final url = Uri.parse(
      ApiConstants.updateProperty.replaceFirst("{uuid}", property.uuid));

  try {
    List<Map<String, dynamic>> imagesPayload = [];

    // Convert existing images to Base64
    for (var imageUrl in existingImages) {
      try {
        final uri = Uri.parse(imageUrl);
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final base64Str = base64Encode(response.bodyBytes);
          imagesPayload.add({"image": base64Str});
          debugPrint("Existing image converted to Base64: $imageUrl");
        } else {
          debugPrint("Failed to fetch existing image: $imageUrl, status: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("Error converting existing image $imageUrl: $e");
      }
    }

    // Convert new images to Base64
    for (var img in newImages) {
      final bytes = await img.readAsBytes();
      final base64Str = base64Encode(bytes);
      imagesPayload.add({"image": base64Str});
      debugPrint("New image converted to Base64: ${img.path}");
    }

    // Prepare final JSON
    final jsonData = property.toJson(forUpload: true);
    jsonData.remove("uuid"); // backend does not need uuid in body
    jsonData["images"] = imagesPayload;

    debugPrint("FINAL JSON to send: ${jsonEncode(jsonData)}");

    // Send PUT request
    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(jsonData),
    );

    debugPrint("Update status: ${response.statusCode}");
    debugPrint("Update response: ${response.body}");

    if (response.statusCode == 200) {
      await fetchUploaderProperties(token);
      return true;
    }
  } catch (e) {
    debugPrint("Error updating property: $e");
  }

  return false;
}




  /// Delete property by UUID
  Future<bool> deleteProperty(String token, String uuid) async {
    try {
      final url = '${ApiConstants.uploaderProperties}$uuid/'; // delete endpoint
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _properties.removeWhere((p) => p.uuid == uuid);
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to delete property: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting property: $e');
      return false;
    }
  }
}
