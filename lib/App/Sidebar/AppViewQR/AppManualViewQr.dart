// ignore_for_file: use_build_context_synchronously, unused_local_variable, unnecessary_null_comparison

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppManualViewQrPage extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String qrData;

  const AppManualViewQrPage({
    super.key,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.qrData,
  });

  @override
  State<AppManualViewQrPage> createState() => _AppManualViewQrPageState();
}

class _AppManualViewQrPageState extends State<AppManualViewQrPage> {
  late String firstName;
  late String middleName;
  late String lastName;
  late String qrData;

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

  @override
  void initState() {
    super.initState();
    firstName = widget.firstName;
    middleName = widget.middleName;
    lastName = widget.lastName;
    qrData = widget.qrData;
  }

  String get fullName =>
      "$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName"
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

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
      marginAll: 0.1 * PdfPageFormat.inch,
    );

    final qrBytesForPdf = await _generateQrBytes(qrData, size: 130);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFF0D743D),
                width: 1.2,
              ),
              color: PdfColors.white,
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'MSWDO EVACUATION ID',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0D743D),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Divider(
                        thickness: 0.7,
                        color: PdfColor.fromInt(0xFF0D743D),
                      ),
                    ],
                  ),

                  pw.Container(
                    width: 130,
                    height: 130,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(
                        color: PdfColor.fromInt(0xFF0D743D),
                        width: 0.8,
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Image(pw.MemoryImage(qrBytesForPdf)),
                    ),
                  ),

                  pw.Column(
                    children: [
                      pw.SizedBox(height: 6),
                      pw.Text(
                        fullName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0D743D),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Head of the Family',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),

                  pw.Column(
                    children: [
                      pw.Divider(thickness: 0.4),
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
                ],
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to print: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfBytes = await _generatePdf();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${fullName.replaceAll(' ', '_')}_ID.pdf',
      );

      if (!mounted) return;

      await _showDownloadSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDownloadSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryGreen.withOpacity(0.10),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Download Successful',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${fullName}_ID.pdf has been generated.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.2,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 132,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 12.2,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 800;

    final double qrSize = isWide ? 260 : 220;

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QR Code Generated',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isWide ? 28 : 18,
          18,
          isWide ? 28 : 18,
          110,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                _buildQrPreviewCard(qrSize),
                const SizedBox(height: 16),
                _buildResidentInfoCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(isWide),
    );
  }

  Widget _buildQrPreviewCard(double qrSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MSWDO Evacuation QR',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan this code to identify the resident record.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FBF9), Color(0xFFF1F7F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEAF0EC)),
            ),
            child: qrData.isNotEmpty
                ? QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: qrSize,
                    gapless: true,
                    foregroundColor: Colors.black,
                  )
                : SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 90,
                      color: Colors.grey[500],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Head of the Family',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generated via MSWDO System',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 28 : 18, 14, isWide ? 28 : 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Print ID',
                      icon: Icons.print_rounded,
                      backgroundColor: Colors.black87,
                      onPressed: _printPage,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Download',
                      icon: Icons.download_rounded,
                      backgroundColor: primaryGreen,
                      onPressed: _downloadPdf,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    label: 'Print ID',
                    icon: Icons.print_rounded,
                    backgroundColor: Colors.black87,
                    onPressed: _printPage,
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    backgroundColor: primaryGreen,
                    onPressed: _downloadPdf,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
