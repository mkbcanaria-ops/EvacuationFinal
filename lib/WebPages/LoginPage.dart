import 'dart:ui';

import 'package:evacutaion/ResidentPAges/ResidentDashboard.dart';
import 'package:evacutaion/WebPages/ForgotPassword.dart';
import 'package:evacutaion/WebPages/SignUp.dart';
import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  static const Color primaryGreen = Color(0xFF0D743D);
  static const Color darkGreen = Color(0xFF084F2A);
  static const Color lightGreen = Color(0xFF49A76E);
  static const Color softWhite = Color(0xFFF8FBF8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isAuthUserVerified(User user) {
    return user.emailConfirmedAt != null || user.confirmedAt != null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 800;
    final bool isSmallMobile = size.width < 500;

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
                    Colors.black.withOpacity(0.75),
                    darkGreen.withOpacity(0.68),
                    Colors.black.withOpacity(0.72),
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
            top: 100,
            right: 80,
            child: _decorCircle(size: 120, color: lightGreen.withOpacity(0.08)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 18 : 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isMobile) ...[
                        Expanded(
                          flex: 11,
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
                        child: _buildLoginCard(isMobile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen.withOpacity(0.12),
                      lightGreen.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 70,
              width: 70,
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
        const SizedBox(height: 42),
        Text(
          "Manage Evacuation,\nProtect Every Resident.",
          style: GoogleFonts.poppins(
            fontSize: 42,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 70,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFA7E0B7),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            "A digital system for managing resident evacuation, registration, deployment, monitoring, and reporting during emergency situations.",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.88),
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 34),
        _featureTile(
          icon: Icons.how_to_reg_rounded,
          title: "Resident Registration",
          subtitle:
              "Record and organize resident information for faster evacuation assistance.",
        ),
        const SizedBox(height: 18),
        _featureTile(
          icon: Icons.location_on_rounded,
          title: "Evacuation Center Monitoring",
          subtitle:
              "Track evacuees, assigned sites, family members, and current evacuation status.",
        ),
        const SizedBox(height: 18),
        _featureTile(
          icon: Icons.assessment_rounded,
          title: "Reliable Reports",
          subtitle:
              "Generate accurate evacuation reports to support quick decisions and response.",
        ),
        const SizedBox(height: 38),
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

  Widget _buildLoginCard(bool isMobile) {
    final double cardWidth = isMobile ? double.infinity : 470;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: cardWidth,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 22 : 34,
              vertical: isMobile ? 26 : 34,
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
                    height: 92,
                    width: 92,
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
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "System Login",
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
                    "Access the MSWDO-Santa eCamp Management System",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildTextField(
                    controller: _emailController,
                    label: "Email Address",
                    hintText: "Enter your registered email address",
                    icon: Icons.email_outlined,
                    isPassword: false,
                  ),
                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    hintText: "Enter your account password",
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isVisible: _isPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                      ),
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: primaryGreen.withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A8A4E), Color(0xFF084F2A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
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
                                      "LOGIN",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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

                  const SizedBox(height: 24),

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

                  const SizedBox(height: 22),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "New resident user? ",
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: "Register Account",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isPassword,
    bool? isVisible,
    VoidCallback? onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !(isVisible ?? false) : false,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return "This field is required.";
            }

            if (!isPassword) {
              final email = value!.trim();
              final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
              if (!emailRegex.hasMatch(email)) {
                return "Please enter a valid email address.";
              }
            }

            return null;
          },
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
            fillColor: softWhite.withOpacity(0.95),
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

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _showPopup(
        "Invalid Input",
        "Please enter a valid email address and password to access the evacuation system.",
        isError: true,
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        await _showPopup(
          "Login Failed",
          "Invalid email or password. Please check your account details.",
          isError: true,
        );
        return;
      }

      final uid = user.id;

      final adminRecord = await supabase
          .from('Admin_Account')
          .select('Admin_ID')
          .eq('Admin_ID', uid)
          .maybeSingle();

      if (adminRecord != null) {
        await _showPopup(
          "Admin Login Successful",
          "Welcome back. You may now manage resident evacuation records, evacuation centers, and reports.",
          autoClose: true,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WebMainDashboard()),
        );
        return;
      }

      if (!_isAuthUserVerified(user)) {
        await supabase.auth.signOut();

        await _showPopup(
          "Account Not Verified",
          "Your account exists, but your email is not yet verified. Please check your email and verify your account before logging in.",
          isError: true,
        );
        return;
      }

      final userRecord = await supabase
          .from('Users')
          .select('UID, Email')
          .eq('UID', uid)
          .maybeSingle();

      if (userRecord == null) {
        await supabase.auth.signOut();

        await _showPopup(
          "User Record Not Found",
          "Your account is verified, but no matching record was found in the Users table. Please register first or contact the system administrator.",
          isError: true,
        );
        return;
      }

      await _showPopup(
        "Login Successful",
        "Welcome to the resident evacuation portal.",
        autoClose: true,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResidentDashboardPage()),
      );
    } on AuthException catch (e) {
      await _showPopup("Authentication Error", e.message, isError: true);
    } catch (e) {
      await _showPopup("Unexpected Error", e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPopup(
    String title,
    String message, {
    bool isError = false,
    bool autoClose = false,
  }) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: !autoClose,
      barrierLabel: 'Popup',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        final curved = Curves.easeOutBack.transform(animation.value);

        return Transform.scale(
          scale: curved,
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              elevation: 18,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              title: Column(
                children: [
                  Container(
                    height: 76,
                    width: 76,
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
                      size: 42,
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
              content: message.isNotEmpty
                  ? Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    )
                  : const SizedBox.shrink(),
              actionsAlignment: MainAxisAlignment.center,
              actions: !autoClose
                  ? [
                      SizedBox(
                        width: 130,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isError
                                ? Colors.redAccent
                                : primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "OK",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
        );
      },
    );

    if (autoClose) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}
