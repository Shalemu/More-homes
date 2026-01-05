import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:morehomesapp/theme/app_color.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- CONTACT FUNCTIONS ----------------

Future<void> _openWhatsapp() async {
  final whatsappUrl = Uri.parse(
    "whatsapp://send?phone=+255767983236&text=Hello%20MoreHomes%20Team,%20I%20need%20support.",
  );

  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  } else {
    // Fallback
    final fallbackUrl = Uri.parse(
      "https://wa.me/255767983236?text=Hello%20MoreHomes%20Team,%20I%20need%20support.",
    );
    await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
  }
}


  Future<void> _sendEmail() async {
    final email = "shadrackmussa97@gmail.com";
    final mailUrl = Uri.parse("mailto:$email?subject=MoreHomes Support");

    if (await canLaunchUrl(mailUrl)) {
      await launchUrl(mailUrl);
    }
  }

  Future<void> _callPhone() async {
    final url = Uri.parse("tel:+255767983236");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // ---------------- UI COMPONENT ----------------

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: _slide,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(icon, size: 30, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- MAIN SCREEN ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Help & Support",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              "We're here to help!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Contact us anytime for support, questions or feedback.",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 25),

            // Contact Cards
            _contactCard(
              icon: FontAwesomeIcons.whatsapp,
              title: "WhatsApp Support",
              subtitle: "+255 767 983 236",
              onTap: _openWhatsapp,
            ),

            _contactCard(
              icon: Icons.email_outlined,
              title: "Email Support",
              subtitle: "shadrackmussa97@gmail.com",
              onTap: _sendEmail,
            ),
            _contactCard(
              icon: Icons.phone_in_talk,
              title: "Call Us",
              subtitle: "+255 767 983 236",
              onTap: _callPhone,
            ),

            const SizedBox(height: 30),

            // Additional MoreHomes Info Section
            SlideTransition(
              position: _slide,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "About MoreHomes App",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "MoreHomes is a smart real estate platform designed to help users find, rent, or buy their ideal homes with convenience. "
                      "We provide premium services including bookings, listings, and secure payments.",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
