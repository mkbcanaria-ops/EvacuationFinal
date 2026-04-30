// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, unused_import, unused_field
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShowRegistrationPage extends StatelessWidget {
  const ShowRegistrationPage({super.key, required this.uid});
  final String uid; // ✅ add UID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true,
        title: Text(
          'Registration Page',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: ShowRegistrationPageFormWidget(uid: uid), // pass UID to form
    );
  }
}

class ShowRegistrationPageFormWidget extends StatefulWidget {
  final String uid;

  const ShowRegistrationPageFormWidget({super.key, required this.uid});

  @override
  State<ShowRegistrationPageFormWidget> createState() =>
      _ShowRegistrationPageFormWidgetState();
}

class _ShowRegistrationPageFormWidgetState
    extends State<ShowRegistrationPageFormWidget> {
  final TransformationController _controller = TransformationController();

  // Zoom / fitted-view settings
  static const double _formWidth = 1760.0; // wide enough for the full table
  double _fitScale = 0.4;
  final double _minScale = 0.12;
  final double _maxScale = 4.0;
  final double _zoomStep = 0.15;
  bool _zoomInitialized = false;

  // Controllers
  final TextEditingController _disasterController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
  );
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _munController = TextEditingController();
  final TextEditingController _brgyController = TextEditingController();
  final TextEditingController _evacBrgyController = TextEditingController();
  final TextEditingController _evacCenterController = TextEditingController();
  final TextEditingController _evacSiteController = TextEditingController();
  final TextEditingController _civilOtherController = TextEditingController();
  // -------------------- CONTROLLERS --------------------
  final TextEditingController _headSurnameController = TextEditingController();
  final TextEditingController _headFirstController = TextEditingController();
  final TextEditingController _headMiddleController = TextEditingController();
  final TextEditingController _headAgeController = TextEditingController();
  final TextEditingController _headSexController =
      TextEditingController(); // Holds "M" or "F"
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  // -------------------- CONTROLLERS --------------------
  final List<Map<String, TextEditingController>> _familyRows = [];
  final TextEditingController _dateRegisteredController =
      TextEditingController();
  File? imageFile;
  Uint8List? _headImageBytes; // 👈 to store downloaded image
  String? _headImageUrl; // 👈 optional, to hold Supabase URL
  File? _headImageFile; // New image picked from gallery
  double _baseScale = 1.0; // kept for compatibility with old gesture variables
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  bool _isMousePanning = false;
  int? _activePointer;
  final double _contentWidth =
      _formWidth; // kept for compatibility with old fields
  bool _didCenterOnce = false;

  // Civil Status
  bool _single = false;
  bool _married = false;
  bool _widowed = false;
  bool _is4PsBeneficiary = false;
  bool _isIP = false;
  TextEditingController _ipTypeController = TextEditingController();
  String _formatMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat(
      'MMMM dd, yyyy • hh:mm a',
    ).format(DateTime.now());
    for (int i = 0; i < 5; i++) {
      _familyRows.add({
        'name': TextEditingController(),
        'relation': TextEditingController(),
        'birthdate': TextEditingController(), // ✅ NEW DOB CONTROLLER
        'age': TextEditingController(),
        'gender': TextEditingController(),
        'civilStatus': TextEditingController(),
        'education': TextEditingController(),
        'skills': TextEditingController(),
        'remarks': TextEditingController(),
        'code': TextEditingController(),
      });
    }
    _fetchRegistrationDetails();
  }

  double _calculateFitScale(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;

    // Fit by width so the form is readable and not too zoomed out.
    final widthScale = (screenWidth - 20) / _formWidth;
    return widthScale.clamp(_minScale, _maxScale).toDouble();
  }

  Matrix4 _buildFitMatrix(BoxConstraints constraints, double scale) {
    final screenWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;

    final scaledWidth = _formWidth * scale;
    final dx = math.max((screenWidth - scaledWidth) / 2, 0).toDouble();

    return Matrix4.identity()
      ..translate(dx, 0.0)
      ..scale(scale);
  }

  void _initializeZoom(BoxConstraints constraints) {
    final scale = _calculateFitScale(constraints);
    _fitScale = scale;

    if (_zoomInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _controller.value = _buildFitMatrix(constraints, _fitScale);
        _zoomInitialized = true;
      });
    });
  }

  void _setZoomScale(double newScale) {
    final currentMatrix = Matrix4.copy(_controller.value);
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    if (currentScale == 0) return;

    final ratio = newScale / currentScale;

    setState(() {
      _controller.value = currentMatrix..scale(ratio);
    });
  }

  void _zoomIn() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final newScale = (currentScale + _zoomStep).clamp(_minScale, _maxScale);
    _setZoomScale(newScale.toDouble());
  }

  void _zoomOut() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final newScale = (currentScale - _zoomStep).clamp(_minScale, _maxScale);
    _setZoomScale(newScale.toDouble());
  }

  void _resetZoom() {
    final size = MediaQuery.of(context).size;

    final constraints = BoxConstraints(
      maxWidth: size.width,
      maxHeight: size.height,
    );

    setState(() {
      _fitScale = _calculateFitScale(constraints);
      _controller.value = _buildFitMatrix(constraints, _fitScale);
    });
  }

  Future<void> _updateRegisterSave() async {
    try {
      final supabase = Supabase.instance.client;

      print('🧩 Updating registration...');
      print('🧩 Date of Occurrence: ${_dateController.text}');
      print('🧩 Selected Evacuation Site: ${_evacSiteController.text}');

      // Step 1: Fetch existing image
      final existingRecord = await supabase
          .from('Registration_Table')
          .select('Head_Image')
          .eq('UID', widget.uid)
          .maybeSingle();

      String? oldImagePath = existingRecord?['Head_Image'];
      String? newImagePath;

      // Step 2: Upload new image if selected
      if (_headImageBytes != null) {
        final bucket = supabase.storage.from('headimage');

        // Delete old image
        if (oldImagePath != null && oldImagePath.isNotEmpty) {
          try {
            await bucket.remove([oldImagePath]);
            debugPrint('🧹 Old image deleted: $oldImagePath');
          } catch (e) {
            debugPrint('⚠️ Could not delete old image: $e');
          }
        }

        // Upload new image using bytes (compatible with Flutter Web)
        final fileName =
            '${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await bucket.uploadBinary(
          fileName,
          _headImageBytes!,
          fileOptions: const FileOptions(upsert: false),
        );

        newImagePath = fileName;
        debugPrint('✅ New image uploaded: $newImagePath');
      }

      // Step 3: Prepare updated registration data
      final updateData = {
        'Head_Firstname': _headFirstController.text,
        'Head_Middlename': _headMiddleController.text,
        'Head_Surname': _headSurnameController.text,
        'Head_Age': int.tryParse(_headAgeController.text) ?? 0,
        'Head_Sex': _headSexController.text,
        'Date_of_Birth': _dobController.text,
        'Occupation': _occupationController.text,
        'Monthly_Income': double.tryParse(_monthlyIncomeController.text) ?? 0,
        'Type_of_Disaster': _disasterController.text,
        'Date_of_Occurrence': _dateController.text,
        'City': _cityController.text,
        'Municipality': _munController.text,
        'Barangay': _brgyController.text.trim(),
        'Site': _evacSiteController.text,
        'Civil_Status': _single
            ? 'Single'
            : _married
            ? 'Married'
            : _widowed
            ? 'Widowed'
            : _civilOtherController.text,
        '4Ps_Beneficiary': _is4PsBeneficiary,
        'IP': _isIP,
        'IP_Type_of_Ethnicity': _ipTypeController.text,
        if (newImagePath != null) 'Head_Image': newImagePath,
      };

      // Step 4: Update Registration table
      await supabase
          .from('Registration_Table')
          .update(updateData)
          .eq('UID', widget.uid);

      // Step 5: Refresh Family Members
      final registrationData = await supabase
          .from('Registration_Table')
          .select('Registration_ID')
          .eq('UID', widget.uid)
          .maybeSingle();

      if (registrationData == null) {
        throw Exception("Registration not found for UID: ${widget.uid}");
      }

      final registrationId = registrationData['Registration_ID'];

      // Delete previous family members
      await supabase.from('Family_Members').delete().eq('UID', widget.uid);

      // Insert updated family members (only non-empty rows)
      final List<Map<String, dynamic>> newFamilyMembers = [];
      for (var row in _familyRows) {
        bool hasData = [
          row['name']?.text,
          row['relation']?.text,
          row['birthdate']?.text,
          row['gender']?.text,
          row['civilStatus']?.text,
          row['education']?.text,
          row['skills']?.text,
          row['remarks']?.text,
          row['code']?.text,
        ].any((field) => field != null && field.trim().isNotEmpty);

        if (!hasData) continue;

        // Calculate age string using birthdate
        String ageString = '';
        if (row['birthdate']?.text != null &&
            row['birthdate']!.text.isNotEmpty) {
          try {
            DateTime birthDate = DateTime.parse(row['birthdate']!.text);
            ageString = calculateAge(birthDate);
          } catch (_) {
            ageString = row['age']?.text ?? '';
          }
        } else {
          ageString = row['age']?.text ?? '';
        }

        newFamilyMembers.add({
          'UID': widget.uid,
          'Registration_ID': registrationId,
          'Family_Member': row['name']?.text ?? '',
          'Relation': row['relation']?.text ?? '',
          'Age': ageString,
          'Gender': row['gender']?.text ?? '',
          'Civil_Status': row['civilStatus']?.text ?? '',
          'Education': row['education']?.text ?? '',
          'Occupational_Skills': row['skills']?.text ?? '',
          'Remarks': row['remarks']?.text ?? '',
          'Code': row['code']?.text ?? '',
          'Date_of_Birth': row['birthdate']?.text ?? '',
        });
      }

      if (newFamilyMembers.isNotEmpty) {
        await supabase.from('Family_Members').insert(newFamilyMembers);
      }

      // Step 6: Re-run Evacuation Logics
      await _checkSickMembersAndAssign(registrationId);
    } catch (e) {
      debugPrint('❌ Error updating registration: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error updating data: $e')));
    }
  }

  // ============================================================================
  // ASSIGNMENT LOGIC — with BIRTHDATE added & skipping empty rows
  // ============================================================================

  Future<void> _checkSickMembersAndAssign(String registrationId) async {
    if (!mounted) return;
    final supabase = Supabase.instance.client;
    final String headBarangay = _brgyController.text.trim();

    // Only consider rows with meaningful data
    final allMembersWithData = _familyRows.where((row) {
      return [
        row['name']?.text,
        row['relation']?.text,
        row['birthdate']?.text,
      ].any((f) => f != null && f.trim().isNotEmpty);
    }).toList();

    String _ageFromDobOrFallback(
      String dobText,
      TextEditingController? ageCtrl,
    ) {
      if (dobText.trim().isNotEmpty) {
        try {
          final DateTime? bd = DateTime.tryParse(dobText.trim());
          if (bd == null) {
            return ageCtrl?.text.trim().isNotEmpty == true
                ? ageCtrl!.text.trim()
                : '0';
          }
          return calculateAge(bd);
        } catch (_) {
          return ageCtrl?.text.trim().isNotEmpty == true
              ? ageCtrl!.text.trim()
              : '0';
        }
      } else {
        return ageCtrl?.text.trim().isNotEmpty == true
            ? ageCtrl!.text.trim()
            : '0';
      }
    }

    String _formatTimeDeployed(DateTime dateTime) {
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

    final membersWithCode = allMembersWithData
        .where((row) => (row['code']?.text ?? '').isNotEmpty)
        .toList();

    final potentialHelpers = allMembersWithData
        .where((row) => !membersWithCode.contains(row))
        .toList();

    final nowDateTime = DateTime.now();
    final now = nowDateTime.toIso8601String();
    final formattedTimeDeployed = _formatTimeDeployed(nowDateTime);
    final headSite = _evacSiteController.text;

    Map<String, Object> _buildHeadEntry() {
      final headFullName =
          '${_headSurnameController.text} ${_headFirstController.text} ${_headMiddleController.text}'
              .trim();

      final headAgeValue = _ageFromDobOrFallback(
        _dobController.text,
        _headAgeController,
      );

      return <String, Object>{
        'UID': widget.uid,
        'Registration_ID': registrationId,
        'Family_Member': headFullName,
        'Relation': 'Head of Family',
        'Age': headAgeValue,
        'Gender': _headSexController.text,
        'Civil_Status': _single
            ? 'Single'
            : _married
            ? 'Married'
            : _widowed
            ? 'Widowed'
            : _civilOtherController.text,
        'Education': '',
        'Occupational_Skills': _occupationController.text,
        'Remarks': 'Head of family entry',
        'Code': '',
        'Head_Surname': _headSurnameController.text,
        'Head_Firstname': _headFirstController.text,
        'Head_Middlename': _headMiddleController.text,
        'Head_Occupation': _occupationController.text,
        'Head_Monthly_Income':
            double.tryParse(_monthlyIncomeController.text) ?? 0.0,
        'City': _cityController.text,
        'Municipality': _munController.text,
        'Barangay': headBarangay,
        'Site': headSite,
        'Date_Transferred': now,
        'Time_Deployed': formattedTimeDeployed,
        'Date_of_Birth': _dobController.text,
        '4Ps_Families': _is4PsBeneficiary,
      };
    }

    // Step 0: Check if anyone is already in Evacuation_A or B
    final existingEvacResidents = await supabase
        .from('Evacuation_A')
        .select('Family_Member')
        .eq('UID', widget.uid)
        .then((aRows) async {
          final bRows = await supabase
              .from('Evacuation_B')
              .select('Family_Member')
              .eq('UID', widget.uid);
          return [
            ...aRows.map((e) => e['Family_Member']?.toString() ?? ''),
            ...bRows.map((e) => e['Family_Member']?.toString() ?? ''),
          ];
        });

    final alreadyInEvacuation = <String>[];

    // Members
    for (var member in allMembersWithData) {
      final memberName = member['name']?.text ?? '';
      if (existingEvacResidents.contains(memberName)) {
        alreadyInEvacuation.add(memberName);
      }
    }

    // Head
    final headFullName =
        '${_headSurnameController.text} ${_headFirstController.text} ${_headMiddleController.text}'
            .trim();

    if (existingEvacResidents.contains(headFullName)) {
      alreadyInEvacuation.add(headFullName);
    }

    // If already assigned → show modal + return
    if (alreadyInEvacuation.isNotEmpty) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Already Assigned',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The following resident(s) are already in the evacuation list:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ...alreadyInEvacuation.map(
                          (name) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainDashboard()),
            (route) => false,
          );
        }
      });
      return;
    }

    // NO CODE assigned → everyone goes to Evacuation_A
    if (membersWithCode.isEmpty) {
      final List<Map<String, Object>> evacAInserts = allMembersWithData.map((
        member,
      ) {
        final ageValue = _ageFromDobOrFallback(
          member['birthdate']?.text ?? '',
          member['age'],
        );

        return <String, Object>{
          'UID': widget.uid,
          'Registration_ID': registrationId,
          'Family_Member': member['name']?.text ?? '',
          'Relation': member['relation']?.text ?? '',
          'Age': ageValue,
          'Gender': member['gender']?.text ?? '',
          'Civil_Status': member['civilStatus']?.text ?? '',
          'Education': member['education']?.text ?? '',
          'Occupational_Skills': member['skills']?.text ?? '',
          'Remarks': member['remarks']?.text ?? '',
          'Code': member['code']?.text ?? '',
          'Date_of_Birth': member['birthdate']?.text ?? '',
          'Barangay': headBarangay,
          'Site': headSite,
          'Date_Transferred': now,
          'Time_Deployed': formattedTimeDeployed,
          '4Ps_Families': _is4PsBeneficiary,
        };
      }).toList();

      evacAInserts.add(_buildHeadEntry());

      try {
        await supabase.from('Evacuation_A').insert(evacAInserts);
      } catch (e) {
        debugPrint('❌ Error inserting Evacuation_A: $e');
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dCtx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  'Resident Successfully Evacuated',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: evacAInserts.map((entry) {
                        final name = entry['Family_Member']?.toString() ?? '';
                        final relation = entry['Relation']?.toString() ?? '';
                        final isHead = relation == 'Head of Family';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                isHead ? Icons.star : Icons.person,
                                size: 20,
                                color: isHead ? Colors.amber : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$name ($relation)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isHead
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainDashboard()),
            (route) => false,
          );
        }
      });
      return;
    }

    // ------------------------------------------------------------
    // STEP 3: CODE MEMBER LOGIC
    // ------------------------------------------------------------
    String? selectedHelper = potentialHelpers.isNotEmpty
        ? potentialHelpers.first['name']?.text
        : null;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Assign In-Charge',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a family member to oversee all members with a code.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Members with a Code:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    membersWithCode
                        .map((e) => e['name']?.text ?? '')
                        .join(', '),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select In-Charge:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButton<String>(
                        value: selectedHelper,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: potentialHelpers
                            .map(
                              (row) => DropdownMenuItem(
                                value: row['name']?.text ?? '',
                                child: Text(row['name']?.text ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedHelper = val),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);

                          try {
                            final nowLocal = DateTime.now().toIso8601String();

                            List<Map<String, Object>> evacBInserts = [];
                            List<Map<String, Object>> evacAInserts = [];

                            // 1️⃣ CODED MEMBERS → EVAC B
                            for (var member in membersWithCode) {
                              final ageValue = _ageFromDobOrFallback(
                                member['birthdate']?.text ?? '',
                                member['age'],
                              );

                              evacBInserts.add({
                                'UID': widget.uid,
                                'Registration_ID': registrationId,
                                'Family_Member': member['name']?.text ?? '',
                                'Relation': member['relation']?.text ?? '',
                                'Age': ageValue,
                                'Gender': member['gender']?.text ?? '',
                                'Civil_Status':
                                    member['civilStatus']?.text ?? '',
                                'Education': member['education']?.text ?? '',
                                'Occupational_Skills':
                                    member['skills']?.text ?? '',
                                'Remarks': member['remarks']?.text ?? '',
                                'Code': member['code']?.text ?? '',
                                'Date_of_Birth':
                                    member['birthdate']?.text ?? '',
                                'Barangay': headBarangay,
                                'Site': 'Santa RHU',
                                'Date_Transferred': nowLocal,
                                'Time_Deployed': formattedTimeDeployed,
                                '4Ps_Families': _is4PsBeneficiary,
                              });
                            }

                            // 2️⃣ SELECTED HELPER → EVAC B
                            final helperRow = allMembersWithData.firstWhere(
                              (row) => row['name']?.text == selectedHelper,
                            );

                            final helperAgeValue = _ageFromDobOrFallback(
                              helperRow['birthdate']?.text ?? '',
                              helperRow['age'],
                            );

                            evacBInserts.add({
                              'UID': widget.uid,
                              'Registration_ID': registrationId,
                              'Family_Member': selectedHelper ?? '',
                              'Relation': helperRow['relation']?.text ?? '',
                              'Age': helperAgeValue,
                              'Gender': helperRow['gender']?.text ?? '',
                              'Civil_Status':
                                  helperRow['civilStatus']?.text ?? '',
                              'Education': helperRow['education']?.text ?? '',
                              'Occupational_Skills':
                                  helperRow['skills']?.text ?? '',
                              'Remarks': helperRow['remarks']?.text ?? '',
                              'Code': 'Assign',
                              'Date_of_Birth':
                                  helperRow['birthdate']?.text ?? '',
                              'Barangay': headBarangay,
                              'Site': 'Santa RHU',
                              'Date_Transferred': nowLocal,
                              'Time_Deployed': formattedTimeDeployed,
                              '4Ps_Families': _is4PsBeneficiary,
                            });

                            // 3️⃣ ALL OTHER MEMBERS → EVAC A
                            final usedNames = {
                              ...membersWithCode.map(
                                (m) => m['name']?.text ?? '',
                              ),
                              selectedHelper ?? '',
                            };

                            for (var member in allMembersWithData) {
                              if (!usedNames.contains(
                                member['name']?.text ?? '',
                              )) {
                                final ageValue = _ageFromDobOrFallback(
                                  member['birthdate']?.text ?? '',
                                  member['age'],
                                );

                                evacAInserts.add({
                                  'UID': widget.uid,
                                  'Registration_ID': registrationId,
                                  'Family_Member': member['name']?.text ?? '',
                                  'Relation': member['relation']?.text ?? '',
                                  'Age': ageValue,
                                  'Gender': member['gender']?.text ?? '',
                                  'Civil_Status':
                                      member['civilStatus']?.text ?? '',
                                  'Education': member['education']?.text ?? '',
                                  'Occupational_Skills':
                                      member['skills']?.text ?? '',
                                  'Remarks': member['remarks']?.text ?? '',
                                  'Code': member['code']?.text ?? '',
                                  'Date_of_Birth':
                                      member['birthdate']?.text ?? '',
                                  'Barangay': headBarangay,
                                  'Site': headSite,
                                  'Date_Transferred': nowLocal,
                                  'Time_Deployed': formattedTimeDeployed,
                                  '4Ps_Families': _is4PsBeneficiary,
                                });
                              }
                            }

                            // 4️⃣ ADD HEAD TO EVAC A
                            evacAInserts.add(_buildHeadEntry());

                            // 5️⃣ INSERT TO DB
                            bool okA = true;
                            bool okB = true;

                            try {
                              await supabase
                                  .from('Evacuation_B')
                                  .insert(evacBInserts);
                            } catch (e) {
                              okB = false;
                              debugPrint('❌ Evacuation_B insert failed: $e');
                            }

                            try {
                              await supabase
                                  .from('Evacuation_A')
                                  .insert(evacAInserts);
                            } catch (e) {
                              okA = false;
                              debugPrint('❌ Evacuation_A insert failed: $e');
                            }

                            if (mounted) {
                              if (okA && okB) {
                                await _showInsertSuccessDialog(
                                  context,
                                  evacAInserts.length,
                                  evacBInserts.length,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '⚠ Partial Success → A: ${okA ? "OK" : "FAILED"}, B: ${okB ? "OK" : "FAILED"}',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint('❌ Error in Code Assignment: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ Error: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFF0D743D),
                        ),
                        child: Text(
                          'Assign',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ...existing code...

  Future<void> _showInsertSuccessDialog(
    BuildContext context,
    int evacACount,
    int evacBCount,
  ) async {
    if (!mounted) return;

    // Build the dialog and display it
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                'Resident Successfully Evacuated',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              // Summary counts
              Text(
                'Evacuation_A: $evacACount item${evacACount == 1 ? '' : 's'}\n'
                'Evacuation_B: $evacBCount item${evacBCount == 1 ? '' : 's'}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-close after a short delay and navigate back to dashboard
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainDashboard()),
        (route) => false,
      );
    });
  }

  Future<void> _fetchRegistrationDetails() async {
    try {
      final supabase = Supabase.instance.client;

      // ✅ Fetch main registration details
      final registrationResponse = await supabase
          .from('Registration_Table')
          .select('*')
          .eq('UID', widget.uid)
          .maybeSingle();

      // ✅ Fetch related family members
      final familyResponse = await supabase
          .from('Family_Members')
          .select('*')
          .eq('UID', widget.uid);

      if (registrationResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No record found for this UID')),
        );
        return;
      }

      // ✅ --- HEAD IMAGE FETCH ---
      final headImageValue = registrationResponse['Head_Image'];
      if (headImageValue != null && headImageValue.isNotEmpty) {
        try {
          if (headImageValue.startsWith('http')) {
            _headImageUrl = headImageValue;
          } else {
            _headImageUrl = supabase.storage
                .from('headimage')
                .getPublicUrl(headImageValue);
          }
        } catch (e) {
          debugPrint('❌ Error fetching head image: $e');
        }
      } else {
        _headImageUrl = null;
      }

      // ✅ Populate text controllers
      _headFirstController.text = registrationResponse['Head_Firstname'] ?? '';
      _headMiddleController.text =
          registrationResponse['Head_Middlename'] ?? '';
      _headSurnameController.text = registrationResponse['Head_Surname'] ?? '';
      _headAgeController.text =
          registrationResponse['Head_Age']?.toString() ?? '';
      _headSexController.text = registrationResponse['Head_Sex'] ?? '';

      _dobController.text = registrationResponse['Date_of_Birth'] ?? '';
      _occupationController.text = registrationResponse['Occupation'] ?? '';
      _monthlyIncomeController.text =
          registrationResponse['Monthly_Income']?.toString() ?? '';

      _disasterController.text = registrationResponse['Type_of_Disaster'] ?? '';
      _cityController.text = registrationResponse['City'] ?? '';
      _munController.text = registrationResponse['Municipality'] ?? '';
      _brgyController.text = registrationResponse['Barangay'] ?? '';
      _evacBrgyController.text =
          registrationResponse['Evacuation_Barangay'] ?? '';
      _evacCenterController.text =
          registrationResponse['Evacuation_Center'] ?? '';
      _evacSiteController.text = registrationResponse['Site'] ?? '';
      _dateRegisteredController.text =
          registrationResponse['Date_Registered']?.toString() ?? 'N/A';

      // ✅ Civil Status Handling
      final civilStatus = registrationResponse['Civil_Status'] ?? '';
      setState(() {
        _single = civilStatus == 'Single';
        _married = civilStatus == 'Married';
        _widowed = civilStatus == 'Widowed';

        if (!_single && !_married && !_widowed) {
          _civilOtherController.text = civilStatus;
        } else {
          _civilOtherController.clear();
        }

        _is4PsBeneficiary = registrationResponse['4Ps_Beneficiary'] ?? false;
        _isIP = registrationResponse['IP'] ?? false;
        _ipTypeController.text =
            registrationResponse['IP_Type_of_Ethnicity'] ?? '';
      });

      // ✅ Populate Family Members
      if (familyResponse != null && familyResponse.isNotEmpty) {
        _familyRows.clear();

        for (var member in familyResponse) {
          final dobString = member['Date_of_Birth'] ?? '';
          DateTime? dob;
          String computedAge = '';

          if (dobString.isNotEmpty) {
            try {
              dob = DateTime.parse(dobString);
              computedAge = calculateAge(dob);
            } catch (e) {
              debugPrint('⚠️ Invalid DOB format: $dobString');
            }
          }

          _familyRows.add({
            'name': TextEditingController(text: member['Family_Member'] ?? ''),
            'relation': TextEditingController(text: member['Relation'] ?? ''),
            'birthdate': TextEditingController(text: dobString),
            'age': TextEditingController(text: computedAge), // ✅ AUTO AGE
            'gender': TextEditingController(text: member['Gender'] ?? ''),
            'civilStatus': TextEditingController(
              text: member['Civil_Status'] ?? '',
            ),
            'education': TextEditingController(text: member['Education'] ?? ''),
            'skills': TextEditingController(
              text: member['Occupational_Skills'] ?? '',
            ),
            'remarks': TextEditingController(text: member['Remarks'] ?? ''),
            'code': TextEditingController(text: member['Code'] ?? ''),
          });
        }
      }

      // ✅ Refresh UI
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error fetching registration details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  Widget _buildFormCanvas() {
    return Container(
      width: _formWidth,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(),
          const SizedBox(height: 24),
          _buildDisasterDateSection(),
          const SizedBox(height: 60),
          _buildLocationCivilRow(),
          const SizedBox(height: 60),
          _buildHeadOfFamilyRow(),
          const SizedBox(height: 60),
          _buildAdditionalInfoRow(),
          const SizedBox(height: 50),
          _buildBeneficiaryEthnicityRow(),
          const SizedBox(height: 60),
          _buildFamilyMembersTable(),
          const SizedBox(height: 10),
          _buildInformationBox(),
          const SizedBox(height: 40),
          _buildHeadOfFamilyImageSection(),
          const SizedBox(height: 40),
          _buildDateRegisteredSection(),
          const SizedBox(height: 40),
          _buildSubmitButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initializeZoom(constraints);

        return Stack(
          children: [
            ClipRect(
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: _minScale,
                maxScale: _maxScale,
                panEnabled: true,
                scaleEnabled: true,
                constrained: false,
                alignment: Alignment.topLeft,
                boundaryMargin: const EdgeInsets.all(3000),
                child: _buildFormCanvas(),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                children: [
                  _buildZoomButton(Icons.add, Colors.green, _zoomIn, 'Zoom In'),
                  const SizedBox(height: 6),
                  _buildZoomButton(
                    Icons.remove,
                    Colors.orange,
                    _zoomOut,
                    'Zoom Out',
                  ),
                  const SizedBox(height: 6),
                  _buildZoomButton(
                    Icons.fit_screen,
                    const Color(0xFF0D743D),
                    _resetZoom,
                    'Fit to Screen',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------- UPDATED WIDGET: TYPE OF DISASTER & DATE OF OCCURRENCE (ALIGNED FAR LEFT) -------------
  Widget _buildDisasterDateSection() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10.0,
        top: 20.0,
      ), // ✅ moved closer to the left
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type of Disaster (inline)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Type of Disaster:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _disasterController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: GoogleFonts.poppins(fontSize: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Date of Occurrence (inline)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Date of Occurrence:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _dateController,
                  readOnly: true,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: GoogleFonts.poppins(fontSize: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'MUNICIPAL SOCIAL WELFARE AND DEVELOPMENT OFFICE\nREGISTRATION FORM',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 500, height: 2, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildZoomButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: FloatingActionButton(
          heroTag: null,
          backgroundColor: color,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onPressed: onPressed,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInlineField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    double width = 250,
    double fontSize = 22,
    double labelFontSize = 22,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: labelFontSize,
          ),
        ),
        SizedBox(
          width: width,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black87, width: 2),
              ),
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: fontSize),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCivilRow() {
    final List<String> mainEvacuationCenters = [
      "Municipal Evacuation Center, Magsaysay",
      "Municipal Farmers Covered Court",
      "Santa RHU",
    ];

    final List<String> supplementalEvacuationCenters = [
      "Santa High School",
      "Santa National High School",
    ];

    final List<String> allEvacuationCenters = [
      ...mainEvacuationCenters,
      ...supplementalEvacuationCenters,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: CITY/MUN/BRGY + BRGY/EVACUATION CENTER/SITE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City/Mun/Brgy fields
              Row(
                children: [
                  Text(
                    'CITY/MUN/BRGY: ',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _cityController,
                        style: GoogleFonts.poppins(fontSize: 22),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '/',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _munController,
                        style: GoogleFonts.poppins(fontSize: 22),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '/',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _brgyController,
                        style: GoogleFonts.poppins(fontSize: 22),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Evacuation Center Dropdown
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brgy/Evacuation Center/Site: ',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              'Select Evacuation Site',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: allEvacuationCenters
                                .map(
                                  (site) => SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, site),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        site,
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                        if (selected != null) {
                          setState(() {
                            _evacSiteController.text = selected;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black87, width: 2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _evacSiteController.text.isEmpty
                                    ? 'Select Evacuation Site'
                                    : _evacSiteController.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  color: _evacSiteController.text.isEmpty
                                      ? Colors.black54
                                      : Colors.black,
                                ),
                                maxLines:
                                    2, // Allow the text to wrap into 2 lines if needed
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_drop_down, size: 34),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 60),

        // Right: Civil Status
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 180.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Civil Status:',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 160,
                      child: _buildCheckBox('Single', _single, (val) {
                        setState(() {
                          _single = val!;
                          if (val) {
                            _married = false;
                            _widowed = false;
                            _civilOtherController.clear();
                          }
                        });
                      }),
                    ),
                    SizedBox(
                      width: 160,
                      child: _buildCheckBox('Married', _married, (val) {
                        setState(() {
                          _married = val!;
                          if (val) {
                            _single = false;
                            _widowed = false;
                            _civilOtherController.clear();
                          }
                        });
                      }),
                    ),
                    SizedBox(
                      width: 160,
                      child: _buildCheckBox('Widowed', _widowed, (val) {
                        setState(() {
                          _widowed = val!;
                          if (val) {
                            _single = false;
                            _married = false;
                            _civilOtherController.clear();
                          }
                        });
                      }),
                    ),
                    Container(
                      width: 250,
                      child: Row(
                        children: [
                          Text(
                            'Other:',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _civilOtherController,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    _single = false;
                                    _married = false;
                                    _widowed = false;
                                  });
                                }
                              },
                              style: GoogleFonts.poppins(fontSize: 22),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black87,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeadOfFamilyRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Name fields
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add more padding to move header further to the right
              Padding(
                padding: const EdgeInsets.only(left: 130.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'HEAD OF THE FAMILY',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 250, // line width under header
                      height: 2,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Row for Surname / First / Middle
              Row(
                children: [
                  // Surname
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _headSurnameController,
                      decoration: const InputDecoration(
                        hintText: 'Surname',
                        border: UnderlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // First Name
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _headFirstController,
                      decoration: const InputDecoration(
                        hintText: 'First Name',
                        border: UnderlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Middle Name
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _headMiddleController,
                      decoration: const InputDecoration(
                        hintText: 'Middle Name',
                        border: UnderlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Add padding to push Age & Sex further to the right
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 220.0,
            ), // adjust this value to move further right
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Age
                _buildInlineField(
                  'Age:',
                  _headAgeController,
                  fontSize: 22,
                  labelFontSize: 22,
                ),
                const SizedBox(height: 12),
                // Sex label and choices in a row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Sex:',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Male
                    _buildCheckBox('M', _headSexController.text == 'M', (val) {
                      setState(() {
                        if (val!) {
                          _headSexController.text = 'M';
                        } else {
                          _headSexController.text = '';
                        }
                      });
                    }),
                    const SizedBox(width: 10),
                    // Female
                    _buildCheckBox('F', _headSexController.text == 'F', (val) {
                      setState(() {
                        if (val!) {
                          _headSexController.text = 'F';
                        } else {
                          _headSexController.text = '';
                        }
                      });
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date of Birth
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _dobController,
                textAlign: TextAlign.center, // center text
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Select Date',
                  border: const UnderlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                style: GoogleFonts.poppins(fontSize: 22),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );

                  if (pickedDate != null) {
                    String formattedDate =
                        "${_formatMonth(pickedDate.month)}, ${pickedDate.day}, ${pickedDate.year}";
                    setState(() {
                      _dobController.text = formattedDate;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date of Birth',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
          ],
        ),

        const SizedBox(width: 200),

        // Occupation
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _occupationController,
                textAlign: TextAlign.center, // center text
                decoration: const InputDecoration(
                  hintText: '',
                  border: UnderlineInputBorder(),
                ),
                style: GoogleFonts.poppins(fontSize: 22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Occupation',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
          ],
        ),

        const SizedBox(width: 200),

        // Monthly Income
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _monthlyIncomeController,
                textAlign: TextAlign.center, // center text
                decoration: const InputDecoration(
                  hintText: '',
                  border: UnderlineInputBorder(),
                ),
                style: GoogleFonts.poppins(fontSize: 22),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly Income',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBeneficiaryEthnicityRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4P's Beneficiary
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _is4PsBeneficiary,
                onChanged: (value) {
                  setState(() {
                    _is4PsBeneficiary = value!;
                  });
                },
              ),
              Text(
                "4P's Beneficiary",
                style: GoogleFonts.poppins(fontSize: 22),
              ),
            ],
          ),
        ),

        const SizedBox(width: 40), // spacing between the two
        // IP-Type of Ethnicity
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _isIP,
                onChanged: (value) {
                  setState(() {
                    _isIP = value!;
                  });
                },
              ),
              Text(
                "IP - Type of Ethnicity:",
                style: GoogleFonts.poppins(fontSize: 22),
              ),
              const SizedBox(width: 8),
              // TextField for specifying ethnicity
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _ipTypeController,
                  decoration: const InputDecoration(
                    hintText: 'Specify',
                    border: UnderlineInputBorder(),
                  ),
                  style: GoogleFonts.poppins(fontSize: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- AGE CALCULATOR FUNCTION ----------------
  String calculateAge(DateTime birthDate) {
    final today = DateTime.now();

    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;
    int days = today.day - birthDate.day;

    // Adjust if day difference is negative
    if (days < 0) {
      months--;
      final prevMonth = DateTime(today.year, today.month, 0).day;
      days += prevMonth;
    }

    // Adjust if month difference is negative
    if (months < 0) {
      years--;
      months += 12;
    }

    // If at least 1 year → return ONLY the number
    if (years >= 1) {
      return "$years";
    }

    // Otherwise → return months for babies
    return "$months month${months == 1 ? '' : 's'}";
  }

  // -------------------- FAMILY MEMBERS TABLE --------------------
  Widget _buildFamilyMembersTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'FAMILY MEMBERS INFORMATION',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 400, height: 2, color: Colors.black87),
            ],
          ),
        ),

        Center(
          child: Container(
            width: 1650,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Table(
              border: TableBorder.all(color: Colors.black54, width: 1),

              // 🔥 UPDATED WIDTHS — DELETE COLUMN WIDER
              columnWidths: const {
                0: FlexColumnWidth(2.2), // Name
                1: FlexColumnWidth(2.2), // Relation
                2: FlexColumnWidth(2.8), // DOB
                3: FlexColumnWidth(1), // Age
                4: FlexColumnWidth(1.4), // Gender
                5: FlexColumnWidth(1.5), // Civil Status
                6: FlexColumnWidth(1.5), // Education
                7: FlexColumnWidth(2.5), // Skills
                8: FlexColumnWidth(2.5), // Remarks
                9: FlexColumnWidth(1.2), // Code
                10: FlexColumnWidth(1.3), // 🔥 WIDER DELETE COLUMN
              },

              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    _buildTableHeader('Family Members'),
                    _buildTableHeader('Relation to Family Head'),
                    _buildTableHeader('Date of Birth'),
                    _buildTableHeader('Age'),
                    _buildTableHeader('Gender'),
                    _buildTableHeader('Civil Status'),
                    _buildTableHeader('Educ.'),
                    _buildTableHeader('Occupational Skills'),
                    _buildTableHeader('Remarks'),
                    _buildTableHeader('Code'),
                    _buildTableHeader('Delete'),
                  ],
                ),

                // Data Rows
                for (int i = 0; i < _familyRows.length; i++)
                  TableRow(
                    children: [
                      _buildTableTextField(_familyRows[i]['name']!),
                      _buildTableTextField(_familyRows[i]['relation']!),
                      _buildDatePickerField(
                        _familyRows[i]['birthdate']!,
                        _familyRows[i]['age']!,
                      ),
                      _buildTableTextField(
                        _familyRows[i]['age']!,
                        disabled: true,
                      ),
                      _buildTableTextField(_familyRows[i]['gender']!),
                      _buildTableTextField(_familyRows[i]['civilStatus']!),
                      _buildTableTextField(_familyRows[i]['education']!),
                      _buildTableTextField(_familyRows[i]['skills']!),
                      _buildTableTextField(_familyRows[i]['remarks']!),
                      _buildTableTextField(_familyRows[i]['code']!),

                      // 🔥 UPDATED DELETE CELL (MORE SPACE)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, // wider
                          vertical: 8,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete this row',
                          onPressed: () {
                            setState(() {
                              _familyRows.removeAt(i);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Add Row Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D743D),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          label: Text(
            'Add Row',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: () {
            setState(() {
              _familyRows.add({
                'name': TextEditingController(),
                'relation': TextEditingController(),
                'birthdate': TextEditingController(),
                'age': TextEditingController(),
                'gender': TextEditingController(),
                'civilStatus': TextEditingController(),
                'education': TextEditingController(),
                'skills': TextEditingController(),
                'remarks': TextEditingController(),
                'code': TextEditingController(),
              });
            });
          },
        ),
      ],
    );
  }

  // -------------------- HELPERS --------------------
  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableTextField(
    TextEditingController controller, {
    bool disabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextField(
        controller: controller,
        enabled: !disabled,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        style: GoogleFonts.poppins(fontSize: 16),
      ),
    );
  }

  // -------------------- DATE PICKER FIELD --------------------
  Widget _buildDatePickerField(
    TextEditingController birthController,
    TextEditingController ageController,
  ) {
    bool hasSelectedDate = birthController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SHOW LABEL ONLY WHEN NO DATE SELECTED
          if (!hasSelectedDate)
            Text(
              "Select your birthday",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

          if (!hasSelectedDate) const SizedBox(height: 4),

          GestureDetector(
            onTap: () async {
              DateTime now = DateTime.now();

              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(now.year - 100),
                lastDate: now,
              );

              if (pickedDate != null) {
                birthController.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

                ageController.text = calculateAge(pickedDate);

                setState(() {});
              }
            },
            child: AbsorbPointer(
              child: TextField(
                controller: birthController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------- UPDATED INFORMATION BOX (A, B, C on first row; D, E on second) -------------
  Widget _buildInformationBox() {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, top: 20.0),
        child: Container(
          width: 500,
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.black87, width: 1.2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'CODE',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.black54, thickness: 1),
              const SizedBox(height: 12),

              // ✅ First row (A, B, C)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoRow('A', 'Older Person'),
                  _buildInfoRow('B', 'Lactating Mother'),
                  _buildInfoRow('C', 'PWD'),
                ],
              ),
              const SizedBox(height: 10),

              // ✅ Second row (D, E)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildInfoRow('D', 'Pregnant Mother'),
                  const SizedBox(width: 40), // spacing between D and E
                  _buildInfoRow('E', 'Solo Parent'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for each code-description pair
  Widget _buildInfoRow(String code, String description) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Text(
            '$code:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRegisteredSection() {
    return Center(
      child: Column(
        children: [
          // Label
          Text(
            'Date Registered:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),

          // TextField displaying the inserted date/time from DB
          SizedBox(
            width: 320,
            child: TextField(
              controller:
                  _dateRegisteredController, // ✅ now uses your fetched data
              readOnly: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.black87),
              decoration: const InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black87, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black87, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadOfFamilyImageSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Head of the Family (Photo)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ Image box with tap & long press actions
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    setState(() {
                      _headImageFile = File(picked.path);
                      _headImageBytes = bytes;
                      _headImageUrl = null;
                    });
                  }
                },
                onLongPress:
                    (_headImageFile != null ||
                        _headImageBytes != null ||
                        _headImageUrl != null)
                    ? () async {
                        final shouldRemove = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Remove Image',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              'Do you want to remove this image?',
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('No', style: GoogleFonts.poppins()),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Yes',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldRemove == true) {
                          setState(() {
                            _headImageFile = null;
                            _headImageBytes = null;
                            _headImageUrl = null;
                          });
                        }
                      }
                    : null,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black54, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(3, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _headImageBytes != null
                        ? Image.memory(_headImageBytes!, fit: BoxFit.cover)
                        : _headImageUrl != null
                        ? Image.network(
                            _headImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 80),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.black54,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Attach Photo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(width: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    (_headImageFile == null &&
                            _headImageBytes == null &&
                            _headImageUrl == null)
                        ? 'Tap the box to attach the Head of the Family photo.\nMake sure the image is clear and front-facing.'
                        : 'Long press the image to remove or replace it.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D743D), // ✅ Custom green color
          padding: const EdgeInsets.symmetric(
            horizontal: 100,
            vertical: 28,
          ), // ✅ Bigger button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        onPressed: () {
          _updateRegisterSave(); // ✅ new function call
        },
        child: Text(
          'SUBMIT',
          style: GoogleFonts.poppins(
            fontSize: 26, // ✅ Larger font
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckBox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(title, style: GoogleFonts.poppins(fontSize: 22)),
      ],
    );
  }
}
