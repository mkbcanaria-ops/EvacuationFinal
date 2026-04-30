import 'dart:math' as math;

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
  bool _isDialogVisible = false;

  final TextEditingController _manualNameController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  List<Map<String, dynamic>> _searchResults = [];

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color lightBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ================= SEARCH BY QR =================

  Future<void> _searchInSupabase(String qrCode) async {
    if (!mounted || _isSearching) return;

    _safeSetState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final response = await Supabase.instance.client
          .from('Registration_Table')
          .select('UID, Head_Firstname, Head_Surname, Status')
          .eq('UID', qrCode)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        final status = response['Status'] ?? 'Active';

        if (status == 'Active') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowRegistrationPage(uid: response['UID']),
            ),
          );

          _resetScanner();
        } else {
          _showInfoDialog('This user is ${status.toString()}. Cannot proceed.');
        }
      } else {
        _showErrorDialog('No matching record found.');
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog('Error: $error');
    } finally {
      if (mounted) {
        _safeSetState(() => _isSearching = false);
      }
    }
  }

  // ================= SEARCH BY NAME =================

  Future<void> _searchByName(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _safeSetState(() {
        _searchResults = [];
      });
      return;
    }

    _safeSetState(() {
      _isSearching = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('Registration_Table')
          .select('UID, Head_Firstname, Head_Middlename, Head_Surname, Status')
          .or(
            'Head_Firstname.ilike.%$trimmed%,Head_Middlename.ilike.%$trimmed%,Head_Surname.ilike.%$trimmed%',
          )
          .eq('Status', 'Active')
          .limit(20);

      if (!mounted) return;

      _safeSetState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      debugPrint('Search error: $error');
    } finally {
      if (mounted) {
        _safeSetState(() => _isSearching = false);
      }
    }
  }

  // ================= DIALOGS =================

  void _showErrorDialog(String message) {
    if (!mounted || _isDialogVisible) return;

    _isDialogVisible = true;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetScanner();
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
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
    ).then((_) {
      _isDialogVisible = false;
      _resetScanner();
    });
  }

  void _showInfoDialog(String message) {
    if (!mounted || _isDialogVisible) return;

    _isDialogVisible = true;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Information',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetScanner();
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
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
    ).then((_) {
      _isDialogVisible = false;
      _resetScanner();
    });
  }

  // ================= SCANNER =================

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    final value = capture.barcodes.first.rawValue;

    if (value != null &&
        value != scannedResult &&
        !_isSearching &&
        !_isDialogVisible) {
      _safeSetState(() => scannedResult = value);
      _searchInSupabase(value);
    }
  }

  void _resetScanner() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      _safeSetState(() {
        scannedResult = null;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    _manualNameController.addListener(() {
      _safeSetState(() {});
      _searchByName(_manualNameController.text);
    });
  }

  @override
  void dispose() {
    _manualNameController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ================= UI HEADER =================

  Widget _buildHeaderCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 650;
        final bool isVerySmall = constraints.maxWidth < 420;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 10 : 16,
            vertical: isVerySmall ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isVerySmall ? 14 : 16),
            gradient: LinearGradient(
              colors: [primaryGreen, darkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: isSmall ? double.infinity : 430,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Scanner & Manual Search',
                      style: GoogleFonts.poppins(
                        fontSize: isVerySmall ? 14 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan a QR code or search the head of the family manually to quickly open resident details.',
                      style: GoogleFonts.poppins(
                        fontSize: isVerySmall ? 9.5 : 11,
                        height: 1.25,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmall ? 8 : 10,
                  vertical: isVerySmall ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: isVerySmall ? 14 : 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Fast Resident Lookup',
                      style: GoogleFonts.poppins(
                        fontSize: isVerySmall ? 9.5 : 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= UI SCANNER CARD =================

  Widget _buildScannerCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bool isVerySmall = width < 380;
        final bool isSmall = width < 600;
        final bool isMedium = width < 900;

        final double cardPadding = isVerySmall
            ? 10
            : isSmall
            ? 12
            : 18;

        final double iconBox = isVerySmall ? 38 : 48;
        final double iconSize = isVerySmall ? 20 : 26;
        final double titleSize = isVerySmall ? 15 : 18;
        final double subtitleSize = isVerySmall ? 11 : 13;

        final double scannerAspectRatio = isVerySmall
            ? 1.20
            : isSmall
            ? 1.35
            : isMedium
            ? 1.65
            : 1.95;

        final double innerPadding = isVerySmall ? 8 : 14;
        final double frameSizeFactor = isVerySmall ? 0.58 : 0.66;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isVerySmall ? 18 : 24),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: primaryGreen,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isVerySmall ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan QR Code',
                          style: GoogleFonts.poppins(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Use the camera to scan the resident QR code.',
                          style: GoogleFonts.poppins(
                            fontSize: subtitleSize,
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isVerySmall ? 10 : 18),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isVerySmall ? 16 : 22),
                  border: Border.all(color: primaryGreen, width: 2),
                  gradient: LinearGradient(
                    colors: [primaryGreen.withOpacity(0.05), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(innerPadding),
                  child: AspectRatio(
                    aspectRatio: scannerAspectRatio,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final double shortestSide = math.min(
                          box.maxWidth,
                          box.maxHeight,
                        );

                        final double frameSize = shortestSide * frameSizeFactor;
                        final double bottomLabelHorizontal = isVerySmall
                            ? 8
                            : 12;
                        final double bottomLabelVertical = isVerySmall ? 8 : 10;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(
                            isVerySmall ? 14 : 18,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                controller: _scannerController,
                                fit: BoxFit.cover,
                                onDetect: _onDetect,
                              ),
                              IgnorePointer(
                                child: Center(
                                  child: Container(
                                    width: frameSize,
                                    height: frameSize,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: isVerySmall ? 2.8 : 3.6,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        isVerySmall ? 18 : 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: bottomLabelHorizontal,
                                right: bottomLabelHorizontal,
                                bottom: bottomLabelVertical,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isVerySmall ? 10 : 12,
                                    vertical: isVerySmall ? 8 : 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Place the QR code inside the frame',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: isVerySmall ? 10.5 : 12.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= UI SEARCH CARD =================

  Widget _buildSearchCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 420;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmall ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isSmall ? 40 : 42,
                    height: isSmall ? 40 : 42,
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: primaryGreen,
                      size: isSmall ? 20 : 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual Search',
                          style: GoogleFonts.poppins(
                            fontSize: isSmall ? 15 : 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Search active residents by name.',
                          style: GoogleFonts.poppins(
                            fontSize: isSmall ? 11 : 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Head of the Family',
                style: GoogleFonts.poppins(
                  fontSize: isSmall ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _manualNameController,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: isSmall ? 12 : 13,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.person_search_rounded,
                    color: primaryGreen,
                    size: 20,
                  ),
                  suffixIcon: _manualNameController.text.trim().isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _manualNameController.clear();

                            _safeSetState(() {
                              _searchResults = [];
                            });
                          },
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: Colors.grey[600],
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAF9),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isSmall ? 12 : 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primaryGreen, width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: isSmall ? 12.5 : 13.5),
              ),
              const SizedBox(height: 12),
              _buildSearchResults(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_manualNameController.text.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Text(
          'Start typing a name to search.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[600]),
        ),
      );
    }

    if (_isSearching) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(color: primaryGreen, strokeWidth: 2.5),
            const SizedBox(height: 10),
            Text(
              'Searching records...',
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, color: Colors.grey[500], size: 28),
            const SizedBox(height: 8),
            Text(
              'No matching active records found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _searchResults.map((record) {
        final fullName =
            '${record['Head_Firstname'] ?? ''} ${record['Head_Middlename'] ?? ''} ${record['Head_Surname'] ?? ''}'
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person_rounded, color: primaryGreen, size: 19),
            ),
            title: Text(
              fullName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Active resident record',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: primaryGreen,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShowRegistrationPage(uid: record['UID']),
                ),
              );

              _resetScanner();
            },
          ),
        );
      }).toList(),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isVerySmall = constraints.maxWidth < 420;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isVerySmall ? 10 : 16,
              isVerySmall ? 10 : 16,
              isVerySmall ? 10 : 16,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final bool isWide = innerConstraints.maxWidth >= 980;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: _buildScannerCard()),
                              const SizedBox(width: 18),
                              Expanded(flex: 3, child: _buildSearchCard()),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _buildScannerCard(),
                            const SizedBox(height: 18),
                            _buildSearchCard(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
