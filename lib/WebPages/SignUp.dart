import 'dart:async';
import 'dart:ui';

import 'package:evacutaion/WebPages/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final supabase = Supabase.instance.client;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  static const Color primaryGreen = Color(0xFF0D743D);
  static const Color darkGreen = Color(0xFF084F2A);
  static const Color lightGreen = Color(0xFF49A76E);
  static const Color softWhite = Color(0xFFF8FBF8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _provinceController.dispose();
    _municipalityController.dispose();
    _barangayController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;
    final bool isSmallMobile = size.width < 520;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/Mainpic1.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.76),
                    darkGreen.withOpacity(0.68),
                    Colors.black.withOpacity(0.74),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Positioned(
            top: -80,
            left: -80,
            child: _decorCircle(size: 220, color: lightGreen.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _decorCircle(
              size: 260,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Positioned(
            top: 120,
            right: 90,
            child: _decorCircle(size: 120, color: lightGreen.withOpacity(0.08)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 16 : 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile) ...[
                        Expanded(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 30,
                              left: 10,
                              top: 20,
                              bottom: 20,
                            ),
                            child: _buildLeftPanel(),
                          ),
                        ),
                      ],
                      Expanded(
                        flex: isMobile ? 1 : 9,
                        child: _buildSignUpCard(isMobile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              height: 72,
              width: 72,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/Logo2.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MSWDO-Santa",
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "eCamp Management System",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: const Color(0xFFA7E0B7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          "Register Today,\nBe Ready When It Matters.",
          style: GoogleFonts.poppins(
            fontSize: 42,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 72,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFA7E0B7),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          "Create your resident account so your information can be accessed faster during evacuation, emergency assistance, and disaster response operations.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.88),
            height: 1.7,
          ),
        ),
        const SizedBox(height: 34),
        _featureTile(
          icon: Icons.person_add_alt_1_rounded,
          title: "Resident Evacuation Profile",
          subtitle:
              "Register your basic information, address, and contact number for faster identification during emergencies.",
        ),
        const SizedBox(height: 18),
        _featureTile(
          icon: Icons.home_work_rounded,
          title: "Barangay-Based Records",
          subtitle:
              "Your address details help the system organize residents by province, municipality, and barangay.",
        ),
        const SizedBox(height: 18),
        _featureTile(
          icon: Icons.health_and_safety_rounded,
          title: "Faster Emergency Support",
          subtitle:
              "Registered residents can be managed more easily during evacuation, deployment, monitoring, and reporting.",
        ),
        const SizedBox(height: 40),
        Text(
          "MSWDO-Santa eCamp Management System\n© 2026 All rights reserved.",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white.withOpacity(0.72),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A8A4E).withOpacity(0.30),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: Colors.white.withOpacity(0.82),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpCard(bool isMobile) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: isMobile ? double.infinity : 690,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 30,
              vertical: isMobile ? 24 : 28,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.84),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [primaryGreen, darkGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.assignment_ind_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Resident Registration",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 28 : 34,
                      fontWeight: FontWeight.w700,
                      color: darkGreen,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Create your account for the MSWDO-Santa eCamp Management System",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionCard(
                    title: "Resident Personal Information",
                    icon: Icons.badge_outlined,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool useTwoColumns = constraints.maxWidth > 560;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _firstNameController,
                                label: "First Name",
                                hintText: "Enter your first name",
                                icon: Icons.person_outline,
                                isPassword: false,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return "First name is required.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _middleNameController,
                                label: "Middle Name (Optional)",
                                hintText: "Enter your middle name",
                                icon: Icons.person_outline,
                                isPassword: false,
                              ),
                            ),
                            _buildFieldItem(
                              width: constraints.maxWidth,
                              child: _buildTextField(
                                controller: _lastNameController,
                                label: "Last Name",
                                hintText: "Enter your last name",
                                icon: Icons.person_outline,
                                isPassword: false,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return "Last name is required.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    title: "Resident Address Information",
                    icon: Icons.location_on_outlined,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool useTwoColumns = constraints.maxWidth > 560;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _provinceController,
                                label: "Province",
                                hintText: "Enter your province",
                                icon: Icons.map_outlined,
                                isPassword: false,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return "Province is required.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _municipalityController,
                                label: "Municipality",
                                hintText: "Enter your municipality",
                                icon: Icons.location_city_outlined,
                                isPassword: false,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return "Municipality is required.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _buildFieldItem(
                              width: constraints.maxWidth,
                              child: _buildTextField(
                                controller: _barangayController,
                                label: "Barangay",
                                hintText: "Enter your barangay",
                                icon: Icons.home_work_outlined,
                                isPassword: false,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return "Barangay is required.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    title: "Emergency Contact & Account Credentials",
                    icon: Icons.lock_outline_rounded,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool useTwoColumns = constraints.maxWidth > 560;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _contactController,
                                label: "Contact Number",
                                hintText: "Enter your active contact number",
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                isPassword: false,
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) {
                                    return "Contact number is required.";
                                  }
                                  if (text.length < 7) {
                                    return "Please enter a valid contact number.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _emailController,
                                label: "Email Address",
                                hintText: "Enter your active email address",
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                isPassword: false,
                                validator: (value) {
                                  final email = (value ?? '').trim();
                                  if (email.isEmpty) {
                                    return "Email is required.";
                                  }
                                  final emailRegex = RegExp(
                                    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                  );
                                  if (!emailRegex.hasMatch(email)) {
                                    return "Please enter a valid email.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _passwordController,
                                label: "Password",
                                hintText: "Create your account password",
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                onVisibilityToggle: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                validator: (value) {
                                  final pass = (value ?? '').trim();
                                  if (pass.isEmpty) {
                                    return "Password is required.";
                                  }
                                  if (pass.length < 6) {
                                    return "Password must be at least 6 characters.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            _buildFieldItem(
                              width: useTwoColumns
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _buildTextField(
                                controller: _confirmPasswordController,
                                label: "Confirm Password",
                                hintText: "Re-enter your account password",
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isVisible: _isConfirmPasswordVisible,
                                onVisibilityToggle: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                                validator: (value) {
                                  final confirm = (value ?? '').trim();
                                  if (confirm.isEmpty) {
                                    return "Please confirm your password.";
                                  }
                                  if (confirm !=
                                      _passwordController.text.trim()) {
                                    return "Passwords do not match.";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: softWhite.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.16)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          activeColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Wrap(
                              children: [
                                Text(
                                  "I confirm that the information provided is true and I agree to the ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showTermsDialog,
                                  child: Text(
                                    "Terms & Privacy Policy",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: (_agreeToTerms && !_isLoading)
                          ? _handleSignUp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: primaryGreen.withOpacity(0.45),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: (_agreeToTerms && !_isLoading)
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1A8A4E),
                                    Color(0xFF084F2A),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade500,
                                    Colors.grey.shade600,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.6,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "REGISTER RESIDENT",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey.withOpacity(0.35),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "or",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Already registered? ",
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: "Log in to your account",
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: primaryGreen,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softWhite.withOpacity(0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldItem({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isPassword,
    bool? isVisible,
    VoidCallback? onVisibilityToggle,
    TextInputType? keyboardType,
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
          obscureText: isPassword ? !(isVisible ?? false) : false,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            prefixIcon: Icon(icon, color: primaryGreen, size: 21),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onVisibilityToggle,
                    icon: Icon(
                      (isVisible ?? false)
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.grey[600],
                      size: 21,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.96),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.18)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: primaryGreen, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _decorCircle({required double size, required Color color}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Terms & Privacy Policy",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: darkGreen,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            "By creating an account, you allow the MSWDO-Santa eCamp Management System to store and use your provided information for resident identification, evacuation assistance, emergency monitoring, and report generation. Your personal information will be handled with care and used only for system-related and emergency response purposes.",
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.black87,
              height: 1.7,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.poppins(
                color: primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    if (!_agreeToTerms) {
      await _showDialog(
        title: "Agreement Required",
        message:
            "Please confirm the Terms & Privacy Policy before creating your resident evacuation account.",
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      await _showDialog(
        title: "Incomplete Information",
        message:
            "Please check all required resident information before continuing.",
        isError: true,
      );
      return;
    }

    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    final province = _provinceController.text.trim();
    final municipality = _municipalityController.text.trim();
    final barangay = _barangayController.text.trim();

    final contactNumber = _contactController.text.trim();

    if (pass != confirmPass) {
      await _showDialog(
        title: "Password Mismatch",
        message: "Your passwords do not match. Please re-enter them correctly.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existingUser = await supabase
          .from('Users')
          .select('Email')
          .eq('Email', email)
          .maybeSingle();

      if (existingUser != null) {
        await _showDialog(
          title: "Email Already Registered",
          message:
              "The email address '$email' is already registered in the evacuation system.\n\nPlease use a different email or log in instead.",
          isError: true,
        );
        return;
      }

      final response = await supabase.auth.signUp(email: email, password: pass);

      if (response.user == null) {
        throw Exception("Failed to create resident account. Please try again.");
      }

      final verified = await _showTokenDialog(email);

      if (!verified) {
        await _showDialog(
          title: "Verification Failed",
          message:
              "Incorrect or expired verification code. Please check your email and try again.",
          isError: true,
        );
        return;
      }

      await supabase.from('Users').insert({
        'UID': response.user!.id,
        'Email': email,
        'First_Name': firstName,
        'Middle_Name': middleName.isEmpty ? null : middleName,
        'Last_Name': lastName,
        'Province': province,
        'Municipality': municipality,
        'Barangay': barangay,
        'Contact_Number': contactNumber,
      });

      await _showDialog(
        title: "Resident Account Verified",
        message:
            "Your resident account has been successfully created and verified.\n\nYou may now log in to access the MSWDO-Santa eCamp Management System.",
        isError: false,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      await _showDialog(
        title: "Account Creation Error",
        message:
            "An error occurred while creating your resident evacuation account.\n\n$e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showTokenDialog(String email) async {
    final TextEditingController tokenController = TextEditingController();
    bool verified = false;
    int remainingTime = 120;
    Timer? timer;
    bool hasStartedTimer = false;

    void startTimer(void Function(void Function()) setStateDialog) {
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (remainingTime > 0) {
          setStateDialog(() => remainingTime--);
        } else {
          t.cancel();
        }
      });
    }

    String formatTime(int seconds) {
      final minutes = (seconds ~/ 60).toString();
      final secs = (seconds % 60).toString().padLeft(2, '0');
      return "$minutes:$secs";
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (!hasStartedTimer) {
              hasStartedTimer = true;
              startTimer(setStateDialog);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Column(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryGreen.withOpacity(0.10),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: primaryGreen,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Verify Resident Account",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 21,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "A 6-digit verification code has been sent to your email.\n\nPlease enter it below to confirm your resident registration.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter 6-digit code",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                      counterText: "",
                      filled: true,
                      fillColor: softWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.18),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.18),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(color: primaryGreen, width: 1.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    remainingTime > 0
                        ? "Code expires in ${formatTime(remainingTime)}"
                        : "Code expired",
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: remainingTime > 0
                          ? Colors.grey[700]
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: 150,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: remainingTime > 0
                          ? primaryGreen
                          : Colors.grey,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: remainingTime > 0
                        ? () async {
                            final token = tokenController.text.trim();

                            try {
                              await supabase.auth.verifyOTP(
                                email: email,
                                token: token,
                                type: OtpType.signup,
                              );
                              verified = true;
                            } catch (_) {
                              verified = false;
                            }

                            timer?.cancel();
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: Text(
                      "Verify",
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
      },
    );

    timer?.cancel();
    tokenController.dispose();
    return verified;
  }

  Future<void> _showDialog({
    required String title,
    required String message,
    required bool isError,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Container(
                height: 72,
                width: 72,
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
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isError ? Colors.redAccent : darkGreen,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 130,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.redAccent : primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
