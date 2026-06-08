// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:evacutaion/WebPages/sidebar/WebEditResident/WebManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class WebEditResidentsDetailsPage extends StatelessWidget {
  const WebEditResidentsDetailsPage({super.key, required this.uid});
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

  // -------------------- ZOOM / FIT TO SCREEN SETTINGS --------------------
  final GlobalKey _canvasKey = GlobalKey();

  static const double _formWidth = 1560.0;
  double _canvasHeight = 2200.0;

  final double _minScale = 0.05;
  final double _maxScale = 4.0;
  final double _zoomStep = 0.15;

  double _fitScale = 0.4;
  bool _zoomInitialized = false;
  Size? _lastViewportSize;

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
  final TextEditingController _headCodeController = TextEditingController();
  final TextEditingController _headRemarksController = TextEditingController();
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

  // -------------------- FIT SCREEN / PINCH ZOOM FUNCTIONS --------------------

  double _safeWidth(BoxConstraints constraints) {
    if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      return constraints.maxWidth;
    }
    return MediaQuery.of(context).size.width;
  }

  double _safeHeight(BoxConstraints constraints) {
    if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
      return constraints.maxHeight;
    }
    return MediaQuery.of(context).size.height;
  }

  double _calculateFitScale(BoxConstraints constraints) {
    final screenWidth = _safeWidth(constraints);
    final screenHeight = _safeHeight(constraints);

    const double horizontalPadding = 20;
    const double verticalPadding = 20;

    final widthScale = (screenWidth - horizontalPadding) / _formWidth;
    final heightScale = (screenHeight - verticalPadding) / _canvasHeight;

    final scale = math.min(widthScale, heightScale);

    return scale.clamp(_minScale, _maxScale).toDouble();
  }

  Matrix4 _buildFitMatrix(BoxConstraints constraints, double scale) {
    final screenWidth = _safeWidth(constraints);
    final screenHeight = _safeHeight(constraints);

    final scaledWidth = _formWidth * scale;
    final scaledHeight = _canvasHeight * scale;

    final dx = math.max((screenWidth - scaledWidth) / 2, 0).toDouble();
    final dy = math.max((screenHeight - scaledHeight) / 2, 0).toDouble();

    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _syncFitToViewport(BoxConstraints constraints) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;

      final measuredHeight = renderBox?.size.height ?? _canvasHeight;

      final viewportSize = Size(
        _safeWidth(constraints),
        _safeHeight(constraints),
      );

      final viewportChanged =
          _lastViewportSize == null ||
          (_lastViewportSize!.width - viewportSize.width).abs() > 1 ||
          (_lastViewportSize!.height - viewportSize.height).abs() > 1;

      final heightChanged = (measuredHeight - _canvasHeight).abs() > 1;

      if (!_zoomInitialized || viewportChanged) {
        setState(() {
          _canvasHeight = measuredHeight;
          _lastViewportSize = viewportSize;
          _fitScale = _calculateFitScale(constraints);
          _controller.value = _buildFitMatrix(constraints, _fitScale);
          _zoomInitialized = true;
        });
      } else if (heightChanged) {
        setState(() {
          _canvasHeight = measuredHeight;
        });
      }
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

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      _canvasHeight = renderBox.size.height;
    }

    setState(() {
      _fitScale = _calculateFitScale(constraints);
      _controller.value = _buildFitMatrix(constraints, _fitScale);
    });
  }

  Future<void> _updateRegisterSave() async {
    try {
      final supabase = Supabase.instance.client;

      debugPrint('🧩 Saving registration update...');
      debugPrint('🧩 Date of Occurrence: ${_dateController.text}');
      debugPrint('🧩 Selected Evacuation Site: ${_evacSiteController.text}');

      // Step 1: Fetch existing image
      final existingRecord = await supabase
          .from('Registration_Table')
          .select('Head_Image')
          .eq('UID', widget.uid)
          .maybeSingle();

      String? oldImagePath = existingRecord?['Head_Image']?.toString();
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
        'Head_Firstname': _headFirstController.text.trim(),
        'Head_Middlename': _headMiddleController.text.trim(),
        'Head_Surname': _headSurnameController.text.trim(),
        'Head_Age': int.tryParse(_headAgeController.text.trim()) ?? 0,
        'Head_Sex': _headSexController.text.trim(),
        'Head_Code': _headCodeController.text.trim(),
        'Head_Remarks': _headRemarksController.text.trim(),
        'Date_of_Birth': _dobController.text.trim(),
        'Occupation': _occupationController.text.trim(),
        'Monthly_Income':
            double.tryParse(_monthlyIncomeController.text.trim()) ?? 0,
        'Type_of_Disaster': _disasterController.text.trim(),
        'Date_of_Occurrence': _dateController.text.trim(),
        'City': _cityController.text.trim(),
        'Municipality': _munController.text.trim(),
        'Barangay': _brgyController.text.trim(),
        'Site': _evacSiteController.text.trim(),
        'Civil_Status': _single
            ? 'Single'
            : _married
            ? 'Married'
            : _widowed
            ? 'Widowed'
            : _civilOtherController.text.trim(),
        '4Ps_Beneficiary': _is4PsBeneficiary,
        'IP': _isIP,
        'IP_Type_of_Ethnicity': _ipTypeController.text.trim(),
        if (newImagePath != null) 'Head_Image': newImagePath,
      };

      // Step 4: Update Registration_Table
      await supabase
          .from('Registration_Table')
          .update(updateData)
          .eq('UID', widget.uid);

      // Step 5: Fetch Registration_ID
      final registrationData = await supabase
          .from('Registration_Table')
          .select('Registration_ID')
          .eq('UID', widget.uid)
          .maybeSingle();

      if (registrationData == null) {
        throw Exception("Registration not found for UID: ${widget.uid}");
      }

      final registrationId = registrationData['Registration_ID'];

      // Step 6: Delete old family members
      await supabase.from('Family_Members').delete().eq('UID', widget.uid);

      // Step 7: Insert updated family members
      final List<Map<String, dynamic>> newFamilyMembers = [];

      for (var row in _familyRows) {
        final name = row['name']?.text.trim() ?? '';
        final relation = row['relation']?.text.trim() ?? '';
        final birthdate = row['birthdate']?.text.trim() ?? '';
        final age = row['age']?.text.trim() ?? '';
        final gender = row['gender']?.text.trim() ?? '';
        final civilStatus = row['civilStatus']?.text.trim() ?? '';
        final education = row['education']?.text.trim() ?? '';
        final skills = row['skills']?.text.trim() ?? '';
        final remarks = row['remarks']?.text.trim() ?? '';
        final code = row['code']?.text.trim() ?? '';

        // ✅ Skip row if everything is empty
        final isRowEmpty =
            name.isEmpty &&
            relation.isEmpty &&
            birthdate.isEmpty &&
            age.isEmpty &&
            gender.isEmpty &&
            civilStatus.isEmpty &&
            education.isEmpty &&
            skills.isEmpty &&
            remarks.isEmpty &&
            code.isEmpty;

        if (isRowEmpty) continue;

        newFamilyMembers.add({
          'UID': widget.uid,
          'Registration_ID': registrationId,
          'Family_Member': name,
          'Relation': relation,
          'Date_of_Birth': birthdate,
          'Age': int.tryParse(age) ?? 0,
          'Gender': gender,
          'Civil_Status': civilStatus,
          'Education': education,
          'Occupational_Skills': skills,
          'Remarks': remarks,
          'Code': code,
        });
      }

      if (newFamilyMembers.isNotEmpty) {
        await supabase.from('Family_Members').insert(newFamilyMembers);
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('❌ Error updating registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Improved success dialog with auto navigate after 1 second
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(dialogContext).pop(); // close dialog
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const WebManageResidentsPage(),
              ),
              (route) => false,
            );
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 12,
          child: Container(
            width: 420,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D743D).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: Color(0xFF0D743D),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Update Successful',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D743D),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Registration details and family members were updated successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D743D),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WebManageResidentsPage(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      'Go to Manage Residents',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Redirecting automatically...',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
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
      if (headImageValue != null && headImageValue.toString().isNotEmpty) {
        try {
          if (headImageValue.toString().startsWith('http')) {
            _headImageUrl = headImageValue.toString();
            debugPrint('🖼️ Head image URL (direct): $_headImageUrl');
          } else {
            _headImageUrl = supabase.storage
                .from('headimage')
                .getPublicUrl(headImageValue.toString());
            debugPrint('🖼️ Head image URL (from storage): $_headImageUrl');
          }
        } catch (e) {
          debugPrint('❌ Error fetching head image: $e');
          _headImageUrl = null;
        }
      } else {
        _headImageUrl = null;
        debugPrint('ℹ️ No head image found for this record.');
      }

      // ✅ Populate text controllers
      _headFirstController.text =
          registrationResponse['Head_Firstname']?.toString() ?? '';
      _headMiddleController.text =
          registrationResponse['Head_Middlename']?.toString() ?? '';
      _headSurnameController.text =
          registrationResponse['Head_Surname']?.toString() ?? '';
      _headAgeController.text =
          registrationResponse['Head_Age']?.toString() ?? '';
      _headSexController.text =
          registrationResponse['Head_Sex']?.toString() ?? '';
      _headCodeController.text =
          registrationResponse['Head_Code']?.toString() ?? '';
      _headRemarksController.text =
          registrationResponse['Head_Remarks']?.toString() ?? '';

      _dobController.text =
          registrationResponse['Date_of_Birth']?.toString() ?? '';
      _occupationController.text =
          registrationResponse['Occupation']?.toString() ?? '';
      _monthlyIncomeController.text =
          registrationResponse['Monthly_Income']?.toString() ?? '';

      _disasterController.text =
          registrationResponse['Type_of_Disaster']?.toString() ?? '';
      _cityController.text = registrationResponse['City']?.toString() ?? '';
      _munController.text =
          registrationResponse['Municipality']?.toString() ?? '';
      _brgyController.text = registrationResponse['Barangay']?.toString() ?? '';
      _evacBrgyController.text =
          registrationResponse['Evacuation_Barangay']?.toString() ?? '';
      _evacCenterController.text =
          registrationResponse['Evacuation_Center']?.toString() ?? '';
      _evacSiteController.text = registrationResponse['Site']?.toString() ?? '';
      _dateRegisteredController.text =
          registrationResponse['Date_Registered']?.toString() ?? 'N/A';

      // ✅ Civil Status Handling
      final civilStatus =
          registrationResponse['Civil_Status']?.toString() ?? '';

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
            registrationResponse['IP_Type_of_Ethnicity']?.toString() ?? '';
      });

      // ✅ Populate Family Members
      _familyRows.clear();

      if (familyResponse.isNotEmpty) {
        for (var member in familyResponse) {
          _familyRows.add({
            'name': TextEditingController(
              text: member['Family_Member']?.toString() ?? '',
            ),
            'relation': TextEditingController(
              text: member['Relation']?.toString() ?? '',
            ),
            'birthdate': TextEditingController(
              text: member['Date_of_Birth']?.toString() ?? '',
            ),
            'age': TextEditingController(text: member['Age']?.toString() ?? ''),
            'gender': TextEditingController(
              text: member['Gender']?.toString() ?? '',
            ),
            'civilStatus': TextEditingController(
              text: member['Civil_Status']?.toString() ?? '',
            ),
            'education': TextEditingController(
              text: member['Education']?.toString() ?? '',
            ),
            'skills': TextEditingController(
              text: member['Occupational_Skills']?.toString() ?? '',
            ),
            'remarks': TextEditingController(
              text: member['Remarks']?.toString() ?? '',
            ),
            'code': TextEditingController(
              text: member['Code']?.toString() ?? '',
            ),
          });
        }
      } else {
        // ✅ optional: keep at least 1 empty row if no family members found
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
      }

      // ✅ Refresh UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Error fetching registration details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    _disasterController.dispose();
    _dateController.dispose();
    _cityController.dispose();
    _munController.dispose();
    _brgyController.dispose();
    _evacBrgyController.dispose();
    _evacCenterController.dispose();
    _evacSiteController.dispose();
    _civilOtherController.dispose();
    _headSurnameController.dispose();
    _headFirstController.dispose();
    _headMiddleController.dispose();
    _headCodeController.dispose();
    _headRemarksController.dispose();
    _headAgeController.dispose();
    _headSexController.dispose();
    _dobController.dispose();
    _occupationController.dispose();
    _monthlyIncomeController.dispose();
    _dateRegisteredController.dispose();
    _ipTypeController.dispose();

    for (final row in _familyRows) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  Widget _buildFormCanvas() {
    return Container(
      key: _canvasKey,
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
        _syncFitToViewport(constraints);

        return Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  panEnabled: true,
                  scaleEnabled: true,
                  constrained: false,
                  alignment: Alignment.topLeft,
                  boundaryMargin: const EdgeInsets.all(5000),
                  clipBehavior: Clip.none,
                  child: _buildFormCanvas(),
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
    const List<String> barangayList = [
      "BANAOANG",
      "NAMALANGAN",
      "RIZAL",
      "SACUYYA NORTE",
      "SACUYYA SUR",
      "AMPANDULA",
      "BASUG",
      "CABANGARAN",
      "MANUEVA",
      "MABILBILA NORTE",
      "MABILBILA SUR",
      "LABUT NORTE",
      "LABUT SUR",
      "MARCOS",
      "MAGSAYSAY",
      "QUEZON",
      "QUIRINO",
      "PASUNGOL",
      "BUCALAG",
      "TABUCOLAN",
      "CALUNGBOYAN",
      "CASIBER",
      "RANCHO",
      "ORIBI",
      "DAMMAY",
      "NAGPANAOAN",
    ];

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
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
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
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black87,
                              width: 2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
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

                  // UPDATED BRGY PART
                  Container(
                    width: 260,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              'Select Barangay',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: barangayList
                                .map(
                                  (brgy) => SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, brgy),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        brgy,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
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
                            _brgyController.text = selected;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black87, width: 2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _brgyController.text.isEmpty
                                    ? 'Select Barangay'
                                    : _brgyController.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  color: _brgyController.text.isEmpty
                                      ? Colors.black54
                                      : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_drop_down, size: 28),
                          ],
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
                                maxLines: 2,
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
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black87,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
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
        // Left: Head name fields + Code
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 130.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HEAD OF THE FAMILY',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(width: 250, height: 2, color: Colors.black87),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Row for Surname / First Name / Middle Name
              Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _headSurnameController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Surname',
                        border: UnderlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _headFirstController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'First Name',
                        border: UnderlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _headMiddleController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Middle Name',
                        border: UnderlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(fontSize: 22),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Code under the head name fields
              Padding(
                padding: const EdgeInsets.only(left: 180.0),
                child: SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _headCodeController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Code',
                      border: UnderlineInputBorder(),
                    ),
                    style: GoogleFonts.poppins(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right: Age, Sex + Remarks
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 220.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInlineField(
                  'Age:',
                  _headAgeController,
                  fontSize: 22,
                  labelFontSize: 22,
                ),

                const SizedBox(height: 12),

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

                const SizedBox(height: 18),

                // Remarks under Age and Sex
                SizedBox(
                  width: 340,
                  child: TextField(
                    controller: _headRemarksController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Remarks',
                      border: UnderlineInputBorder(),
                    ),
                    style: GoogleFonts.poppins(fontSize: 22),
                  ),
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
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(2.2),
                2: FlexColumnWidth(2.8),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1.4),
                5: FlexColumnWidth(1.5),
                6: FlexColumnWidth(1.5),
                7: FlexColumnWidth(2.5),
                8: FlexColumnWidth(2.5),
                9: FlexColumnWidth(1.2),
                10: FlexColumnWidth(1.3),
              },
              children: [
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

                for (int i = 0; i < _familyRows.length; i++)
                  TableRow(
                    children: [
                      _buildTableTextField(
                        _familyRows[i]['name'] ?? TextEditingController(),
                      ),
                      _buildTableTextField(
                        _familyRows[i]['relation'] ?? TextEditingController(),
                      ),
                      _buildDatePickerField(
                        _familyRows[i]['birthdate'] ?? TextEditingController(),
                        _familyRows[i]['age'] ?? TextEditingController(),
                      ),
                      _buildTableTextField(
                        _familyRows[i]['age'] ?? TextEditingController(),
                        disabled: true,
                      ),
                      _buildTableTextField(
                        _familyRows[i]['gender'] ?? TextEditingController(),
                      ),
                      _buildTableTextField(
                        _familyRows[i]['civilStatus'] ??
                            TextEditingController(),
                      ),
                      _buildTableTextField(
                        _familyRows[i]['education'] ?? TextEditingController(),
                      ),
                      _buildTableTextField(
                        _familyRows[i]['skills'] ?? TextEditingController(),
                      ),
                      _buildTableTextField(
                        _familyRows[i]['remarks'] ?? TextEditingController(),
                      ),
                      _buildTableTextField(
                        _familyRows[i]['code'] ?? TextEditingController(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
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
    final bool hasSelectedDate = birthController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
              final DateTime now = DateTime.now();

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
