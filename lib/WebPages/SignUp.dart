import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:evacutaion/WebPages/Loginpage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final supabase = Supabase.instance.client;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Mainpic1.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.6)),

          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ), // space top & bottom
              child: Container(
                width: screenWidth < 600
                    ? screenWidth * 0.85
                    : screenWidth * 0.38,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/Logo2.jpg',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        "Create Account",
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D743D),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PERSONAL INFORMATION
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Personal Information",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0D743D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildTextField(
                        controller: _firstNameController,
                        label: "First Name",
                        icon: Icons.person_outline,
                        isPassword: false,
                      ),
                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: _middleNameController,
                        label: "Middle Name (Optional)",
                        icon: Icons.person_outline,
                        isPassword: false,
                      ),
                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: _lastNameController,
                        label: "Last Name",
                        icon: Icons.person_outline,
                        isPassword: false,
                      ),
                      const SizedBox(height: 16),

                      // ADDRESS INFORMATION
                      _buildTextField(
                        controller: _provinceController,
                        label: "Province",
                        icon: Icons.location_on_outlined,
                        isPassword: false,
                      ),
                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: _municipalityController,
                        label: "Municipality",
                        icon: Icons.location_city_outlined,
                        isPassword: false,
                      ),
                      const SizedBox(height: 10),

                      _buildTextField(
                        controller: _barangayController,
                        label: "Barangay",
                        icon: Icons.home_work_outlined,
                        isPassword: false,
                      ),
                      const SizedBox(height: 16),

                      // CONTACT NUMBER
                      _buildTextField(
                        controller: _contactController,
                        label: "Contact Number",
                        icon: Icons.phone_outlined,
                        isPassword: false,
                      ),
                      const SizedBox(height: 16),

                      // ACCOUNT CREDENTIALS
                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        isPassword: false,
                      ),
                      const SizedBox(height: 10),

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

                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: "Confirm Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // TERMS
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            activeColor: const Color(0xFF0D743D),
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsDialog,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "I agree to the ",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Terms & Privacy Policy",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0D743D),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // SIGN UP BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _agreeToTerms && !_isLoading
                              ? _handleSignUp
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D743D),
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                                  "Sign Up",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // LOGIN LINK
                      Text.rich(
                        TextSpan(
                          text: "Already have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: "Log in",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF0D743D),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                            ),
                          ],
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
    bool? isVisible,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !(isVisible ?? false) : false,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF0D743D), size: 18),
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
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Terms & Privacy Policy",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D743D),
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            "By creating an account, you agree to our Terms of Service and Privacy Policy. "
            "We value your privacy and are committed to protecting your personal information.",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.poppins(
                color: const Color(0xFF0D743D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim(); // optional
    final lastName = _lastNameController.text.trim();

    final province = _provinceController.text.trim();
    final municipality = _municipalityController.text.trim();
    final barangay = _barangayController.text.trim();

    final contactNumber = _contactController.text.trim(); // ✅ FIXED

    // ----------------------------------------
    // VALIDATION
    // ----------------------------------------
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        province.isEmpty ||
        municipality.isEmpty ||
        barangay.isEmpty ||
        contactNumber.isEmpty ||
        email.isEmpty ||
        pass.isEmpty ||
        confirmPass.isEmpty) {
      _showDialog(
        title: "Missing Information",
        message: "Please fill in all required fields before continuing.",
        isError: true,
      );
      return;
    }

    if (pass != confirmPass) {
      _showDialog(
        title: "Password Mismatch",
        message: "Your passwords do not match. Please re-enter them correctly.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check duplicate email
      final existingUser = await supabase
          .from('Users')
          .select('Email')
          .eq('Email', email)
          .maybeSingle();

      if (existingUser != null) {
        await _showDialog(
          title: "Duplicate Email Detected",
          message:
              "The email address '$email' is already registered.\n\nPlease use a different email or log in instead.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Create Auth user
      final response = await supabase.auth.signUp(email: email, password: pass);

      if (response.user == null) {
        throw Exception("Failed to create account. Please try again.");
      }

      // OTP Verification
      final verified = await _showTokenDialog(email);

      if (!verified) {
        await _showDialog(
          title: "Verification Failed",
          message:
              "Incorrect or expired token entered. Please check your email and try again.",
          isError: true,
        );
        return;
      }

      // Insert full user info
      await supabase.from('Users').insert({
        'UID': response.user!.id,
        'Email': email,

        // Personal info
        'First_Name': firstName,
        'Middle_Name': middleName.isEmpty ? null : middleName,
        'Last_Name': lastName,

        // Address
        'Province': province,
        'Municipality': municipality,
        'Barangay': barangay,

        // Contact
        'Contact_Number': contactNumber,
      });

      await _showDialog(
        title: "Account Verified",
        message:
            "Your account has been successfully created and verified.\n\nYou may now log in using your email.",
        isError: false,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      await _showDialog(
        title: "Unexpected Error",
        message: "An error occurred while creating your account.\n\n$e",
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Token Dialog (verifies using Supabase OTP)
  Future<bool> _showTokenDialog(String email) async {
    final TextEditingController tokenController = TextEditingController();
    bool verified = false;
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
      final minutes = (seconds ~/ 60).toString().padLeft(1, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      return "$minutes:$secs";
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (remainingTime == 120) startTimer(setStateDialog);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Email Verification",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "A 6-digit verification code has been sent to your email.\n\nPlease enter it below before it expires.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: tokenController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: "Enter 6-digit code",
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    remainingTime > 0
                        ? "Code expires in ${formatTime(remainingTime)}"
                        : "Code expired",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: remainingTime > 0
                          ? Colors.grey[700]
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: remainingTime > 0
                          ? const Color(0xFF0D743D)
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    onPressed: remainingTime > 0
                        ? () async {
                            final token = tokenController.text.trim();

                            try {
                              // ✅ Verify using Supabase Auth API
                              await supabase.auth.verifyOTP(
                                email: email,
                                token: token,
                                type: OtpType.signup,
                              );
                              verified = true;
                            } catch (e) {
                              verified = false;
                            }

                            timer?.cancel();
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text(
                      "Verify",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
    return verified;
  }

  /// ✅ Reusable alert dialog
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
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red.shade700 : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isError
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError
                      ? Colors.red.shade700
                      : const Color(0xFF0D743D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
