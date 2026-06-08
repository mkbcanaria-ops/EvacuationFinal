// ignore_for_file: use_build_context_synchronously, unused_import, unused_field

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:evacutaion/App/DisplayQr.dart';
import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

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
      body: const Center(child: RegistrationFormWidget()),
    );
  }
}

class RegistrationFormWidget extends StatefulWidget {
  const RegistrationFormWidget({super.key});

  @override
  State<RegistrationFormWidget> createState() => _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState extends State<RegistrationFormWidget> {
  // Zoom / fitted-view settings
  final TransformationController _controller = TransformationController();
  static const double _formWidth = 1760.0; // wider canvas for the family table
  final double _minScale = 0.12;
  final double _maxScale = 4.0;
  final double _zoomStep = 0.15;
  double _fitScale = 0.4;
  bool _zoomInitialized = false;

  // Controllers
  final TextEditingController _disasterController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
  );
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _munController = TextEditingController();
  final TextEditingController _brgyController = TextEditingController();

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
  File? imageFile;
  Uint8List? imageBytes; // ✅ ADD THIS LINE HERE - for storing image bytes
  // Add scroll controllers and pointer tracking for horizontal + vertical scrolling
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  bool _isMousePanning = false;
  int? _activePointer;
  final double _contentWidth =
      _formWidth; // kept for compatibility with old desktop panning code
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
        'code': TextEditingController(), // ✅ Added for the new Code column
      });
    }
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

  Future<void> _registerSave() async {
    final supabase = Supabase.instance.client;

    final disasterType = _disasterController.text.trim();
    final date = _dateController.text.trim();
    final city = _cityController.text.trim();
    final municipality = _munController.text.trim();
    final barangay = _brgyController.text.trim();
    final site = _evacSiteController.text.trim();

    final headSurname = _headSurnameController.text.trim();
    final headFirst = _headFirstController.text.trim();
    final headMiddle = _headMiddleController.text.trim();
    final headCode = _headCodeController.text.trim();
    final headRemarks = _headRemarksController.text.trim();
    final headAge = _headAgeController.text.trim();
    final headSex = _headSexController.text.trim();

    final dob = _dobController.text.trim();
    final occupation = _occupationController.text.trim();
    final monthlyIncome = _monthlyIncomeController.text.trim();

    String civilStatus = '';
    if (_single)
      civilStatus = 'Single';
    else if (_married)
      civilStatus = 'Married';
    else if (_widowed)
      civilStatus = 'Widowed';
    else if (_civilOtherController.text.trim().isNotEmpty) {
      civilStatus = _civilOtherController.text.trim();
    }

    final is4Ps = _is4PsBeneficiary;
    final isIP = _isIP;
    final ipType = _ipTypeController.text.trim();

    final now = DateTime.now();
    final formattedDateRegistered = DateFormat(
      'MMMM dd, yyyy • hh:mm a',
    ).format(now);

    if (disasterType.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in both Type of Disaster and Date of Occurrence.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final existing = await supabase
          .from('Registration_Table')
          .select('Registration_ID')
          .eq('Type_of_Disaster', disasterType)
          .eq('Date_of_Occurrence', date)
          .maybeSingle();

      if (existing != null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This disaster record already exists.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final inserted = await supabase
          .from('Registration_Table')
          .insert({
            'Type_of_Disaster': disasterType,
            'Date_of_Occurrence': date,
            'City': city,
            'Municipality': municipality,
            'Barangay': barangay,
            'Site': site,
            'Civil_Status': civilStatus,
            'Head_Surname': headSurname,
            'Head_Firstname': headFirst,
            'Head_Middlename': headMiddle,
            'Head_Code': headCode,
            'Head_Remarks': headRemarks,
            'Head_Age': headAge,
            'Head_Sex': headSex,
            'Date_of_Birth': dob,
            'Occupation': occupation,
            'Monthly_Income': monthlyIncome,
            '4Ps_Beneficiary': is4Ps,
            'IP': isIP,
            'IP_Type_of_Ethnicity': ipType,
            'Date_Registered': formattedDateRegistered,
          })
          .select('Registration_ID, UID')
          .single();

      final registrationId = inserted['Registration_ID'];
      final uid = inserted['UID'];

      String? imageUrl;
      final fileName =
          'head_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (imageBytes != null) {
        await supabase.storage
            .from('headimage')
            .uploadBinary(
              fileName,
              imageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        imageUrl = supabase.storage.from('headimage').getPublicUrl(fileName);
      } else if (imageFile != null) {
        await supabase.storage
            .from('headimage')
            .upload(
              fileName,
              imageFile!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        imageUrl = supabase.storage.from('headimage').getPublicUrl(fileName);
      }

      if (imageUrl != null) {
        await supabase
            .from('Registration_Table')
            .update({'Head_Image': imageUrl})
            .eq('UID', uid);
      }

      final qrPainter = QrPainter(
        data: uid.toString(),
        version: QrVersions.auto,
        gapless: true,
      );

      final imageData = await qrPainter.toImageData(300);
      final qrBytes = imageData!.buffer.asUint8List();
      final qrBase64 = base64Encode(qrBytes);

      await supabase
          .from('Registration_Table')
          .update({'QR_Code': qrBase64})
          .eq('UID', uid);

      for (var row in _familyRows) {
        final name = row['name']!.text.trim();
        final relation = row['relation']!.text.trim();
        final ageText = row['age']!.text.trim();
        final gender = row['gender']!.text.trim();
        final civil = row['civilStatus']!.text.trim();
        final education = row['education']!.text.trim();
        final skills = row['skills']!.text.trim();
        final remarks = row['remarks']!.text.trim();
        final code = row['code']!.text.trim();
        final dobText = row['birthdate']!.text.trim();

        if (name.isEmpty &&
            relation.isEmpty &&
            ageText.isEmpty &&
            gender.isEmpty) {
          continue;
        }

        await supabase.from('Family_Members').insert({
          'UID': uid,
          'Registration_ID': registrationId,
          'Family_Member': name,
          'Relation': relation,
          'Age': int.tryParse(ageText) ?? 0,
          'Gender': gender,
          'Civil_Status': civil,
          'Education': education,
          'Occupational_Skills': skills,
          'Remarks': remarks,
          'Code': code,
          'Date_of_Birth': dobText,
        });
      }

      final fullRecord = await supabase
          .from('Registration_Table')
          .select()
          .eq('UID', uid)
          .single();

      if (!mounted) return;
      Navigator.of(context).pop();

      // 🔥 SHOW MODERN SUCCESS POPUP
      showSuccessPopup(context);

      // ⏳ Delay then navigate
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QRCodeDisplayPage(
              qrBytes: qrBytes,
              fullName:
                  '${fullRecord['Head_Firstname']} ${fullRecord['Head_Middlename']} ${fullRecord['Head_Surname']}',
              details: fullRecord,
            ),
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon with gradient circle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Success!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Registration has been saved successfully.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // close popup

                // Navigate to the dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainDashboard()),
                );
              },
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    _headCodeController.dispose();
    _headRemarksController.dispose();
    super.dispose();
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

                  // UPDATED BRGY PART ONLY - longer line + dropdown
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
    // local inline checkbox widget
    Widget buildCheckBox(String label, bool value, Function(bool?) onChanged) {
      return Row(
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label, style: GoogleFonts.poppins(fontSize: 20)),
        ],
      );
    }

    // local inline field builder (for Age)
    Widget buildInlineField(
      String label,
      TextEditingController controller, {
      double fontSize = 22,
      double labelFontSize = 22,
    }) {
      int age = int.tryParse(controller.text) ?? 0;
      bool isValidAge = controller.text.isEmpty || age >= 18;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                errorText: isValidAge ? null : "Must be 18+",
              ),
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                color: isValidAge ? Colors.black : Colors.red,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT : HEADER + NAME FIELDS + CODE
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

              // NAME ROW
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

              // Head Code under the names
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

        // RIGHT : AGE + SEX + REMARKS
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AGE (MUST BE 18+)
                buildInlineField(
                  "Age:",
                  _headAgeController,
                  fontSize: 22,
                  labelFontSize: 22,
                ),
                const SizedBox(height: 16),

                // SEX SELECTION
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

                    buildCheckBox('M', _headSexController.text == 'M', (val) {
                      setState(() {
                        _headSexController.text = val! ? 'M' : '';
                      });
                    }),
                    const SizedBox(width: 10),

                    buildCheckBox('F', _headSexController.text == 'F', (val) {
                      setState(() {
                        _headSexController.text = val! ? 'F' : '';
                      });
                    }),
                  ],
                ),

                const SizedBox(height: 18),

                // Head Remarks under Age and Sex
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
        // DATE OF BIRTH
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
                    int age = _calculateAge(pickedDate);

                    if (age < 18) {
                      _showUnderagePopup();
                      return; // Prevent updating DOB
                    }

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

        // OCCUPATION
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

        // MONTHLY INCOME
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

  /// CALCULATE AGE
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// UNDERAGE POPUP
  void _showUnderagePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  "Age Restriction",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "The selected date makes the individual under 18.\nPlease select a valid birthdate (18 years old and above).",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    "OK",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
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

  // ------------- FAMILY MEMBERS TABLE WIDGET -------------
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

        // Table
        Center(
          child: Container(
            width: 1700, // made slightly wider to accommodate delete column
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

                // Data Rows WITH DELETE BUTTON
                for (int index = 0; index < _familyRows.length; index++)
                  TableRow(
                    children: [
                      _buildTableTextField(_familyRows[index]['name']!),
                      _buildTableTextField(_familyRows[index]['relation']!),
                      _buildDatePickerField(
                        _familyRows[index]['birthdate']!,
                        _familyRows[index]['age']!,
                      ),
                      _buildTableTextField(
                        _familyRows[index]['age']!,
                        disabled: true,
                      ),
                      _buildTableTextField(_familyRows[index]['gender']!),
                      _buildTableTextField(_familyRows[index]['civilStatus']!),
                      _buildTableTextField(_familyRows[index]['education']!),
                      _buildTableTextField(_familyRows[index]['skills']!),
                      _buildTableTextField(_familyRows[index]['remarks']!),
                      _buildTableTextField(_familyRows[index]['code']!),

                      // DELETE BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete this row',
                          onPressed: () {
                            setState(() {
                              _familyRows.removeAt(index);
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

  // ------------- DATE REGISTERED (Centered Line with Date) -------------
  Widget _buildDateRegisteredSection() {
    // Get formatted current date and time with AM/PM
    String formattedDate = DateFormat(
      'MMMM dd, yyyy • hh:mm a',
    ).format(DateTime.now());

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

          // TextField with underline style
          SizedBox(
            width: 320,
            child: TextField(
              controller: TextEditingController(text: formattedDate),
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

  // ------------- HEAD OF FAMILY IMAGE (Larger Left-aligned Box Design) -------------
  Widget _buildHeadOfFamilyImageSection() {
    // ✅ Move this outside the StatefulBuilder to preserve the image

    return Padding(
      padding: const EdgeInsets.only(left: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Head of the Family (Photo)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),

          // Image Box with tap/long-press actions
          StatefulBuilder(
            builder: (context, setState) {
              // ✅ Function to pick image
              Future<void> _pickImage() async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );

                if (picked != null) {
                  // ✅ Store file for upload and bytes for display (web-compatible)
                  setState(() {
                    imageFile = File(picked.path);
                    // Load bytes for display (handles web blob URLs better)
                    picked.readAsBytes().then((bytes) {
                      setState(() => imageBytes = bytes);
                    });
                  });
                }
              }

              // ✅ Function to confirm image removal
              Future<void> _confirmRemoveImage() async {
                final shouldRemove = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Remove Image',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                    imageFile = null;
                    imageBytes = null; // ✅ Clear bytes too
                  });
                }
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image container (box)
                  GestureDetector(
                    onTap: _pickImage,
                    onLongPress: imageFile != null ? _confirmRemoveImage : null,
                    child: Container(
                      width: 240, // 🟢 Bigger width
                      height: 240, // 🟢 Bigger height
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
                      child: imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                18,
                              ), // Match container
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                                width: 240,
                                height: 240,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
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

                  // Right-side hint text
                  const SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        imageFile == null
                            ? 'Tap the box to attach the Head of the Family photo.\n'
                                  'Make sure the image is clear and front-facing.'
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
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------- SUBMIT BUTTON (Centered) -------------

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
          _registerSave(); // ✅ new function call
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
