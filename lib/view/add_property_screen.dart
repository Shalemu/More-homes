import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:morehomesapp/models/property_model.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/services/property_services.dart';
import 'package:morehomesapp/theme/app_color.dart';

import 'map_picker.dart';

class UploadPropertyScreen extends StatefulWidget {
  const UploadPropertyScreen({Key? key}) : super(key: key);

  @override
  State<UploadPropertyScreen> createState() => _UploadPropertyScreenState();
}

class _UploadPropertyScreenState extends State<UploadPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _totalPrice = TextEditingController();
  double _extraCost = 0.0;
  double _finalTotalCost = 0.0;

  final _description = TextEditingController();
  final _address = TextEditingController();

  // Dropdowns
  String _selectedType = 'House';
  String _selectedCategory = 'Rent';

  // Map details
  double? _lat;
  double? _lng;
  String? _region;
  String? _district;

  // ---------------- PROPERTY COSTS (RENT ONLY) ----------------

  // Available cost types
  final List<String> _availableCosts = [
    'Ulinzi',
    'Maintenance',
    'Cleaning',
    'Other',
  ];

  // Selected costs with amount
  final Map<String, TextEditingController> _costControllers = {};



  // Types
  final List<String> _types = [
    'House',
    'Apartment',
    'Room',
    'Land',
    'Office',
    'Construction',
  ];

  final List<String> _categories = ['Rent', 'Sale', 'Short Stay'];

  // Facilities
  final List<Map<String, dynamic>> _facilities = [
    {'name': 'Parking', 'icon': Icons.local_parking},
    {'name': 'Swimming Pool', 'icon': Icons.pool},
    {'name': 'Garden', 'icon': Icons.park},
    {'name': 'Security', 'icon': Icons.shield_outlined},
    {'name': 'Gym', 'icon': Icons.fitness_center},
    {'name': 'Internet', 'icon': Icons.wifi},
    {'name': 'Air Conditioning', 'icon': Icons.ac_unit},
    {'name': 'Furnished', 'icon': Icons.chair_outlined},
  ];
  final List<String> _selectedFacilities = [];

  // Image handling
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final int maxImages = 5;

  bool _loading = false;

  void calculateTotalCost() {
    double extras = 0.0;

    for (var controller in _costControllers.values) {
      final value = double.tryParse(controller.text) ?? 0;
      extras += value;
    }

    final price = double.tryParse(_price.text) ?? 0;

    setState(() {
      _extraCost = extras;
      _finalTotalCost = price + extras;
    });
  }

  void toggleCost(String cost, bool selected) {
    setState(() {
      if (selected) {
        _costControllers[cost] = TextEditingController();
      } else {
        _costControllers[cost]?.dispose();
        _costControllers.remove(cost);
        calculateTotalCost();
      }
    });
  }

  // ---------------- SELECT IMAGES ----------------

  Future<void> pickFromGallery() async {
    if (_selectedImages.length >= maxImages) {
      showMessage("Maximum $maxImages images allowed.");
      return;
    }

    final images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
    );

    final remaining = maxImages - _selectedImages.length;
    final addImages = images.length <= remaining
        ? images
        : images.sublist(0, remaining);

    setState(() => _selectedImages.addAll(addImages));
  }

  Future<void> takePhoto() async {
    if (_selectedImages.length >= maxImages) {
      showMessage("Maximum $maxImages images allowed.");
      return;
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() => _selectedImages.add(photo));
    }
  }

  void removeImage(XFile img) {
    setState(() => _selectedImages.remove(img));
  }

  // ---------------- MAP PICKER ----------------
  Future<void> openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _lat = result['latitude'];
        _lng = result['longitude'];
        _region = result['region'];
        _district = result['district'];
        _address.text = result['address'];
      });
    }
  }

Future<void> uploadProperty() async {
  if (_loading) return;
  if (!_formKey.currentState!.validate()) return;

  // ---------------- BASIC VALIDATIONS ----------------
  if (_selectedImages.isEmpty) {
    showMessage("Please add at least one image.");
    return;
  }

  if (_lat == null || _lng == null) {
    showMessage("Please select property location.");
    return;
  }

  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (auth.accessToken == null) {
    showMessage("Please login first.");
    return;
  }

  // ---------------- RENT COST VALIDATION ----------------
  if (_selectedCategory == 'Rent') {
    for (var entry in _costControllers.entries) {
      if (entry.value.text.trim().isEmpty) {
        showMessage("Enter amount for ${entry.key}");
        return;
      }
    }
  }

  setState(() => _loading = true);

  try {
    // ---------------- IMAGES TO BASE64 ----------------
    final List<String> base64Imgs = [];
    for (var img in _selectedImages) {
      final bytes = await File(img.path).readAsBytes();
      base64Imgs.add(base64Encode(bytes));
    }

    // ---------------- PROPERTY COSTS ----------------
    final List<Map<String, String>> propertyCosts =
        _selectedCategory == 'Rent'
            ? _costControllers.entries.map((e) {
                return {
                  "name": e.key,
                  "amount": e.value.text.trim(),
                };
              }).toList()
            : [];

    // ---------------- CALCULATE TOTAL COST ----------------
    double extraCost = propertyCosts.fold(0.0, (sum, cost) {
      return sum + (double.tryParse(cost['amount'] ?? '0') ?? 0);
    });
    final double totalCost = extraCost + (double.tryParse(_price.text.trim()) ?? 0);

    // ---------------- BUILD PROPERTY MODEL ----------------
    final property = PropertyModel(
      uuid: "",
      name: _name.text.trim(),
      type: _selectedType,
      address: _address.text.trim(),
      price: _price.text.trim(),
      totalPrice: _totalPrice.text.trim().isEmpty
          ? _price.text.trim()
          : _totalPrice.text.trim(),
      maintenance: "1.00",
      thumbnail: null,
      isBooked: false,
      description: _description.text.trim(),
      latitude: _lat!.toStringAsFixed(6),
      longitude: _lng!.toStringAsFixed(6),
      region: _region ?? "",
      district: _district ?? "",
      category: _selectedCategory,
      uploaderName: "",
      uploaderPhone: "",
      uploaderRole: "",
      uploaderId: null,
      uploaderImageUrl: null,
      images: [],
      base64Images: base64Imgs,
      facilities: _selectedFacilities,
      propertyCosts: propertyCosts,
      totalCost: totalCost,
      createdAt: DateTime.now(),
    );

    // ---------------- PRINT FULL PAYLOAD ----------------
    debugPrint(" PROPERTY PAYLOAD ");
    debugPrint(jsonEncode(property.toJson(forUpload: true)));

    // ---------------- API CALL ----------------
    final success = await PropertyService.uploadProperty(
      property.toJson(forUpload: true),
      auth.accessToken!,
    );

    if (success) {
      // ---------------- PRINT EXTRA COSTS ----------------
      if (propertyCosts.isNotEmpty) {
        debugPrint(" Extra Costs ");
        for (var cost in propertyCosts) {
          debugPrint("${cost['name']}: TZS ${cost['amount']}");
        }
      }

      debugPrint("TOTAL COST ");
      debugPrint("Total Cost: TZS ${totalCost.toStringAsFixed(0)}");

      showMessage(
        "Property uploaded successfully!",
        color: AppColors.primary,
      );
      Navigator.pop(context);
    } else {
      showMessage("Upload failed. Try again.");
    }
  } catch (e) {
    showMessage("Error: $e");
    debugPrint("Error during uploadProperty: $e");
  }

  setState(() => _loading = false);
}


  // ---------------- IMAGE GRID ----------------
  Widget buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedImages.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        if (i == _selectedImages.length) {
          return GestureDetector(
            onTap: pickFromGallery,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
                color: Colors.grey.shade200,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, size: 30),
            ),
          );
        }

        final img = _selectedImages[i];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(img.path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: () => removeImage(img),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------- TOAST ----------------
  void showMessage(String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Property"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- Section: Images ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Property Images",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: takePhoto,
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                        IconButton(
                          onPressed: pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
                buildImageGrid(),
                const SizedBox(height: 20),

                // ---------------- Name ----------------
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: "Property Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Enter property name" : null,
                ),
                const SizedBox(height: 16),

                // ---------------- Dropdowns ----------------
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        value: _selectedType,
                        items: _types
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                        decoration: const InputDecoration(
                          labelText: "Type",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: _categories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---------------- Prices ----------------
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Price",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Enter price" : null,
                  onChanged: (_) => calculateTotalCost(),
                ),

                // const SizedBox(height: 16),

                // TextFormField(
                //   controller: _totalPrice,
                //   keyboardType: TextInputType.number,
                //   decoration: const InputDecoration(
                //     labelText: "Total Price (Optional)",
                //     border: OutlineInputBorder(),
                //   ),
                // ),
                const SizedBox(height: 20),

                // ---------------- Location ----------------
                const Text(
                  "Location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: openMap,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                      color: Colors.grey.shade200,
                    ),
                    child: const Center(
                      child: Icon(Icons.map, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _address,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Pick location first" : null,
                ),
                const SizedBox(height: 20),

                // ---------------- Description ----------------
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Enter description" : null,
                ),
                const SizedBox(height: 20),

                // ---------------- PROPERTY COSTS (RENT ONLY) ----------------
                if (_selectedCategory == 'Rent') ...[
                  const Text(
                    "Property Costs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    children: _availableCosts.map((cost) {
                      final selected = _costControllers.containsKey(cost);
                      return FilterChip(
                        label: Text(cost),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                        onSelected: (value) => toggleCost(cost, value),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Amount inputs
                  Column(
                    children: _costControllers.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "${entry.key} Amount",
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => calculateTotalCost(),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // Total Cost Display
                  // ---------------- COST SUMMARY ----------------
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Extra Costs"),
                            Text(
                              "TZS ${_extraCost.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "FINAL TOTAL",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "TZS ${_finalTotalCost.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],

                // ---------------- Facilities ----------------
                const Text(
                  "Facilities",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _facilities.map((f) {
                    final selected = _selectedFacilities.contains(f['name']);
                    return FilterChip(
                      label: Text(f['name']),
                      avatar: Icon(
                        f['icon'],
                        size: 18,
                        color: selected ? Colors.white : Colors.grey,
                      ),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedFacilities.add(f['name']);
                          } else {
                            _selectedFacilities.remove(f['name']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // ---------------- Submit ----------------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : uploadProperty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Upload Property",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
