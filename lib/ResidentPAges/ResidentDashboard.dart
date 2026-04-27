import 'package:evacutaion/ResidentPAges/ResidentRegistration.dart';
import 'package:evacutaion/ResidentPAges/ResidentRequestQrCode.dart';
import 'package:evacutaion/ResidentPAges/ResidentViewQR.dart';
import 'package:evacutaion/ResidentPAges/UpdateApplication.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentDashboardPage extends StatefulWidget {
  const ResidentDashboardPage({super.key});

  @override
  State<ResidentDashboardPage> createState() => _ResidentDashboardPageState();
}

class _ResidentDashboardPageState extends State<ResidentDashboardPage> {
  String? userName;
  String? currentUid;
  bool isLoadingUser = true;
  bool isCheckingRegistration = false;

  static const Color primaryGreen = Color(0xFF0D743D);
  static const Color darkGreen = Color(0xFF084F2A);
  static const Color softGreen = Color(0xFFEAF6EF);
  static const Color lightGreen = Color(0xFF49A76E);
  static const Color cardWhite = Color(0xFFFDFDFD);

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          userName = "Resident";
          currentUid = null;
          isLoadingUser = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('Users')
          .select('First_Name')
          .eq('UID', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        currentUid = user.id;
        userName = response != null && response['First_Name'] != null
            ? response['First_Name'].toString()
            : "Resident";
        isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userName = "Resident";
        currentUid = Supabase.instance.client.auth.currentUser?.id;
        isLoadingUser = false;
      });
    }
  }

  Future<void> _openRegistrationWithCheck() async {
    final uid = currentUid ?? Supabase.instance.client.auth.currentUser?.id;

    if (uid == null || uid.isEmpty) {
      await _showMessage(
        title: "Account Not Found",
        message:
            "Unable to identify your account. Please log in again before submitting a resident registration.",
        isError: true,
      );
      return;
    }

    setState(() => isCheckingRegistration = true);

    try {
      final existingRegistration = await Supabase.instance.client
          .from('Registration_Table')
          .select('UID')
          .eq('UID', uid)
          .maybeSingle();

      if (!mounted) return;

      if (existingRegistration != null) {
        await _showMessage(
          title: "Already Registered",
          message:
              "This account is already registered in the evacuation system.\n\nOnly one resident registration is allowed per account.",
          isError: true,
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResidentRegistrationPage()),
      );
    } catch (e) {
      if (!mounted) return;

      await _showMessage(
        title: "Checking Failed",
        message:
            "Unable to check your registration record right now.\n\nPlease try again.\n\nError: $e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isCheckingRegistration = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 700;
    final bool isTablet = size.width >= 700 && size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
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
                    Colors.black.withOpacity(0.72),
                    darkGreen.withOpacity(0.62),
                    Colors.black.withOpacity(0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Positioned(
            top: -90,
            left: -80,
            child: _decorCircle(size: 240, color: lightGreen.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _decorCircle(
              size: 300,
              color: Colors.white.withOpacity(0.08),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: isMobile ? 18 : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 18 : 28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopHeader(isMobile),
                        const SizedBox(height: 24),
                        _buildHeroSection(isMobile),
                        const SizedBox(height: 24),
                        _buildNoticeCard(isMobile),
                        const SizedBox(height: 24),
                        _buildSectionTitle(),
                        const SizedBox(height: 16),
                        _buildActionGrid(isMobile, isTablet),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (isCheckingRegistration)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 34,
                          width: 34,
                          child: CircularProgressIndicator(
                            color: primaryGreen,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Checking registration...",
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
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

  Widget _buildTopHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          height: isMobile ? 54 : 66,
          width: isMobile ? 54 : 66,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryGreen.withOpacity(0.12)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset('assets/images/Logo2.jpg', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MSWDO-Santa",
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.w800,
                  color: darkGreen,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "eCamp Management System",
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 12.5 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: primaryGreen.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.health_and_safety_rounded,
                  size: 18,
                  color: primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  "Resident Portal",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D743D), Color(0xFF084F2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Icon(
              Icons.shield_rounded,
              size: isMobile ? 130 : 180,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  isLoadingUser
                      ? "Loading resident profile..."
                      : "Welcome, ${userName ?? 'Resident'}",
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12.5 : 13.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Manage Your Evacuation Services Easily",
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 25 : 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  "Submit your resident application, request or view your QR code, and keep your information ready for evacuation monitoring and emergency response.",
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 13.5 : 15,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statusChip(
                    icon: Icons.assignment_turned_in_rounded,
                    label: "Application",
                  ),
                  _statusChip(
                    icon: Icons.qr_code_2_rounded,
                    label: "QR Access",
                  ),
                  _statusChip(
                    icon: Icons.location_on_rounded,
                    label: "Evacuation Record",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Reminder: Only one resident registration is allowed per account. Please keep your information accurate and updated for faster evacuation monitoring and reporting.",
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 12.5 : 13.5,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.dashboard_customize_rounded,
            color: primaryGreen,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Resident Actions",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: darkGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(bool isMobile, bool isTablet) {
    int crossAxisCount = 1;
    double childAspectRatio = 1.45;

    if (!isMobile && isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.35;
    } else if (!isMobile && !isTablet) {
      crossAxisCount = 4;
      childAspectRatio = 1.05;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _actionCard(
          icon: Icons.app_registration_rounded,
          title: "Fill Application",
          subtitle:
              "Submit your resident evacuation application. Only one registration is allowed per account.",
          buttonText: "Start Application",
          onTap: isCheckingRegistration ? null : _openRegistrationWithCheck,
        ),
        _actionCard(
          icon: Icons.qr_code_2_rounded,
          title: "View QR Code",
          subtitle:
              "Open your assigned QR code for identification during evacuation processing.",
          buttonText: "View Code",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResidentViewQrCodePage()),
            );
          },
        ),
        _actionCard(
          icon: Icons.qr_code_scanner_rounded,
          title: "Request QR Code",
          subtitle:
              "Request a QR code if you do not have one yet or need assistance.",
          buttonText: "Request Now",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResidentQrRequestPage()),
            );
          },
        ),
        _actionCard(
          icon: Icons.edit_note_rounded,
          title: "Update Application",
          subtitle:
              "Edit or update your submitted resident evacuation information.",
          buttonText: "Update Record",
          onTap: () {
            final uid = currentUid;

            if (uid == null || uid.isEmpty) {
              _showMessage(
                title: "Account Not Found",
                message:
                    "Unable to identify your account. Please log in again before updating your application.",
                isError: true,
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UpdateRegistrationPage(uid: uid),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback? onTap,
  }) {
    final bool isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade100 : cardWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    gradient: isDisabled
                        ? LinearGradient(
                            colors: [
                              Colors.grey.shade500,
                              Colors.grey.shade600,
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF1A8A4E), Color(0xFF084F2A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: isDisabled
                            ? Colors.grey.withOpacity(0.15)
                            : primaryGreen.withOpacity(0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 27, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: isDisabled ? Colors.black45 : darkGreen,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: isDisabled ? Colors.black38 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDisabled ? Colors.grey.shade200 : softGreen,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDisabled
                          ? Colors.grey.withOpacity(0.20)
                          : primaryGreen.withOpacity(0.10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isCheckingRegistration && title == "Fill Application"
                            ? "Checking..."
                            : buttonText,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDisabled ? Colors.black45 : primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(
                        isCheckingRegistration && title == "Fill Application"
                            ? Icons.hourglass_top_rounded
                            : Icons.arrow_forward_rounded,
                        color: isDisabled ? Colors.black45 : primaryGreen,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMessage({
    required String title,
    required String message,
    bool isError = false,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.redAccent : primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
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

  Widget _decorCircle({required double size, required Color color}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
