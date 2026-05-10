// ignore_for_file: unused_field

import 'package:evacutaion/WebPages/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WLandingPage extends StatefulWidget {
  const WLandingPage({super.key});

  @override
  State<WLandingPage> createState() => _WLandingPageState();
}

class _WLandingPageState extends State<WLandingPage> {
  static const String systemName = 'MSWDO-Santa eCamp Management System';

  static final Uri _weatherTrackerUrl = Uri.parse(
    'https://www.windy.com/-Waves-waves',
  );

  void openFullImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullImageView(imagePath: imagePath),
      ),
    );
  }

  void openEvacuationMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EvacuationMapView()),
    );
  }

  Future<void> _openWeatherTracker() async {
    final opened = await launchUrl(
      _weatherTrackerUrl,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D743D),
          content: Text(
            'Unable to open weather tracker.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

  IconData _featureIcon(String title) {
    switch (title) {
      case 'Evacuation Sites':
        return Icons.location_on_rounded;
      case 'Emergency Hotlines':
        return Icons.call_rounded;
      case 'Alerts & Safety Tips':
        return Icons.notifications_active_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _featureDescription(String title) {
    switch (title) {
      case 'Evacuation Sites':
        return 'View pinned evacuation centers with location details, occupancy, and current status.';
      case 'Emergency Hotlines':
        return 'Access important emergency contact information for faster assistance and response.';
      case 'Alerts & Safety Tips':
        return 'Stay informed with announcements, reminders, and safety guidance.';
      default:
        return 'Important information for the community.';
    }
  }

  Widget _buildGetStartedButton({
    required bool isMobile,
    bool compact = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: compact
              ? 12
              : isMobile
              ? 16
              : 22,
          vertical: compact
              ? 10
              : isMobile
              ? 11
              : 14,
        ),
        minimumSize: Size(compact ? 92 : 120, compact ? 38 : 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Get Started',
          style: GoogleFonts.poppins(
            fontSize: compact
                ? 12
                : isMobile
                ? 13
                : 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D743D),
          ),
        ),
      ),
    );
  }

  Widget _buildTopFloatingBar(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = isMobile || constraints.maxWidth < 520;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/Logo2.jpg',
                  height: compact ? 34 : 40,
                  width: compact ? 34 : 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  compact ? 'MSWDO-Santa eCamp' : systemName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 13.5 : 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildGetStartedButton(isMobile: isMobile, compact: compact),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String imagePath,
    required String title,
    required bool isMobile,
  }) {
    return GestureDetector(
      onTap: () {
        if (title == 'Evacuation Sites') {
          openEvacuationMap();
        } else {
          openFullImage(imagePath);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.14),
                        Colors.black.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: isMobile ? 12 : 16,
                left: isMobile ? 12 : 16,
                child: Container(
                  width: isMobile ? 38 : 42,
                  height: isMobile ? 38 : 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _featureIcon(title),
                    color: const Color(0xFF0D743D),
                    size: isMobile ? 18 : 20,
                  ),
                ),
              ),
              Positioned(
                top: isMobile ? 12 : 16,
                right: isMobile ? 12 : 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    title == 'Evacuation Sites' ? 'Open map' : 'Tap to view',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D743D),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: isMobile ? 14 : 18,
                right: isMobile ? 14 : 18,
                bottom: isMobile ? 14 : 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _featureDescription(title),
                      maxLines: isMobile ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12.2 : 13.5,
                        color: Colors.white.withOpacity(0.94),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection({
    required bool isMobile,
    required bool isSmallPhone,
    required double heroHeight,
  }) {
    final borderRadius = isMobile ? 26.0 : 36.0;

    return Container(
      height: heroHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D743D).withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/Mainpic1.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(105, 0, 0, 0),
                      Color.fromARGB(135, 0, 0, 0),
                      Color.fromARGB(242, 6, 34, 20),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 14 : 26,
                    14,
                    isMobile ? 14 : 26,
                    isMobile ? 20 : 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopFloatingBar(isMobile),
                      SizedBox(height: isSmallPhone ? 22 : 28),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallPhone ? 10 : 14,
                                      vertical: isSmallPhone ? 7 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.18),
                                      ),
                                    ),
                                    child: Text(
                                      isSmallPhone
                                          ? 'Santa • Emergency System'
                                          : 'Municipality of Santa • Emergency Information System',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallPhone
                                            ? 10.5
                                            : isMobile
                                            ? 11.5
                                            : 12.5,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 14 : 18),
                                  Text(
                                    isMobile
                                        ? 'MSWDO-Santa eCamp\nManagement System'
                                        : systemName,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallPhone
                                          ? 27
                                          : isMobile
                                          ? 30
                                          : 46,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Prepared • Informed • Protected',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallPhone
                                          ? 13.5
                                          : isMobile
                                          ? 15
                                          : 18,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white.withOpacity(0.96),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 12 : 16),
                                  Text(
                                    'Your safety matters. Stay updated with real-time alerts, evacuation sites, and essential resources designed to keep every resident informed and ready during emergencies.',
                                    maxLines: isSmallPhone ? 5 : null,
                                    overflow: isSmallPhone
                                        ? TextOverflow.ellipsis
                                        : TextOverflow.visible,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallPhone
                                          ? 12.5
                                          : isMobile
                                          ? 14
                                          : 16,
                                      color: Colors.white.withOpacity(0.94),
                                      height: isSmallPhone ? 1.55 : 1.7,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 18 : 24),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          'Enter Portal',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0D743D,
                                          ),
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallPhone ? 20 : 22,
                                            vertical: isSmallPhone ? 14 : 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _openWeatherTracker,
                                        icon: const Icon(
                                          Icons.cloud_outlined,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          'Track Weather',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.35,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallPhone ? 20 : 20,
                                            vertical: isSmallPhone ? 14 : 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isMobile,
    required bool isSmallPhone,
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isSmallPhone
                ? 21
                : isMobile
                ? 24
                : 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D743D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isSmallPhone
                ? 12.5
                : isMobile
                ? 13.5
                : 15,
            color: Colors.black87,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyTag({
    required IconData icon,
    required String label,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isMobile ? 15 : 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 11.5 : 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherActionCard(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 300,
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 44 : 48,
            height: isMobile ? 44 : 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.wb_cloudy_outlined, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            'Live Weather Monitoring',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check wind, wave, and surrounding weather conditions using the external Windy map tracker.',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12.5 : 13,
              color: Colors.white.withOpacity(0.92),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openWeatherTracker,
              icon: const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF0D743D),
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Open Weather Tracker',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D743D),
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyHighlight(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 24,
        vertical: isMobile ? 20 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D743D), Color(0xFF168B4E)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D743D).withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Preparedness Matters',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This portal helps residents quickly access important information before, during, and after emergency situations in Santa.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.94),
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildEmergencyTag(
                      icon: Icons.cloud_outlined,
                      label: 'Live Weather',
                      isMobile: true,
                    ),
                    _buildEmergencyTag(
                      icon: Icons.waves_outlined,
                      label: 'Wave Monitoring',
                      isMobile: true,
                    ),
                    _buildEmergencyTag(
                      icon: Icons.travel_explore_outlined,
                      label: 'Fast Access',
                      isMobile: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWeatherActionCard(true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Preparedness Matters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'This portal helps residents quickly access important information before, during, and after emergency situations in Santa.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.94),
                                      height: 1.65,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildEmergencyTag(
                              icon: Icons.cloud_outlined,
                              label: 'Live Weather',
                              isMobile: false,
                            ),
                            _buildEmergencyTag(
                              icon: Icons.waves_outlined,
                              label: 'Wave Monitoring',
                              isMobile: false,
                            ),
                            _buildEmergencyTag(
                              icon: Icons.travel_explore_outlined,
                              label: 'Fast Access',
                              isMobile: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Residents can quickly open the weather tracker to monitor conditions that may affect travel, coastal areas, and emergency response.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.90),
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildWeatherActionCard(false),
              ],
            ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 30,
        vertical: isMobile ? 22 : 28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF082B18),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            systemName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Helping the community stay prepared, informed, and protected.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12.5 : 13.5,
              color: Colors.white.withOpacity(0.82),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  double _getHeroHeight({
    required bool isMobile,
    required bool isTablet,
    required bool isSmallPhone,
  }) {
    if (isSmallPhone) return 760;
    if (isMobile) return 710;
    if (isTablet) return 620;
    return 680;
  }

  double _getFeatureAspectRatio({
    required bool isMobile,
    required bool isTablet,
    required bool isSmallPhone,
  }) {
    if (isSmallPhone) return 0.86;
    if (isMobile) return 0.94;
    if (isTablet) return 1.05;
    return 1.08;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isSmallPhone = width < 430;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1000;
        final isDesktop = width >= 1000;

        final heroHeight = _getHeroHeight(
          isMobile: isMobile,
          isTablet: isTablet,
          isSmallPhone: isSmallPhone,
        );

        final featureCount = isDesktop
            ? 3
            : isTablet
            ? 2
            : 1;

        final sidePadding = isSmallPhone
            ? 12.0
            : isMobile
            ? 16.0
            : isTablet
            ? 26.0
            : 42.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF5FAF7),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      isMobile ? 8 : 12,
                      sidePadding,
                      0,
                    ),
                    child: _buildHeroSection(
                      isMobile: isMobile,
                      isSmallPhone: isSmallPhone,
                      heroHeight: heroHeight,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      24,
                      sidePadding,
                      0,
                    ),
                    child: _buildSectionHeader(
                      title: 'Essential Emergency Resources',
                      subtitle:
                          'Quickly access important sections designed to support residents during emergencies and evacuation response.',
                      isMobile: isMobile,
                      isSmallPhone: isSmallPhone,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      24,
                      sidePadding,
                      0,
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: featureCount,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: _getFeatureAspectRatio(
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isSmallPhone: isSmallPhone,
                      ),
                      children: [
                        _buildFeatureCard(
                          imagePath: 'assets/images/map.jpg',
                          title: 'Evacuation Sites',
                          isMobile: isMobile,
                        ),
                        _buildFeatureCard(
                          imagePath: 'assets/images/Mainpic2.jpg',
                          title: 'Emergency Hotlines',
                          isMobile: isMobile,
                        ),
                        _buildFeatureCard(
                          imagePath: 'assets/images/Mainpic3.jpg',
                          title: 'Alerts & Safety Tips',
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      28,
                      sidePadding,
                      0,
                    ),
                    child: _buildEmergencyHighlight(isMobile),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      30,
                      sidePadding,
                      40,
                    ),
                    child: _buildFooter(isMobile),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EvacuationSite {
  final String name;
  final String imagePath;
  final String address;
  final String occupancy;
  final String status;
  final double x;
  final double y;

  const EvacuationSite({
    required this.name,
    required this.imagePath,
    required this.address,
    required this.occupancy,
    required this.status,
    required this.x,
    required this.y,
  });
}

class EvacuationMapView extends StatelessWidget {
  const EvacuationMapView({super.key});

  static const double _mapAspectRatio = 1280 / 1154;

  static const List<EvacuationSite> _sites = [
    EvacuationSite(
      name: 'Santa National High School',
      imagePath: 'assets/images/SantaNational.jpg',
      address: 'Marcos District, Santa, Ilocos Sur',
      occupancy: 'To be updated',
      status: 'Available',
      x: 0.695,
      y: 0.112,
    ),
    EvacuationSite(
      name: 'Santa High School',
      imagePath: 'assets/images/SantaHigh.jpeg',
      address: 'Quirino District, Santa, Ilocos Sur',
      occupancy: 'To be updated',
      status: 'Available',
      x: 0.255,
      y: 0.582,
    ),
    EvacuationSite(
      name: 'RHU',
      imagePath: 'assets/images/RHU.jpg',
      address: 'Santa Rural Health Unit, Santa, Ilocos Sur',
      occupancy: 'To be updated',
      status: 'Available',
      x: 0.447,
      y: 0.632,
    ),
    EvacuationSite(
      name: "Santa Farmer's Multipurpose Building",
      imagePath: 'assets/images/Farmers.jpg',
      address: "Santa Farmer's Multipurpose Building",
      occupancy: 'To be updated',
      status: 'Available',
      x: 0.458,
      y: 0.748,
    ),
    EvacuationSite(
      name: 'Municipal Evacuation Center, Magsaysay',
      imagePath: 'assets/images/Magsaysay.jpg',
      address: 'Municipal Evacuation Center, Magsaysay',
      occupancy: 'To be updated',
      status: 'Available',
      x: 0.478,
      y: 0.934,
    ),
  ];

  void _showSiteDetails(BuildContext context, EvacuationSite site) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.asset(
                        site.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5FAF7),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFF0D743D),
                                  size: 38,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D743D),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D743D).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF0D743D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          site.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D743D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailTile(
                    icon: Icons.place_outlined,
                    label: 'Address',
                    value: site.address,
                  ),
                  _detailTile(
                    icon: Icons.groups_rounded,
                    label: 'Occupancy',
                    value: site.occupancy,
                  ),
                  _detailTile(
                    icon: Icons.verified_outlined,
                    label: 'Status',
                    value: site.status,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Okay',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D743D),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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

  static Widget _detailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D743D).withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0D743D), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(BuildContext context, EvacuationSite site) {
    return GestureDetector(
      onTap: () => _showSiteDetails(context, site),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: const Color(0xFFE53935),
                size: 32,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.40),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                site.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap({
    required BuildContext context,
    required double mapWidth,
    required double mapHeight,
  }) {
    return SizedBox(
      width: mapWidth,
      height: mapHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('assets/images/map.jpg', fit: BoxFit.fill),
            ),
          ),
          ..._sites.map((site) {
            return Positioned(
              left: (mapWidth * site.x) - 70,
              top: (mapHeight * site.y) - 40,
              child: _buildMapPin(context, site),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06160E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06160E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Evacuation Sites Map',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double mapWidth = constraints.maxWidth - 24;
            double mapHeight = mapWidth / _mapAspectRatio;

            if (mapHeight > constraints.maxHeight - 24) {
              mapHeight = constraints.maxHeight - 24;
              mapWidth = mapHeight * _mapAspectRatio;
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    boundaryMargin: const EdgeInsets.all(120),
                    child: Center(
                      child: _buildMap(
                        context: context,
                        mapWidth: mapWidth,
                        mapHeight: mapHeight,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FullImageView extends StatelessWidget {
  final String imagePath;

  const FullImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06160E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06160E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Image Preview',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 0.7,
                maxScale: 4,
                boundaryMargin: const EdgeInsets.all(80),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
