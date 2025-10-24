import 'package:flutter/material.dart';
import 'package:morehousesapp/screen/profile_screen';
import 'package:morehousesapp/theme/app_color.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            "More Homes",
            style: TextStyle(fontWeight: FontWeight.bold,
            color:Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true, 
          type: BottomNavigationBarType.fixed, // keeps all labels visible
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _homeContent();
      case 1:
        return const Center(child: Text("Favorites Screen"));
      case 2:
        return const Center(child: Text("Settings Screen"));
      case 3:
       return ProfileScreen();

      default:
        return _homeContent();
    }
  }

  Widget _homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Good Morning, Luggie!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _searchBar(),
          const SizedBox(height: 20),
          _categorySection(),
          const SizedBox(height: 25),
          _popularSection(),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search for houses, apartments...",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 🔹 Improved small rounded category buttons
  Widget _categorySection() {
  final categories = ["For Sale", "For Rent", "Apartment", "House"];
  return SizedBox(
    height: 40, // 👈 Reduced height for compact look
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), 
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              categories[index],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13, 
              ),
            ),
          ),
        );
      },
    ),
  );
}


  /// 🔹 2 columns, only 4 properties + See All button
  Widget _popularSection() {
    final houses = [
      {"name": "Luxury Villa", "price": "\$450,000"},
      {"name": "Cozy Apartment", "price": "\$120,000"},
      {"name": "Modern House", "price": "\$320,000"},
      {"name": "Beach Cottage", "price": "\$250,000"},
      {"name": "Urban Loft", "price": "\$200,000"}, // 5th item (for “See All”)
    ];

    final displayHouses = houses.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Popular Properties",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all properties screen later
              },
              child: const Text(
                "See All",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayHouses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // two per row
            childAspectRatio: 0.8, // controls card height
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final house = displayHouses[index];
            return GestureDetector(
              onTap: () {
                // Navigate to property detail
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Icon(Icons.home, size: 50, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        house["name"]!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        house["price"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
