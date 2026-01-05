import 'package:flutter/material.dart';
import 'package:morehomesapp/theme/app_color.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("About MoreHomes", style: TextStyle(color:Colors.white),),
        backgroundColor: AppColors.primary,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "MoreHomes App",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Smart Real Estate Platform for Renting, Buying, and Listing Properties",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // SECTION: What We Do
            _sectionTitle("What is MoreHomes?"),
            _sectionText(
              "MoreHomes is a modern real estate application that helps users "
              "find houses, apartments, plots, and commercial properties for rent or sale. "
              "Property owners can upload their listings, and customers can view, search, "
              "book tours, make payments, and contact owners directly."
            ),

            _sectionTitle("Key Features"),
            _sectionText(
              "• Search properties for rent or sale\n"
              "• View detailed property information\n"
              "• Contact owners via call, message, or WhatsApp\n"
              "• Book tours for properties\n"
              "• Property owners can upload listings\n"
              "• Secured payment system for subscriptions\n"
              "• Premium clean UI experience"
            ),

            _sectionTitle("Who is it for?"),
            _sectionText(
              "• Home seekers looking to rent or buy\n"
              "• Property owners wanting to list properties\n"
              "• Real estate agencies managing multiple listings\n"
              "• Anyone searching for a home with convenience"
            ),

            _sectionTitle("Our Mission"),
            _sectionText(
              "To simplify the real estate process by connecting buyers, renters, "
              "and property owners through a reliable, smart, and user-friendly platform."
            ),

            _sectionTitle("Developer Information"),
            _sectionText(
              "MoreHomes is developed by a passionate team focused on delivering a smooth "
              "and innovative house-searching experience with modern technology."
            ),

            const SizedBox(height: 20),

            // Version
            Center(
              child: Text(
                "App Version 1.0.0",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }
}
