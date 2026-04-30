// ignore_for_file: unnecessary_type_check, unused_local_variable, unnecessary_null_comparison

import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:evacutaion/App/Sidebar/AppManageResidents/ManageResidents.dart';
import 'package:evacutaion/App/Sidebar/AppViewQR/ManageQR.dart';
import 'package:evacutaion/App/Sidebar/Appreport/AppReport.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeFarmers.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeMagsaysay.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeSantaHigh.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeRHU.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/AppDischargeSantaNational.dart';
import 'package:evacutaion/App/Sidebar/Request/AppRequest.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _isRefreshingCounts = false;
  bool _isDischarging = false;

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  int _safeCount(dynamic result) {
    if (result is List) return result.length;
    return 0;
  }

  Future<int> _fetchCount({required String table, String? site}) async {
    final supabase = Supabase.instance.client;

    var query = supabase.from(table).select('UID');

    if (site != null) {
      query = query.eq('Site', site);
    }

    final result = await query.timeout(const Duration(seconds: 10));
    return _safeCount(result);
  }

  Future<void> _refreshCounts() async {
    if (_isRefreshingCounts) return;

    _safeSetState(() {
      _isRefreshingCounts = true;
    });

    try {
      final results = await Future.wait<int>([
        _fetchCount(
          table: 'Evacuation_A',
          site: 'Municipal Evacuation Center, Magsaysay',
        ),
        _fetchCount(
          table: 'Evacuation_A',
          site: 'Municipal Farmers Covered Court',
        ),
        _fetchCount(table: 'Evacuation_B'),
        _fetchCount(table: 'Evacuation_A', site: 'Santa High School'),
        _fetchCount(table: 'Evacuation_A', site: 'Santa National High School'),
      ]);

      if (!mounted) return;

      _safeSetState(() {
        _magsaysayCount = results[0];
        _farmersCourtCount = results[1];
        _santaRhuCount = results[2];
        _santaHighSchoolCount = results[3];
        _santaNationalHighSchoolCount = results[4];
        _isRefreshingCounts = false;
      });

      _checkCapacityWarnings();
    } catch (e) {
      debugPrint('❌ Error refreshing counts: $e');

      if (!mounted) return;

      _safeSetState(() {
        _magsaysayCount = 0;
        _farmersCourtCount = 0;
        _santaRhuCount = 0;
        _santaHighSchoolCount = 0;
        _santaNationalHighSchoolCount = 0;
        _isRefreshingCounts = false;
      });
    }
  }

  void _checkCapacityWarnings() {
    if (!mounted) return;

    final List<String> fullCenters = [];

    if (_magsaysayCount >= 250) {
      fullCenters.add('Municipal Evacuation Center - Magsaysay');
    }

    if (_farmersCourtCount >= 200) {
      fullCenters.add('Municipal Farmer’s Covered Court');
    }

    if (_santaRhuCount >= 150) {
      fullCenters.add('Santa RHU');
    }

    if (_santaHighSchoolCount >= 120) {
      fullCenters.add('Santa High School (Supplemental)');
    }

    if (_santaNationalHighSchoolCount >= 100) {
      fullCenters.add('Santa National High School (Supplemental)');
    }

    if (fullCenters.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _showCapacityFullDialog(fullCenters.join('\n'));
    });
  }

  void _showCapacityFullDialog(String centerName) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Capacity Full',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$centerName has reached or exceeded its capacity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
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

  Future<void> _dischargeAllResidents() async {
    if (!mounted || _isDischarging) return;

    _safeSetState(() {
      _isDischarging = true;
    });

    final supabase = Supabase.instance.client;

    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;

      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == 'true' || v == '1' || v == 'yes';
      }

      return false;
    }

    String normalizeName(String value) {
      return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    }

    try {
      final evacResults = await Future.wait([
        supabase.from('Evacuation_A').select('*'),
        supabase.from('Evacuation_B').select('*'),
      ]);

      if (!mounted) return;

      final evacAData = List<Map<String, dynamic>>.from(evacResults[0]);
      final evacBData = List<Map<String, dynamic>>.from(evacResults[1]);
      final combined = [...evacAData, ...evacBData];

      if (combined.isEmpty) {
        _safeSetState(() {
          _isDischarging = false;
        });

        await _showNoResidentsFoundDialog();
        return;
      }

      final now = DateTime.now().toIso8601String();

      final Set<String> uniqueUIDs = {};
      final Map<String, String> timeDeployedMap = {};
      final Map<String, bool> fourPsFamiliesMap = {};
      final Map<String, List<Map<String, dynamic>>> evacRowsByUid = {};

      for (final resident in combined) {
        final uid = resident['UID']?.toString() ?? '';
        if (uid.isEmpty) continue;

        uniqueUIDs.add(uid);

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
          fourPsFamiliesMap[uid] = toBool(raw4ps);
        }
      }

      final uidList = uniqueUIDs.toList();

      if (uidList.isEmpty) {
        _safeSetState(() {
          _isDischarging = false;
        });

        await _showNoResidentsFoundDialog();
        return;
      }

      final fetchedData = await Future.wait([
        supabase
            .from('Registration_Table')
            .select('*')
            .inFilter('UID', uidList),
        supabase.from('Family_Members').select('*').inFilter('UID', uidList),
      ]);

      if (!mounted) return;

      final registrations = List<Map<String, dynamic>>.from(fetchedData[0]);
      final familyMembers = List<Map<String, dynamic>>.from(fetchedData[1]);

      final Map<String, Map<String, dynamic>> registrationByUid = {};
      for (final reg in registrations) {
        final uid = reg['UID']?.toString() ?? '';
        if (uid.isNotEmpty) {
          registrationByUid[uid] = reg;
        }
      }

      final Map<String, List<Map<String, dynamic>>> familyByUid = {};
      for (final member in familyMembers) {
        final uid = member['UID']?.toString() ?? '';
        if (uid.isNotEmpty) {
          familyByUid.putIfAbsent(uid, () => []).add(member);
        }
      }

      final List<Map<String, Object?>> dischargeInserts = [];

      for (final uid in uidList) {
        final registrationData = registrationByUid[uid];
        final familyData = familyByUid[uid] ?? [];

        final regId = registrationData?['Registration_ID']?.toString() ?? uid;
        final timeDeployed = timeDeployedMap[uid] ?? '';
        final headBarangay = (registrationData?['Barangay'] ?? '').toString();
        final fourPsFamilies = fourPsFamiliesMap[uid] ?? false;

        final uidEvacRows = evacRowsByUid[uid] ?? [];
        final Map<String, Map<String, dynamic>> evacRowByName = {};

        for (final row in uidEvacRows) {
          final name = (row['Family_Member'] ?? '').toString().trim();
          if (name.isEmpty) continue;

          evacRowByName[normalizeName(name)] = row;
        }

        if (registrationData != null) {
          final headFullName =
              '${registrationData['Head_Surname'] ?? ''} ${registrationData['Head_Firstname'] ?? ''} ${registrationData['Head_Middlename'] ?? ''}'
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();

          final headEvacRow = evacRowByName[normalizeName(headFullName)];

          final headActualSite =
              (headEvacRow?['Site'] ?? registrationData['Site'] ?? '')
                  .toString();

          final headBirthDate = headEvacRow?['Date_of_Birth'];

          dischargeInserts.add({
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
          });
        }

        for (final member in familyData) {
          final memberName = (member['Family_Member'] ?? '').toString().trim();
          final memberEvacRow = evacRowByName[normalizeName(memberName)];

          final actualSite =
              (memberEvacRow?['Site'] ?? registrationData?['Site'] ?? '')
                  .toString();

          final memberBirthDate = memberEvacRow?['Date_of_Birth'];

          dischargeInserts.add({
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
          });
        }
      }

      if (dischargeInserts.isNotEmpty) {
        await supabase.from('Discharge_Resident').insert(dischargeInserts);
      }

      if (!mounted) return;

      await Future.wait([
        supabase.from('Evacuation_A').delete().neq('UID', ''),
        supabase.from('Evacuation_B').delete().neq('UID', ''),
      ]);

      if (!mounted) return;

      _safeSetState(() {
        _isDischarging = false;
      });

      await _showDischargeSuccessDialog(
        residentCount: uniqueUIDs.length,
        memberCount: dischargeInserts.length,
      );

      await _refreshCounts();
    } catch (e) {
      debugPrint('❌ Error discharging all residents: $e');

      if (!mounted) return;

      _safeSetState(() {
        _isDischarging = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to discharge all residents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showNoResidentsFoundDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.14),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Residents Found',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All evacuation centers are already empty.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dCtx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

  Future<void> _showDischargeSuccessDialog({
    required int residentCount,
    required int memberCount,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryGreen.withOpacity(0.14),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF0D743D),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discharge Successful',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$residentCount resident(s) with $memberCount total member(s) discharged successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dCtx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: softBg,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primaryGreen,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              "Discharge Residents",
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          drawer: _buildAdminDrawer(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            elevation: 3,
            backgroundColor: _isDischarging
                ? Colors.grey.shade500
                : primaryGreen,
            icon: _isDischarging
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.exit_to_app_rounded, color: Colors.white),
            label: Text(
              _isDischarging ? "Discharging..." : "Discharge All",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            onPressed: _isDischarging ? null : _showDischargeAllConfirmDialog,
          ),
          body: RefreshIndicator(
            color: primaryGreen,
            onRefresh: _refreshCounts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 94),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBanner(),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 1000;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildSummaryCard(
                            title: 'Total Residents',
                            value: '$_totalResidents',
                            icon: Icons.groups_rounded,
                            color: primaryGreen,
                            width: isWide ? 230 : constraints.maxWidth,
                          ),
                          _buildSummaryCard(
                            title: 'Total Capacity',
                            value: '$_totalCapacity',
                            icon: Icons.meeting_room_rounded,
                            color: const Color(0xFF0B5ED7),
                            width: isWide ? 230 : constraints.maxWidth,
                          ),
                          _buildSummaryCard(
                            title: 'Available Slots',
                            value: '$_availableSlots',
                            icon: Icons.event_seat_rounded,
                            color: const Color(0xFFF39C12),
                            width: isWide ? 230 : constraints.maxWidth,
                          ),
                          _buildSummaryCard(
                            title: 'Occupancy',
                            value:
                                '${(_overallProgress * 100).toStringAsFixed(1)}%',
                            icon: Icons.pie_chart_rounded,
                            color: const Color(0xFF8E44AD),
                            width: isWide ? 230 : constraints.maxWidth,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Evacuation Centers',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Select a site to view and manage discharged residents.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSiteGrid(),
                ],
              ),
            ),
          ),
        ),

        if (_isDischarging)
          Container(
            color: Colors.black.withOpacity(0.15),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryGreen),
                    const SizedBox(height: 14),
                    Text(
                      'Discharging residents...',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDischargeAllConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
  }

  Widget _buildSiteGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double spacing = 14;

        int columns = 1;

        if (width >= 1200) {
          columns = 3;
        } else if (width >= 760) {
          columns = 2;
        } else {
          columns = 1;
        }

        final double itemWidth = (width - ((columns - 1) * spacing)) / columns;

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
                      builder: (context) => const AppMagsaysayEvacuationPage(),
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
                      builder: (context) => const AppFarmersResidentsPage(),
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
                      builder: (context) => const AppSantaRHUResidentsPage(),
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
                          const AppSantaHighSchoolResidentsPage(),
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
                          const AppSantaNationalHighSchoolResidentsPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [primaryGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        spacing: 12,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discharge Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor occupancy and discharge residents across all sites.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.white.withOpacity(0.90),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  '5 Active Sites',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
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
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
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
      onTap:
          onTap ??
          () {
            _safeSetState(() {
              selectedSite = site;
            });
          },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F8F4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : cardBorder,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 24,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    site,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: primaryGreen, size: 22),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSmallInfo(
                    'Current',
                    currentCount.toString(),
                    Icons.people_alt_rounded,
                  ),
                ),
                const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryGreen),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
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
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evacuation Management System',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
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
          dense: true,
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
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: isSelected ? primaryGreen : Colors.black87,
            ),
          ),
          onTap: () {
            _safeSetState(() {
              selectedPage = title;
            });

            Navigator.pop(context);

            if (title == 'Dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainDashboard()),
              );
            } else if (title == 'Resident Management') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageResidentsPage()),
              );
            } else if (title == 'QR Code Management') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DisplayAllQrPage()),
              );
            } else if (title == 'Discharge Residents') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DischargeScanQrPage()),
              );
            } else if (title == 'Reports') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppReportsPage()),
              );
            } else if (title == 'Requests') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppRequestsPage()),
              );
            }
          },
        ),
      ),
    );
  }
}
