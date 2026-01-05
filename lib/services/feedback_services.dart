import 'dart:convert';
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/models/min_property_model.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final _client = MyHttpClient();

  /// ✔ SEND FEEDBACK
  Future<FeedbackModel?> sendFeedback(
    String token,
    String message,
    String propertyUuid,
  ) async {
    final url = Uri.parse(ApiConstants.saveFeedback);

    final bodyData = {"message": message, "property": propertyUuid};

    try {
      final response = await _client.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(bodyData),
      );

      print("➡ SEND FEEDBACK");
      print("URL: $url");
      print("BODY: ${jsonEncode(bodyData)}");
      print("STATUS: ${response.statusCode}");
      print("RESP: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded["data"];

        if (data != null) {
          return FeedbackModel.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      print("Error sending feedback: $e");
      return null;
    }
  }

  /// ✔ OWNER FEEDBACK (ALL FEEDBACKS FOR OWNER)
  Future<List<FeedbackModel>> fetchOwnerFeedback(String token) async {
    final url = Uri.parse(ApiConstants.propertyFeedback);

    try {
      final response = await _client.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("➡ OWNER FEEDBACK STATUS: ${response.statusCode}");
      print("OWNER FEEDBACK BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List dataList = decoded["data"] ?? [];

        return dataList.map((e) => FeedbackModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      print("Error loading owner feedback: $e");
      return [];
    }
  }

  /// ✔ GET PROPERTY BY UUID
  Future<MiniProperty?> getPropertyByUuid(String uuid, String token) async {
    final url = Uri.parse(
      ApiConstants.propertyDetail.replaceFirst("{uuid}", uuid),
    );

    try {
      final response = await _client.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("➡ FETCH PROPERTY UUID: $uuid");
      print("STATUS: ${response.statusCode}");
      print("RESP: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final propertyJson = decoded["data"];

        if (propertyJson != null && propertyJson is Map<String, dynamic>) {
          return MiniProperty.fromJson(propertyJson);
        }
      }

      return null;
    } catch (e) {
      print("Error fetching property: $e");
      return null;
    }
  }

  Future<List<FeedbackModel>> fetchFeedbackForProperty(
    String token,
    String propertyUuid,
  ) async {
    final url = Uri.parse(
      "${ApiConstants.listPropertyFeedback}?property=$propertyUuid",
    );

    try {
      final response = await _client.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("➡ PROPERTY FEEDBACK STATUS: ${response.statusCode}");
      print("PROPERTY FEEDBACK BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List dataList = decoded["data"] ?? [];

        return dataList.map((e) => FeedbackModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      print(" Error loading property feedback: $e");
      return [];
    }
  }
}
