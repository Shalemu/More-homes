import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:morehomesapp/view/home_screen.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../theme/app_color.dart';
import 'property_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  final int _backendPort = 9099;
  String _fixImageUrl(String url) {
    try {
      if (url.startsWith('http')) {
        // Already a full URL, return as is
        return url;
      } else {
        // Relative path from backend
        return 'http://$_backendPort:$_backendPort/$url'
            .replaceAll('//', '/')
            .replaceFirst(':/', '://');
      }
    } catch (e) {
      debugPrint('Error fixing image URL ($url): $e');
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();
    final favoriteProperties = propertyProvider.favorites;

    if (favoriteProperties.isEmpty) {
      return const Center(child: Text('No favorites yet!'));
    }
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false, // remove all previous routes
        );
        return false; // prevent default pop
      },
      child: Scaffold(
        body: GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: favoriteProperties.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final prop = favoriteProperties[index];

            // Determine the image to show
            String? imageUrl = prop.thumbnail;
            if (imageUrl == null || imageUrl.isEmpty) {
              if (prop.images.isNotEmpty) {
                imageUrl = _fixImageUrl(prop.images.first);
              }
            } else {
              imageUrl = _fixImageUrl(imageUrl);
            }

            Widget imageWidget;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              if (imageUrl.startsWith('http')) {
                imageWidget = Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.home, size: 40, color: Colors.grey),
                  ),
                );
              } else {
                // Base64 fallback
                try {
                  imageWidget = Image.memory(
                    base64Decode(imageUrl),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                } catch (_) {
                  imageWidget = Container(
                    height: 120,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.home, size: 40, color: Colors.grey),
                  );
                }
              }
            } else {
              imageWidget = Container(
                height: 120,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.home, size: 40, color: Colors.grey),
                ),
              );
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailScreen(property: prop),
                  ),
                );
              },
              child: Stack(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: imageWidget,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.currency(
                                  symbol: "TZS ",
                                  decimalDigits: 0,
                                ).format(double.tryParse(prop.price) ?? 0),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      prop.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Heart icon to remove favorite
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => propertyProvider.toggleFavorite(prop),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
