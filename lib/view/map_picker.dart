import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:morehomesapp/theme/app_color.dart';


class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  MapLibreMapController? _controller;

  LatLng _center = const LatLng(-6.7924, 39.2083);

  Timer? _debounce;

  final TextEditingController _searchController = TextEditingController();

  String address = "";
  String district = "";
  String region = "";
  String country = "";

  bool _loadingAddress = false;


  final String styleUrl = '''
{
  "version": 8,
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": [
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors"
    }
  },
  "layers": [
    {
      "id": "osm",
      "type": "raster",
      "source": "osm"
    }
  ]
}
''';


  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    _goToCurrentLocation();
  }


  void _onCameraMove(CameraPosition position) {
    _center = position.target;
  }


  void _onCameraIdle() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(_center);
    });
  }

 
  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();

      final latLng = LatLng(pos.latitude, pos.longitude);

      _center = latLng;

      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );

      _reverseGeocode(latLng);
    } catch (_) {}
  }

 
  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _loadingAddress = true);

    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?format=jsonv2&lat=${latLng.latitude}&lon=${latLng.longitude}",
      );

      final res = await http.get(url, headers: {
        "User-Agent": "map-app"
      });

      final data = jsonDecode(res.body);
      final addr = data["address"] ?? {};

      setState(() {
        address = data["display_name"] ?? "";
        district = addr["county"] ?? addr["city"] ?? addr["suburb"] ?? "";
        region = addr["state"] ?? "";
        country = addr["country"] ?? "";
      });
    } catch (_) {}

    setState(() => _loadingAddress = false);
  }

 
  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search"
      "?format=jsonv2&q=$query",
    );

    final res = await http.get(url, headers: {
      "User-Agent": "map-app"
    });

    final data = jsonDecode(res.body);
    if (data.isEmpty) return;

    final latLng = LatLng(
      double.parse(data[0]["lat"]),
      double.parse(data[0]["lon"]),
    );

    _center = latLng;

    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 16),
    );

    _reverseGeocode(latLng);
  }


  void _confirm() {
    Navigator.pop(context, {
      "latitude": _center.latitude,
      "longitude": _center.longitude,
      "address": address,
      "district": district,
      "region": region,
      "country": country,
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        
     MapLibreMap(
      styleString: styleUrl,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 15,
      ),
      onMapCreated: _onMapCreated,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      myLocationEnabled: true,
      compassEnabled: false,
    ),

        
          const Center(
            child: Icon(
              Icons.location_pin,
              size: 60,
              color: Colors.red,
            ),
          ),

         
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black.withOpacity(0.1),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search location...",
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchPlace,
                  ),
                ),
              ),
            ),
          ),

      
          Positioned(
            right: 15,
            bottom: 170,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

      
          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.15),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingAddress)
                    const LinearProgressIndicator(),

                  Text(
                    address.isEmpty
                        ? "Move map to select location"
                        : address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _confirm,
                      child: const Text("Confirm Location",style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}