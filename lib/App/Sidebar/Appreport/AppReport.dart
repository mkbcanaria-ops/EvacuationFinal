// ignore_for_file: use_build_context_synchronously

import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:evacutaion/App/Sidebar/AppManageResidents/ManageResidents.dart';
import 'package:evacutaion/App/Sidebar/AppViewQR/ManageQR.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/DischargeResidentScanner.dart';
import 'package:evacutaion/App/Sidebar/Request/AppRequest.dart';
import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/WebDischargeScanner.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report_Preview.dart';
import 'package:evacutaion/WebPages/sidebar/Request/Request.dart';
import 'package:evacutaion/WebPages/sidebar/ViewQRcode/WebManageQr.dart';
import 'package:evacutaion/WebPages/sidebar/WebEditResident/WebManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppReportsPage extends StatefulWidget {
  const AppReportsPage({super.key});

  @override
  State<AppReportsPage> createState() => _AppReportsPageState();
}

class _AppReportsPageState extends State<AppReportsPage> {
  String selectedPage = "Reports";

  DateTime? _startDate;
  DateTime? _endDateTime;

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _datepickerTheme,
    );

    if (picked != null) {
      final newStartDate = DateTime(picked.year, picked.month, picked.day);

      setState(() {
        _startDate = newStartDate;

        if (_endDateTime != null && _endDateTime!.isBefore(_startDate!)) {
          _endDateTime = null;
        }
      });
    }
  }

  Future<void> _pickEndDateTime() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the start date first.')),
      );
      return;
    }

    final initialBase = _endDateTime ?? _startDate!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialBase,
      firstDate: _startDate!,
      lastDate: DateTime(2100),
      builder: _datepickerTheme,
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final initialTime = _endDateTime != null
        ? TimeOfDay.fromDateTime(_endDateTime!)
        : const TimeOfDay(hour: 0, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D743D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (selectedDateTime.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date and time cannot be earlier than start date.'),
        ),
      );
      return;
    }

    setState(() {
      _endDateTime = selectedDateTime;
    });
  }

  Widget _datepickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0D743D),
          onPrimary: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      child: child!,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return "${dateTime.year.toString().padLeft(4, '0')}-"
        "${dateTime.month.toString().padLeft(2, '0')}-"
        "${dateTime.day.toString().padLeft(2, '0')} "
        "$hour:$minute $period";
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evacuation Management System',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.90),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    _buildDrawerItem('Dashboard', Icons.dashboard_outlined),
                    _buildDrawerItem(
                      'Resident Management',
                      Icons.people_alt_outlined,
                    ),
                    _buildDrawerItem('QR Code Management', Icons.qr_code_2),
                    _buildDrawerItem(
                      'Discharge Residents',
                      Icons.exit_to_app_rounded,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Divider(color: Colors.grey.shade300),
                    ),
                    _buildDrawerItem('Reports', Icons.analytics_outlined),
                    _buildDrawerItem(
                      'Requests',
                      Icons.pending_actions_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon) {
    final bool isSelected = selectedPage == title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? primaryGreen.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(
            icon,
            color: isSelected ? primaryGreen : Colors.black54,
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isSelected ? primaryGreen : Colors.black87,
            ),
          ),
          onTap: () {
            setState(() {
              selectedPage = title;
            });

            Navigator.pop(context);

            if (title == 'Dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainDashboard()),
              );
            } else if (title == 'Resident Management') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageResidentsPage(),
                ),
              );
            } else if (title == 'QR Code Management') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisplayAllQrPage(),
                ),
              );
            } else if (title == 'Discharge Residents') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DischargeScanQrPage(),
                ),
              );
            } else if (title == 'Reports') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppReportsPage()),
              );
            } else if (title == 'Requests') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppRequestsPage(),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 820;

    return Scaffold(
      backgroundColor: softBg,
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Reports",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBanner(),
                const SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(isWide ? 28 : 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Report Period",
                        style: GoogleFonts.poppins(
                          fontSize: isWide ? 21 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Choose the start date and end date with time to preview the evacuation population report.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 22),
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _dateField(
                                    "Start Date",
                                    _startDate,
                                    _pickStartDate,
                                    Icons.calendar_today,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _dateField(
                                    "End Date & Time",
                                    _endDateTime,
                                    _pickEndDateTime,
                                    Icons.access_time,
                                    isDateTime: true,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _dateField(
                                  "Start Date",
                                  _startDate,
                                  _pickStartDate,
                                  Icons.calendar_today,
                                ),
                                const SizedBox(height: 15),
                                _dateField(
                                  "End Date & Time",
                                  _endDateTime,
                                  _pickEndDateTime,
                                  Icons.access_time,
                                  isDateTime: true,
                                ),
                              ],
                            ),
                      const SizedBox(height: 26),
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: isWide ? 280 : double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_startDate == null || _endDateTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select the start date and end date & time.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (_endDateTime!.isBefore(_startDate!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'End date and time cannot be earlier than start date.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WebReportsPreviewPage(
                                    startDate: _startDate!,
                                    endDateTime: _endDateTime!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.preview,
                              color: Colors.white,
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            label: Text(
                              "Preview Report",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [primaryGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        spacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evacuation Population Report',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate and preview evacuation reports based on your selected date range and time period.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Reports Module',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? date,
    VoidCallback onTap,
    IconData icon, {
    bool isDateTime = false,
  }) {
    final displayText = date == null
        ? label
        : (isDateTime ? _formatDateTime(date) : _formatDate(date));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          color: const Color(0xFFF9FBFA),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: date == null ? Colors.grey[600] : Colors.black87,
                  fontWeight: date == null ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
