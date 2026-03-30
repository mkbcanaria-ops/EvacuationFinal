// ignore_for_file: use_build_context_synchronously

import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/WebDischargeScanner.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report_Preview.dart';
import 'package:evacutaion/WebPages/sidebar/ViewQRcode/WebManageQr.dart';
import 'package:evacutaion/WebPages/sidebar/WebEditResident/WebManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebReportsPage extends StatefulWidget {
  const WebReportsPage({super.key});

  @override
  State<WebReportsPage> createState() => _WebReportsPageState();
}

class _WebReportsPageState extends State<WebReportsPage> {
  String selectedPage = "Reports";

  DateTime? _startDate;
  DateTime? _endDateTime;

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
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0D743D)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
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
              const Divider(),
              _buildDrawerItem('Reports', Icons.analytics_outlined),
              _buildDrawerItem('Requests', Icons.pending_actions_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon) {
    final bool isSelected = selectedPage == title;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF0D743D) : Colors.black54,
      ),
      tileColor: isSelected ? const Color(0xFF0D743D).withOpacity(0.1) : null,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFF0D743D) : Colors.black,
        ),
      ),
      onTap: () {
        setState(() => selectedPage = title);
        Navigator.pop(context);

        if (title == 'Dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WebMainDashboard()),
          );
        } else if (title == 'Resident Management') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WebManageResidentsPage()),
          );
        } else if (title == 'QR Code Management') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WebDisplayAllQrPage()),
          );
        } else if (title == 'Discharge Residents') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WebDischargeDashboardPage(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 820;

    return Scaffold(
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
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
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.all(isWide ? 40 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Evacuation Population Report",
                  style: GoogleFonts.poppins(
                    fontSize: isWide ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: EdgeInsets.all(isWide ? 25 : 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Report Period",
                        style: GoogleFonts.poppins(
                          fontSize: isWide ? 20 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: _dateField(
                                    "Start Date",
                                    _startDate,
                                    _pickStartDate,
                                  ),
                                ),
                                const SizedBox(width: 25),
                                Expanded(
                                  child: _dateTimeField(
                                    "End Date & Time",
                                    _endDateTime,
                                    _pickEndDateTime,
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
                                ),
                                const SizedBox(height: 15),
                                _dateTimeField(
                                  "End Date & Time",
                                  _endDateTime,
                                  _pickEndDateTime,
                                ),
                              ],
                            ),
                      const SizedBox(height: 25),
                      Center(
                        child: SizedBox(
                          width: isWide ? 300 : double.infinity,
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
                              backgroundColor: const Color(0xFF0D743D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            label: Text(
                              "Preview",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
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

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFF0D743D),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date == null ? label : _formatDate(date),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: date == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTimeField(String label, DateTime? dateTime, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF0D743D)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dateTime == null ? label : _formatDateTime(dateTime),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: dateTime == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
