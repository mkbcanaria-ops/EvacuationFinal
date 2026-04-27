// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ResidentViewQrCodePage extends StatefulWidget {
  const ResidentViewQrCodePage({super.key});

  @override
  State<ResidentViewQrCodePage> createState() => _ResidentViewQrCodePageState();
}

class _ResidentViewQrCodePageState extends State<ResidentViewQrCodePage> {
  String firstName = '';
  String middleName = '';
  String lastName = '';
  String qrData = '';
  bool isLoading = true;
  Map<String, dynamic> userDetails = {};
  String uid = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        uid = user.id;

        final response = await supabase
            .from('Registration_Table')
            .select()
            .eq('UID', user.id)
            .maybeSingle();

        if (response != null) {
          firstName = response['Head_Surname'] ?? '';
          middleName = response['Head_Middlename'] ?? '';
          lastName = response['Head_Firstname'] ?? '';

          userDetails = {
            'address': response['Address'] ?? '',
            'contact': response['Contact'] ?? '',
          };

          qrData = uid;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No registration record found.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch user data: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String get fullName =>
      "$firstName${middleName.isNotEmpty ? ' $middleName' : ''} $lastName"
          .trim();

  String get shortUid {
    if (uid.isEmpty) return '';
    if (uid.length <= 10) return uid.toUpperCase();
    return uid.substring(0, 10).toUpperCase();
  }

  Future<Uint8List> _generateQrBytes(String data, {double size = 130}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: Colors.black,
      emptyColor: Colors.white,
    );
    final picData = await painter.toImageData(size);
    return picData!.buffer.asUint8List();
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final pageFormat = PdfPageFormat(
      3.375 * PdfPageFormat.inch,
      4.5 * PdfPageFormat.inch,
      marginAll: 0.08 * PdfPageFormat.inch,
    );

    final qrBytesForPdf = await _generateQrBytes(qrData, size: 135);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Center(
            child: pw.Container(
              width: 2.95 * PdfPageFormat.inch,
              height: 3.95 * PdfPageFormat.inch,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFF0D743D),
                  width: 1.3,
                ),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFEAF5EE),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Text(
                        'MSWDO EVACUATION ID',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0D743D),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Municipality of Santa',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),

                    pw.SizedBox(height: 18),

                    // centered QR in printed ID
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Container(
                        width: 145,
                        height: 145,
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(14),
                          border: pw.Border.all(
                            color: PdfColor.fromInt(0xFF0D743D),
                            width: 0.9,
                          ),
                        ),
                        child: pw.Center(
                          child: pw.Image(
                            pw.MemoryImage(qrBytesForPdf),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 14),

                    pw.Text(
                      fullName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 13.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF0D743D),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Head of the Family',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'ID: $shortUid',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),

                    pw.Spacer(),

                    pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated via MSWDO System',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _printPage() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'MSWDO_ID_${fullName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfBytes = await _generatePdf();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${fullName.replaceAll(' ', '_')}_ID.pdf',
      );

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D743D).withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0D743D),
                    size: 58,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Download Successful!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D743D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${fullName}_ID.pdf is ready.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 130,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D743D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to download: $e')));
    }
  }

  Widget _buildIdPreviewCard() {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF0D743D).withOpacity(0.20),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D743D).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'MSWDO EVACUATION ID',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D743D),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Municipality of Santa',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF0D743D).withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: qrData.isNotEmpty
                ? QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180,
                    gapless: true,
                    foregroundColor: Colors.black,
                  )
                : const Center(child: Text("No QR code available")),
          ),
          const SizedBox(height: 18),
          Text(
            fullName.isEmpty ? 'No Name Available' : fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D743D),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Head of the Family',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ID: $shortUid',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0D743D).withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF0D743D),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Use the buttons below to print or download your evacuation ID.',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.black87,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFF0D743D).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(18.0),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF0D743D),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading your ID...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D743D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    Color foregroundColor = Colors.white,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: foregroundColor, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true,
        title: Text(
          'QR CODE GENERATED',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Download ID',
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF6FBF7), Color(0xFFEAF5EE)],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Your Evacuation ID',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D743D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preview your QR ID below. This ID is linked to your unique registration record.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.center,
                          child: _buildIdPreviewCard(),
                        ),
                        const SizedBox(height: 22),
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBottomButton(
                  onPressed: _printPage,
                  label: 'Print ID',
                  icon: Icons.print_rounded,
                  backgroundColor: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildBottomButton(
                  onPressed: () => Navigator.pop(context),
                  label: 'Done',
                  icon: Icons.check_rounded,
                  backgroundColor: const Color(0xFF0D743D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
