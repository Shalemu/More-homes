import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:morehomesapp/config/backend_apis.dart';
import 'package:morehomesapp/models/banner_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_model.dart';
import '../providers/property_provider.dart';
import '../providers/auth_providers.dart';
import '../theme/app_color.dart';
import 'property_details_screen.dart';
import 'login_screen.dart';

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
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String activeCategory = 'All';
  final categories = ['All', 'House', 'Apartment', 'Office', 'Land'];

  late final AnimationController _animationController;

  //  Banner State
  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  List<BannerModel> banners = [];
  bool isLoadingBanners = true;
  Timer? _bannerTimer;

  Future<List<BannerModel>> fetchBanners() async {
    try {
      print("Fetching banners from: ${ApiConstants.addBanner}");

      final response = await http.get(Uri.parse(ApiConstants.addBanner));

      print("Status Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List list = data['data'] ?? [];

        print("Parsed banners count: ${list.length}");

        final banners = list.map((e) => BannerModel.fromJson(e)).toList();

        for (var banner in banners) {
          print(" Banner -> image: ${banner.image}");
        }

        return banners;
      } else {
        print("Failed to load banners (Status: ${response.statusCode})");
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      print("ERROR fetching banners: $e");
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();

    loadBanners();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final token = auth.accessToken;

    if (token != null) {
      propertyProvider
          .fetchProperties(token)
          .then((_) {
            if (mounted) {
              _animationController.forward();
            }
          })
          .catchError((e) async {
            if (e.toString().contains("unauthorized")) {
              await auth.logout();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          });
    }
  }

  String _fixImageUrl(String url) {
    if (url.startsWith('http')) return url;
    return url; // Add domain prefix if needed
  }

  void startAutoScroll() {
    _bannerTimer?.cancel(); // prevent duplicates

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || banners.isEmpty) return;

      _currentBanner = (_currentBanner + 1) % banners.length;

      _bannerController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> saveBannersLocally(List<BannerModel> banners) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = banners.map((e) => e.toJson()).toList();

    await prefs.setString('cached_banners', jsonEncode(jsonList));
  }

  Future<List<BannerModel>> loadBannersLocally() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('cached_banners');

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded.map((e) => BannerModel.fromJson(e)).toList();
  }

  Future<void> loadBanners() async {
    try {
      final cached = await loadBannersLocally();

      if (cached.isNotEmpty && mounted) {
        setState(() {
          banners = cached;
          isLoadingBanners = false;
        });

        startAutoScroll();
      }

      final result = await fetchBanners();

      if (!mounted) return;

      setState(() {
        banners = result;
        isLoadingBanners = false;
      });

      await saveBannersLocally(result);

      if (banners.isNotEmpty) {
        startAutoScroll();
      }
    } catch (e) {
      print("Banner error: $e");

      if (!mounted) return;

      setState(() => isLoadingBanners = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final token = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).accessToken;
                if (token != null) {
                  await propertyProvider.fetchProperties(token);
                  _animationController.forward(from: 0);
                }
              },
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
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
                  ),

                  SliverToBoxAdapter(child: _buildBanner()),

                  // Categories
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (_, index) {
                          final category = categories[index];
                          final isActive = category == activeCategory;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => activeCategory = category),
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
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Properties Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600
                            ? 3
                            : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final prop = filteredProperties[index];
                        String? imageUrl =
                            (prop.thumbnail != null &&
                                prop.thumbnail!.isNotEmpty)
                            ? _fixImageUrl(prop.thumbnail!)
                            : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PropertyDetailScreen(property: prop),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ================= IMAGE =================
                                    Stack(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 10,
                                          child: imageUrl != null
                                              ? Image.network(
                                                  imageUrl,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(
                                                    Icons.home,
                                                    size: 40,
                                                  ),
                                                ),
                                        ),

                                        // CATEGORY BADGE
                                        if (prop.category.isNotEmpty)
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: getCategoryColor(
                                                  prop.category,
                                                ),
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
                                          ),

                                        // FAVORITE ICON
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<PropertyProvider>()
                                                  .toggleFavorite(prop);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                context
                                                        .watch<
                                                          PropertyProvider
                                                        >()
                                                        .isFavorite(prop)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ================= DETAILS =================
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        10,
                                        10,
                                        10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // NAME
                                          Text(
                                            prop.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // PRICE (NOW AFTER NAME ✔)
                                          Text(
                                            "TZS ${NumberFormat("#,###").format(double.tryParse(prop.price) ?? 0)}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // LOCATION
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
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 4),

                                          // TIME
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
                            ),
                          ),
                        );
                      }, childCount: filteredProperties.length),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBanner() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() => _currentBanner = index);
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner.image.isNotEmpty
                            ? banner.image
                            : "https://via.placeholder.com/800x300", // fallback image
                        fit: BoxFit.cover,
                      ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),

                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Text(
                          banner.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // INDICATOR DOTS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isActive = index == _currentBanner;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }
}
