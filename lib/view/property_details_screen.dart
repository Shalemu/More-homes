import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:morehomesapp/models/feedback_model.dart';
import 'package:morehomesapp/models/min_property_model.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/auth_providers.dart';
import '../providers/feedback_provider.dart';
import '../providers/property_provider.dart';
import '../services/payment_service.dart';
import '../view/payment_web_view.dart';
import '../widget/animated_payment_dialog.dart';
import '../theme/app_color.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;
  const PropertyDetailScreen({Key? key, required this.property})
    : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImageIndex = 0;
  bool _showFullDescription = false;
  final TextEditingController _commentController = TextEditingController();
  bool isSending = false;

  final String _backendHost = 'http://213.199.45.65';
  final int _backendPort = 9099;

  @override
  void initState() {
    super.initState();

    // Delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final feedbackProvider = Provider.of<FeedbackProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load token from AuthProvider (already loaded from SharedPreferences at app start)
      String? token = authProvider.accessToken;

      if (token != null && token.isNotEmpty) {
        await feedbackProvider.loadFeedbackForProperty(
          token: token,
          propertyUuid: widget.property.uuid,
        );
      } else {
        print("⚠No access token found. User might not be logged in.");
      }
    });
  }

  // facility icon map (kept small & extendable)
  final Map<String, IconData> _facilityIcons = {
    'parking': Icons.local_parking,
    'swimming pool': Icons.pool,
    'garden': Icons.park,
    'security': Icons.security,
    'gym': Icons.fitness_center,
    'internet': Icons.wifi,
    'air conditioning': Icons.ac_unit,
    'furnished': Icons.chair,
  };

String _fixImageUrl(String url) {
  try {
    if (url.startsWith('http')) {
      // Already a full URL, return as is
      return url;
    } else {
      // Relative path from backend
      return 'http://$_backendHost:$_backendPort/$url'
          .replaceAll('//', '/')
          .replaceFirst(':/', '://');
    }
  } catch (e) {
    debugPrint('Error fixing image URL ($url): $e');
    return url;
  }
}

  IconData _getFacilityIcon(String name) {
    final key = name.toLowerCase();
    return _facilityIcons[key] ?? Icons.check;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Helper to safely try fetch property id (int) from model

  void _showUploaderDialog(BuildContext context) {
    final property = widget.property;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Uploader Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${property.uploaderName}"),
            const SizedBox(height: 6),
            Text("Contact: ${property.uploaderPhone}"),
            const SizedBox(height: 6),
            Text("Role: ${property.uploaderRole}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Close",
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContactOwner(
    BuildContext context,
    PropertyModel property,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final paymentInfo = await PaymentService.getUserPaymentStatus(
        authProvider.accessToken!,
      );
      Navigator.pop(context);

      if (paymentInfo['isPaid'] == true) {
        Navigator.pushNamed(
          context,
          '/uploader-detail',
          arguments: property.uploaderId,
        );
        return;
      }

      // needs payment
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => AnimatedPaymentDialog(
          property: property,
          message:
              "You need to complete payment to view uploader details.\nAmount: ${paymentInfo['amount'] ?? 'N/A'}",
          type: DialogType.payment,
          onAction: () {
            Navigator.pop(context);
            final url = paymentInfo['paymentUrl'];
            if (url != null && url.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentWebView(url: url)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment link is not available.")),
              );
            }
          },
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _sendMessage(
    PropertyModel property,
    BuildContext sheetContext,
  ) async {
    final message = _commentController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(
        sheetContext,
      ).showSnackBar(const SnackBar(content: Text("Please write a message")));
      return;
    }

    final propertyUuid = property.uuid;
    if (propertyUuid.isEmpty) {
      debugPrint("Property UUID missing. Cannot send message.");
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(
          content: Text("Unable to send message: property UUID missing"),
        ),
      );
      return;
    }

    setState(() => isSending = true);

    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) {
      debugPrint("Auth token missing.");
      setState(() => isSending = false);
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text("Please login to send messages.")),
      );
      return;
    }

    try {
      final feedbackProvider = Provider.of<FeedbackProvider>(
        context,
        listen: false,
      );

      debugPrint("Sending message: $message to property UUID: $propertyUuid");

    
      final result = await feedbackProvider.sendFeedbackWithProperty(
        token: token,
        message: message,
        propertyUuid: propertyUuid,
      );

      setState(() => isSending = false);

      if (result != null) {
        final feedback = result["feedback"] as FeedbackModel;
        final propertyInfo = result["property"] as MiniProperty?;

        _commentController.clear();
        Navigator.pop(sheetContext);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Message sent to owner: ${propertyInfo?.title ?? 'Unknown Property'}",
            ),
          ),
        );

        debugPrint(
          "Message sent successfully! Feedback UUID: ${feedback.uuid}",
        );
      } else {
        ScaffoldMessenger.of(
          sheetContext,
        ).showSnackBar(const SnackBar(content: Text("Failed to send message")));
        debugPrint("Failed to send message.");
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      setState(() => isSending = false);
      ScaffoldMessenger.of(
        sheetContext,
      ).showSnackBar(SnackBar(content: Text("Error sending message: $e")));
    }
  }

  void _openMessageBottomSheet(PropertyModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.33,
            minChildSize: 0.22,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // drag handle
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // title + close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Message Owner",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // property preview
                            _buildPropertyPreview(property),
                            const SizedBox(height: 14),

                            // message field + submit button
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              color: Colors.grey[100],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _commentController,
                                      maxLines: 5,
                                      textInputAction: TextInputAction.newline,
                                      decoration: const InputDecoration(
                                        hintText: "Write your comment...",
                                        border: InputBorder.none,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // CENTERED WIDE BUTTON
                                    Center(
                                      child: SizedBox(
                                        width: 260,
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          icon: isSending
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.send,
                                                  color: Colors.white,
                                                ),

                                          label: Text(
                                            isSending ? "Sending..." : "Send",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),

                                          onPressed: isSending
                                              ? null
                                              : () => _sendMessage(
                                                  property,
                                                  context,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPropertyPreview(PropertyModel property) {
    final firstImage =
        (property.thumbnail != null && property.thumbnail!.isNotEmpty)
        ? _fixImageUrl(property.thumbnail!)
        : (property.images.isNotEmpty
              ? _fixImageUrl(property.images.first)
              : null);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: firstImage != null
              ? Image.network(
                  firstImage,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    width: 84,
                    height: 84,
                    child: const Icon(Icons.broken_image),
                  ),
                )
              : Container(
                  width: 84,
                  height: 84,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                property.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      property.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                property.price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final provider = Provider.of<PropertyProvider>(context);
    final bool isFavorite = provider.isFavorite(property);
    final size = MediaQuery.of(context).size;

    final images = [
      if (property.thumbnail != null && property.thumbnail!.isNotEmpty)
        _fixImageUrl(property.thumbnail!),
      ...property.images.map((img) => _fixImageUrl(img)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          property.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showUploaderDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel + page indicator
            SizedBox(
              height: size.height * 0.36,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (idx) =>
                        setState(() => _currentImageIndex = idx),
                    itemBuilder: (_, i) {
                      final url = images[i];
                      if (url.startsWith('http')) {
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image),
                          ),
                        );
                      } else {
                        try {
                          return Image.memory(
                            base64Decode(url),
                            fit: BoxFit.cover,
                          );
                        } catch (_) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image),
                          );
                        }
                      }
                    },
                  ),

                  // top-right message FAB
                 

                  // page indicator bottom-left
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // time + favorite
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        property.formattedUploadTime,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.redAccent,
                        ),
                        onPressed: () => provider.toggleFavorite(property),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          property.address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        backgroundColor:
                            property.category.toLowerCase() == 'rent'
                            ? AppColors.primary
                            : Colors.green,
                        label: Text(
                          "For ${property.category}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Chip(
                      //   backgroundColor: Colors.black87,
                      //   label: Text(
                      //     property.uploaderName,
                      //     style: const TextStyle(color: Colors.white70),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Property Description",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showFullDescription
                        ? property.description
                        : '${property.description.substring(0, property.description.length > 140 ? 140 : property.description.length)}${property.description.length > 140 ? '...' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (property.description.length > 140)
                    TextButton(
                      onPressed: () => setState(
                        () => _showFullDescription = !_showFullDescription,
                      ),
                      child: Text(
                        _showFullDescription ? 'Read Less' : 'Read More',
                        style: const TextStyle(
                          color: AppColors.buttonSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                 // ---------------- FACILITIES ----------------
if (property.facilities.isNotEmpty) ...[
  const Text(
    "Facilities",
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  ),
  const SizedBox(height: 8),
  Wrap(
    spacing: 8,
    runSpacing: 6,
    children: property.facilities.map((f) {
      return Chip(
        avatar: Icon(
          _getFacilityIcon(f),
          size: 16,
          color: Colors.white,
        ),
        label: Text(
          f,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      );
    }).toList(),
  ),
  const SizedBox(height: 20),
],

// ---------------- PRICE + COST SUMMARY + CONTACT OWNER ----------------
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // -------- PRICE --------
      const Text(
        "Price",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        "TZS ${property.price}",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      // -------- EXTRA COSTS --------
      if (property.category.toLowerCase() == 'rent' &&
          property.propertyCosts.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Divider(),

        const SizedBox(height: 10),
        const Text(
          "Extra costs",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),

        Column(
          children: property.propertyCosts.map((cost) {
            IconData icon;
            switch (cost['name']!.toLowerCase()) {
              case 'umeme':
                icon = Icons.electrical_services_outlined;
                break;
              case 'ulinzi':
                icon = Icons.security_outlined;
                break;
              case 'maintenance':
                icon = Icons.build_outlined;
                break;
              default:
                icon = Icons.attach_money;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cost['name']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    "TZS ${cost['amount']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],

      const SizedBox(height: 12),
      const Divider(),

      // -------- TOTAL --------
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total price",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "TZS ${(
              (double.tryParse(property.price) ?? 0) +
              property.propertyCosts.fold<double>(
                0,
                (sum, e) =>
                    sum + (double.tryParse(e['amount'] ?? '0') ?? 0),
              )
            ).toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),

      // -------- CONTACT OWNER --------
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: () => _handleContactOwner(context, property),
          child: const Text(
            "Contact owner",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  ),
),


                  const SizedBox(height: 24),

                  Consumer<FeedbackProvider>(
                    builder: (context, provider, child) {
                      if (provider.isPropertyFeedbackLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final comments = provider.propertyFeedbacks;

                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            "No comments yet!",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        );
                      }

                      // Local state for show more/less
                      bool showAll = false;

                      return StatefulBuilder(
                        builder: (context, setState) {
                          final visibleComments = showAll
                              ? comments
                              : [comments.first];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Comments",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...visibleComments.map((fb) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.green.shade400,
                                        child: Text(
                                          fb.senderName.isNotEmpty
                                              ? fb.senderName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fb.senderName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              fb.message,
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              fb.createdAtFormatted,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              if (comments.length > 1)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      showAll = !showAll;
                                    });
                                  },
                                  child: Text(
                                    showAll ? "Show less" : "Show more",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      // fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating action (alternate quick open)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openMessageBottomSheet(property),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}
