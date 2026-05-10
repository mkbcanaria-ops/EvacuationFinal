import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'LoginPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  static const Color primaryGreen = Color(0xFF0D743D);
  static const Color darkGreen = Color(0xFF075C2E);
  static const Color softGreen = Color(0xFFEAF7EF);
  static const Color dangerRed = Color(0xFFD32F2F);

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (email.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      return _showDialog(
        "Missing Fields",
        "Please complete all required fields.",
        true,
      );
    }

    if (newPass != confirmPass) {
      return _showDialog(
        "Password Mismatch",
        "New password and confirm password do not match.",
        true,
      );
    }

    final passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$',
    );

    if (!passwordRegex.hasMatch(newPass)) {
      return _showDialog(
        "Weak Password",
        "Your password must contain:\n\n"
            "• At least 8 characters\n"
            "• One uppercase letter\n"
            "• One lowercase letter\n"
            "• One number\n"
            "• One special character (!@#\$&*~)",
        true,
      );
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(email);

      final verified = await _showTokenDialog(email, newPass);

      if (verified) {
        await _showDialog(
          "Password Updated",
          "Your password has been successfully updated.",
          false,
        );

        _emailController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        await _showDialog(
          "Verification Failed",
          "The verification code is invalid or expired.",
          true,
        );
      }
    } catch (e) {
      await _showDialog(
        "Error",
        "Failed to send verification code.\n\n${e.toString()}",
        true,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showTokenDialog(String email, String newPass) async {
    final TextEditingController tokenController = TextEditingController();

    bool verified = false;
    bool timerStarted = false;
    int remainingTime = 120;
    Timer? timer;

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
            if (!timerStarted) {
              timerStarted = true;
              startTimer(setStateDialog);
            }

            final bool isExpired = remainingTime <= 0;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: softGreen,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: primaryGreen,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Email Verification",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "A 6-digit verification code was sent to your email. Enter it below before it expires.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: tokenController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: "------",
                          hintStyle: GoogleFonts.poppins(
                            letterSpacing: 8,
                            color: Colors.black26,
                          ),
                          counterText: "",
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: primaryGreen,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red.withOpacity(0.08)
                              : softGreen,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          isExpired
                              ? "Code expired"
                              : "Code expires in ${formatTime(remainingTime)}",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isExpired ? dangerRed : primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpired
                                ? Colors.grey
                                : primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isExpired
                              ? null
                              : () async {
                                  final token = tokenController.text.trim();

                                  if (token.length != 6) {
                                    return;
                                  }

                                  try {
                                    await supabase.auth.verifyOTP(
                                      email: email,
                                      token: token,
                                      type: OtpType.recovery,
                                    );

                                    await supabase.auth.updateUser(
                                      UserAttributes(password: newPass),
                                    );

                                    verified = true;
                                  } catch (_) {
                                    verified = false;
                                  }

                                  timer?.cancel();

                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            "Verify Code",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          timer?.cancel();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
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
      },
    );

    timer?.cancel();
    tokenController.dispose();

    return verified;
  }

  Future<void> _showDialog(String title, String message, bool isError) async {
    final Color mainColor = isError ? dangerRed : primaryGreen;
    final IconData icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: mainColor, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: mainColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
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
                          fontSize: 13.5,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
    bool? isVisible,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !(isVisible ?? false) : false,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black38),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 10, right: 8),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        suffixIcon: isPassword
            ? IconButton(
                splashRadius: 20,
                icon: Icon(
                  (isVisible ?? false)
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.black45,
                  size: 20,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildPasswordHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: primaryGreen, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Use at least 8 characters with uppercase, lowercase, number, and special character.",
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.45,
                color: darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        Container(
          height: 92,
          width: 92,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/images/Logo2.jpg', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Reset Password",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: primaryGreen,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Enter your email and new password to continue.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            height: 1.4,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildResetCard(double screenWidth) {
    final bool isSmall = screenWidth < 600;

    return Container(
      width: isSmall ? screenWidth * 0.90 : 430,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 22 : 30,
        vertical: isSmall ? 24 : 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoHeader(),
          const SizedBox(height: 26),
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            hint: "Enter your email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isPassword: false,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _newPasswordController,
            label: "New Password",
            hint: "Enter new password",
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            isVisible: _isPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Confirm Password",
            hint: "Confirm new password",
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            isVisible: _isConfirmPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildPasswordHint(),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: primaryGreen.withOpacity(0.55),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 21,
                      width: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 19,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Reset Password",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              "Back to Login",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: primaryGreen),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Mainpic1.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.72),
                  primaryGreen.withOpacity(0.45),
                  Colors.black.withOpacity(0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: screenHeight < 700 ? 18 : 28,
                ),
                child: _buildResetCard(screenWidth),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
