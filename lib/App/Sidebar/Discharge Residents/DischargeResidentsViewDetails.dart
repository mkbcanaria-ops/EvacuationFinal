// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison
import 'dart:io';
import 'dart:typed_data';

import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class DischargeResidentsDetailsPage extends StatelessWidget {
  const DischargeResidentsDetailsPage({super.key, required this.uid});
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
      body: DischargeResidentsDetailsPageFormWidget(
        uid: uid,
      ), // pass UID to form
    );
  }
}

class DischargeResidentsDetailsPageFormWidget extends StatefulWidget {
  final String uid;

  const DischargeResidentsDetailsPageFormWidget({super.key, required this.uid});

  @override
  State<DischargeResidentsDetailsPageFormWidget> createState() =>
      _DischargeResidentsDetailsPageFormWidgetState();
}

class _DischargeResidentsDetailsPageFormWidgetState
    extends State<DischargeResidentsDetailsPageFormWidget> {
  final TransformationController _controller = TransformationController();

  // Zoom settings
  final double _initialScale = 0.4;
  final double _minScale = 0.2;
  final double _maxScale = 3.0;
  final double _zoomStep = 0.1;

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
    _controller.value = Matrix4.identity()..scale(_initialScale);
    for (int i = 0; i < 5; i++) {
      _familyRows.add({
        'name': TextEditingController(),
        'relation': TextEditingController(),
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

  void _zoomIn() {
    setState(() {
      final currentScale = _controller.value.getMaxScaleOnAxis();
      final newScale = (currentScale + _zoomStep).clamp(_minScale, _maxScale);
      _controller.value = Matrix4.identity()..scale(newScale);
    });
  }

  void _zoomOut() {
    setState(() {
      final currentScale = _controller.value.getMaxScaleOnAxis();
      final newScale = (currentScale - _zoomStep).clamp(_minScale, _maxScale);
      _controller.value = Matrix4.identity()..scale(newScale);
    });
  }

  void _resetZoom() {
    setState(() {
      _controller.value = Matrix4.identity()..scale(_initialScale);
    });
  }

  Future<void> _updateRegisterSave() async {
    try {
      final supabase = Supabase.instance.client;

      print('🧩 Saving registration update...');
      print('🧩 Date of Occurrence: ${_dateController.text}');
      print('🧩 Selected Evacuation Site: ${_evacSiteController.text}');

      // Step 1: Fetch existing image (limit to 1 to avoid multiple rows error)
      final existingRecord = await supabase
          .from('Registration_Table')
          .select('Head_Image')
          .eq('UID', widget.uid)
          .limit(1)
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

        // Upload new image
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

      // Step 3: Prepare registration data
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
        'Barangay': _brgyController.text,
        'Site': _evacSiteController.text, // ✅ Selected site
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

      // Step 4: Update Registration_Table
      await supabase
          .from('Registration_Table')
          .update(updateData)
          .eq('UID', widget.uid);

      // Step 5: Refresh family members (limit to 1 to avoid multiple rows error)
      final registrationData = await supabase
          .from('Registration_Table')
          .select('Registration_ID')
          .eq('UID', widget.uid)
          .limit(1)
          .single();

      if (registrationData == null) {
        throw Exception("Registration not found for UID: ${widget.uid}");
      }

      final registrationId = registrationData['Registration_ID'];

      // Delete old family members
      await supabase.from('Family_Members').delete().eq('UID', widget.uid);

      // Insert updated family members
      final List<Map<String, dynamic>> newFamilyMembers = [];
      for (var row in _familyRows) {
        newFamilyMembers.add({
          'UID': widget.uid,
          'Registration_ID': registrationId,
          'Family_Member': row['name']?.text ?? '',
          'Relation': row['relation']?.text ?? '',
          'Age': int.tryParse(row['age']?.text ?? '') ?? 0,
          'Gender': row['gender']?.text ?? '',
          'Civil_Status': row['civilStatus']?.text ?? '',
          'Education': row['education']?.text ?? '',
          'Occupational_Skills': row['skills']?.text ?? '',
          'Remarks': row['remarks']?.text ?? '',
          'Code': row['code']?.text ?? '',
        });
      }

      if (newFamilyMembers.isNotEmpty) {
        await supabase.from('Family_Members').insert(newFamilyMembers);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registration and photo updated successfully!'),
        ),
      );

      // Step 6: Discharge residents
      await _dischargeResidents(registrationId);
    } catch (e) {
      debugPrint('❌ Error updating registration: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error updating data: $e')));
    }
  }

  Future<void> _dischargeResidents(String registrationId) async {
    if (!mounted) return;
    final supabase = Supabase.instance.client;

    final now = DateTime.now().toUtc().toIso8601String();
    final headSite = _evacSiteController.text; // Get head's site once

    // Step 1: Check if residents are currently in Evacuation_A or Evacuation_B (limit to 1 to avoid multiple rows error)
    final evacAData = await supabase
        .from('Evacuation_A')
        .select('UID')
        .eq('UID', widget.uid)
        .limit(1)
        .maybeSingle();

    final evacBData = await supabase
        .from('Evacuation_B')
        .select('UID')
        .eq('UID', widget.uid)
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
                    // Warning icon
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

    // Step 2: Delete existing entries from Evacuation_A and Evacuation_B
    try {
      await supabase.from('Evacuation_A').delete().eq('UID', widget.uid);
      await supabase.from('Evacuation_B').delete().eq('UID', widget.uid);
      debugPrint(
        '🧹 Removed residents from Evacuation_A and Evacuation_B for UID: ${widget.uid}',
      );
    } catch (e) {
      debugPrint('⚠️ Error deleting from Evacuation tables: $e');
      // Continue with insertion even if deletion fails
    }

    // Helper to build head-of-family map for Discharge_Resident table
    Map<String, Object> _buildHeadEntry() {
      final headFullName =
          '${_headSurnameController.text} ${_headFirstController.text} ${_headMiddleController.text}'
              .trim();
      return <String, Object>{
        'UID': widget.uid,
        'Registration_ID': registrationId,
        'Family_Member': headFullName,
        'Relation': 'Head of Family',
        'Age': int.tryParse(_headAgeController.text) ?? 0,
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
        'Barangay': _brgyController.text,
        'Site': headSite,
        'Date_Transferred': now, // Keep as per original, or adjust if needed
        'Time_Discharge': now, // New column
      };
    }

    // Prepare inserts for all family members
    final List<Map<String, Object>> dischargeInserts = _familyRows.map((
      member,
    ) {
      return <String, Object>{
        'UID': widget.uid,
        'Registration_ID': registrationId,
        'Family_Member': member['name']?.text ?? '',
        'Relation': member['relation']?.text ?? '',
        'Age': int.tryParse(member['age']?.text ?? '') ?? 0,
        'Gender': member['gender']?.text ?? '',
        'Civil_Status': member['civilStatus']?.text ?? '',
        'Education': member['education']?.text ?? '',
        'Occupational_Skills': member['skills']?.text ?? '',
        'Remarks': member['remarks']?.text ?? '',
        'Code': member['code']?.text ?? '',
        'Site': headSite,
        'Date_Transferred': now, // Keep as per original
        'Time_Discharge': now, // New column
      };
    }).toList();

    // Add head entry
    dischargeInserts.add(_buildHeadEntry());

    // Step 3: Insert into Discharge_Resident
    try {
      await supabase.from('Discharge_Resident').insert(dischargeInserts);
      if (mounted) {
        await _showDischargeSuccessDialog(context, dischargeInserts.length);
      }
    } catch (e) {
      debugPrint('❌ Error inserting into Discharge_Resident: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inserting into Discharge_Resident: $e'),
          ),
        );
      }
    }
  }

  Future<void> _showDischargeSuccessDialog(BuildContext ctx, int count) async {
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
                // ✅ Large green check icon
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

                // ✅ Title
                Text(
                  'Residents Successfully Discharged',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ Subtext
                Text(
                  'Total Discharged: $count member(s)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 25),

                // ✅ OK Button — Navigates to MainDashboard
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dCtx).pop(); // Close dialog first
                      Navigator.pushAndRemoveUntil(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const MainDashboard(),
                        ),
                        (route) => false, // Remove all previous routes
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

      // ✅ --- HEAD IMAGE FETCH (supports file path or full URL) ---
      final headImageValue = registrationResponse['Head_Image'];
      if (headImageValue != null && headImageValue.isNotEmpty) {
        try {
          if (headImageValue.startsWith('http')) {
            _headImageUrl = headImageValue;
            debugPrint('🖼️ Head image URL (direct): $_headImageUrl');
          } else {
            _headImageUrl = supabase.storage
                .from('headimage')
                .getPublicUrl(headImageValue);
            debugPrint('🖼️ Head image URL (from storage): $_headImageUrl');
          }
        } catch (e) {
          debugPrint('❌ Error fetching head image: $e');
        }
      } else {
        _headImageUrl = null;
        debugPrint('ℹ️ No head image found for this record.');
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
          _familyRows.add({
            'name': TextEditingController(text: member['Family_Member'] ?? ''),
            'relation': TextEditingController(text: member['Relation'] ?? ''),
            'age': TextEditingController(text: member['Age']?.toString() ?? ''),
            'gender': TextEditingController(text: member['Gender'] ?? ''),
            'civilStatus': TextEditingController(
              text: member['Civil_Status'] ?? '',
            ),
            'education': TextEditingController(text: member['Education'] ?? ''),
            'skills': TextEditingController(
              text: member['Occupational_Skills'] ?? '',
            ),
            'remarks': TextEditingController(text: member['Remarks'] ?? ''),
            'code': TextEditingController(
              text: member['Code'] ?? '',
            ), // ✅ new column
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(100),
              child: Container(
                width: 1590,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
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
                    const SizedBox(height: 40),
                    _buildInformationBox(),
                    const SizedBox(height: 40),
                    _buildHeadOfFamilyImageSection(),
                    const SizedBox(height: 40),
                    _buildDateRegisteredSection(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
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
                Icons.refresh,
                Colors.redAccent,
                _resetZoom,
                'Reset Zoom',
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildFamilyMembersTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Table Header (centered)
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
              Container(width: 1560, height: 2, color: Colors.black87),
            ],
          ),
        ),

        // Table container
        Center(
          child: Container(
            width: 1560,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Table(
              border: TableBorder.all(color: Colors.black54, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(2.2), // Family Members
                1: FlexColumnWidth(2.2), // Relation
                2: FlexColumnWidth(1), // Age
                3: FlexColumnWidth(1), // Gender
                4: FlexColumnWidth(1.5), // Civil Status
                5: FlexColumnWidth(1.5), // Educ.
                6: FlexColumnWidth(2.5), // Occupational Skills
                7: FlexColumnWidth(2.5), // Remarks
                8: FlexColumnWidth(1), // Code
                9: FlexColumnWidth(1), // Actions (new)
              },
              children: [
                // Table Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    _buildTableHeader('Family Members'),
                    _buildTableHeader('Relation to Family Head'),
                    _buildTableHeader('Age'),
                    _buildTableHeader('Gender'),
                    _buildTableHeader('Civil Status'),
                    _buildTableHeader('Educ.'),
                    _buildTableHeader('Occupational Skills'),
                    _buildTableHeader('Remarks'),
                    _buildTableHeader('Code'),
                    _buildTableHeader('Actions'), // New header for actions
                  ],
                ),
                // Dynamic Data Rows
                for (var row in _familyRows)
                  TableRow(
                    children: [
                      _buildTableTextField(row['name']!),
                      _buildTableTextField(row['relation']!),
                      _buildTableTextField(row['age']!),
                      _buildTableTextField(row['gender']!),
                      _buildTableTextField(row['civilStatus']!),
                      _buildTableTextField(row['education']!),
                      _buildTableTextField(row['skills']!),
                      _buildTableTextField(row['remarks']!),
                      _buildTableTextField(row['code']!),
                      // New cell for remove button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                // Dispose controllers to avoid memory leaks
                                row['name']!.dispose();
                                row['relation']!.dispose();
                                row['age']!.dispose();
                                row['gender']!.dispose();
                                row['civilStatus']!.dispose();
                                row['education']!.dispose();
                                row['skills']!.dispose();
                                row['remarks']!.dispose();
                                row['code']!.dispose();
                                // Remove the row
                                _familyRows.remove(row);
                              });
                            },
                            tooltip: 'Remove Row',
                          ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
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

  // Helper: Table header cell
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

  // Helper: Table text field cell
  Widget _buildTableTextField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextField(
        controller: controller,
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
          'Discharge',
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
