// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:evacutaion/WebPages/Request/Request.dart';
import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/WebDischargeScanner.dart';
import 'package:evacutaion/WebPages/sidebar/WebManageQr.dart';
import 'package:evacutaion/WebPages/sidebar/WebManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart' as xls; // FIX: Avoid Border conflict
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class WebReportsPage extends StatefulWidget {
  const WebReportsPage({super.key});

  @override
  State<WebReportsPage> createState() => _WebReportsPageState();
}

class _WebReportsPageState extends State<WebReportsPage> {
  String selectedPage = "Reports";

  DateTime? _startDate;
  DateTime? _endDate;

  // ----------------------------------------------------------------------
  //                            DATE PICKERS
  // ----------------------------------------------------------------------

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
      setState(() => _startDate = picked);

      if (_endDate != null && _endDate!.isBefore(picked)) {
        setState(() => _endDate = picked);
      }
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      builder: _datepickerTheme,
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
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

  // ----------------------------------------------------------------------
  //                         EXCEL GENERATION
  // ----------------------------------------------------------------------

  void _generateExcelReport() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both start and end dates."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header
    sheet.appendRow([
      xls.TextCellValue('Report Title'),
      xls.TextCellValue('Date Range'),
      xls.TextCellValue('Total Residents'),
    ]);

    // Data
    sheet.appendRow([
      xls.TextCellValue('Evacuee Population Report'),
      xls.TextCellValue(
        "${_startDate!.toString().split(' ')[0]} → ${_endDate!.toString().split(' ')[0]}",
      ),
      xls.IntCellValue(350),
    ]);

    final excelBytes = excel.encode();
    if (excelBytes == null) return;

    // WEB DOWNLOAD
    if (kIsWeb) {
      final blob = html.Blob([Uint8List.fromList(excelBytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Evacuee_Report.xlsx")
        ..click();

      html.Url.revokeObjectUrl(url);
      return;
    }

    debugPrint("Excel generated (mobile). Add FileSaver for mobile use.");
  }

  // 🧭 Drawer
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

              // Drawer items
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

  // 🔹 Drawer Item Widget with if-else navigation logic
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
        setState(() {
          selectedPage = title;
        });

        Navigator.pop(context);

        // 🧭 Navigation logic
        if (title == 'Dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WebMainDashboard()),
          );
        } else if (title == 'Resident Management') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebManageResidentsPage(),
            ),
          );
        } else if (title == 'QR Code Management') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebDisplayAllQrPage(),
            ),
          );
        } else if (title == 'Discharge Residents') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebDischargeScanQrPage(),
            ),
          );
        } else if (title == 'Reports') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WebReportsPage()),
          );
        } else if (title == 'Requests') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WebRequestsPage()),
          );
        }
      },
    );
  }
  // ----------------------------------------------------------------------
  //                                UI
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 820;

    return Scaffold(
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true, // CENTER TITLE
        iconTheme: const IconThemeData(color: Colors.white), // <-- icons color
        title: Text(
          "Reports",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white, // <-- title color
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
                // PAGE TITLE
                Text(
                  "Evacuation Population Report",
                  style: GoogleFonts.poppins(
                    fontSize: isWide ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // DATE RANGE CARD
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
                        "Select Date Range",
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
                                  child: _dateField(
                                    "End Date",
                                    _endDate,
                                    _pickEndDate,
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
                                _dateField("End Date", _endDate, _pickEndDate),
                              ],
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // CENTERED DOWNLOAD BUTTON
                Center(
                  child: SizedBox(
                    width: isWide ? 300 : double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateExcelReport,
                      icon: const Icon(
                        Icons.download,
                        color: Colors.white, // <-- set icon color to white
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D743D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      label: Text(
                        "Generate Excel Report",
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
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  //                          DATE FIELD UI
  // ----------------------------------------------------------------------

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
                date == null ? label : date.toString().split(" ")[0],
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
}
