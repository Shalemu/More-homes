import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../providers/auth_providers.dart';
import '../theme/app_color.dart';

import 'property_list_screen.dart';
import 'owner_feedback_screen.dart';
import 'favorites_screen.dart';
import 'plans_screen.dart';
import 'profile_screen.dart';
import 'add_property_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Fetch properties for logged-in users
    Future.microtask(() {
      final token = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).accessToken;
      if (token != null) {
        Provider.of<PropertyProvider>(
          context,
          listen: false,
        ).fetchProperties(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    //  Check if user is OWNER (group ID = 3)
    bool isOwner = false;
    bool canAddProperty = false;

    if (user != null && user.groups.isNotEmpty) {
      isOwner = user.groups.contains(3);
      canAddProperty = user.groups.contains(3);
    }

    final screens = [
      const PropertyListScreen(),
      if (isOwner) const OwnerFeedbackScreen(),
      const FavoritesScreen(),
      const PlansScreen(),
      const ProfileScreen(),
    ];

    final titles = [
      'More Homes',
      if (isOwner) 'Feedback',
      'Favorites',
      'Plans',
      'Profile',
    ];

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Home',
      ),

      if (isOwner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.feedback_rounded),
          label: 'Feedback',
        ),

      const BottomNavigationBarItem(
        icon: Icon(Icons.favorite_rounded),
        label: 'Favorites',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.subscriptions), // or Icons.payment
        label: 'Plans',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: TextStyle(
            color: Colors.white,
            fontSize: isLargeScreen ? 26 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 2,
        centerTitle: true,

        actions: [
          if (canAddProperty)
            Padding(
              padding: EdgeInsets.only(right: isLargeScreen ? 20 : 10),
              child: IconButton(
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: Colors.white,
                  size: isLargeScreen ? 32 : 24,
                ),
                tooltip: 'Add Property',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadPropertyScreen(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      body: screens[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          iconSize: isLargeScreen ? 30 : 24,
          selectedFontSize: isLargeScreen ? 16 : 13,
          unselectedFontSize: isLargeScreen ? 14 : 12,
          items: navItems,
        ),
      ),
    );
  }
}
