import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:morehomesapp/theme/app_color.dart';
import 'package:morehomesapp/view/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;
  bool _pressed = false;

  final List<Map<String, dynamic>> pages = [
    {
      "title": "Find Your Ideal Home",
      "desc": "Discover verified houses, apartments, and plots across Tanzania.",
      "icon": FontAwesomeIcons.houseChimney,
    },
    {
      "title": "Verified Owner Profiles",
      "desc": "View genuine owner details and connect with confidence and safety.",
      "icon": FontAwesomeIcons.userShield,
    },
    {
      "title": "Private Feedback",
      "desc": "Share property feedback privately — only the owner sees your comment.",
      "icon": FontAwesomeIcons.commentDots,
    },
  ];

  void goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // SKIP BUTTON
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: goToLogin,
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // PAGE VIEW
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => currentIndex = index),
                itemCount: pages.length,
                itemBuilder: (_, i) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      key: ValueKey(i),
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ICON
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: FaIcon(
                              pages[i]["icon"],
                              size: size.width * 0.17,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // TITLE
                          Text(
                            pages[i]["title"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: size.width * 0.058,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // DESCRIPTION
                          Text(
                            pages[i]["desc"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: size.width * 0.042,
                              color: Colors.grey[600],
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // DOT INDICATORS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 8,
                  width: currentIndex == i ? 28 : 10,
                  decoration: BoxDecoration(
                    color: currentIndex == i ? AppColors.primary : Colors.grey[350],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // NEXT / GET STARTED BUTTON
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: size.height * 0.04),
              child: AnimatedScale(
                scale: _pressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (currentIndex == pages.length - 1) {
                          goToLogin();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      onHighlightChanged: (pressed) {
                        setState(() => _pressed = pressed);
                      },
                      child: SizedBox(
                        height: size.height * 0.065,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              currentIndex == pages.length - 1 ? "Get Started" : "Next",
                              key: ValueKey(currentIndex),
                              style: TextStyle(
                                fontSize: size.width * 0.047,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
