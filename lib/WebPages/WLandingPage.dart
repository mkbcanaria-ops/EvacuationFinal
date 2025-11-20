// ignore_for_file: unused_field

import 'package:evacutaion/WebPages/LoginPage.dart';
import 'package:flutter/material.dart';

class WLandingPage extends StatefulWidget {
  const WLandingPage({super.key});

  @override
  State<WLandingPage> createState() => _WLandingPageState();
}

class _WLandingPageState extends State<WLandingPage> {
  void openFullImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullImageView(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;

        // Responsive breakpoints
        bool isMobile = width < 600;
        bool isTablet = width >= 600 && width < 1000;
        bool isDesktop = width >= 1000;

        // Responsive font sizes
        double titleSize = isMobile
            ? 26
            : isTablet
            ? 32
            : 38;
        double subtitleSize = isMobile ? 16 : 18;
        double descSize = isMobile ? 14 : 16;

        // Responsive banner height
        double bannerHeight = isMobile
            ? 260
            : isTablet
            ? 380
            : 450;

        // Feature card layout
        int featureCount = isDesktop
            ? 3
            : isTablet
            ? 2
            : 1;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.5),
            elevation: 0,
            automaticallyImplyLeading: false,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/Logo2.jpg',
                      height: isMobile ? 32 : 40,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MSWDO',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D743D),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                      vertical: isMobile ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          body: SingleChildScrollView(
            child: Column(
              children: [
                // TOP BANNER
                SizedBox(
                  height: bannerHeight,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/LandingPage1.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                // TEXT CONTENT
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Santa Evacuation Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0D743D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prepared • Informed • Protected',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your safety matters. Stay updated with real-time alerts, '
                        'evacuation routes, and essential resources designed to keep '
                        'every resident informed and ready during emergencies.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: descSize,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // FEATURE CARDS
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: featureCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.1 : 1.3,
                    children: [
                      _buildFeatureCard(
                        'assets/images/Mainpic1.jpg',
                        'Evacuation Routes',
                      ),
                      _buildFeatureCard(
                        'assets/images/Mainpic2.jpg',
                        'Emergency Shelters',
                      ),
                      _buildFeatureCard(
                        'assets/images/Mainpic3.jpg',
                        'Alerts & Safety Tips',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(String imagePath, String title) {
    return GestureDetector(
      onTap: () => openFullImage(imagePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

// FULL IMAGE VIEWER
class FullImageView extends StatelessWidget {
  final String imagePath;

  const FullImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: InteractiveViewer(child: Image.asset(imagePath))),
    );
  }
}
