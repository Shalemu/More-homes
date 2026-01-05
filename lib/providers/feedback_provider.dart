import 'package:flutter/material.dart';
import 'package:morehomesapp/services/feedback_services.dart';
import '../models/feedback_model.dart';
import '../models/min_property_model.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _service = FeedbackService();

  // Owner feedback list
  List<FeedbackModel> ownerFeedbacks = [];

  // Property-specific feedback list
  List<FeedbackModel> propertyFeedbacks = [];

  // Cache for property short info
  final Map<String, MiniProperty> propertyCache = {};

  // Loading states
  bool isLoading = false;
  bool isPropertyFeedbackLoading = false;

  /// ✔ Send feedback and return both feedback + property info
  Future<Map<String, dynamic>?> sendFeedbackWithProperty({
    required String token,
    required String message,
    required String propertyUuid,
  }) async {
    print("➡ Sending feedback: property=$propertyUuid message=$message");

    final feedback =
        await _service.sendFeedback(token, message, propertyUuid);

    if (feedback == null) {
      print("Feedback send failed.");
      return null;
    }

    print("Feedback stored: ${feedback.uuid}");

    // Fetch property info
    final property = await getPropertyInfo(feedback.propertyUuid, token);

    return {
      "feedback": feedback,
      "property": property,
    };
  }

  /// ✔ Load all feedbacks for an OWNER
  Future<void> loadOwnerFeedback(String token) async {
    isLoading = true;
    notifyListeners();

    try {
      ownerFeedbacks = await _service.fetchOwnerFeedback(token);
      print("✔ Owner feedback count: ${ownerFeedbacks.length}");

      // Cache property info for each feedback
      await Future.wait(ownerFeedbacks.map((fb) async {
        if (!propertyCache.containsKey(fb.propertyUuid)) {
          final prop = await _service.getPropertyByUuid(fb.propertyUuid, token);
          if (prop != null) propertyCache[fb.propertyUuid] = prop;
        }
      }));
    } catch (e) {
      print(" Error loading owner feedbacks: $e");
      ownerFeedbacks = [];
    }

    isLoading = false;
    notifyListeners();
  }

  /// ✔ Get property info using cache
  Future<MiniProperty?> getPropertyInfo(String uuid, String token) async {
    if (propertyCache.containsKey(uuid)) {
      return propertyCache[uuid];
    }

    try {
      final property = await _service.getPropertyByUuid(uuid, token);

      if (property != null) {
        propertyCache[uuid] = property;
      }

      return property;
    } catch (e) {
      print(" Error fetching property info: $e");
      return null;
    }
  }


  /// { total_item, detail, data: [...], status_code }
  Future<void> loadFeedbackForProperty({
    required String token,
    required String propertyUuid,
  }) async {
    isPropertyFeedbackLoading = true;
    notifyListeners();

    try {
      propertyFeedbacks = await _service.fetchFeedbackForProperty(
        token,
        propertyUuid,
      );

      print("Feedbacks for property $propertyUuid => ${propertyFeedbacks.length}");

    } catch (e) {
      print("Error loading feedback for property: $e");
      propertyFeedbacks = [];
    }

    isPropertyFeedbackLoading = false;
    notifyListeners();
  }
}
