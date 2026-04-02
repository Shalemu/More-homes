import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:morehomesapp/models/property_model.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:morehomesapp/providers/property_provider.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:provider/provider.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();

  List<String> existingImages = [];
  List<File> newImages = [];

  bool isSaving = false;

final String _baseUrl = 'https://morehomes.co.tz';
String fixImageUrl(String url) {
  if (url.startsWith('http')) return url;
  return '$_baseUrl/$url'.replaceAll('//', '/');
}

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.property.name;
    priceCtrl.text = widget.property.price.toString();
    addressCtrl.text = widget.property.address;
    descriptionCtrl.text = widget.property.description;

    existingImages = List.from(widget.property.images);
  }

  /// Convert image URL properly
 

  Future<void> pickNewImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => newImages.add(File(picked.path)));
    }
  }
 Future<void> saveChanges() async {
  setState(() => isSaving = true);

  final auth = Provider.of<AuthProvider>(context, listen: false);
  final provider = Provider.of<PropertyProvider>(context, listen: false);
  final token = auth.accessToken;

  if (token == null) {
    setState(() => isSaving = false);
    return;
  }

  final updatedProperty = widget.property.copyWith(
    name: nameCtrl.text.trim(),
    price: priceCtrl.text.trim(),
    address: addressCtrl.text.trim(),
    description: descriptionCtrl.text.trim(),
  );

  // ✅ Send all images as Base64
  final success = await provider.updateProperty(
    token: token,
    property: updatedProperty,
    newImages: newImages,
    existingImages: existingImages,
  );

  setState(() => isSaving = false);

  if (success) {
    _showSuccessDialog();
  } else {
    _showErrorDialog();
  }
}

  // ---------------------------- UI -------------------------------- //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Edit Property", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Property Images"),
                    const SizedBox(height: 14),
                    _imageGrid(),
                    const SizedBox(height: 24),

                    _sectionTitle("Property Details"),
                    const SizedBox(height: 14),

                    _premiumInput(nameCtrl, "Property Name"),
                    _premiumInput(priceCtrl, "Price (Tsh)"),
                    _premiumInput(addressCtrl, "Address"),
                    _premiumInput(descriptionCtrl, "Description", maxLines: 4),

                    const SizedBox(height: 28),
                    _premiumSaveButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------- Components --------------------------- //

  Widget _imageGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = (constraints.maxWidth - 30) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Existing images
            for (int i = 0; i < existingImages.length; i++)
              _imageBox(
                size: size,
                image: Image.network(fixImageUrl(existingImages[i]), fit: BoxFit.cover),
                onDelete: () => setState(() => existingImages.removeAt(i)),
              ),

            // New images
            for (int i = 0; i < newImages.length; i++)
              _imageBox(
                size: size,
                image: Image.file(newImages[i], fit: BoxFit.cover),
                onDelete: () => setState(() => newImages.removeAt(i)),
              ),

            // Add button
            GestureDetector(
              onTap: pickNewImage,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_a_photo, size: 32, color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _imageBox({
    required Widget image,
    required double size,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.grey[100],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: image),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        )
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _premiumInput(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _premiumSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Save Changes",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

//  Dialogs 
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 70),
                const SizedBox(height: 16),
                const Text(
                  "Property Updated!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your changes have been saved successfully.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context, true); // go back and refresh list
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Failed"),
          content: const Text("Please try again later."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
