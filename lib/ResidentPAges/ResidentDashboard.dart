import 'package:evacutaion/ResidentPAges/ResidentRegistration.dart';
import 'package:evacutaion/ResidentPAges/UpdateApplication.dart';
import 'package:evacutaion/WebPages/sidebar/ViewQrCode.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentDashboardPage extends StatefulWidget {
  const ResidentDashboardPage({super.key});

  @override
  State<ResidentDashboardPage> createState() => _ResidentDashboardPageState();
}

class _ResidentDashboardPageState extends State<ResidentDashboardPage> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('Users')
          .select('First_Name')
          .eq('UID', user.id)
          .maybeSingle();

      setState(() {
        userName = response != null ? response['First_Name'] : "Resident";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const greenIconColor = Color(0xFF0D743D);

    // Adaptive paddings
    final horizontalPadding = screenWidth * 0.05; // 5% of width
    final verticalPadding = screenHeight * 0.03; // 3% of height

    // Adaptive font sizes
    double titleFont = screenWidth > 1000
        ? 26
        : screenWidth > 600
        ? 22
        : 18;
    double subtitleFont = screenWidth > 1000
        ? 24
        : screenWidth > 600
        ? 20
        : 16;
    double bodyFont = screenWidth > 1000
        ? 16
        : screenWidth > 600
        ? 14
        : 12;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset('assets/images/Mainpic1.jpg', fit: BoxFit.cover),
          ),

          // Semi-transparent container
          Positioned(
            top: verticalPadding,
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: verticalPadding,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo + Title
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/Logo2.jpg',
                            width: screenWidth > 600 ? 70 : 50,
                            height: screenWidth > 600 ? 70 : 50,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            "MSWDO",
                            style: TextStyle(
                              fontSize: titleFont,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Welcome
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Text(
                        "👋 Welcome ${userName ?? ''} to Santa Evacuation Portal",
                        style: TextStyle(
                          fontSize: bodyFont,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    Text(
                      "Manage Evacuation Services Easily",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: subtitleFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "Fill your applications, request or view your QR code, "
                      "and stay updated with notifications.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: bodyFont,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Dashboard Actions (responsive grid)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 1000) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth > 600) {
                          crossAxisCount = 2;
                        }

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: screenWidth * 0.02,
                          mainAxisSpacing: screenHeight * 0.02,
                          childAspectRatio: 1.1,
                          children: [
                            _actionCard(
                              icon: Icons.app_registration,
                              title: "Fill Application",
                              subtitle: "Submit a new evacuation application",
                              iconColor: greenIconColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ResidentRegistrationPage(),
                                  ),
                                );
                              },
                            ),
                            _actionCard(
                              icon: Icons.qr_code,
                              title: "View QR Code",
                              subtitle: "Access your unique QR code",
                              iconColor: greenIconColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ViewQrCodePage(),
                                  ),
                                );
                              },
                            ),
                            _actionCard(
                              icon: Icons.qr_code_scanner,
                              title: "Request QR Code",
                              subtitle: "Request a new QR code",
                              iconColor: greenIconColor,
                              onTap: () {},
                            ),
                            _actionCard(
                              icon: Icons.update,
                              title: "Update Application",
                              subtitle: "Edit or update existing applications",
                              iconColor: greenIconColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const UpdateRegistrationPage(
                                          uid: 'UID',
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
