// ignore_for_file: use_build_context_synchronously

import 'package:evacutaion/ResidentPAges/ResidentDashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentQrRequestPage extends StatefulWidget {
  const ResidentQrRequestPage({super.key});

  @override
  State<ResidentQrRequestPage> createState() => _ResidentQrRequestPageState();
}

class _ResidentQrRequestPageState extends State<ResidentQrRequestPage> {
  final supabase = Supabase.instance.client;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  bool _isSubmitting = false;

  static const Color primaryGreen = Color(0xFF0D743D);
  static const Color darkGreen = Color(0xFF084F2A);
  static const Color softGreen = Color(0xFFEAF6EF);
  static const Color lightBackground = Color(0xFFF6FAF7);

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: lightBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkGreen,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request QR Code',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 28,
              vertical: 18,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(isMobile),
                  const SizedBox(height: 18),
                  _buildFormCard(isMobile),
                  const SizedBox(height: 16),
                  _buildReminderCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryGreen.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A8A4E), Color(0xFF084F2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "QR Code Request",
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "Submit a request if you need a QR code for evacuation identification and resident processing.",
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.black,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.person_pin_rounded,
              title: "Resident Information",
              subtitle:
                  "Please enter the details of the head of the family accurately.",
            ),
            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                final bool twoColumns = constraints.maxWidth > 580;
                final double itemWidth = twoColumns
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 14,
                  runSpacing: 16,
                  children: [
                    _fieldBox(
                      width: itemWidth,
                      child: _buildTextField(
                        controller: firstNameController,
                        label: 'First Name',
                        hintText: 'Enter first name',
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'First name is required.';
                          }
                          return null;
                        },
                      ),
                    ),
                    _fieldBox(
                      width: itemWidth,
                      child: _buildTextField(
                        controller: middleNameController,
                        label: 'Middle Name',
                        hintText: 'Optional',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    _fieldBox(
                      width: itemWidth,
                      child: _buildTextField(
                        controller: lastNameController,
                        label: 'Last Name',
                        hintText: 'Enter last name',
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Last name is required.';
                          }
                          return null;
                        },
                      ),
                    ),
                    _fieldBox(
                      width: itemWidth,
                      child: _buildTextField(
                        controller: emailController,
                        label: 'Email Address',
                        hintText: 'Enter active email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = (value ?? '').trim();

                          if (email.isEmpty) {
                            return 'Email address is required.';
                          }

                          final emailRegex = RegExp(
                            r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                          );

                          if (!emailRegex.hasMatch(email)) {
                            return 'Please enter a valid email.';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: reasonController,
              label: 'Reason for QR Code Request',
              hintText: 'Example: I need my QR code for evacuation monitoring.',
              icon: Icons.edit_note_rounded,
              maxLines: 4,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Reason is required.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryGreen.withOpacity(0.10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: primaryGreen,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Make sure the name belongs to the registered head of the family. This request will be reviewed by the administrator.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.black87,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade500,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _isSubmitting
                        ? LinearGradient(
                            colors: [
                              Colors.grey.shade500,
                              Colors.grey.shade600,
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF1A8A4E), Color(0xFF084F2A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Submitting...',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Submit Request',
                                style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: primaryGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'After submission, your request status will remain pending until reviewed by the administrator.',
              style: GoogleFonts.poppins(
                fontSize: 12.8,
                color: Colors.black87,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryGreen, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldBox({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            prefixIcon: Icon(icon, color: primaryGreen, size: 21),
            filled: true,
            fillColor: const Color(0xFFF9FBFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.16)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.16)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: primaryGreen, width: 1.35),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      await _showMessage(
        title: 'Incomplete Details',
        message: 'Please complete all required fields before submitting.',
        isError: true,
      );
      return;
    }

    final firstName = firstNameController.text.trim();
    final middleName = middleNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final reason = reasonController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('MM-dd-yyyy hh:mm a').format(now);

      await supabase.from('Request_Table').insert({
        'First_Name': firstName,
        'Middle_Name': middleName.isEmpty ? null : middleName,
        'Last_Name': lastName,
        'Email_Address': email,
        'Reason': reason,
        'Status': 'Pending',
        'Request_Date': formattedDate,
      });

      await _showMessage(
        title: 'Request Submitted',
        message:
            'Your QR code request has been submitted successfully and is now pending administrator approval.',
        isError: false,
      );

      firstNameController.clear();
      middleNameController.clear();
      lastNameController.clear();
      emailController.clear();
      reasonController.clear();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResidentDashboardPage()),
      );
    } catch (e) {
      await _showMessage(
        title: 'Submission Failed',
        message: 'Unable to submit your QR code request.\n\nError: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showMessage({
    required String title,
    required String message,
    required bool isError,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isError,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          title: Column(
            children: [
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isError
                      ? Colors.redAccent.withOpacity(0.10)
                      : primaryGreen.withOpacity(0.10),
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_rounded,
                  color: isError ? Colors.redAccent : primaryGreen,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isError ? Colors.redAccent : darkGreen,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 120,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.redAccent : primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
