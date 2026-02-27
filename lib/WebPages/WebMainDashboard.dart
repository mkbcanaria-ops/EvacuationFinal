// ignore_for_file: unnecessary_type_check, unused_local_variable

import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/WebDischargeScanner.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:evacutaion/WebPages/sidebar/Request/Request.dart';
import 'package:evacutaion/WebPages/ResidentDeployment/Web_Qr_Scanner.dart';
import 'package:evacutaion/WebPages/Web_Registration.dart';
import 'package:evacutaion/WebPages/sidebar/ViewQRcode/WebManageQr.dart';
import 'package:evacutaion/WebPages/sidebar/WebManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebMainDashboard extends StatefulWidget {
  const WebMainDashboard({super.key});

  @override
  State<WebMainDashboard> createState() => _WebMainDashboardState();
}

class _WebMainDashboardState extends State<WebMainDashboard> {
  String selectedPage = 'Dashboard';
  int _registeredResidents = 0;
  bool _isLoading = true;
  int _evacuatedResidents = 0;
  int _magsaysayCount = 0;
  int _farmersCourtCount = 0;
  int _santaRhuCount = 0;
  int _santaHighSchoolCount = 0;
  int _santaNationalHighSchoolCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredResidents();
    _fetchEvacuatedResidents();
    _fetchMagsaysayCenterCount();
    _fetchFarmersCourtCount();
    _fetchSantaRhuCount();
    _fetchSantaHighSchoolCount();
    _fetchSantaNationalHighSchoolCount();
  }

  void _showCapacityFullDialog(String centerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⚠️ Warning icon in amber
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withOpacity(0.15),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                      size: 55,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Title
                Text(
                  'Capacity Full',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  '$centerName has reached or exceeded its capacity.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 25),

                // OK Button (green accent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0D743D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchMagsaysayCenterCount() async {
    final supabase = Supabase.instance.client;

    try {
      final result = await supabase
          .from('Evacuation_A')
          .select('UID')
          .eq('Site', 'Municipal Evacuation Center, Magsaysay')
          .timeout(const Duration(seconds: 10));

      debugPrint('🔍 Raw result for Magsaysay: $result');
      debugPrint('🔍 Result type: ${result.runtimeType}');

      int count = 0;
      if (result is List) {
        count = result.length;
        debugPrint('🔍 List length (count): $count');
        if (count > 0) {
          debugPrint('🔍 First few rows: ${result.take(3)}');
        }
      } else {
        debugPrint('❌ Result is not a List: $result');
      }

      setState(() {
        _magsaysayCount = count;
      });

      // Check if capacity is full
      if (_magsaysayCount >= 250) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCapacityFullDialog("Municipal Evacuation Center - Magsaysay");
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching Magsaysay center count: $e');
      setState(() => _magsaysayCount = 0);
    }
  }

  Future<void> _fetchFarmersCourtCount() async {
    final supabase = Supabase.instance.client;

    try {
      final result = await supabase
          .from('Evacuation_A')
          .select('UID')
          .eq('Site', 'Municipal Farmers Covered Court')
          .timeout(const Duration(seconds: 10));

      debugPrint('🔍 Raw result for Farmers Court: $result');
      debugPrint('🔍 Result type: ${result.runtimeType}');

      int count = 0;
      if (result is List) {
        count = result.length;
        debugPrint('🔍 List length (count): $count');
        if (count > 0) {
          debugPrint('🔍 First few rows: ${result.take(3)}');
        }
      } else {
        debugPrint('❌ Result is not a List: $result');
      }

      setState(() {
        _farmersCourtCount = count;
      });

      // Check if capacity is full
      if (_farmersCourtCount >= 200) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCapacityFullDialog("Municipal Farmer’s Covered Court");
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching Farmers Court count: $e');
      setState(() => _farmersCourtCount = 0);
    }
  }

  Future<void> _fetchSantaRhuCount() async {
    final supabase = Supabase.instance.client;

    try {
      final result = await supabase
          .from('Evacuation_B')
          .select('UID')
          .timeout(const Duration(seconds: 10));

      debugPrint('🔍 Raw result for Santa RHU (Evacuation_B): $result');
      debugPrint('🔍 Result type: ${result.runtimeType}');

      int count = 0;
      if (result is List) {
        count = result.length;
        debugPrint('🔍 List length (count): $count');
        if (count > 0) {
          debugPrint('🔍 First few rows: ${result.take(3)}');
        }
      } else {
        debugPrint('❌ Result is not a List: $result');
      }

      setState(() {
        _santaRhuCount = count;
      });

      // Check if capacity is full
      if (_santaRhuCount >= 150) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCapacityFullDialog("Santa RHU");
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching Santa RHU count: $e');
      setState(() => _santaRhuCount = 0);
    }
  }

  Future<void> _fetchSantaHighSchoolCount() async {
    final supabase = Supabase.instance.client;

    try {
      final result = await supabase
          .from('Evacuation_A')
          .select('UID')
          .eq('Site', 'Santa High School')
          .timeout(const Duration(seconds: 10));

      debugPrint('🔍 Raw result for Santa High School: $result');
      debugPrint('🔍 Result type: ${result.runtimeType}');

      int count = 0;
      if (result is List) {
        count = result.length;
        debugPrint('🔍 List length (count): $count');
        if (count > 0) {
          debugPrint('🔍 First few rows: ${result.take(3)}');
        }
      } else {
        debugPrint('❌ Result is not a List: $result');
      }

      setState(() {
        _santaHighSchoolCount = count;
      });

      // Check if capacity is full
      if (_santaHighSchoolCount >= 120) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCapacityFullDialog("Santa High School (Supplemental)");
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching Santa High School count: $e');
      setState(() => _santaHighSchoolCount = 0);
    }
  }

  Future<void> _fetchSantaNationalHighSchoolCount() async {
    final supabase = Supabase.instance.client;

    try {
      final result = await supabase
          .from('Evacuation_A')
          .select('UID')
          .eq('Site', 'Santa National High School')
          .timeout(const Duration(seconds: 10));

      debugPrint('🔍 Raw result for Santa National High School: $result');
      debugPrint('🔍 Result type: ${result.runtimeType}');

      int count = 0;
      if (result is List) {
        count = result.length;
        debugPrint('🔍 List length (count): $count');
        if (count > 0) {
          debugPrint('🔍 First few rows: ${result.take(3)}');
        }
      } else {
        debugPrint('❌ Result is not a List: $result');
      }

      setState(() {
        _santaNationalHighSchoolCount = count;
      });

      // Check if capacity is full
      if (_santaNationalHighSchoolCount >= 100) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCapacityFullDialog("Santa National High School (Supplemental)");
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching Santa National High School count: $e');
      setState(() => _santaNationalHighSchoolCount = 0);
    }
  }

  Future<void> _fetchRegisteredResidents() async {
    final supabase = Supabase.instance.client;

    setState(() => _isLoading = true);

    try {
      final dynamic result = await supabase
          .from('Registration_Table')
          .select('Registration_ID')
          .timeout(const Duration(seconds: 10));

      int count = 0;

      if (result == null) {
        count = 0;
      } else if (result is List) {
        count = result.length;
      } else if (result is Map) {
        final data = result['data'];
        if (data is List) {
          count = data.length;
        } else if (result.containsKey('count') && result['count'] is int) {
          count = result['count'] as int;
        }
      } else if (result is Iterable) {
        count = result.length;
      } else {
        try {
          final asList = result as List<dynamic>;
          count = asList.length;
        } catch (_) {
          count = 0;
        }
      }

      setState(() {
        _registeredResidents = count;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching registered residents: $e');
      setState(() {
        _registeredResidents = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEvacuatedResidents() async {
    final supabase = Supabase.instance.client;

    setState(() => _isLoading = true);

    try {
      final evacAResult = await supabase
          .from('Evacuation_A')
          .select('FamilyMember_ID')
          .timeout(const Duration(seconds: 10));

      final evacBResult = await supabase
          .from('Evacuation_B')
          .select('FamilyMember_ID')
          .timeout(const Duration(seconds: 10));

      int _safeCount(dynamic result) {
        if (result == null) return 0;
        if (result is List) return result.length;
        if (result is Map) {
          final data = result['data'];
          if (data is List) return data.length;
          if (result.containsKey('count') && result['count'] is int) {
            return result['count'] as int;
          }
        }
        if (result is Iterable) return result.length;
        try {
          return (result as List<dynamic>).length;
        } catch (_) {
          return 0;
        }
      }

      final countA = _safeCount(evacAResult);
      final countB = _safeCount(evacBResult);

      setState(() {
        _evacuatedResidents = countA + countB;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching evacuated residents: $e');
      setState(() {
        _evacuatedResidents = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _fetchRegisteredResidents();
    await _fetchEvacuatedResidents();

    await _fetchFarmersCourtCount();
    await _fetchSantaRhuCount();
    await _fetchSantaHighSchoolCount();
    await _fetchSantaNationalHighSchoolCount();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    // ...existing code...
    // More responsive grid sizing: calculate columns based on available width
    // and compute childAspectRatio from a desired card height that adapts to breakpoints.
    int crossAxisCount = (width / 320).floor();
    if (crossAxisCount < 1) crossAxisCount = 1;
    if (crossAxisCount > 6) crossAxisCount = 6;

    // Choose a target card height depending on screen size (taller on large screens)
    double targetCardHeight;
    if (width >= 1800) {
      targetCardHeight = 220;
    } else if (width >= 1400) {
      targetCardHeight = 200;
    } else if (width >= 1000) {
      targetCardHeight = 180;
    } else if (width >= 800) {
      targetCardHeight = 170;
    } else if (width >= 600) {
      targetCardHeight = 160;
    } else {
      targetCardHeight = 150;
    }

    // compute childAspectRatio so card height ~ targetCardHeight
    final double columnWidth =
        (width - (crossAxisCount - 1) * 16) / crossAxisCount;
    double childAspectRatio = columnWidth / targetCardHeight;

    // spacing scales a bit with width
    double crossAxisSpacing = width >= 1400
        ? 20
        : width >= 1000
        ? 16
        : 12;
    double mainAxisSpacing = width >= 1400
        ? 20
        : width >= 1000
        ? 16
        : 12;

    // Responsive padding: more fluid by using a percentage for large screens
    EdgeInsets bodyPadding;
    if (width > 1600) {
      bodyPadding = EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: 28,
      );
    } else if (width > 1200) {
      bodyPadding = const EdgeInsets.all(32);
    } else if (width > 1000) {
      bodyPadding = const EdgeInsets.all(28);
    } else if (width > 800) {
      bodyPadding = const EdgeInsets.all(24);
    } else if (width > 600) {
      bodyPadding = const EdgeInsets.all(20);
    } else {
      bodyPadding = const EdgeInsets.all(16);
    }
    // ...existing code...
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true,
        title: Text(
          'MSWDO Dashboard',
          style: GoogleFonts.poppins(
            fontSize: width > 600 ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      // Main Body
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: bodyPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard Overview",
                style: GoogleFonts.poppins(
                  fontSize: width > 600 ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),

              // ✅ Evacuation Center Grid
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _evacuationCenterCard(
                    "Registered Residents",
                    _registeredResidents,
                    null,
                  ),
                  _evacuationCenterCard(
                    "Evacuated Residents",
                    _isLoading ? 0 : _evacuatedResidents,
                    null,
                  ),
                  _evacuationCenterCard(
                    "Municipal Evacuation Center, Magsaysay",
                    _magsaysayCount,
                    250,
                  ),

                  _evacuationCenterCard(
                    "Municipal Farmer’s Covered Court",
                    _farmersCourtCount,
                    180,
                  ),
                  _evacuationCenterCard("Santa RHU", _santaRhuCount, 150),
                  _evacuationCenterCard(
                    "Santa High School (Supplemental)",
                    _santaHighSchoolCount,
                    120,
                  ),
                  _evacuationCenterCard(
                    "Santa National High School (Supplemental)",
                    _santaNationalHighSchoolCount,
                    110,
                  ),
                ],
              ),

              const SizedBox(height: 28),
              const Divider(thickness: 1.2),
              const SizedBox(height: 16),

              // ⚡ Quick Access
              Text(
                "Quick Access",
                style: GoogleFonts.poppins(
                  fontSize: width > 600 ? 20 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _actionCard(
                    title: "QR Scanning",
                    subtitle: "Scan residents’ QR codes quickly",
                    icon: Icons.qr_code_scanner,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WebScanQrPage(),
                        ),
                      );
                    },
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  _actionCard(
                    title: "Applications",
                    subtitle: "View and manage resident applications",
                    icon: Icons.article_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WebRegistrationPage(),
                        ),
                      );
                    },
                    fullWidth: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧭 Drawer
  Widget _buildAdminDrawer() {
    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0D743D)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Drawer items
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

              const Divider(),

              _buildDrawerItem('Reports', Icons.analytics_outlined),
              _buildDrawerItem('Requests', Icons.pending_actions_outlined),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Drawer Item Widget with if-else navigation logic
  Widget _buildDrawerItem(String title, IconData icon) {
    final bool isSelected = selectedPage == title;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF0D743D) : Colors.black54,
      ),
      tileColor: isSelected ? const Color(0xFF0D743D).withOpacity(0.1) : null,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFF0D743D) : Colors.black,
        ),
      ),
      onTap: () {
        setState(() {
          selectedPage = title;
        });

        Navigator.pop(context);

        // 🧭 Navigation logic
        if (title == 'Dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WebMainDashboard()),
          );
        } else if (title == 'Resident Management') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebManageResidentsPage(),
            ),
          );
        } else if (title == 'QR Code Management') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebDisplayAllQrPage(),
            ),
          );
        } else if (title == 'Discharge Residents') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebDischargeDashboardPage(),
            ),
          );
        } else if (title == 'Reports') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WebReportsPage()),
          );
        } else if (title == 'Requests') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WebRequestsPage()),
          );
        }
      },
    );
  }

  // 🏠 Evacuation Center Card
  Widget _evacuationCenterCard(String title, int current, int? capacity) {
    final hasCapacity = capacity != null;
    final remaining = hasCapacity ? (capacity - current) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          top: BorderSide(color: Color(0xFF0D743D), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$current",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D743D),
            ),
          ),
          if (hasCapacity) ...[
            const SizedBox(height: 4),
            Text(
              "Capacity: $capacity",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
            ),
            Text(
              "Remaining: $remaining",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  // ⚡ Quick Access Card
  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 110,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D743D), Color(0xFF1D9A58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Color(0xFF0D743D), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
