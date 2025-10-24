import 'package:flutter/material.dart';
import 'package:morehousesapp/theme/app_color.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String gender = "Male";

  @override
  Widget build(BuildContext context) {
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 Profile picture section
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      AssetImage('assets/images/profile_placeholder.png'),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    onPressed: () {
                      // handle image picker later
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            _buildTextField(label: "Full Name", hint: "Shadrack shalemu"),
            _buildTextField(label: "Username", hint: "Shalemu"),
            _buildDropdown(label: "Gender"),
            _buildTextField(label: "Phone Number", hint: "+255 767 983 236"),
            _buildTextField(label: "Email", hint: "shadrack@gmail.com"),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () {},
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Save Changes",
                style: TextStyle(fontSize: 16, 
                color: Colors.white,
                fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _buildDropdown({required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
