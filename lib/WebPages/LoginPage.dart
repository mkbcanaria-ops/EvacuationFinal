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
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Mainpic1.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.65)),

          Align(
            alignment: const Alignment(0, 0.3),
            child: Container(
              width: screenWidth < 600 ? screenWidth * 0.75 : screenWidth * 0.3,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/Logo2.jpg',
                      height: 150,
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Evacuation Login",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D743D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Login to continue to the MSWDO Evacuation Portal",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 26),

                    // 📧 Email
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      isPassword: false,
                    ),
                    const SizedBox(height: 16),

                    // 🔒 Password
                    _buildTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline,
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
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: const Color(0xFF0D743D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 🚀 Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D743D),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Text(
                                "LOGIN",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.7,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                          text: "Don’t have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: "Register Now",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF0D743D),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 TextField builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
    bool? isVisible,
    VoidCallback? onVisibilityToggle,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return TextField(
            controller: controller,
            obscureText: isPassword ? !(isVisible ?? false) : false,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: hasFocus ? const Color(0xFF0D743D) : Colors.grey[700],
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF0D743D), size: 19),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        (isVisible ?? false)
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showPopup(
        "Missing Information",
        "Please fill in all fields before continuing.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔐 Authenticate using Supabase Auth
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        _showPopup("Login Failed", "Invalid email or password.", isError: true);
        return;
      }

      final uid = user.id;

      // 👉 Check if user is a RESIDENT
      final residentRecord = await supabase
          .from('Users')
          .select('Status')
          .eq('UID', uid)
          .maybeSingle();

      // 👉 Check if user is an ADMIN
      final adminRecord = await supabase
          .from('Admin_Account')
          .select('Status')
          .eq('Admin_ID', uid)
          .maybeSingle();

      // ---------------------------
      // RESIDENT LOGIN
      // ---------------------------
      if (residentRecord != null) {
        if (residentRecord['Status'] != 'Active') {
          _showPopup(
            "Access Denied",
            "Your resident account is blocked.",
            isError: true,
          );
          return;
        }

        await _showPopup("Login Successful", "", autoClose: true);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ResidentDashboardPage(),
            ),
          );
        }
        return;
      }

      // ---------------------------
      // ADMIN LOGIN
      // ---------------------------
      if (adminRecord != null) {
        if (adminRecord['Status'] != 'Active') {
          _showPopup(
            "Access Denied",
            "Your admin account is blocked.",
            isError: true,
          );
          return;
        }

        await _showPopup("Admin Login Successful", "", autoClose: true);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WebMainDashboard()),
          );
        }
        return;
      }

      // If email/password exists in auth but NO matching table record
      _showPopup(
        "Account Not Found",
        "No resident or admin record found for this account.",
        isError: true,
      );
    } on AuthException catch (e) {
      _showPopup("Authentication Error", e.message, isError: true);
    } catch (e) {
      _showPopup("Unexpected Error", e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
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
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        final curvedValue = Curves.easeOutBack.transform(animation.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * -50, 0.0)
            ..scale(animation.value),
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.only(
                top: 25,
                left: 24,
                right: 24,
                bottom: 0,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              actionsPadding: const EdgeInsets.only(
                bottom: 18,
                left: 18,
                right: 18,
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!isError)
                          BoxShadow(
                            color: const Color(0xFF0D743D).withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                      ],
                    ),
                    child: Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_rounded,
                      color: isError
                          ? Colors.redAccent
                          : const Color(0xFF0D743D),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isError
                          ? Colors.redAccent
                          : const Color(0xFF0D743D),
                    ),
                  ),
                ],
              ),
              content: message.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              actionsAlignment: MainAxisAlignment.center,
              actions: !autoClose
                  ? [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isError
                              ? Colors.redAccent
                              : const Color(0xFF0D743D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "OK",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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

    // Auto close for success popups
    if (autoClose) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    }
  }
}
