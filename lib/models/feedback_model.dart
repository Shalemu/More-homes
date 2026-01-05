import 'package:timeago/timeago.dart' as timeago;

class FeedbackModel {
  final String uuid;
  final String message;
  final String propertyUuid;
  final String senderName;
  final DateTime createdAt;

  FeedbackModel({
    required this.uuid,
    required this.message,
    required this.propertyUuid,
    required this.senderName,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      uuid: json['uuid'],
      message: json['message'],
      propertyUuid: json['property_uuid'],
      senderName: json['sender_name'] ?? 'Unknown',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get createdAtFormatted => timeago.format(createdAt);
}
