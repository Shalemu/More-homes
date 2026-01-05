import 'package:flutter/material.dart';
import 'package:morehomesapp/models/property_model.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/providers/property_provider.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/view/add_property_screen.dart';
import 'package:morehomesapp/view/edit_property.dart';
import 'package:morehomesapp/view/property_details_screen.dart';
import 'package:provider/provider.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PropertyModel> _filteredProperties = [];

  /// Backend host and port
  final String _backendHost = 'http://213.199.45.65';
  final int _backendPort = 9099;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProperties);
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load uploader properties and print debug info
  Future<void> _loadProperties() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );
    final token = authProvider.accessToken;

    if (token != null) {
      await propertyProvider.fetchUploaderProperties(token);

      setState(() {
        _filteredProperties = List.from(propertyProvider.properties);
      });

      // DEBUG: print loaded properties
      debugPrint('===== Loaded Properties =====');
      for (var p in _filteredProperties) {
        final firstImage = p.images.isNotEmpty
            ? _fixImageUrl(p.images.first)
            : "None";
        debugPrint(
          'Name: ${p.name}, UUID: ${p.uuid}, Images: ${p.images.length}, First Image: $firstImage',
        );
      }
      debugPrint('===== End of Properties =====');
    }
  }

  /// Ensure image URL contains the backend port
  String _fixImageUrl(String url) {
    if (url.contains('://')) {
      // Already has protocol, check if port is missing
      final uri = Uri.parse(url);
      if (uri.port == 80 || uri.port == 0) {
        return '${uri.scheme}://${uri.host}:$_backendPort${uri.path}';
      }
      return url; // already has correct port
    } else {
      // Relative path, prepend host + port
      return '$_backendHost:$_backendPort/$url'
          .replaceAll('//', '/')
          .replaceFirst(':/', '://');
    }
  }

  /// Filter properties by search query
  void _filterProperties() {
    final query = _searchController.text.toLowerCase();
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );

    setState(() {
      if (query.isEmpty) {
        _filteredProperties = List.from(propertyProvider.properties);
      } else {
        _filteredProperties = propertyProvider.properties.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.address.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  /// Confirm delete dialog
  void _confirmDelete(String uuid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProperty(uuid);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Delete property
  Future<void> _deleteProperty(String uuid) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );
    final token = authProvider.accessToken;

    if (token == null) return;

    final success = await propertyProvider.deleteProperty(token, uuid);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleted successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadProperties();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'My Posted Properties',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: propertyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProperties.isEmpty
          ? _emptyState()
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProperties.length,
                    itemBuilder: (context, index) {
                      final property = _filteredProperties[index];
                      return _buildPropertyCard(property, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search your properties...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Property card with fixed image URLs & debug prints
  Widget _buildPropertyCard(PropertyModel property, int index) {
    final imageUrl = property.images.isNotEmpty
        ? _fixImageUrl(property.images.first)
        : null;

    // Clickable Image Widget
    final imageWidget = imageUrl != null
        ? GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: property),
                ),
              );
            },
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  height: 180,
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
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                  'Image failed to load for property ${property.uuid}: $error',
                );
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                );
              },
            ),
          )
        : GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: property),
                ),
              );
            },
            child: Container(
              height: 180,
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, size: 50),
            ),
          );

    debugPrint('Rendering property #$index: ${property.name}');
    debugPrint(
      'Images count: ${property.images.length}, first: ${imageUrl ?? "None"}',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageWidget,
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  'Tsh ${property.price}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  property.formattedUploadTime,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditPropertyScreen(property: property),
                            ),
                          );

                          if (updated == true) {
                            _loadProperties(); // 🔄 refresh WITHOUT leaving screen
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(property.uuid),
                    ),
                  ],
                ),
                  const SizedBox(height: 15),
              
              ],
            ),
          ),
        ],
      ),
      
      
    );
    
  }

  /// Empty state
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 50),
          const SizedBox(height: 10),
          const Text(
            'You have not posted any properties yet.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadPropertyScreen()),
            ),
            child: const Text('Post New Property'),
          ),
        ],
      ),
    );
  }

}
