import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/feedback_provider.dart';
import '../providers/auth_providers.dart';
import '../models/min_property_model.dart';

class OwnerFeedbackScreen extends StatefulWidget {
  const OwnerFeedbackScreen({super.key});

  @override
  State<OwnerFeedbackScreen> createState() => _OwnerFeedbackScreenState();
}

class _OwnerFeedbackScreenState extends State<OwnerFeedbackScreen> {
  String? token;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      token = Provider.of<AuthProvider>(context, listen: false).accessToken;

      if (token != null) {
        Provider.of<FeedbackProvider>(context, listen: false)
            .loadOwnerFeedback(token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FeedbackProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())

            : provider.ownerFeedbacks.isEmpty
                ? const Center(
                    child: Text(
                      "No feedback yet",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )

                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: provider.ownerFeedbacks.length,
                    separatorBuilder: (_, __) =>
                        Container(height: 1, color: Colors.grey.shade200),

                    itemBuilder: (_, index) {
                      final feedback = provider.ownerFeedbacks[index];

                      return FutureBuilder<MiniProperty?>(
                        future: provider.getPropertyInfo(
                            feedback.propertyUuid, token!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }

                          return _premiumAirbnbLayout(
                              snapshot.data!, feedback);
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _premiumAirbnbLayout(
      MiniProperty property, dynamic feedback) {
    bool isLong = feedback.message.length > 150;
    ValueNotifier<bool> expanded = ValueNotifier(false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Property Title (Airbnb header style)
          Text(
            property.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          // 🏠 Address (soft subtitle)
          Text(
            property.address,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 6),

          // 💵 Price
          Text(
            "Price: ${property.price}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xff2ecc71),
            ),
          ),

          const SizedBox(height: 14),

          // ⭐ Label
          const Text(
            "Customer Feedback",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // ✨ READ MORE / LESS Airbnb Style
          ValueListenableBuilder(
            valueListenable: expanded,
            builder: (context, isExpanded, _) {
              final text = isExpanded
                  ? feedback.message
                  : feedback.message.substring(
                      0, isLong ? 150 : feedback.message.length) +
                      (isLong ? "..." : "");

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),

                  if (isLong)
                    GestureDetector(
                      onTap: () => expanded.value = !isExpanded,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          isExpanded ? "Show less" : "Read more",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    )
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // 🕒 Time Ago
          Text(
            timeago.format(feedback.createdAt, locale: "en_short"),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
