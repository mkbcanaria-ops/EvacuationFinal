import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Adaptive sizes (reduced)
    double logoSize = isPortrait ? screenWidth * 0.11 : screenHeight * 0.11;
    double titleFontSize = isPortrait
        ? screenWidth * 0.035
        : screenHeight * 0.035;
    double buttonFontSize = isPortrait
        ? screenWidth * 0.032
        : screenHeight * 0.032;
    double buttonPaddingH = isPortrait
        ? screenWidth * 0.035
        : screenHeight * 0.035;
    double buttonPaddingV = isPortrait
        ? screenHeight * 0.012
        : screenWidth * 0.012;
    double headingFontSize = isPortrait
        ? screenWidth * 0.045
        : screenHeight * 0.045;
    double iconSize = isPortrait ? screenWidth * 0.065 : screenHeight * 0.065;
    double bottomPadding = isPortrait
        ? screenHeight * 0.08
        : screenHeight * 0.05;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black26,
        titleSpacing: 10,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Logo2.jpg',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'MSWDO',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize, // Smaller
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ONE STATIC BACKGROUND IMAGE
          Image.asset('assets/images/Mainpic1.jpg', fit: BoxFit.cover),

          // Dark overlay
          Container(color: Colors.black.withOpacity(0.45)),

          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_alt,
                          color: Colors.white,
                          size: iconSize, // smaller
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Welcome to MSWDO 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: headingFontSize, // smaller
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // IMPROVED ADVOCACY MESSAGE (smaller)
                        Text(
                          "Building stronger communities together 💛",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: headingFontSize * 0.75, // reduced more
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom button
                Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C6E47),

                          // Smaller size
                          padding: EdgeInsets.symmetric(
                            horizontal: buttonPaddingH * 0.9,
                            vertical: buttonPaddingV * 0.9,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainDashboard(),
                            ),
                          );
                        },
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: buttonFontSize, // smaller
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
