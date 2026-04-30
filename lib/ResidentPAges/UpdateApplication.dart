// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, unused_import

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:evacutaion/ResidentPAges/ResidentDashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateRegistrationPage extends StatelessWidget {
  const UpdateRegistrationPage({super.key, required this.uid});

  final String uid;

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
      body: UpdateRegistrationPageWidget(uid: uid),
    );
  }
}

class UpdateRegistrationPageWidget extends StatefulWidget {
  final String uid;

  const UpdateRegistrationPageWidget({super.key, required this.uid});

  @override
  State<UpdateRegistrationPageWidget> createState() =>
      _UpdateRegistrationPageWidgetState();
}

class _UpdateRegistrationPageWidgetState
    extends State<UpdateRegistrationPageWidget> {
  // -------------------- PINCH ZOOM / FIT SCREEN --------------------
  final TransformationController _controller = TransformationController();
  final GlobalKey _formCanvasKey = GlobalKey();

  static const double _formWidth = 1560.0;
  double _formHeight = 2200.0;

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

  final TextEditingController _headSurnameController = TextEditingController();
  final TextEditingController _headFirstController = TextEditingController();
  final TextEditingController _headMiddleController = TextEditingController();
  final TextEditingController _headAgeController = TextEditingController();
  final TextEditingController _headSexController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();

  final List<Map<String, TextEditingController>> _familyRows = [];

  final TextEditingController _dateRegisteredController =
      TextEditingController();

  File? imageFile;
  Uint8List? _headImageBytes;
  String? _headImageUrl;
  File? _headImageFile;

  // Civil Status
  bool _single = false;
  bool _married = false;
  bool _widowed = false;
  bool _is4PsBeneficiary = false;
  bool _isIP = false;

  final TextEditingController _ipTypeController = TextEditingController();

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
        'age': TextEditingController(),
        'birthdate': TextEditingController(),
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

  // -------------------- FIT SCREEN FUNCTIONS --------------------

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

    const double horizontalPadding = 24;
    const double verticalPadding = 24;

    final widthScale = (screenWidth - horizontalPadding) / _formWidth;
    final heightScale = (screenHeight - verticalPadding) / _formHeight;

    final scale = math.min(widthScale, heightScale);

    return scale.clamp(_minScale, _maxScale).toDouble();
  }

  Matrix4 _buildFitMatrix(BoxConstraints constraints, double scale) {
    final screenWidth = _safeWidth(constraints);
    final screenHeight = _safeHeight(constraints);

    final scaledWidth = _formWidth * scale;
    final scaledHeight = _formHeight * scale;

    final dx = math.max((screenWidth - scaledWidth) / 2, 0).toDouble();
    final dy = math.max((screenHeight - scaledHeight) / 2, 0).toDouble();

    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _syncFitToScreen(BoxConstraints constraints) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderBox =
          _formCanvasKey.currentContext?.findRenderObject() as RenderBox?;

      final measuredHeight = renderBox?.size.height ?? _formHeight;

      final viewportSize = Size(
        _safeWidth(constraints),
        _safeHeight(constraints),
      );

      final viewportChanged =
          _lastViewportSize == null ||
          (_lastViewportSize!.width - viewportSize.width).abs() > 1 ||
          (_lastViewportSize!.height - viewportSize.height).abs() > 1;

      final heightChanged = (measuredHeight - _formHeight).abs() > 1;

      if (!_zoomInitialized || viewportChanged) {
        setState(() {
          _formHeight = measuredHeight;
          _lastViewportSize = viewportSize;
          _fitScale = _calculateFitScale(constraints);
          _controller.value = _buildFitMatrix(constraints, _fitScale);
          _zoomInitialized = true;
        });
      } else if (heightChanged) {
        setState(() {
          _formHeight = measuredHeight;
        });
      }
    });
  }

  void _setZoomScale(double newScale) {
    final matrix = Matrix4.copy(_controller.value);
    final currentScale = matrix.getMaxScaleOnAxis();

    if (currentScale == 0) return;

    final ratio = newScale / currentScale;

    setState(() {
      _controller.value = matrix..scale(ratio);
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
        _formCanvasKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      _formHeight = renderBox.size.height;
    }

    setState(() {
      _fitScale = _calculateFitScale(constraints);
      _controller.value = _buildFitMatrix(constraints, _fitScale);
    });
  }

  Future<void> _updateRegisterSave() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logged-in user found')),
        );
        return;
      }

      final uid = user.id;

      debugPrint('🧩 Saving registration update...');
      debugPrint('🧩 Date of Occurrence: ${_dateController.text}');
      debugPrint('🧩 Selected Evacuation Site: ${_evacSiteController.text}');

      final existingRecord = await supabase
          .from('Registration_Table')
          .select('Head_Image')
          .eq('UID', uid)
          .maybeSingle();

      String? oldImagePath = existingRecord?['Head_Image'];
      String? newImagePath;

      if (_headImageBytes != null) {
        final bucket = supabase.storage.from('headimage');

        if (oldImagePath != null && oldImagePath.isNotEmpty) {
          try {
            await bucket.remove([oldImagePath]);
            debugPrint('🧹 Old image deleted: $oldImagePath');
          } catch (e) {
            debugPrint('⚠️ Could not delete old image: $e');
          }
        }

        final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await bucket.uploadBinary(
          fileName,
          _headImageBytes!,
          fileOptions: const FileOptions(upsert: false),
        );

        newImagePath = fileName;
        debugPrint('✅ New image uploaded: $newImagePath');
      }

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

      await supabase
          .from('Registration_Table')
          .update(updateData)
          .eq('UID', uid);

      final registrationData = await supabase
          .from('Registration_Table')
          .select('Registration_ID')
          .eq('UID', uid)
          .maybeSingle();

      if (registrationData == null) {
        throw Exception("Registration not found for UID: $uid");
      }

      final registrationId = registrationData['Registration_ID'];

      await supabase.from('Family_Members').delete().eq('UID', uid);

      final List<Map<String, dynamic>> newFamilyMembers = [];

      for (var row in _familyRows) {
        newFamilyMembers.add({
          'UID': uid,
          'Registration_ID': registrationId,
          'Family_Member': row['name']?.text ?? '',
          'Relation': row['relation']?.text ?? '',
          'Date_of_Birth': row['birthdate']?.text ?? '',
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

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Success!',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registration updated successfully.',
                    style: GoogleFonts.poppins(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ResidentDashboardPage()),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating registration: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error updating data: $e')));
      }
    }
  }

  Future<void> _fetchRegistrationDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logged-in user found')),
        );
        return;
      }

      final uid = user.id;

      final registrationResponse = await supabase
          .from('Registration_Table')
          .select('*')
          .eq('UID', uid)
          .maybeSingle();

      final familyResponse = await supabase
          .from('Family_Members')
          .select('*')
          .eq('UID', uid);

      if (registrationResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No record found for this user')),
        );
        return;
      }

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

      for (final row in _familyRows) {
        for (final controller in row.values) {
          controller.dispose();
        }
      }

      _familyRows.clear();

      if (familyResponse != null && familyResponse.isNotEmpty) {
        for (var member in familyResponse) {
          String dobString = member['Date_of_Birth'] ?? '';

          TextEditingController birthController = TextEditingController(
            text: dobString,
          );

          TextEditingController ageController = TextEditingController();

          if (dobString.isNotEmpty) {
            try {
              DateTime dob = DateTime.parse(dobString);
              ageController.text = calculateAge(dob);
            } catch (_) {
              ageController.text = '';
            }
          }

          _familyRows.add({
            'name': TextEditingController(text: member['Family_Member'] ?? ''),
            'relation': TextEditingController(text: member['Relation'] ?? ''),
            'birthdate': birthController,
            'age': ageController,
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

      if (mounted) {
        setState(() {
          _zoomInitialized = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching registration details: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  Widget _buildFormCanvas() {
    return Container(
      key: _formCanvasKey,
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
        _syncFitToScreen(constraints);

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
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Pinch to zoom • Drag to move • Tap fit to reset',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
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

  Widget _buildDisasterDateSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                    onPressed: () {
                                      Navigator.pop(context, brgy);
                                    },
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
                                    onPressed: () {
                                      Navigator.pop(context, site);
                                    },
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
                    SizedBox(
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
              Row(
                children: [
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 220.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInlineField(
                  'Age',
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _dobController,
                textAlign: TextAlign.center,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Select Date',
                  border: UnderlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _occupationController,
                textAlign: TextAlign.center,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _monthlyIncomeController,
                textAlign: TextAlign.center,
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
        const SizedBox(width: 40),
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

  String calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();

    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;
    int days = today.day - birthDate.day;

    if (days < 0) {
      months--;
      days += DateTime(birthDate.year, birthDate.month + 1, 0).day;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      return "$years";
    } else {
      return "$months month${months > 1 ? 's' : ''}";
    }
  }

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
              Container(width: 1560, height: 2, color: Colors.black87),
            ],
          ),
        ),
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
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(2.2),
                2: FlexColumnWidth(1.6),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1.5),
                6: FlexColumnWidth(1.5),
                7: FlexColumnWidth(2.5),
                8: FlexColumnWidth(2.5),
                9: FlexColumnWidth(1),
                10: FlexColumnWidth(1),
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
                    _buildTableHeader('Actions'),
                  ],
                ),
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
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final removed = _familyRows.removeAt(i);

                            for (final controller in removed.values) {
                              controller.dispose();
                            }

                            _zoomInitialized = false;
                          });
                        },
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

              _zoomInitialized = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
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

  Widget _buildDatePickerField(
    TextEditingController birthController,
    TextEditingController ageController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: GestureDetector(
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
    );
  }

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
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
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
              const Divider(color: Colors.black54, thickness: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoRow('A', 'Older Person'),
                  _buildInfoRow('B', 'Lactating Mother'),
                  _buildInfoRow('C', 'PWD'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildInfoRow('D', 'Pregnant Mother'),
                  const SizedBox(width: 40),
                  _buildInfoRow('E', 'Solo Parent'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          Text(
            'Date Registered:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _dateRegisteredController,
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
          backgroundColor: const Color(0xFF0D743D),
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        onPressed: () {
          _updateRegisterSave();
        },
        child: Text(
          'SUBMIT',
          style: GoogleFonts.poppins(
            fontSize: 26,
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
}
