// ignore_for_file: unnecessary_type_check

import 'package:evacutaion/App/Discharge%20Residents/DischargeResidentScanner.dart';
import 'package:evacutaion/App/Qr_Scanner.dart';
import 'package:evacutaion/App/RegistrationPage.dart';
import 'package:evacutaion/App/Sidebar/ManageQR.dart';
import 'package:evacutaion/App/Sidebar/ManageResidents.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:evacutaion/WebPages/sidebar/Request/Request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
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
          .select(
            'UID',
          ) // Select any column to get the rows; we'll count the length
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
    await _fetchMagsaysayCenterCount();
    await _fetchFarmersCourtCount();
    await _fetchSantaRhuCount();
    await _fetchSantaHighSchoolCount();
    await _fetchSantaNationalHighSchoolCount();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final width = size.width;

    int crossAxisCount = 2;
    double childAspectRatio = 1.1;
    if (orientation == Orientation.landscape) {
      crossAxisCount = width > 900 ? 5 : (width > 600 ? 4 : 3);
      childAspectRatio = 1.0;
    } else {
      crossAxisCount = width > 600 ? 3 : 2;
      childAspectRatio = width > 600 ? 1.2 : 1.1;
    }

    double titleFontSize = (orientation == Orientation.landscape || width > 600)
        ? 20
        : 18;
    double sectionTitleFontSize =
        (orientation == Orientation.landscape || width > 600) ? 17 : 15;
    double cardTitleFontSize =
        (orientation == Orientation.landscape || width > 600) ? 12 : 11;
    double cardNumberFontSize =
        (orientation == Orientation.landscape || width > 600) ? 24 : 20;
    double cardCapacityFontSize =
        (orientation == Orientation.landscape || width > 600) ? 11 : 10;
    double actionTitleFontSize =
        (orientation == Orientation.landscape || width > 600) ? 15 : 14;
    double actionSubtitleFontSize =
        (orientation == Orientation.landscape || width > 600) ? 11.5 : 10.5;

    EdgeInsets bodyPadding =
        (orientation == Orientation.landscape || width > 600)
        ? const EdgeInsets.all(16).copyWith(bottom: 24)
        : const EdgeInsets.all(10).copyWith(bottom: 16);
    double actionCardHeight =
        (orientation == Orientation.landscape || width > 600) ? 100 : 80;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true,
        title: Text(
          'MSWDO Dashboard',
          style: GoogleFonts.poppins(
            fontSize: titleFontSize,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: bodyPadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard Overview",
                        style: GoogleFonts.poppins(
                          fontSize: sectionTitleFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: childAspectRatio,
                        children: [
                          _evacCard(
                            "Registered Residents",
                            _registeredResidents,
                            null,
                            cardTitleFontSize,
                            cardNumberFontSize,
                            cardCapacityFontSize,
                          ),
                          _evacCard(
                            "Evacuated Residents",
                            _isLoading ? 0 : _evacuatedResidents,
                            null,
                            cardTitleFontSize,
                            cardNumberFontSize,
                            cardCapacityFontSize,
                          ),
                          _evacCard(
                            "Municipal Evacuation Center - Magsaysay",
                            _magsaysayCount,
                            250,
                            cardTitleFontSize,
                            cardNumberFontSize,
                            cardCapacityFontSize,
                          ),
                          _evacCard(
                            "Municipal Farmer’s Covered Court",
                            _farmersCourtCount,
                            200,
                            cardTitleFontSize,
                            cardNumberFontSize,
                            cardCapacityFontSize,
                          ),
                          _evacCard(
                            "Santa RHU",
                            _santaRhuCount,
                            150,
                            cardTitleFontSize,
                            cardNumberFontSize,
                            cardCapacityFontSize,
                          ),
                          _evacCard(
                            "Santa High School (Supplemental)",
                            _santaHighSchoolCount,
                            120,
                            cardTitleFontSize,
                            cardNumberFontSize,
                            cardCapacityFontSize,
                          ),
                          _evacCard(
                            "Santa National High School (Supplemental)",
                            _santaNationalHighSchoolCount,
                            100,
                            cardTitleFontSize,
                            cardNumberFontSize,
                            cardCapacityFontSize,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 8),
                      Text(
                        "Quick Access",
                        style: GoogleFonts.poppins(
                          fontSize: sectionTitleFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _actionCard(
                        title: "QR Scanning",
                        subtitle: "Scan residents’ QR codes quickly",
                        icon: Icons.qr_code_scanner,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanQrPage(),
                            ),
                          );
                        },
                        titleFontSize: actionTitleFontSize,
                        subtitleFontSize: actionSubtitleFontSize,
                        height: actionCardHeight,
                      ),
                      const SizedBox(height: 12),
                      _actionCard(
                        title: "Applications",
                        subtitle: "View and manage resident applications",
                        icon: Icons.article_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistrationPage(),
                            ),
                          );
                        },
                        titleFontSize: actionTitleFontSize,
                        subtitleFontSize: actionSubtitleFontSize,
                        height: actionCardHeight,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            MaterialPageRoute(builder: (context) => const DisplayAllQrPage()),
          );
        } else if (title == 'Discharge Residents') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DischargeScanQrPage(),
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

  Widget _evacCard(
    String title,
    int current,
    int? capacity,
    double titleFontSize,
    double numberFontSize,
    double capacityFontSize,
  ) {
    const Color mainGreen = Color(0xFF0D743D); // Always use this green

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: mainGreen, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
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
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$current",
            style: GoogleFonts.poppins(
              fontSize: numberFontSize,
              fontWeight: FontWeight.bold,
              color: mainGreen,
            ),
          ),
          if (capacity != null) ...[
            const SizedBox(height: 4),
            Text(
              "Capacity: $capacity",
              style: GoogleFonts.poppins(
                fontSize: capacityFontSize,
                color: Colors.black54,
              ),
            ),
            Text(
              "Remaining: ${capacity - current}",
              style: GoogleFonts.poppins(
                fontSize: capacityFontSize,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required double titleFontSize,
    required double subtitleFontSize,
    required double height,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D743D), Color(0xFF1D9A58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(icon, color: const Color(0xFF0D743D), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: subtitleFontSize,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
