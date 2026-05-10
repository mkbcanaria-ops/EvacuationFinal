// ignore_for_file: use_build_context_synchronously

import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:evacutaion/App/Sidebar/AppManageResidents/ManageResidents.dart';
import 'package:evacutaion/App/Sidebar/AppViewQR/ManageQR.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/DischargeResidentScanner.dart';
import 'package:evacutaion/App/Sidebar/Request/AppRequest.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppReportsPage extends StatefulWidget {
  const AppReportsPage({super.key});

  @override
  State<AppReportsPage> createState() => _AppReportsPageState();
}

class _AppReportsPageState extends State<AppReportsPage> {
  String selectedPage = "Reports";

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

  Widget _buildAdminDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evacuation Management System',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.90),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    _buildDrawerItem('Dashboard', Icons.dashboard_outlined),
                    _buildDrawerItem(
                      'Resident Management',
                      Icons.people_alt_outlined,
                    ),
                    _buildDrawerItem('QR Code Management', Icons.qr_code_2),
                    _buildDrawerItem(
                      'Discharge Residents',
                      Icons.exit_to_app_rounded,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Divider(color: Colors.grey.shade300),
                    ),
                    _buildDrawerItem('Reports', Icons.analytics_outlined),
                    _buildDrawerItem(
                      'Requests',
                      Icons.pending_actions_outlined,
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

  Widget _buildDrawerItem(String title, IconData icon) {
    final bool isSelected = selectedPage == title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? primaryGreen.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(
            icon,
            color: isSelected ? primaryGreen : Colors.black54,
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isSelected ? primaryGreen : Colors.black87,
            ),
          ),
          onTap: () {
            setState(() {
              selectedPage = title;
            });

            Navigator.pop(context);

            if (title == 'Dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainDashboard()),
              );
            } else if (title == 'Resident Management') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageResidentsPage(),
                ),
              );
            } else if (title == 'QR Code Management') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisplayAllQrPage(),
                ),
              );
            } else if (title == 'Discharge Residents') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DischargeScanQrPage(),
                ),
              );
            } else if (title == 'Reports') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AppReportsPage()),
              );
            } else if (title == 'Requests') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppRequestsPage(),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 820;

    return Scaffold(
      backgroundColor: softBg,
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Reports",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 32 : 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: _buildWebOnlyBanner(isWide),
          ),
        ),
      ),
    );
  }

  Widget _buildWebOnlyBanner(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 24,
        vertical: isWide ? 42 : 30,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [primaryGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isWide ? 90 : 78,
            height: isWide ? 90 : 78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(
              Icons.language_rounded,
              size: isWide ? 44 : 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reports Only Work on Website',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWide ? 28 : 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please use the web version of the system to access the Reports module.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWide ? 15 : 14,
              height: 1.6,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }
}
