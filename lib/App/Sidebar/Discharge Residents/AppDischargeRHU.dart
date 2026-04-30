// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously

import 'package:evacutaion/App/Sidebar/Discharge%20Residents/DischargeResidentScanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSantaRHUResidentsPage extends StatefulWidget {
  const AppSantaRHUResidentsPage({super.key});

  @override
  State<AppSantaRHUResidentsPage> createState() =>
      _AppSantaRHUResidentsPageState();
}

class _AppSantaRHUResidentsPageState extends State<AppSantaRHUResidentsPage> {
  static const String currentSiteName = 'Santa RHU';

  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> residents = [];
  bool isLoading = true;
  bool _isDischarging = false;

  Map<int, bool> expanded = {};
  Map<int, bool> selected = {};
  Map<String, List<Map<String, dynamic>>> codeMembersMap = {};
  Map<String, Map<String, dynamic>> registrationDetailsCache = {};

  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    _fetchResidents();
  }

  @override
  void dispose() {
    expanded.clear();
    selected.clear();
    codeMembersMap.clear();
    registrationDetailsCache.clear();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ================= FETCH RESIDENTS =================

  Future<void> _fetchResidents() async {
    if (!mounted) return;

    _safeSetState(() {
      isLoading = true;
    });

    try {
      final evacA = await supabase
          .from('Evacuation_A')
          .select(
            'UID, Registration_ID, Family_Member, Relation, Age, Gender, Code, Site',
          )
          .eq('Site', currentSiteName);

      final evacB = await supabase
          .from('Evacuation_B')
          .select(
            'UID, Registration_ID, Family_Member, Relation, Age, Gender, Code, Site',
          )
          .eq('Site', currentSiteName);

      final combined = [
        ...List<Map<String, dynamic>>.from(evacA),
        ...List<Map<String, dynamic>>.from(evacB),
      ];

      final List<Map<String, dynamic>> assigned = [];
      final Map<String, List<Map<String, dynamic>>> nextCodeMembersMap = {};

      for (final res in combined) {
        final regId = (res['Registration_ID'] ?? '').toString();
        final code = (res['Code'] ?? '').toString();

        if (regId.isEmpty) continue;

        nextCodeMembersMap.putIfAbsent(regId, () => []).add(res);

        if (code == 'Assign') {
          assigned.add(res);
        }
      }

      if (!mounted) return;

      _safeSetState(() {
        residents = assigned;
        codeMembersMap = nextCodeMembersMap;
        selected.clear();
        expanded.clear();
        allSelected = false;
        isLoading = false;
      });

      for (final resident in assigned) {
        final uid = resident['UID']?.toString() ?? '';
        final regId = resident['Registration_ID']?.toString() ?? '';

        if (uid.isNotEmpty && regId.isNotEmpty) {
          _fetchRegistrationDetails(uid, regId);
        }
      }
    } catch (e, st) {
      debugPrint('❌ Error fetching RHU residents: $e');
      debugPrint('$st');

      if (!mounted) return;

      _safeSetState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching residents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchRegistrationDetails(String uid, String regId) async {
    try {
      final registrationResponse = await supabase
          .from('Registration_Table')
          .select('*')
          .eq('UID', uid)
          .maybeSingle();

      final familyResponse =
          await supabase.from('Family_Members').select('*').eq('UID', uid);

      if (!mounted) return;

      if (registrationResponse != null) {
        _safeSetState(() {
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

  // ================= SELECTION =================

  void _toggle(int index) {
    _safeSetState(() {
      expanded[index] = !(expanded[index] ?? false);
    });
  }

  void _toggleSelect(int index) {
    _safeSetState(() {
      selected[index] = !(selected[index] ?? false);

      allSelected = residents.isNotEmpty &&
          List.generate(residents.length, (i) => selected[i] ?? false)
              .every((value) => value);
    });
  }

  void _toggleSelectAll() {
    if (residents.isEmpty) return;

    _safeSetState(() {
      allSelected = !allSelected;

      for (int i = 0; i < residents.length; i++) {
        selected[i] = allSelected;
      }
    });
  }

  // ================= HELPERS =================

  Future<List<Map<String, dynamic>>> _fetchAllEvacRowsByUid(String uid) async {
    final evacA =
        await supabase.from('Evacuation_A').select('*').eq('UID', uid);

    final evacB =
        await supabase.from('Evacuation_B').select('*').eq('UID', uid);

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

  List<String> _selectedInChargeNames(
    List<Map<String, dynamic>> selectedResidents,
  ) {
    final List<String> names = [];

    for (final resident in selectedResidents) {
      final regId = (resident['Registration_ID'] ?? '').toString();
      final allFamily = codeMembersMap[regId] ?? [];

      final assignMember = allFamily.firstWhere(
        (m) => (m['Code'] ?? '').toString() == 'Assign',
        orElse: () => resident,
      );

      final name = (assignMember['Family_Member'] ?? 'N/A').toString().trim();

      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }

    return names;
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
      final uid = resident['UID']?.toString() ?? '';
      final familyName = (resident['Family_Member'] ?? 'Resident').toString();

      if (uid.isEmpty) continue;

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

  String _formatDateTime(DateTime dateTime) {
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

  // ================= DIALOGS =================

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
                      'Some selected families have members assigned to another site. Only the members currently in $currentSiteName will be discharged.',
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

  Future<bool?> _showConfirmationDialog(
    List<String> selectedNames,
    List<String> inChargeNames,
  ) async {
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
                  constraints: const BoxConstraints(maxHeight: 120),
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
                    'Who is in charge:',
                    style: GoogleFonts.poppins(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 100),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: _buildNameChips(
                      inChargeNames,
                      bgColor: const Color(0xFFEAF3FF),
                      textColor: const Color(0xFF1D4ED8),
                    ),
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

  Future<void> _showNoMembersInSiteDialog() async {
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
  }

  Future<void> _showDischargeSuccessDialog(
    BuildContext ctx,
    List<String> dischargedNames,
    List<String> dischargedInChargeNames,
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
                    constraints: const BoxConstraints(maxHeight: 120),
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Who is in charge:',
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 100),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: _buildNameChips(
                        dischargedInChargeNames.toSet().toList(),
                        bgColor: const Color(0xFFEAF3FF),
                        textColor: const Color(0xFF1D4ED8),
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
                            builder: (context) => const DischargeScanQrPage(),
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

  // ================= DISCHARGE =================

  Future<void> _dischargeSelectedResidents() async {
    if (!mounted || _isDischarging) return;

    final selectedResidents = selected.entries
        .where((e) => e.value && e.key < residents.length)
        .map((e) => residents[e.key])
        .toList();

    if (selectedResidents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one resident to discharge."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final splitMap = await _getSplitFamilyWarnings(selectedResidents);

    if (!mounted) return;

    if (splitMap.isNotEmpty) {
      final proceed = await _showSplitFamilyWarningDialog(splitMap);

      if (!mounted) return;
      if (proceed != true) return;
    }

    final selectedNames = _selectedResidentNames(selectedResidents);
    final inChargeNames = _selectedInChargeNames(selectedResidents);

    final confirmed = await _showConfirmationDialog(
      selectedNames,
      inChargeNames,
    );

    if (!mounted) return;
    if (confirmed != true) return;

    _safeSetState(() {
      _isDischarging = true;
    });

    final List<String> dischargedNames = [];
    final List<String> dischargedInChargeNames = [];

    for (final resident in selectedResidents) {
      if (!mounted) return;

      final uid = resident['UID']?.toString() ?? '';
      final regId = resident['Registration_ID']?.toString() ?? '';

      if (uid.isEmpty || regId.isEmpty) continue;

      final allFamily = codeMembersMap[regId] ?? [];

      final assignMember = allFamily.firstWhere(
        (m) => (m['Code'] ?? '').toString() == 'Assign',
        orElse: () => resident,
      );

      final assignName =
          (assignMember['Family_Member'] ?? 'N/A').toString().trim();

      if (assignName.isNotEmpty &&
          !dischargedInChargeNames.contains(assignName)) {
        dischargedInChargeNames.add(assignName);
      }

      if (assignName.isNotEmpty && !dischargedNames.contains(assignName)) {
        dischargedNames.add(assignName);
      }

      final didDischarge = await _dischargeResidents(regId, uid);

      if (!didDischarge) {
        dischargedNames.remove(assignName);
        dischargedInChargeNames.remove(assignName);
      }
    }

    if (!mounted) return;

    _safeSetState(() {
      _isDischarging = false;
    });

    if (dischargedNames.isNotEmpty) {
      await _showDischargeSuccessDialog(
        context,
        dischargedNames,
        dischargedInChargeNames,
      );
    } else {
      await _fetchResidents();
    }

    if (!mounted) return;

    _safeSetState(() {
      selected.clear();
      expanded.clear();
      allSelected = false;
    });
  }

  Future<bool> _dischargeResidents(String registrationId, String uid) async {
    if (!mounted) return false;

    final nowDateTime = DateTime.now();
    final now = nowDateTime.toIso8601String();
    final formattedTimeDischarge = _formatDateTime(nowDateTime);

    List<Map<String, dynamic>> currentSiteRows = [];

    try {
      final evacAAll =
          await supabase.from('Evacuation_A').select('*').eq('UID', uid);

      final evacBAll =
          await supabase.from('Evacuation_B').select('*').eq('UID', uid);

      final allRows = [
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

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error fetching evacuation rows: $e'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }

    if (currentSiteRows.isEmpty) {
      if (!mounted) return false;
      await _showNoMembersInSiteDialog();
      return false;
    }

    final String timeDeployed =
        (currentSiteRows.first['Time_Deployed'] ?? '').toString();

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

    if (!mounted) return false;

    final dynamic rawA = evacAHead?['4Ps_Families'];
    final dynamic rawB = evacBHead?['4Ps_Families'];
    final bool fourPsFamilies = _toBool(rawA) || _toBool(rawB);

    Map<String, dynamic>? registrationData;
    List<Map<String, dynamic>> familyMembers = [];

    try {
      registrationData = await supabase
          .from('Registration_Table')
          .select('*')
          .eq('UID', uid)
          .maybeSingle();

      final familyResponse =
          await supabase.from('Family_Members').select('*').eq('UID', uid);

      familyMembers = List<Map<String, dynamic>>.from(familyResponse);
    } catch (e, st) {
      debugPrint('❌ Error fetching registration details: $e');
      debugPrint('$st');

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error fetching resident details: $e'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }

    final String headBarangay =
        (registrationData?['Barangay'] ?? '').toString();

    final Map<String, Map<String, dynamic>> familyMemberByName = {};

    for (final member in familyMembers) {
      final memberName = (member['Family_Member'] ?? '').toString().trim();

      if (memberName.isNotEmpty) {
        familyMemberByName[_normalizeName(memberName)] = member;
      }
    }

    final List<Map<String, Object?>> dischargeInserts = [];

    for (final row in currentSiteRows) {
      final relation = (row['Relation'] ?? '').toString();
      final memberName = (row['Family_Member'] ?? '').toString().trim();
      final matchedFamilyData =
          familyMemberByName[_normalizeName(memberName)];

      if (relation == 'Head of Family') {
        dischargeInserts.add({
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
        });
      } else {
        dischargeInserts.add({
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
        });
      }
    }

    try {
      if (dischargeInserts.isNotEmpty) {
        await supabase.from('Discharge_Resident').insert(dischargeInserts);
      }

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

      return true;
    } catch (e, st) {
      debugPrint('❌ Error discharging resident: $e');
      debugPrint('$st');

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error discharging resident: $e'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }
  }

  // ================= UI HELPERS =================

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
                    Icons.local_hospital_outlined,
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
                        'Santa RHU',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the assigned person to discharge residents currently assigned to this site.',
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
              _buildMiniStat('Assigned', residents.length.toString()),
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

  Widget _buildAssignedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Assigned',
        style: GoogleFonts.poppins(
          fontSize: 11.4,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0D743D),
        ),
      ),
    );
  }

  Widget _buildCodeBadge(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        code,
        style: GoogleFonts.poppins(
          fontSize: 11.3,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1D4ED8),
        ),
      ),
    );
  }

  Widget _buildFamilyCard(
    Map<String, dynamic> head,
    List<Map<String, dynamic>> assignedPersons,
    bool isExpanded,
    bool isSelected,
    int index,
  ) {
    final assignMember = assignedPersons.firstWhere(
      (m) => (m['Code'] ?? '').toString() == 'Assign',
      orElse: () => head,
    );

    final codeMembers = assignedPersons
        .where(
          (m) =>
              (m['Code'] ?? '').toString().isNotEmpty &&
              (m['Code'] ?? '').toString() != 'Assign',
        )
        .toList();

    final displayName = (assignMember['Family_Member'] ?? 'N/A').toString();
    final ageText = (assignMember['Age'] ?? 'N/A').toString();
    final genderText = (assignMember['Gender'] ?? 'N/A').toString();
    final siteText = (head['Site'] ?? 'N/A').toString();

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
                        onChanged: (_) => _toggleSelect(index),
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
                          Icons.local_hospital,
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
                                _buildAssignedBadge(),
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
                  if (codeMembers.isNotEmpty)
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
                                    ? "Hide Assigned Person"
                                    : "Show Assigned Person",
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
                  if (isExpanded && codeMembers.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: codeMembers.map((m) {
                          final memberName =
                              (m['Family_Member'] ?? 'N/A').toString();

                          final memberCode = (m['Code'] ?? '').toString();

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.14),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  memberName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.2,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (memberCode.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  _buildCodeBadge(memberCode),
                                ],
                              ],
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

  // ================= UI =================

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
          onPressed: _isDischarging ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Discharge RHU",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isDischarging ? null : _toggleSelectAll,
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
      floatingActionButton: residents.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor:
                  _isDischarging ? Colors.grey : const Color(0xFF0D743D),
              elevation: 3,
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
                _isDischarging
                    ? "Discharging..."
                    : selectedCount > 0
                        ? "Discharge ($selectedCount)"
                        : "Discharge",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: _isDischarging ? null : _dischargeSelectedResidents,
            ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0D743D),
                    ),
                  )
                : Column(
                    children: [
                      _buildTopSummaryCard(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
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
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          Icons.local_hospital_outlined,
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
                                        'There are no assigned residents currently listed in Santa RHU.',
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

                            return RefreshIndicator(
                              color: const Color(0xFF0D743D),
                              onRefresh: _fetchResidents,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 90),
                                itemCount: residents.length,
                                itemBuilder: (context, index) {
                                  final head = residents[index];
                                  final regId =
                                      head['Registration_ID']?.toString() ??
                                          '';

                                  final assignedPersons =
                                      codeMembersMap[regId] ?? [];

                                  final isExpanded =
                                      expanded[index] ?? false;

                                  final isSelected =
                                      selected[index] ?? false;

                                  return _buildFamilyCard(
                                    head,
                                    assignedPersons,
                                    isExpanded,
                                    isSelected,
                                    index,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          if (_isDischarging)
            Container(
              color: Colors.black.withOpacity(0.10),
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
                      const CircularProgressIndicator(
                        color: Color(0xFF0D743D),
                      ),
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
      ),
    );
  }
}