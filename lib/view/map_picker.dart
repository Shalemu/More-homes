import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  bool _loading = false;
  bool _locationTapped = false;
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final String mapTilerApiKey = 'TeXYsuIuJeX1NepPjksu';

  final Map<String, String> _mapStyles = {
    'Streets': 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=',
    'Satellite + Labels':
        'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=',
    'Satellite (No Labels)':
        'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=',
    'Basic': 'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=',
    'Topographic': 'https://api.maptiler.com/maps/topo/{z}/{x}/{y}.png?key=',
    'Bright': 'https://api.maptiler.com/maps/bright/{z}/{x}/{y}.png?key=',
  };

  String _selectedMapStyle = 'Streets';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _onTap(LatLng latlng) {
    setState(() {
      _pickedLocation = latlng;
      _locationTapped = true;
    });
  }

  Future<Map<String, String>> _getAddressFromMapTiler(
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/$lng,$lat.json?key=$mapTilerApiKey',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'].isNotEmpty) {
        final feature = data['features'].first;
        final context = feature['context'] ?? [];

        String? village;
        String? district;
        String? region;
        String? country;

        for (var item in context) {
          final id = item['id'] ?? '';
          final text = item['text'] ?? '';

          if (id.contains('country') && country == null) country = text;
          if ((id.contains('region') || id.contains('macroregion')) &&
              region == null)
            region = text;
          if ((id.contains('district') || id.contains('county')) &&
              district == null)
            district = text;
          if ((id.contains('locality') || id.contains('place')) &&
              village == null &&
              text != district &&
              text != region)
            village = text;
        }

        if (district == null || district.isEmpty) {
          district = village;
          village = feature['text'];
        }

        village ??= feature['text'];
        district ??= '';
        region ??= '';
        country ??= '';

        final fullAddress = [
          village,
          district,
          region,
          country,
        ].where((e) => e?.isNotEmpty == true).join(', ');

        return {
          'address': fullAddress,
          'district': district,
          'region': region,
          'country': country,
        };
      }
    }

    return {
      'address': 'Unknown address',
      'district': '',
      'region': '',
      'country': '',
    };
  }

  Future<void> _onConfirm() async {
    if (_pickedLocation == null) return;

    setState(() => _loading = true);
    try {
      final result = await _getAddressFromMapTiler(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );

      Navigator.pop(context, {
        'latitude': _pickedLocation!.latitude,
        'longitude': _pickedLocation!.longitude,
        'address': result['address'],
        'district': result['district'],
        'region': result['region'],
        'country': result['country'],
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get address: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/$query.json?key=$mapTilerApiKey',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;

      return features.map((f) {
        final coords = f['geometry']['coordinates'];
        return {'name': f['place_name'], 'lat': coords[1], 'lng': coords[0]};
      }).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = _mapStyles[_selectedMapStyle]! + mapTilerApiKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation ?? LatLng(-6.7924, 39.2083),
              initialZoom: 13.0,
              onTap: (tapPosition, latlng) => _onTap(latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.morehomes.app',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search place or address',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final query = _searchController.text;
                    if (query.isNotEmpty) {
                      final results = await _searchPlaces(query);
                      if (results.isNotEmpty) {
                        final first = results.first;
                        final lat = first['lat'];
                        final lng = first['lng'];
                        setState(() {
                          _pickedLocation = LatLng(lat, lng);
                          _mapController.move(_pickedLocation!, 15);
                          _locationTapped = false;
                        });
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          if (_pickedLocation != null && _locationTapped)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _onConfirm,
                icon: const Icon(Icons.check_circle_outline),
                label: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm This Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.layers, color: Colors.blue, size: 30),
              color: Colors.white,
              onSelected: (val) {
                setState(() {
                  _selectedMapStyle = val;
                });
              },
              itemBuilder: (context) {
                return _mapStyles.entries.map((entry) {
                  IconData iconData;
                  switch (entry.key) {
                    case 'Streets':
                      iconData = Icons.map;
                      break;
                    case 'Satellite + Labels':
                      iconData = Icons.satellite;
                      break;
                    case 'Satellite (No Labels)':
                      iconData = Icons.satellite_outlined;
                      break;
                    case 'Basic':
                      iconData = Icons.layers_clear;
                      break;
                    case 'Topographic':
                      iconData = Icons.terrain;
                      break;
                    case 'Bright':
                      iconData = Icons.wb_sunny;
                      break;
                    default:
                      iconData = Icons.map;
                  }
                  return PopupMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(iconData, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(entry.key),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
    );
  }
}
