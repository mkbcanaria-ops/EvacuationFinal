// ignore_for_file: unnecessary_type_check, unused_local_variable

import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:evacutaion/App/Sidebar/AppManageResidents/ManageResidents.dart';
import 'package:evacutaion/App/Sidebar/AppViewQR/ManageQR.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeFarmers.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeMagsaysay.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeNationalHigh.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeRHU.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeSantaNational.dart';
import 'package:evacutaion/App/Sidebar/Request/AppRequest.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:evacutaion/WebPages/sidebar/Request/Request.dart';

class DischargeScanQrPage extends StatefulWidget {
  const DischargeScanQrPage({super.key});

  @override
  State<DischargeScanQrPage> createState() => _DischargeScanQrPageState();
}

class _DischargeScanQrPageState extends State<DischargeScanQrPage> {
  String selectedPage = 'Discharge Residents';
  String? selectedSite;

  int _magsaysayCount = 0;
  int _farmersCourtCount = 0;
  int _santaRhuCount = 0;
  int _santaHighSchoolCount = 0;
  int _santaNationalHighSchoolCount = 0;

  @override
  void initState() {
    super.initState();
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
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text(
                '$centerName has reached or exceeded its capacity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 25),
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
      ),
    );
  }

  // ===================== FETCH FUNCTIONS =====================
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

  Future<void> _dischargeAllResidents() async {
    if (!mounted) return;
    final supabase = Supabase.instance.client;

    try {
      // STEP 1: Fetch all residents from Evacuation_A and Evacuation_B
      final evacAData = await supabase.from('Evacuation_A').select('*');

      final evacBData = await supabase.from('Evacuation_B').select('*');

      final combined = [...evacAData, ...evacBData];

      if (combined.isEmpty) {
        // NO RESIDENTS POPUP
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 25,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.15),
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 65,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No Residents Found',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'All evacuation centers are already empty.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dCtx).pop();

                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DischargeScanQrPage(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.poppins(
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
        return;
      }

      // STEP 2: Group residents by UID and collect their details
      final Map<String, dynamic> dischargeData = {};
      final now = DateTime.now().toUtc().toIso8601String();

      // Get unique UIDs
      final Set<String> uniqueUIDs = {};
      for (var resident in combined) {
        uniqueUIDs.add(resident['UID'].toString());
      }

      debugPrint('✅ Found ${uniqueUIDs.length} unique residents to discharge');

      // STEP 3: For each UID, fetch registration and family details
      final List<Map<String, Object>> dischargeInserts = [];

      for (var uid in uniqueUIDs) {
        try {
          // Fetch registration data
          final registrationData = await supabase
              .from('Registration_Table')
              .select('*')
              .eq('UID', uid)
              .maybeSingle();

          // Fetch family members
          final familyData = await supabase
              .from('Family_Members')
              .select('*')
              .eq('UID', uid);

          final regId = registrationData?['Registration_ID'].toString() ?? uid;

          // Build head of family entry from registration data
          if (registrationData != null) {
            final headFullName =
                '${registrationData['Head_Surname'] ?? ''} ${registrationData['Head_Firstname'] ?? ''} ${registrationData['Head_Middlename'] ?? ''}'
                    .trim();

            final headEntry = <String, Object>{
              'UID': uid,
              'Registration_ID': regId,
              'Family_Member': headFullName,
              'Relation': 'Head of Family',
              'Age': registrationData['Head_Age'] ?? 0,
              'Gender': registrationData['Head_Sex'] ?? '',
              'Civil_Status': registrationData['Civil_Status'] ?? '',
              'Education': registrationData['Education'] ?? '',
              'Occupational_Skills': registrationData['Occupation'] ?? '',
              'Remarks': 'Head of family entry',
              'Code': '',
              'Head_Surname': registrationData['Head_Surname'] ?? '',
              'Head_Firstname': registrationData['Head_Firstname'] ?? '',
              'Head_Middlename': registrationData['Head_Middlename'] ?? '',
              'Head_Occupation': registrationData['Occupation'] ?? '',
              'Head_Monthly_Income': registrationData['Monthly_Income'] ?? 0.0,
              'City': registrationData['City'] ?? '',
              'Municipality': registrationData['Municipality'] ?? '',
              'Barangay': registrationData['Barangay'] ?? '',
              'Site': registrationData['Site'] ?? '',
              'Date_Transferred': now,
              'Time_Discharge': now,
            };
            dischargeInserts.add(headEntry);
          }

          // Build family member entries
          if (familyData != null && familyData.isNotEmpty) {
            for (var member in familyData) {
              final familyEntry = <String, Object>{
                'UID': uid,
                'Registration_ID': regId,
                'Family_Member': member['Family_Member'] ?? '',
                'Relation': member['Relation'] ?? '',
                'Age': member['Age'] ?? 0,
                'Gender': member['Gender'] ?? '',
                'Civil_Status': member['Civil_Status'] ?? '',
                'Education': member['Education'] ?? '',
                'Occupational_Skills': member['Occupational_Skills'] ?? '',
                'Remarks': member['Remarks'] ?? '',
                'Code': member['Code'] ?? '',
                'Site': registrationData?['Site'] ?? '',
                'Date_Transferred': now,
                'Time_Discharge': now,
              };
              dischargeInserts.add(familyEntry);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching details for UID $uid: $e');
        }
      }

      // STEP 4: Insert all discharge records
      if (dischargeInserts.isNotEmpty) {
        try {
          await supabase.from('Discharge_Resident').insert(dischargeInserts);
          debugPrint('✅ Inserted ${dischargeInserts.length} discharge records');
        } catch (e) {
          debugPrint('❌ Error inserting discharge records: $e');
          throw Exception('Failed to insert discharge records: $e');
        }
      }

      // STEP 5: Delete ALL residents from evacuation tables
      await supabase.from('Evacuation_A').delete().neq('UID', '');
      await supabase.from('Evacuation_B').delete().neq('UID', '');

      debugPrint('🧹 ALL residents removed from evacuation tables');

      // STEP 6: Show SUCCESS POPUP
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 25,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D743D).withOpacity(0.15),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF0D743D),
                        size: 65,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Discharge Successful',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${uniqueUIDs.length} resident(s) with ${dischargeInserts.length} total member(s) discharged successfully.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dCtx).pop();

                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DischargeScanQrPage(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D743D),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.poppins(
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
    } catch (e) {
      debugPrint('❌ Error discharging all residents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to discharge all residents: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Discharge Residents",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      drawer: _buildAdminDrawer(),

      // ✅ CENTERED FLOATING BUTTON
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D743D),
        icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
        label: Text(
          "Discharge All",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Confirm Discharge",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Text(
                "Are you sure you want to discharge ALL residents from all evacuation centers?",
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _dischargeAllResidents();
                  },
                  child: Text(
                    "Discharge All",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth, // take full width
                ),
                child: _buildResponsiveGrid(),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== SITE CARD =====================
  Widget _buildSiteCard(
    String site,
    int currentCount,
    int capacity, {
    VoidCallback? onTap,
  }) {
    final bool isSelected = selectedSite == site;
    final double progress = (currentCount / capacity).clamp(0, 1).toDouble();

    return InkWell(
      onTap: onTap ?? () => setState(() => selectedSite = site),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D743D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 28,
                  color: isSelected ? Colors.white : const Color(0xFF0D743D),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    site,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: progress >= 1 ? Colors.redAccent : const Color(0xFF0D743D),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: $currentCount / $capacity',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  'Remaining: ${capacity - currentCount}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== RESPONSIVE GRID =====================
  Widget _buildResponsiveGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    int crossAxisCount;
    double childAspectRatio;

    if (orientation == Orientation.portrait) {
      crossAxisCount = 1; // 1 card per row for full width
      childAspectRatio = screenWidth / 150; // height approx. 150
    } else {
      crossAxisCount = screenWidth > 1200
          ? 4
          : 2; // multiple cards for landscape
      childAspectRatio = 16 / 9;
    }

    final List<Widget> cards = [
      _buildSiteCard(
        "Municipal Evacuation Center, Magsaysay",
        _magsaysayCount,
        250,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppMagsaysayEvacuationPage(),
            ),
          );
        },
      ),
      _buildSiteCard(
        "Municipal Farmers Covered Court",
        _farmersCourtCount,
        180,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppFarmersResidentsPage(),
            ),
          );
        },
      ),
      _buildSiteCard(
        "Santa RHU",
        _santaRhuCount,
        150,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppSantaRHUResidentsPage(),
            ),
          );
        },
      ),
      _buildSiteCard(
        "Santa High School (Supplemental)",
        _santaHighSchoolCount,
        120,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppSantaHighSchoolResidentsPage(),
            ),
          );
        },
      ),
      _buildSiteCard(
        "Santa National High School (Supplemental)",
        _santaNationalHighSchoolCount,
        110,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AppSantaNationalHighSchoolResidentsPage(),
            ),
          );
        },
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  // ===================== DASHBOARD DRAWER =====================
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
        setState(() => selectedPage = title);
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
            MaterialPageRoute(builder: (context) => const DisplayAllQrPage()),
          );
        } else if (title == 'Reports') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WebReportsPage()),
          );
        } else if (title == 'Requests') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppRequestsPage()),
          );
        }
      },
    );
  }
}
