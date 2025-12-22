// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ApprovedUserQRPage extends StatefulWidget {
  final String registrationId;
  final String firstName;
  final String middleName;
  final String lastName;

  const ApprovedUserQRPage({
    super.key,
    required this.registrationId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
  });

  @override
  State<ApprovedUserQRPage> createState() => _ApprovedUserQRPageState();
}

class _ApprovedUserQRPageState extends State<ApprovedUserQRPage> {
  final supabase = Supabase.instance.client;

  String qrData = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQrData();
  }

  Future<void> _fetchQrData() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('Registration_Table')
          .select()
          .eq('Registration_ID', widget.registrationId)
          .single();

      if (response != null) {
        qrData = widget.registrationId;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch QR: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  String get fullName =>
      '${widget.firstName} ${widget.middleName.isNotEmpty ? widget.middleName + ' ' : ''}${widget.lastName}';

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
    final qrBytes = await _generateQrBytes(qrData, size: 130);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          3.375 * PdfPageFormat.inch,
          4.5 * PdfPageFormat.inch,
          marginAll: 0.1 * PdfPageFormat.inch,
        ),
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
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Barangay Resident QR ID',
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
                    child: pw.Center(child: pw.Image(pw.MemoryImage(qrBytes))),
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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF0D743D),
                  size: 70,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Successful!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D743D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${fullName}_ID.pdf has been downloaded.',
                  style: GoogleFonts.poppins(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D743D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(color: Colors.white),
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

  Future<void> _printPdf() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: '${fullName.replaceAll(' ', '_')}_ID.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        title: Text(
          'QR CODE GENERATED',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    if (qrData.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 260,
                          gapless: true,
                          foregroundColor: Colors.black,
                        ),
                      )
                    else
                      const Text("No QR code available"),
                    const SizedBox(height: 40),
                    Text(
                      'Head of the Family',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D743D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _printPdf,
                icon: const Icon(Icons.print, color: Colors.white),
                label: Text(
                  'Print ID',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(
                  'Download',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D743D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
