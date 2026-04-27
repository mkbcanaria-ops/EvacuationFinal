// ignore_for_file: unnecessary_type_check, unused_local_variable, unnecessary_null_comparison

import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/Discharge_Farmers.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/Discharge_Magsaysay.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/Discharge_RHU.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/Discharge_SantaHignh.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/Discharge_SantaNational.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:evacutaion/WebPages/sidebar/ViewQRcode/WebManageQr.dart';
import 'package:evacutaion/WebPages/sidebar/WebEditResident/WebManageResidents.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:evacutaion/WebPages/sidebar/Request/Request.dart';

class WebDischargeDashboardPage extends StatefulWidget {
  const WebDischargeDashboardPage({super.key});

  @override
  State<WebDischargeDashboardPage> createState() =>
      _WebDischargeDashboardPageState();
}

class _WebDischargeDashboardPageState extends State<WebDischargeDashboardPage> {
  String selectedPage = 'Discharge Residents';
  String? selectedSite;

  int _magsaysayCount = 0;
  int _farmersCourtCount = 0;
  int _santaRhuCount = 0;
  int _santaHighSchoolCount = 0;
  int _santaNationalHighSchoolCount = 0;

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Capacity Full',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$centerName has reached or exceeded its capacity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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

  Future<void> _fetchMagsaysayCenterCount() async {
    final supabase = Supabase.instance.client;

    try {
      final result = await supabase
          .from('Evacuation_A')
          .select('UID')
          .eq('Site', 'Municipal Evacuation Center, Magsaysay')
          .timeout(const Duration(seconds: 10));

      int count = 0;
      if (result is List) {
        count = result.length;
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

      int count = 0;
      if (result is List) {
        count = result.length;
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

      int count = 0;
      if (result is List) {
        count = result.length;
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

      int count = 0;
      if (result is List) {
        count = result.length;
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

      int count = 0;
      if (result is List) {
        count = result.length;
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

    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == 'true' || v == '1' || v == 'yes';
      }
      return false;
    }

    String _normalizeName(String value) {
      return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    }

    try {
      final evacAData = await supabase.from('Evacuation_A').select('*');
      final evacBData = await supabase.from('Evacuation_B').select('*');

      final combined = [...evacAData, ...evacBData];

      if (combined.isEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.14),
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No Residents Found',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 23,
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
                                    const WebDischargeDashboardPage(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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

      final now = DateTime.now().toIso8601String();

      final Map<String, String> timeDeployedMap = {};
      final Map<String, bool> fourPsFamiliesMap = {};
      final Map<String, List<Map<String, dynamic>>> evacRowsByUid = {};

      for (var resident in combined) {
        final uid = resident['UID']?.toString() ?? '';
        if (uid.isEmpty) continue;

        timeDeployedMap.putIfAbsent(
          uid,
          () => (resident['Time_Deployed'] ?? '').toString(),
        );

        evacRowsByUid
            .putIfAbsent(uid, () => [])
            .add(Map<String, dynamic>.from(resident));

        final relation = (resident['Relation'] ?? '').toString().trim();
        if (relation == 'Head of Family') {
          final raw4ps = resident['4Ps_Families'];
          fourPsFamiliesMap[uid] = _toBool(raw4ps);
        }
      }

      final Set<String> uniqueUIDs = {};
      for (var resident in combined) {
        final uid = resident['UID']?.toString() ?? '';
        if (uid.isNotEmpty) {
          uniqueUIDs.add(uid);
        }
      }

      final List<Map<String, Object?>> dischargeInserts = [];

      for (var uid in uniqueUIDs) {
        try {
          final registrationData = await supabase
              .from('Registration_Table')
              .select('*')
              .eq('UID', uid)
              .maybeSingle();

          final familyData = await supabase
              .from('Family_Members')
              .select('*')
              .eq('UID', uid);

          final regId = registrationData?['Registration_ID'].toString() ?? uid;
          final timeDeployed = timeDeployedMap[uid] ?? '';
          final headBarangay = (registrationData?['Barangay'] ?? '').toString();
          final fourPsFamilies = fourPsFamiliesMap[uid] ?? false;

          final uidEvacRows = evacRowsByUid[uid] ?? [];
          final Map<String, Map<String, dynamic>> evacRowByName = {};

          for (final row in uidEvacRows) {
            final name = (row['Family_Member'] ?? '').toString().trim();
            if (name.isEmpty) continue;
            evacRowByName[_normalizeName(name)] = row;
          }

          if (registrationData != null) {
            final headFullName =
                '${registrationData['Head_Surname'] ?? ''} ${registrationData['Head_Firstname'] ?? ''} ${registrationData['Head_Middlename'] ?? ''}'
                    .trim();

            final headEvacRow = evacRowByName[_normalizeName(headFullName)];
            final headActualSite =
                (headEvacRow?['Site'] ?? registrationData['Site'] ?? '')
                    .toString();
            final headBirthDate = headEvacRow?['Date_of_Birth'];

            final headEntry = <String, Object?>{
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
              'Barangay': headBarangay,
              'Site': headActualSite,
              'BirthDate': headBirthDate,
              'Date_Transferred': now,
              'Time_Deployed': timeDeployed,
              'Time_Discharge': now,
              '4Ps_Families': fourPsFamilies,
            };
            dischargeInserts.add(headEntry);
          }

          if (familyData != null && familyData.isNotEmpty) {
            for (var member in familyData) {
              final memberName = (member['Family_Member'] ?? '')
                  .toString()
                  .trim();
              final memberEvacRow = evacRowByName[_normalizeName(memberName)];
              final actualSite =
                  (memberEvacRow?['Site'] ?? registrationData?['Site'] ?? '')
                      .toString();
              final memberBirthDate = memberEvacRow?['Date_of_Birth'];

              final familyEntry = <String, Object?>{
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
                'Barangay': headBarangay,
                'Site': actualSite,
                'BirthDate': memberBirthDate,
                'Date_Transferred': now,
                'Time_Deployed': timeDeployed,
                'Time_Discharge': now,
                '4Ps_Families': fourPsFamilies,
              };
              dischargeInserts.add(familyEntry);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching details for UID $uid: $e');
        }
      }

      if (dischargeInserts.isNotEmpty) {
        try {
          await supabase.from('Discharge_Resident').insert(dischargeInserts);
        } catch (e) {
          throw Exception('Failed to insert discharge records: $e');
        }
      }

      await supabase.from('Evacuation_A').delete().neq('UID', '');
      await supabase.from('Evacuation_B').delete().neq('UID', '');

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryGreen.withOpacity(0.14),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF0D743D),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Discharge Successful',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 23,
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
                                    const WebDischargeDashboardPage(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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

  int get _totalResidents =>
      _magsaysayCount +
      _farmersCourtCount +
      _santaRhuCount +
      _santaHighSchoolCount +
      _santaNationalHighSchoolCount;

  int get _totalCapacity => 250 + 180 + 150 + 120 + 110;

  int get _availableSlots =>
      (_totalCapacity - _totalResidents).clamp(0, 999999);

  double get _overallProgress =>
      _totalCapacity == 0 ? 0 : (_totalResidents / _totalCapacity).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        backgroundColor: primaryGreen,
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
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                "Confirm Discharge",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Text(
                "Are you sure you want to discharge ALL residents from all evacuation centers?",
                style: GoogleFonts.poppins(height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBanner(),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth > 1000;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildSummaryCard(
                      title: 'Total Residents',
                      value: '$_totalResidents',
                      icon: Icons.groups_rounded,
                      color: primaryGreen,
                      width: isWide ? 240 : constraints.maxWidth,
                    ),
                    _buildSummaryCard(
                      title: 'Total Capacity',
                      value: '$_totalCapacity',
                      icon: Icons.meeting_room_rounded,
                      color: const Color(0xFF0B5ED7),
                      width: isWide ? 240 : constraints.maxWidth,
                    ),
                    _buildSummaryCard(
                      title: 'Available Slots',
                      value: '$_availableSlots',
                      icon: Icons.event_seat_rounded,
                      color: const Color(0xFFF39C12),
                      width: isWide ? 240 : constraints.maxWidth,
                    ),
                    _buildSummaryCard(
                      title: 'Occupancy',
                      value: '${(_overallProgress * 100).toStringAsFixed(1)}%',
                      icon: Icons.pie_chart_rounded,
                      color: const Color(0xFF8E44AD),
                      width: isWide ? 240 : constraints.maxWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Evacuation Centers',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a site to view and manage discharged residents.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                const double spacing = 20;

                int columns = 1;
                if (width >= 1200) {
                  columns = 3;
                } else if (width >= 800) {
                  columns = 2;
                } else {
                  columns = 1;
                }

                final double itemWidth =
                    (width - ((columns - 1) * spacing)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildSiteCard(
                        "Municipal Evacuation Center, Magsaysay",
                        _magsaysayCount,
                        250,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WebMagsaysayEvacuationPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildSiteCard(
                        "Municipal Farmers Covered Court",
                        _farmersCourtCount,
                        180,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WebFarmersResidentsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildSiteCard(
                        "Santa RHU",
                        _santaRhuCount,
                        150,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WebSantaRHUResidentsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildSiteCard(
                        "Santa High School (Supplemental)",
                        _santaHighSchoolCount,
                        120,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WebSantaHighSchoolResidentsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildSiteCard(
                        "Santa National High School (Supplemental)",
                        _santaNationalHighSchoolCount,
                        110,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WebSantaNationalHighSchoolResidentsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [primaryGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        spacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discharge Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor evacuation center occupancy and discharge residents efficiently across all available sites.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_hospital_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  '5 Active Sites',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(
    String site,
    int currentCount,
    int capacity, {
    VoidCallback? onTap,
  }) {
    final bool isSelected = selectedSite == site;
    final double progress = (currentCount / capacity).clamp(0, 1).toDouble();
    final int remaining = (capacity - currentCount).clamp(0, 999999);
    final bool isFull = currentCount >= capacity;

    Color statusColor;
    String statusText;

    if (isFull) {
      statusColor = Colors.redAccent;
      statusText = 'Full';
    } else if (progress >= 0.8) {
      statusColor = Colors.orange;
      statusText = 'Nearly Full';
    } else {
      statusColor = primaryGreen;
      statusText = 'Available';
    }

    return InkWell(
      onTap: onTap ?? () => setState(() => selectedSite = site),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F8F4) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryGreen : cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 28,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    site,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: primaryGreen, size: 24),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '$currentCount / $capacity',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSmallInfo(
                    'Current',
                    currentCount.toString(),
                    Icons.people_alt_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallInfo(
                    'Remaining',
                    remaining.toString(),
                    Icons.event_seat_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            setState(() => selectedPage = title);
            Navigator.pop(context);

            if (title == 'Dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebMainDashboard(),
                ),
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
            } else if (title == 'Reports') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WebReportsPage()),
              );
            } else if (title == 'Requests') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebRequestsPage(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
