import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge Function/WebDischargeScanner.dart';

class WebSantaNationalHighSchoolResidentsPage extends StatefulWidget {
  const WebSantaNationalHighSchoolResidentsPage({super.key});

  @override
  State<WebSantaNationalHighSchoolResidentsPage> createState() =>
      _WebSantaNationalHighSchoolResidentsPagePageState();
}

class _WebSantaNationalHighSchoolResidentsPagePageState
    extends State<WebSantaNationalHighSchoolResidentsPage> {
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

  // ================= FETCH RESIDENTS =================
  Future<void> _fetchResidents() async {
    final supabase = Supabase.instance.client;

    try {
      final evacA = await supabase
          .from('Evacuation_A')
          .select()
          .eq('Site', 'Santa National High School');

      final evacB = await supabase
          .from('Evacuation_B')
          .select()
          .eq('Site', 'Santa National High School');

      final combined = [...evacA, ...evacB];

      final Map<String, Map<String, dynamic>> headMap = {};
      final Map<String, List<String>> familyMap = {};

      for (var resident in combined) {
        final regId = resident['Registration_ID'].toString();
        final relation = resident['Relation'].toString();
        final name = resident['Family_Member'].toString();

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
        familyMembersCache[regId] = familyMap[regId] ?? [];

        // Optional: fetch full registration & family members for discharge logic
        _fetchRegistrationDetails(entry.value['UID'].toString(), regId);
      }

      setState(() {
        residents = headsList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching residents: $e');
      setState(() => isLoading = false);
    }
  }

  // ================= FETCH REGISTRATION DETAILS (CACHED) =================
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

      if (registrationResponse != null) {
        registrationDetailsCache[regId] = {
          'registration': registrationResponse,
          'family': familyResponse ?? [],
        };
        debugPrint('✅ Registration data cached for $regId');
      }
    } catch (e) {
      debugPrint('❌ Error fetching registration details for $regId: $e');
    }
  }

  // ================= SELECTION HANDLERS =================
  void _toggle(int index) =>
      setState(() => expanded[index] = !(expanded[index] ?? false));
  void _toggleSelect(int index) =>
      setState(() => selected[index] = !(selected[index] ?? false));
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      for (int i = 0; i < residents.length; i++) {
        selected[i] = allSelected;
      }
    });
  }

  // ================= DISCHARGE SELECTED RESIDENTS =================
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

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      selectedResidents.length,
      selectedResidents.first['Family_Member']?.toString() ?? 'Resident',
    );

    if (confirmed != true) return;

    // Discharge each selected resident
    for (var resident in selectedResidents) {
      final uid = resident['UID'].toString();
      final regId = resident['Registration_ID'].toString();
      await _dischargeResidents(regId, uid);
    }

    // Refresh list and clear selection
    await _fetchResidents();
    if (mounted) {
      setState(() {
        selected.clear();
        allSelected = false;
      });
    }
  }

  // ================= CONFIRMATION DIALOG =================
  Future<bool?> _showConfirmationDialog(int count, String residentName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange[100],
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 40,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Confirm Discharge',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Are you sure you want to discharge ',
                          ),
                          TextSpan(
                            text: count == 1
                                ? residentName
                                : '$count resident${count > 1 ? 's' : ''}',
                            style: const TextSpan(
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D743D),
                              ),
                            ).style,
                          ),
                          const TextSpan(
                            text: '?\n\nThis action cannot be undone.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Buttons
              Row(
                children: [
                  // No Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'No, Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Yes Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D743D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Yes, Discharge',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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
  }

  Future<void> _dischargeResidents(String registrationId, String uid) async {
    if (!mounted) return;
    final supabase = Supabase.instance.client;

    final now = DateTime.now().toUtc().toIso8601String();

    // Step 1: Check if residents are currently in Evacuation_A or Evacuation_B
    final evacAData = await supabase
        .from('Evacuation_A')
        .select('*')
        .eq('UID', uid)
        .limit(1)
        .maybeSingle();

    final evacBData = await supabase
        .from('Evacuation_B')
        .select('*')
        .eq('UID', uid)
        .limit(1)
        .maybeSingle();

    if (evacAData == null && evacBData == null) {
      // Residents are not in evacuation tables, meaning already discharged
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
                        color: Colors.orange.withOpacity(0.15),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 65,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Resident Already Discharged',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This resident has already been discharged.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dCtx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.orange,
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
      return; // Exit without discharging
    }

    // Step 2: Fetch registration details and family members
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

      if (familyResponse != null) {
        familyMembers = List<Map<String, dynamic>>.from(familyResponse);
      }

      debugPrint(
        '✅ Fetched registration data and ${familyMembers.length} family members for UID: $uid',
      );
    } catch (e) {
      debugPrint('❌ Error fetching registration details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error fetching resident details: $e')),
        );
      }
      return;
    }

    // Step 3: Delete existing entries from Evacuation_A and Evacuation_B
    try {
      await supabase.from('Evacuation_A').delete().eq('UID', uid);
      await supabase.from('Evacuation_B').delete().eq('UID', uid);
      debugPrint(
        '🧹 Removed residents from Evacuation_A and Evacuation_B for UID: $uid',
      );
    } catch (e) {
      debugPrint('⚠️ Error deleting from Evacuation tables: $e');
    }

    // Step 4: Build discharge entries
    final List<Map<String, Object>> dischargeInserts = [];

    // Build head of family entry from registration data
    if (registrationData != null) {
      final headFullName =
          '${registrationData['Head_Surname'] ?? ''} ${registrationData['Head_Firstname'] ?? ''} ${registrationData['Head_Middlename'] ?? ''}'
              .trim();

      final headEntry = <String, Object>{
        'UID': uid,
        'Registration_ID': registrationId,
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
    for (var member in familyMembers) {
      final familyEntry = <String, Object>{
        'UID': uid,
        'Registration_ID': registrationId,
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

    // Step 5: Insert into Discharge_Resident
    try {
      await supabase.from('Discharge_Resident').insert(dischargeInserts);
      if (mounted) {
        await _showDischargeSuccessDialog(
          context,
          registrationData?['Head_Firstname'] ?? 'Resident',
          dischargeInserts.length,
        );
      }
    } catch (e) {
      debugPrint('❌ Error inserting into Discharge_Resident: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error discharging resident: $e')),
        );
      }
    }
  }

  Future<void> _showDischargeSuccessDialog(
    BuildContext ctx,
    dynamic residentName,
    int totalMembers,
  ) async {
    if (!ctx.mounted) return;

    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    color: const Color(0xFF0D743D).withOpacity(0.15),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF0D743D),
                      size: 65,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Successfully Discharged',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$residentName and $totalMembers member(s) discharged.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        backgroundColor: const Color(0xFF0D743D),
        title: Text(
          "Farmers Covered Court Residents",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D743D),
        icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
        label: Text(
          "Discharge",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        onPressed: _dischargeSelectedResidents,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;

                  return ListView.builder(
                    itemCount: residents.length,
                    itemBuilder: (context, index) {
                      final r = residents[index];
                      final regId = r['Registration_ID'].toString();
                      final family = familyMembersCache[regId] ?? [];
                      final isExpanded = expanded[index] ?? false;
                      final isSelected = selected[index] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green[50] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ===== HEADER =====
                            isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) =>
                                            _toggleSelect(index),
                                        activeColor: const Color(0xFF0D743D),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.person,
                                        color: Color(0xFF0D743D),
                                        size: 26,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 20,
                                          runSpacing: 6,
                                          children: [
                                            Text(
                                              r['Family_Member'] ?? 'N/A',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              "Age: ${r['Age'] ?? 'N/A'}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              "Gender: ${r['Gender'] ?? 'N/A'}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Site",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            r['Site'] ?? 'N/A',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (val) =>
                                                _toggleSelect(index),
                                            activeColor: const Color(
                                              0xFF0D743D,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.person,
                                            color: Color(0xFF0D743D),
                                            size: 26,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              r['Family_Member'] ?? 'N/A',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 16,
                                        children: [
                                          Text(
                                            "Age: ${r['Age'] ?? 'N/A'}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "Gender: ${r['Gender'] ?? 'N/A'}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Site: ${r['Site'] ?? 'N/A'}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),

                            const SizedBox(height: 10),

                            // ===== TOGGLE FAMILY MEMBERS =====
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _toggle(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isExpanded
                                          ? "Hide Family Members"
                                          : "Show Family Members",
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (isExpanded)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: family.isEmpty
                                    ? Text(
                                        "No family members found",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: family
                                            .map(
                                              (m) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 3,
                                                    ),
                                                child: Text(
                                                  "• $m",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
