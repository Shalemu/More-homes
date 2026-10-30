import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:morehomesapp/providers/auth_providers.dart';
import 'package:provider/provider.dart';
import '../theme/app_color.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  String gender = "Male";

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    firstNameController = TextEditingController(text: user?.firstName ?? '');
    lastNameController = TextEditingController(text: user?.lastName ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(ctx);
                await _selectImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _selectImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile picture
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (authProvider.user?.profilePictureUrl != null
                                ? NetworkImage(
                                    authProvider.user!.profilePictureUrl!,
                                  )
                                : const AssetImage(
                                    'assets/images/profile_placeholder.png',
                                  )),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildTextField("First Name", firstNameController),
                  _buildTextField("Last Name", lastNameController),
                  _buildDropdown(),
                  _buildTextField("Phone Number", phoneController),
                  _buildTextField("Email", emailController),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    onPressed: _saving
                        ? null
                        : () async {
                            if (authProvider.user == null) return;

                            setState(() => _saving = true);

                            final result = await authProvider.updateProfile(
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim(),
                              profileImage: _selectedImage,
                            );

                            if (!context.mounted) return;
                            setState(() => _saving = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['success'] == true
                                      ? 'Profile updated successfully'
                                      : (result['message'] ??
                                          'Failed to update profile'),
                                ),
                              ),
                            );

                            if (result['success'] == true) {
                              Navigator.pop(context);
                            }
                          },
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _saving ? "Saving..." : "Save Changes",
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gender",
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: gender,
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
            ],
            onChanged: (value) => setState(() => gender = value!),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
