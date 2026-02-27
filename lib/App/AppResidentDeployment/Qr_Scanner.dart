import 'package:evacutaion/App/AppResidentDeployment/ShowEditRegistration.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  String? scannedResult;
  bool _isSearching = false;
  bool _isDialogVisible = false; // ✅ Prevent multiple dialogs
  final TextEditingController _manualNameController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  /// 🔍 Search Supabase by UID (from scanned QR)
  Future<void> _searchInSupabase(String qrCode) async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final response = await Supabase.instance.client
          .from('Registration_Table')
          .select('UID, Head_Firstname, Head_Surname, Status')
          .eq('UID', qrCode)
          .maybeSingle();

      if (response != null) {
        final status = response['Status'] ?? 'Active';
        if (status == 'Active') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowRegistrationPage(uid: response['UID']),
            ),
          ).then((_) => _resetScanner()); // ✅ Reset scanner when back
        } else {
          _showInfoDialog(
            '⚠️ This user is ${status.toString()}. Cannot proceed.',
          );
        }
      } else {
        _showErrorDialog('❌ No matching record found.');
      }
    } catch (error) {
      _showErrorDialog('⚠️ Error: $error');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// 🔍 Search Supabase by Name (Active users only)
  Future<void> _searchByName(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await Supabase.instance.client
          .from('Registration_Table')
          .select('UID, Head_Firstname, Head_Middlename, Head_Surname, Status')
          .or(
            'Head_Firstname.ilike.%$trimmed%,Head_Middlename.ilike.%$trimmed%,Head_Surname.ilike.%$trimmed%',
          )
          .eq('Status', 'Active') // ✅ Only Active users
          .limit(20);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      debugPrint('Search error: $error');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// ⚠️ Error popup
  void _showErrorDialog(String message) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Error',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.redAccent,
          ),
        ),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _isDialogVisible = false);
  }

  /// ℹ️ Info popup for Archived/Blocked users
  void _showInfoDialog(String message) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Info',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.orange,
          ),
        ),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _isDialogVisible = false);
  }

  /// 📸 Called when QR is detected
  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      final value = capture.barcodes.first.rawValue;
      if (value != null && value != scannedResult && !_isDialogVisible) {
        setState(() => scannedResult = value);
        _searchInSupabase(value);
      }
    }
  }

  /// 🔄 Reset scanner to scan again
  void _resetScanner() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => scannedResult = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _manualNameController.addListener(() {
      _searchByName(_manualNameController.text);
    });
  }

  @override
  void dispose() {
    _manualNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Point your camera at a QR code 📷\nOr type the name below to search.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // 📷 Scanner box
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                border: Border.all(color: const Color(0xFF0D743D), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: MobileScanner(
                  onDetect: _onDetect,
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.normal,
                    facing: CameraFacing.back,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Or',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Name of the Head of the Family:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 🧍 Manual search field
            TextField(
              controller: _manualNameController,
              decoration: InputDecoration(
                hintText: 'Enter name to search',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D743D),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D743D),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D743D),
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 10),
            // 🔽 Show results (Active users only)
            if (_manualNameController.text.trim().isNotEmpty)
              _isSearching
                  ? const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0D743D),
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No matching Active records found.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : Column(
                      children: _searchResults.map((record) {
                        final fullName =
                            '${record['Head_Firstname'] ?? ''} ${record['Head_Middlename'] ?? ''} ${record['Head_Surname'] ?? ''}'
                                .trim();
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              fullName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF0D743D),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ShowRegistrationPage(uid: record['UID']),
                                ),
                              ).then((_) => _resetScanner());
                            },
                          ),
                        );
                      }).toList(),
                    ),
          ],
        ),
      ),
    );
  }
}
