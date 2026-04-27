// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge Function/WebDischargeScanner.dart';

class WebMagsaysayEvacuationPage extends StatefulWidget {
  const WebMagsaysayEvacuationPage({super.key});

  @override
  State<WebMagsaysayEvacuationPage> createState() =>
      _WebMagsaysayEvacuationPageState();
}

class _WebMagsaysayEvacuationPageState
    extends State<WebMagsaysayEvacuationPage> {
  static const String currentSiteName =
      'Municipal Evacuation Center, Magsaysay';

  List<Map<String, dynamic>> residents = [];
  bool isLoading = true;

  Map<int, bool> expanded = {};
  Map<int, bool> selected = {};
  Map<String, List<String>> familyMembersCache = {};
  Map<String, Map<String, dynamic>> registrationDetailsCache = {};

  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    _fetchResidents();
  }

  Future<void> _fetchResidents() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final supabase = Supabase.instance.client;

    try {
      final evacA = await supabase
          .from('Evacuation_A')
          .select()
          .eq('Site', currentSiteName);

      final evacB = await supabase
          .from('Evacuation_B')
          .select()
          .eq('Site', currentSiteName);

      final combined = [...evacA, ...evacB];

      final Map<String, Map<String, dynamic>> headMap = {};
      final Map<String, List<String>> familyMap = {};
      final Map<String, List<String>> nextFamilyMembersCache = {};

      for (var resident in combined) {
        final regId = resident['Registration_ID'].toString();
        final relation = (resident['Relation'] ?? '').toString();
        final name = (resident['Family_Member'] ?? '').toString();

        if (relation == 'Head of Family') {
          headMap[regId] = resident;
        } else {
          familyMap.putIfAbsent(regId, () => []).add(name);
        }
      }

      final List<Map<String, dynamic>> headsList = [];
      for (var entry in headMap.entries) {
        final regId = entry.key;
        headsList.add(entry.value);
        nextFamilyMembersCache[regId] = familyMap[regId] ?? [];
      }

      if (!mounted) return;

      setState(() {
        residents = headsList;
        familyMembersCache = nextFamilyMembersCache;
        isLoading = false;
      });

      for (var entry in headMap.entries) {
        _fetchRegistrationDetails(entry.value['UID'].toString(), entry.key);
      }
    } catch (e, st) {
      debugPrint('❌ Error fetching residents: $e');
      debugPrint('$st');

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching residents: $e')));
    }
  }

  Future<void> _fetchRegistrationDetails(String uid, String regId) async {
    try {
      final supabase = Supabase.instance.client;

      final registrationResponse = await supabase
          .from('Registration_Table')
          .select('*')
          .eq('UID', uid)
          .maybeSingle();

      final familyResponse = await supabase
          .from('Family_Members')
          .select('*')
          .eq('UID', uid);

      if (registrationResponse != null && mounted) {
        setState(() {
          registrationDetailsCache[regId] = {
            'registration': registrationResponse,
            'family': familyResponse,
          };
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching registration details for $regId: $e');
    }
  }

  void _toggle(int index) {
    if (!mounted) return;
    setState(() => expanded[index] = !(expanded[index] ?? false));
  }

  void _toggleSelect(int index) {
    if (!mounted) return;
    setState(() => selected[index] = !(selected[index] ?? false));
  }

  void _toggleSelectAll() {
    if (!mounted) return;
    setState(() {
      allSelected = !allSelected;
      for (int i = 0; i < residents.length; i++) {
        selected[i] = allSelected;
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchAllEvacRowsByUid(String uid) async {
    final supabase = Supabase.instance.client;

    final evacA = await supabase
        .from('Evacuation_A')
        .select('*')
        .eq('UID', uid);
    final evacB = await supabase
        .from('Evacuation_B')
        .select('*')
        .eq('UID', uid);

    return [
      ...List<Map<String, dynamic>>.from(evacA),
      ...List<Map<String, dynamic>>.from(evacB),
    ];
  }

  List<String> _selectedResidentNames(
    List<Map<String, dynamic>> selectedResidents,
  ) {
    return selectedResidents
        .map((e) => (e['Family_Member'] ?? 'Resident').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  Widget _buildNameChips(
    List<String> names, {
    Color? bgColor,
    Color? textColor,
  }) {
    final uniqueNames = names.toSet().toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: uniqueNames.map((name) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor ?? const Color(0xFFE8F5EC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (textColor ?? const Color(0xFF0D743D)).withOpacity(0.10),
            ),
          ),
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12.3,
              fontWeight: FontWeight.w500,
              color: textColor ?? const Color(0xFF0D743D),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<Map<String, List<String>>> _getSplitFamilyWarnings(
    List<Map<String, dynamic>> selectedResidents,
  ) async {
    final Map<String, List<String>> splitMap = {};

    for (final resident in selectedResidents) {
      final uid = resident['UID'].toString();
      final familyName = (resident['Family_Member'] ?? 'Resident').toString();

      try {
        final allRows = await _fetchAllEvacRowsByUid(uid);

        final otherSites = allRows
            .map((row) => (row['Site'] ?? '').toString().trim())
            .where((site) => site.isNotEmpty && site != currentSiteName)
            .toSet()
            .toList();

        if (otherSites.isNotEmpty) {
          splitMap[familyName] = otherSites;
        }
      } catch (e) {
        debugPrint('❌ Error checking split family for UID $uid: $e');
      }
    }

    return splitMap;
  }

  Future<bool?> _showSplitFamilyWarningDialog(
    Map<String, List<String>> splitMap,
  ) async {
    if (!mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Split Family Detected',
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Some selected families still have members in another site or RHU. Only the members currently in $currentSiteName will be discharged.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 145),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: splitMap.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${entry.key}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: entry.value.join(', ')),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D743D),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _dischargeSelectedResidents() async {
    if (!mounted) return;

    final selectedResidents = selected.entries
        .where((e) => e.value)
        .map((e) => residents[e.key])
        .toList();

    if (selectedResidents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one resident to discharge."),
        ),
      );
      return;
    }

    final splitMap = await _getSplitFamilyWarnings(selectedResidents);

    if (!mounted) return;

    if (splitMap.isNotEmpty) {
      final proceed = await _showSplitFamilyWarningDialog(splitMap);
      if (proceed != true) return;
    }

    final selectedNames = _selectedResidentNames(selectedResidents);
    final confirmed = await _showConfirmationDialog(selectedNames);

    if (confirmed != true) return;

    final List<String> dischargedNames = [];

    for (var resident in selectedResidents) {
      final uid = resident['UID'].toString();
      final regId = resident['Registration_ID'].toString();
      final headName = (resident['Family_Member'] ?? 'Resident')
          .toString()
          .trim();

      if (headName.isNotEmpty && !dischargedNames.contains(headName)) {
        dischargedNames.add(headName);
      }

      await _dischargeResidents(regId, uid, dischargedNames);
    }

    if (!mounted) return;

    await _fetchResidents();

    if (!mounted) return;

    setState(() {
      selected.clear();
      allSelected = false;
    });
  }

  Future<bool?> _showConfirmationDialog(List<String> selectedNames) async {
    if (!mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 22,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Confirm Discharge',
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'The following selected residents will be discharged from $currentSiteName.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.8,
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: _buildNameChips(selectedNames),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Only members currently assigned to this site will be discharged.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.3,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D743D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _dischargeResidents(
    String registrationId,
    String uid,
    List<String> dischargedNames,
  ) async {
    if (!mounted) return;
    final supabase = Supabase.instance.client;

    final nowDateTime = DateTime.now();
    final now = nowDateTime.toIso8601String();

    String formatDateTime(DateTime dateTime) {
      final List<String> months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final month = months[dateTime.month - 1];
      final day = dateTime.day;
      final year = dateTime.year;

      final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$month $day, $year | $hour12:$minute $period';
    }

    final formattedTimeDischarge = formatDateTime(nowDateTime);

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

    List<Map<String, dynamic>> currentSiteRows = [];
    List<Map<String, dynamic>> allRows = [];

    try {
      final evacAAll = await supabase
          .from('Evacuation_A')
          .select('*')
          .eq('UID', uid);
      final evacBAll = await supabase
          .from('Evacuation_B')
          .select('*')
          .eq('UID', uid);

      allRows = [
        ...List<Map<String, dynamic>>.from(evacAAll),
        ...List<Map<String, dynamic>>.from(evacBAll),
      ];

      currentSiteRows = allRows
          .where(
            (row) => (row['Site'] ?? '').toString().trim() == currentSiteName,
          )
          .toList();
    } catch (e, st) {
      debugPrint('❌ Error fetching evacuation rows: $e');
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error fetching evacuation rows: $e')),
      );
      return;
    }

    if (currentSiteRows.isEmpty) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dCtx) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No Members In This Site',
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'This family has no members currently assigned to $currentSiteName.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dCtx).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                          fontSize: 12.8,
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

    final String timeDeployed = (currentSiteRows.first['Time_Deployed'] ?? '')
        .toString();

    final evacAHead = await supabase
        .from('Evacuation_A')
        .select('4Ps_Families')
        .eq('UID', uid)
        .eq('Relation', 'Head of Family')
        .maybeSingle();

    final evacBHead = await supabase
        .from('Evacuation_B')
        .select('4Ps_Families')
        .eq('UID', uid)
        .eq('Relation', 'Head of Family')
        .maybeSingle();

    final dynamic rawA = evacAHead?['4Ps_Families'];
    final dynamic rawB = evacBHead?['4Ps_Families'];
    final bool fourPsFamilies = toBool(rawA) || toBool(rawB);

    Map<String, dynamic>? registrationData;
    List<Map<String, dynamic>> familyMembers = [];

    try {
      registrationData = await supabase
          .from('Registration_Table')
          .select('*')
          .eq('UID', uid)
          .maybeSingle();

      final familyResponse = await supabase
          .from('Family_Members')
          .select('*')
          .eq('UID', uid);

      familyMembers = List<Map<String, dynamic>>.from(familyResponse);
    } catch (e, st) {
      debugPrint('❌ Error fetching registration details: $e');
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error fetching resident details: $e')),
      );
      return;
    }

    final String headBarangay = (registrationData?['Barangay'] ?? '')
        .toString();

    final Map<String, Map<String, dynamic>> familyMemberByName = {};
    for (final member in familyMembers) {
      final memberName = (member['Family_Member'] ?? '').toString().trim();
      if (memberName.isNotEmpty) {
        familyMemberByName[normalizeName(memberName)] = member;
      }
    }

    final List<Map<String, Object?>> dischargeInserts = [];

    for (final row in currentSiteRows) {
      final relation = (row['Relation'] ?? '').toString();
      final memberName = (row['Family_Member'] ?? '').toString().trim();
      final matchedFamilyData = familyMemberByName[normalizeName(memberName)];

      if (relation == 'Head of Family') {
        final headEntry = <String, Object?>{
          'UID': uid,
          'Registration_ID': registrationId,
          'Family_Member': memberName,
          'Relation': 'Head of Family',
          'Age': row['Age'] ?? registrationData?['Head_Age'] ?? 0,
          'Gender': row['Gender'] ?? registrationData?['Head_Sex'] ?? '',
          'Civil_Status':
              row['Civil_Status'] ?? registrationData?['Civil_Status'] ?? '',
          'Education': row['Education'] ?? registrationData?['Education'] ?? '',
          'Occupational_Skills':
              row['Occupational_Skills'] ??
              registrationData?['Occupation'] ??
              '',
          'Remarks': row['Remarks'] ?? 'Head of family entry',
          'Code': row['Code'] ?? '',
          'Head_Surname': registrationData?['Head_Surname'] ?? '',
          'Head_Firstname': registrationData?['Head_Firstname'] ?? '',
          'Head_Middlename': registrationData?['Head_Middlename'] ?? '',
          'Head_Occupation': registrationData?['Occupation'] ?? '',
          'Head_Monthly_Income': registrationData?['Monthly_Income'] ?? 0.0,
          'City': registrationData?['City'] ?? '',
          'Municipality': registrationData?['Municipality'] ?? '',
          'Barangay': headBarangay,
          'Site': row['Site'] ?? currentSiteName,
          'BirthDate': row['Date_of_Birth'],
          'Date_Transferred': now,
          'Time_Deployed': timeDeployed,
          'Time_Discharge': formattedTimeDischarge,
          '4Ps_Families': fourPsFamilies,
        };
        dischargeInserts.add(headEntry);
      } else {
        final familyEntry = <String, Object?>{
          'UID': uid,
          'Registration_ID': registrationId,
          'Family_Member': memberName,
          'Relation': relation,
          'Age': row['Age'] ?? matchedFamilyData?['Age'] ?? 0,
          'Gender': row['Gender'] ?? matchedFamilyData?['Gender'] ?? '',
          'Civil_Status':
              row['Civil_Status'] ?? matchedFamilyData?['Civil_Status'] ?? '',
          'Education':
              row['Education'] ?? matchedFamilyData?['Education'] ?? '',
          'Occupational_Skills':
              row['Occupational_Skills'] ??
              matchedFamilyData?['Occupational_Skills'] ??
              '',
          'Remarks': row['Remarks'] ?? matchedFamilyData?['Remarks'] ?? '',
          'Code': row['Code'] ?? matchedFamilyData?['Code'] ?? '',
          'Barangay': headBarangay,
          'Site': row['Site'] ?? currentSiteName,
          'BirthDate': row['Date_of_Birth'],
          'Date_Transferred': now,
          'Time_Deployed': timeDeployed,
          'Time_Discharge': formattedTimeDischarge,
          '4Ps_Families': fourPsFamilies,
        };
        dischargeInserts.add(familyEntry);
      }
    }

    try {
      await supabase.from('Discharge_Resident').insert(dischargeInserts);

      await supabase
          .from('Evacuation_A')
          .delete()
          .eq('UID', uid)
          .eq('Site', currentSiteName);

      await supabase
          .from('Evacuation_B')
          .delete()
          .eq('UID', uid)
          .eq('Site', currentSiteName);

      if (!mounted) return;

      await _showDischargeSuccessDialog(context, dischargedNames);
    } catch (e, st) {
      debugPrint('❌ Error discharging resident: $e');
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error discharging resident: $e')),
      );
    }
  }

  Future<void> _showDischargeSuccessDialog(
    BuildContext ctx,
    List<String> dischargedNames,
  ) async {
    if (!ctx.mounted) return;

    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D743D).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF0D743D),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Residents Discharged',
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'The following selected residents were discharged from $currentSiteName.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 140),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: _buildNameChips(
                        dischargedNames.toSet().toList(),
                        bgColor: const Color(0xFFE8F5EC),
                        textColor: const Color(0xFF0D743D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dCtx).pop();
                        Navigator.pushReplacement(
                          ctx,
                          MaterialPageRoute(
                            builder: (context) =>
                                const WebDischargeDashboardPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        backgroundColor: const Color(0xFF0D743D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                          fontSize: 12.8,
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
      },
    );
  }

  Widget _buildTopSummaryCard() {
    final selectedCount = selected.values.where((v) => v).length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D743D), Color(0xFF169B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D743D).withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 420,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Magsaysay Evacuation Center',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the family head to discharge the residents currently assigned to this site.',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12.6,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMiniStat('Families', residents.length.toString()),
              _buildMiniStat('Selected', selectedCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.88),
              fontSize: 11.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0D743D).withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0D743D)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$count member${count == 1 ? '' : 's'}',
        style: GoogleFonts.poppins(
          fontSize: 11.4,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0D743D),
        ),
      ),
    );
  }

  Widget _buildFamilyCard(
    Map<String, dynamic> r,
    List<String> family,
    bool isExpanded,
    bool isSelected,
    int index,
    bool isWide,
  ) {
    final displayName = (r['Family_Member'] ?? 'N/A').toString();
    final ageText = (r['Age'] ?? 'N/A').toString();
    final genderText = (r['Gender'] ?? 'N/A').toString();
    final siteText = (r['Site'] ?? 'N/A').toString();
    final familyCount = family.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF2FAF5) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0D743D).withOpacity(0.22)
              : Colors.grey.withOpacity(0.10),
          width: isSelected ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: isExpanded ? 210 : 138,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0D743D)
                  : const Color(0xFF0D743D).withOpacity(0.10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) => _toggleSelect(index),
                        activeColor: const Color(0xFF0D743D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D743D).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF0D743D),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildFamilyCountBadge(familyCount),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D743D),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Selected',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 10),
                                _buildInfoPill(
                                  Icons.cake_outlined,
                                  'Age: $ageText',
                                ),
                                const SizedBox(width: 8),
                                _buildInfoPill(
                                  Icons.person_outline,
                                  'Gender: $genderText',
                                ),
                                const SizedBox(width: 8),
                                _buildInfoPill(Icons.place_outlined, siteText),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withOpacity(0.10),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _toggle(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? const Color(0xFF0D743D).withOpacity(0.08)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF0D743D),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpanded
                                  ? "Hide Family Members"
                                  : "Show Family Members",
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: family.isEmpty
                          ? Text(
                              "No family members found",
                              style: GoogleFonts.poppins(
                                fontSize: 12.8,
                                color: Colors.black87,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: family.map((m) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.14),
                                    ),
                                  ),
                                  child: Text(
                                    m,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.2,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = selected.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F4),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF0D743D),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Magsaysay Evacuation Center Residents",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text(
              allSelected ? "Deselect All" : "Select All",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.8,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D743D),
        elevation: 3,
        icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
        label: Text(
          selectedCount > 0 ? "Discharge ($selectedCount)" : "Discharge",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        onPressed: _dischargeSelectedResidents,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTopSummaryCard(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;

                        if (residents.isEmpty) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.10),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F7F5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.groups_outlined,
                                      size: 30,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No residents found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'There are no families currently assigned to this site.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.8,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: residents.length,
                          itemBuilder: (context, index) {
                            final r = residents[index];
                            final regId = r['Registration_ID'].toString();
                            final family = familyMembersCache[regId] ?? [];
                            final isExpanded = expanded[index] ?? false;
                            final isSelected = selected[index] ?? false;

                            return _buildFamilyCard(
                              r,
                              family,
                              isExpanded,
                              isSelected,
                              index,
                              isWide,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
