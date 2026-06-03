// ignore_for_file: use_build_context_synchronously, unused_local_variable, unnecessary_null_comparison

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;

class ManualViewQrPage extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String qrData;

  const ManualViewQrPage({
    super.key,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.qrData,
  });

  @override
  State<ManualViewQrPage> createState() => _ManualViewQrPageState();
}

class _ManualViewQrPageState extends State<ManualViewQrPage> {
  late String firstName;
  late String middleName;
  late String lastName;
  late String qrData;

  bool _isDownloading = false;

  static const Color primaryGreen = Color(0xFF0D743D);

  @override
  void initState() {
    super.initState();
    firstName = widget.firstName;
    middleName = widget.middleName;
    lastName = widget.lastName;
    qrData = widget.qrData;
  }

  String get fullName =>
      "$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName";

  String get fileName => '${_safeFileName(fullName)}_ID.pdf';

  String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '');

    if (cleaned.isEmpty) return 'Resident';
    return cleaned;
  }

  /// Generate QR for PDF
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

  /// Generate PDF
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    /// Bond paper / short bond paper size
    final bondPaperFormat = PdfPageFormat.letter;

    /// ID size
    final idWidth = 3.375 * PdfPageFormat.inch;
    final idHeight = 4.5 * PdfPageFormat.inch;

    final qrBytesForPdf = await _generateQrBytes(qrData, size: 130);

    pdf.addPage(
      pw.Page(
        pageFormat: bondPaperFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Center(
            child: pw.Container(
              width: idWidth,
              height: idHeight,
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
                        child: pw.Image(
                          pw.MemoryImage(qrBytesForPdf),
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),

                    pw.Column(
                      children: [
                        pw.SizedBox(height: 6),
                        pw.Text(
                          fullName.toUpperCase(),
                          textAlign: pw.TextAlign.center,
                          maxLines: 2,
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF0D743D),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Head of the Family',
                          textAlign: pw.TextAlign.center,
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

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: fileName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final pdfBytes = await _generatePdf();

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');

        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(url);

        if (!mounted) return;

        _showDownloadSuccessDialog(
          title: 'Download Successful!',
          message:
              '$fileName has been downloaded.\n\nPlease check your Downloads folder or browser downloads.',
        );
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);

        if (!mounted) return;

        _showDownloadSuccessDialog(
          title: 'PDF Ready!',
          message:
              '$fileName is ready.\n\nChoose Save, Files, Drive, or your preferred folder from the share window.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to download: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _showDownloadSuccessDialog({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: primaryGreen,
                  size: 70,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    height: 1.5,
                    color: Colors.black87,
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
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }

  Future<void> _sharePdf() async {
    try {
      final pdfBytes = await _generatePdf();

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 420;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: primaryGreen,
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

      body: SingleChildScrollView(
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
                    size: isSmallScreen ? 220 : 260,
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
                  fontSize: isSmallScreen ? 23 : 26,
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),

              const SizedBox(height: 18),

              TextButton.icon(
                onPressed: _sharePdf,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(
                  'Share PDF instead',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(foregroundColor: primaryGreen),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
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
                  onPressed: _printPage,
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: Text(
                    'Print ID',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadPdf,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.3,
                          ),
                        )
                      : const Icon(Icons.download, color: Colors.white),
                  label: Text(
                    _isDownloading ? 'Saving...' : 'Download',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 17,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: primaryGreen.withOpacity(0.65),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
