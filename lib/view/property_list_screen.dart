import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/property_provider.dart';
import '../providers/auth_providers.dart';
import '../theme/app_color.dart';
import 'property_details_screen.dart';

Color getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'rent':
      return Colors.green;
    case 'sale':
      return Colors.blue;
    case 'short stay':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({Key? key}) : super(key: key);

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String activeCategory = 'All';
  bool showAll = false;
  final categories = ['All', 'House', 'Apartment', 'Office', 'Land'];

  final String _backendHost = 'http://213.199.45.65';
  final int _backendPort = 9099;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;

    if (token != null) {
      propertyProvider.fetchProperties(token).then((_) {
        _animationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;

    List<PropertyModel> filteredProperties = propertyProvider.properties
        .where(
          (prop) =>
              (activeCategory == 'All' ||
                  prop.type.toLowerCase() == activeCategory.toLowerCase()) &&
              (prop.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  prop.address.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  )),
        )
        .toList();

    List<PropertyModel> displayedProperties = showAll
        ? filteredProperties
        : filteredProperties.take(4).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (token != null) {
                  await propertyProvider.fetchProperties(token);
                  _animationController.forward(from: 0);
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  const SizedBox(height: 8),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search by name or location...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey.shade200,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Categories
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (_, index) {
                        final category = categories[index];
                        final isActive = category == activeCategory;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              activeCategory = category;
                              showAll = false;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      "Properties",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // View All Button
                  if (!showAll && filteredProperties.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => showAll = true),
                          child: const Text(
                            'View All',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                  // Properties Grid
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedProperties.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600
                            ? 3
                            : 2, // 3 columns on large screens
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.70, // keeps all cards uniform
                      ),
                      itemBuilder: (context, index) {
                        final prop = displayedProperties[index];

                        String? imageUrl = prop.thumbnail;
                        if (imageUrl == null || imageUrl.isEmpty) {
                          if (prop.images.isNotEmpty) {
                            imageUrl = _fixImageUrl(prop.images.first);
                          }
                        } else {
                          imageUrl = _fixImageUrl(imageUrl);
                        }

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailScreen(property: prop),
                            ),
                          ),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image area with fixed aspect ratio
                                AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.home,
                                                      color: Colors.grey,
                                                      size: 40,
                                                    ),
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          color: Colors.grey.shade300,
                                          child: const Center(
                                            child: Icon(
                                              Icons.home,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                ),

                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category + Favorite icons row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (prop.category.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: getCategoryColor(
                                                  prop.category,
                                                ).withOpacity(0.9),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                prop.category,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<PropertyProvider>()
                                                  .toggleFavorite(prop);
                                            },
                                            child: Icon(
                                              context
                                                      .watch<PropertyProvider>()
                                                      .isFavorite(prop)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color:
                                                  context
                                                      .watch<PropertyProvider>()
                                                      .isFavorite(prop)
                                                  ? Colors.red
                                                  : Colors.grey,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),
                                      Text(
                                        prop.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        prop.price,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        prop.formattedUploadTime,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
