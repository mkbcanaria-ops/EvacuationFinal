// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison
import 'dart:io';
import 'dart:typed_data';
import 'package:evacutaion/App/Sidebar/AppManageResidents/ManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditResidentsDetailsPage extends StatelessWidget {
  const EditResidentsDetailsPage({super.key, required this.uid});
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

      debugPrint('🧩 Updating registration...');
      debugPrint('🧩 Date of Occurrence: ${_dateController.text}');
      debugPrint('🧩 Selected Evacuation Site: ${_evacSiteController.text}');

      // ------------------------------------------------------------------
      // STEP 1: FETCH EXISTING IMAGE
      // ------------------------------------------------------------------
      final existingRecord = await supabase
          .from('Registration_Table')
          .select('Head_Image')
          .eq('UID', widget.uid)
          .maybeSingle();

      String? oldImagePath = existingRecord?['Head_Image'];
      String? newImagePath;

      // ------------------------------------------------------------------
      // STEP 2: UPLOAD NEW IMAGE (IF ANY)
      // ------------------------------------------------------------------
      if (_headImageBytes != null) {
        final bucket = supabase.storage.from('headimage');

        if (oldImagePath != null && oldImagePath.isNotEmpty) {
          try {
            await bucket.remove([oldImagePath]);
            debugPrint('🧹 Old image deleted');
          } catch (e) {
            debugPrint('⚠️ Image delete failed: $e');
          }
        }

        final fileName =
            '${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await bucket.uploadBinary(
          fileName,
          _headImageBytes!,
          fileOptions: const FileOptions(upsert: false),
        );

        newImagePath = fileName;
        debugPrint('✅ New image uploaded');
      }

      // ------------------------------------------------------------------
      // STEP 3: UPDATE REGISTRATION TABLE
      // ------------------------------------------------------------------
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
          .eq('UID', widget.uid);

      // ------------------------------------------------------------------
      // STEP 4: GET REGISTRATION ID
      // ------------------------------------------------------------------
      final registrationData = await supabase
          .from('Registration_Table')
          .select('Registration_ID')
          .eq('UID', widget.uid)
          .maybeSingle();

      if (registrationData == null) {
        throw Exception('Registration not found');
      }

      final registrationId = registrationData['Registration_ID'];

      // ------------------------------------------------------------------
      // STEP 5: REFRESH FAMILY MEMBERS
      // ------------------------------------------------------------------
      await supabase.from('Family_Members').delete().eq('UID', widget.uid);

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
        ].any((v) => v != null && v.trim().isNotEmpty);

        if (!hasData) continue;

        // ----------------- AGE CALCULATION -----------------
        String ageValue = '';
        final birthText = row['birthdate']?.text ?? '';

        if (birthText.isNotEmpty) {
          try {
            final dob = DateTime.parse(birthText);
            ageValue = calculateAge(dob); // supports months / years
          } catch (_) {
            ageValue = row['age']?.text ?? '';
          }
        }

        newFamilyMembers.add({
          'UID': widget.uid,
          'Registration_ID': registrationId,
          'Family_Member': row['name']?.text ?? '',
          'Relation': row['relation']?.text ?? '',
          'Date_of_Birth': birthText,
          'Age': ageValue,
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

      // ------------------------------------------------------------------
      // SUCCESS
      // ------------------------------------------------------------------
      if (mounted) _showSuccessDialog();
    } catch (e) {
      debugPrint('❌ Update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  // Custom success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D743D).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: Color(0xFF0D743D),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Update Successful",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D743D),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "The registration record and all family member details were successfully saved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D743D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // 1️⃣ Close dialog
                      Navigator.of(dialogContext).pop();

                      // 2️⃣ Navigate to ManageResidentsPage
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const ManageResidentsPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Ok",
                      style: TextStyle(
                        fontSize: 16,
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

      // ✅ --- HEAD IMAGE FETCH (supports URL or storage path) ---
      final headImageValue = registrationResponse['Head_Image'] ?? '';
      if (headImageValue.isNotEmpty) {
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
          _headImageUrl = null;
        }
      } else {
        _headImageUrl = null;
      }

      // ✅ Populate main text controllers safely
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

      // ✅ Populate Family Members safely
      _familyRows.clear();
      if (familyResponse != null && familyResponse.isNotEmpty) {
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
            'age': TextEditingController(text: computedAge),
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      }
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
    // Inline helpers
    Widget _buildCheckBox(String label, bool value, Function(bool?) onChanged) {
      return Row(
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label, style: GoogleFonts.poppins(fontSize: 20)),
        ],
      );
    }

    Widget _buildInlineField(
      String label,
      TextEditingController controller, {
      double fontSize = 22,
      double labelFontSize = 22,
    }) {
      int age = int.tryParse(controller.text) ?? 0;
      bool isValidAge = age >= 18;

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
              onChanged: (_) => setState(() {}), // refresh to update error
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

    // Main Row
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: Name fields
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

        // RIGHT: Age + Sex
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 220.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AGE FIELD WITH 18+ VALIDATION
                _buildInlineField(
                  'Age:',
                  _headAgeController,
                  fontSize: 22,
                  labelFontSize: 22,
                ),
                const SizedBox(height: 12),
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
                    _buildCheckBox('M', _headSexController.text == 'M', (val) {
                      setState(() {
                        _headSexController.text = val! ? 'M' : '';
                      });
                    }),
                    const SizedBox(width: 10),
                    _buildCheckBox('F', _headSexController.text == 'F', (val) {
                      setState(() {
                        _headSexController.text = val! ? 'F' : '';
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
                      return; // prevent updating DOB if under 18
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
