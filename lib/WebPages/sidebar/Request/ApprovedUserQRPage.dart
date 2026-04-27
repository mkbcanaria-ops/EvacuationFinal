// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApprovedUserQRPage extends StatefulWidget {
  final String registrationId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String requestId;
  final String requestEmail;

  const ApprovedUserQRPage({
    super.key,
    required this.registrationId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    this.requestId = '',
    this.requestEmail = '',
  });

  @override
  State<ApprovedUserQRPage> createState() => _ApprovedUserQRPageState();
}

class _ApprovedUserQRPageState extends State<ApprovedUserQRPage> {
  final supabase = Supabase.instance.client;

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

  String qrData = '';
  bool isLoading = true;
  bool isSendingEmail = false;

  @override
  void initState() {
    super.initState();
    _fetchQrData();
  }

  String get fullName {
    return '${widget.firstName} ${widget.middleName.isNotEmpty ? '${widget.middleName} ' : ''}${widget.lastName}'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String get cleanEmail {
    final email = widget.requestEmail.trim();
    if (email.isEmpty || email == 'Not provided') return '';
    return email;
  }

  String get cleanRequestId {
    final id = widget.requestId.trim();
    if (id.isEmpty || id == 'Not provided') return '';
    return id;
  }

  String get safeFileName {
    final name = fullName
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s_-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    return name.isEmpty ? 'Resident_QR_ID.pdf' : '${name}_QR_ID.pdf';
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
        /*
          Current QR value:
          Registration_ID is used as the QR content.

          If your QR_Code column stores the actual QR value, use this instead:
          qrData = response['QR_Code']?.toString() ?? widget.registrationId;
        */
        qrData = widget.registrationId;
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch QR: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<Uint8List> _generateQrBytes(String data, {double size = 170}) async {
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

  Future<Uint8List> _generatePdfBytes() async {
    if (qrData.trim().isEmpty) {
      throw Exception('No QR data available.');
    }

    final pdf = pw.Document();
    final qrBytes = await _generateQrBytes(qrData, size: 170);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          3.375 * PdfPageFormat.inch,
          4.5 * PdfPageFormat.inch,
          marginAll: 0.12 * PdfPageFormat.inch,
        ),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(
                color: PdfColor.fromInt(0xFF0D743D),
                width: 1.4,
              ),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'MSWDO-Santa eCamp Management System',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0D743D),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Resident QR Identification',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0D743D),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Divider(
                        thickness: 0.8,
                        color: PdfColor.fromInt(0xFF0D743D),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 150,
                    height: 150,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(
                        color: PdfColor.fromInt(0xFF0D743D),
                        width: 0.9,
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Image(
                        pw.MemoryImage(qrBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        fullName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0D743D),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Head of the Family',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Registration ID: ${widget.registrationId}',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Divider(thickness: 0.4),
                      pw.Text(
                        'Use this QR for evacuation registration, deployment, and discharge verification.',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 6.8,
                          color: PdfColors.grey700,
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
      final pdfBytes = await _generatePdfBytes();

      await Printing.sharePdf(bytes: pdfBytes, filename: safeFileName);

      if (!mounted) return;

      await _showInfoDialog(
        icon: Icons.check_circle_rounded,
        iconColor: primaryGreen,
        title: 'Download Successful',
        message: '$safeFileName has been downloaded.',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download: $e')));
    }
  }

  Future<void> _printPdf() async {
    try {
      final pdfBytes = await _generatePdfBytes();

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: safeFileName,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
    }
  }

  Future<void> _markRequestAsApproved() async {
    if (cleanRequestId.isEmpty) return;

    await supabase
        .from('Request_Table')
        .update({'Status': 'Approved'})
        .eq('Request_ID', cleanRequestId);
  }

  Future<void> _sendQrToEmail() async {
    if (isSendingEmail) return;

    if (cleanEmail.isEmpty) {
      await _showInfoDialog(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade600,
        title: 'No Email Provided',
        message:
            'This request has no email address. Please decline the request or ask the resident to submit again with an email.',
      );
      return;
    }

    if (qrData.trim().isEmpty) {
      await _showInfoDialog(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade600,
        title: 'No QR Available',
        message: 'No QR code is available to send.',
      );
      return;
    }

    final bool? confirm = await _showSendConfirmationDialog();
    if (confirm != true) return;

    setState(() => isSendingEmail = true);

    try {
      /*
        STEP 1:
        Convert the QR ID design into PDF bytes.
      */
      final pdfBytes = await _generatePdfBytes();

      /*
        STEP 2:
        Convert PDF bytes into Base64 so it can be sent to Supabase Function.
      */
      final pdfBase64 = base64Encode(pdfBytes);

      /*
        STEP 3:
        Send the PDF Base64 to the Supabase Edge Function.
        The function will attach the PDF to the email.
      */
      final response = await supabase.functions.invoke(
        'send_qr_email',
        body: {
          'request_id': cleanRequestId,
          'email': cleanEmail,
          'full_name': fullName,
          'registration_id': widget.registrationId,
          'pdf_base64': pdfBase64,
          'filename': safeFileName,
        },
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception(response.data.toString());
      }

      /*
        STEP 4:
        Mark the request as Approved only after the email was sent.
      */
      await _markRequestAsApproved();

      if (!mounted) return;

      await _showInfoDialog(
        icon: Icons.mark_email_read_rounded,
        iconColor: primaryGreen,
        title: 'QR Sent Successfully',
        message:
            'The QR ID PDF has been sent to $cleanEmail. The request is now marked as Approved.',
      );
    } catch (e) {
      if (!mounted) return;

      await _showInfoDialog(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade600,
        title: 'Email Sending Failed',
        message:
            'The QR PDF was created, but it was not sent.\n\nError: $e\n\nMake sure your Supabase Function has RESEND_API_KEY in secrets.',
      );
    } finally {
      if (mounted) {
        setState(() => isSendingEmail = false);
      }
    }
  }

  Future<bool?> _showSendConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 600 ? 430 : screenWidth * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 58,
                    color: primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Send QR PDF to Email?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The system will convert the QR ID into a PDF and send it to:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cleanEmail,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Send PDF',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  Future<void> _showInfoDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 600 ? 430 : screenWidth * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primaryGreen.withOpacity(0.15)),
            ),
            child: qrData.isNotEmpty
                ? QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 250,
                    gapless: true,
                    foregroundColor: Colors.black,
                  )
                : Text(
                    'No QR code available',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
          ),
          const SizedBox(height: 26),
          Text(
            'Head of the Family',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          _detailRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Registration ID:',
            value: widget.registrationId,
          ),
          const SizedBox(height: 10),
          _detailRow(
            icon: Icons.email_outlined,
            label: 'Send To:',
            value: cleanEmail.isEmpty ? 'No email provided' : cleanEmail,
          ),
          const SizedBox(height: 10),
          _detailRow(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Attachment:',
            value: safeFileName,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isSendingEmail || isLoading ? null : _sendQrToEmail,
                icon: isSendingEmail
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.email_rounded, color: Colors.white),
                label: Text(
                  isSendingEmail ? 'Sending PDF...' : 'Send QR PDF to Email',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: primaryGreen.withOpacity(0.45),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: isLoading || isSendingEmail ? null : _printPdf,
                      icon: const Icon(
                        Icons.print,
                        color: Colors.white,
                        size: 19,
                      ),
                      label: Text(
                        'Print ID',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: isLoading || isSendingEmail
                          ? null
                          : _downloadPdf,
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      label: Text(
                        'Download',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: darkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'The system will convert this QR ID layout into a PDF file and send it to the resident email as an attachment.',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'QR Code Preview',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: isSendingEmail ? null : () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      _infoNotice(),
                      const SizedBox(height: 20),
                      _buildQrCard(),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }
}
