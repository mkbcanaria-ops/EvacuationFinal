import 'dart:convert';
import 'package:evacutaion/App/Discharge%20Residents/DischargeResidentScanner.dart';
import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:evacutaion/App/Sidebar/ManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class DisplayAllQrPage extends StatefulWidget {
  const DisplayAllQrPage({super.key});

  @override
  State<DisplayAllQrPage> createState() => _DisplayAllQrPageState();
}

class _DisplayAllQrPageState extends State<DisplayAllQrPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String selectedPage = 'QR Code Management';

  @override
  void initState() {
    super.initState();
    _fetchAllQRCodes();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllQRCodes() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('Registration_Table')
          .select(
            'UID, Head_Firstname, Head_Middlename, Head_Surname, QR_Code, Date_Registered',
          )
          .order('Date_Registered', ascending: false);

      setState(() {
        _records = List<Map<String, dynamic>>.from(response);
        _filteredRecords = _records;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching QR Codes: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredRecords = _records);
      return;
    }

    setState(() {
      _filteredRecords = _records.where((record) {
        final fullName =
            '${record['Head_Firstname']} ${record['Head_Middlename'] ?? ''} ${record['Head_Surname']}'
                .toLowerCase();
        final uid = record['UID'].toString().toLowerCase();
        return fullName.contains(query) || uid.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'All Generated QR Codes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D743D)),
            )
          : _records.isEmpty
          ? Center(
              child: Text(
                'No QR Codes found.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchAllQRCodes,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  double width = constraints.maxWidth;

                  if (width > 1200) {
                    crossAxisCount = 5;
                  } else if (width > 900) {
                    crossAxisCount = 4;
                  } else if (width > 600) {
                    crossAxisCount = 3;
                  }

                  double childAspectRatio = (width / crossAxisCount) / 280;

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name or UID...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[500],
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF0D743D),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0D743D),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0D743D),
                                width: 1.3,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0D743D),
                                width: 2,
                              ),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            itemCount: _filteredRecords.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: childAspectRatio,
                                ),
                            itemBuilder: (context, index) {
                              final record = _filteredRecords[index];
                              final qrBase64 = record['QR_Code'];
                              final qrBytes =
                                  qrBase64 != null && qrBase64.isNotEmpty
                                  ? base64Decode(qrBase64)
                                  : null;
                              final fullName =
                                  '${record['Head_Firstname']} ${record['Head_Middlename'] ?? ''} ${record['Head_Surname']}'
                                      .trim();
                              final date = record['Date_Registered'] ?? '';

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: Colors.black26,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Use Expanded to avoid cutting QR
                                      Expanded(
                                        child: qrBytes != null
                                            ? Image.memory(
                                                qrBytes,
                                                fit: BoxFit.contain,
                                              )
                                            : const Icon(
                                                Icons.qr_code_2,
                                                size: 80,
                                                color: Colors.grey,
                                              ),
                                      ),
                                      const SizedBox(height: 12),
                                      Flexible(
                                        child: Text(
                                          fullName,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Registered: $date',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  // 🧭 Admin Drawer
  Widget _buildAdminDrawer() {
    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Drawer Header
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0D743D)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Drawer items
              _buildDrawerItem(
                title: 'Dashboard',
                icon: Icons.dashboard_outlined,
                onTap: () {
                  _navigateToPage('Dashboard');
                },
              ),
              _buildDrawerItem(
                title: 'Resident Management',
                icon: Icons.people_alt_outlined,
                onTap: () {
                  _navigateToPage('Resident Management');
                },
              ),
              _buildDrawerItem(
                title: 'QR Code Management',
                icon: Icons.qr_code_2,
                onTap: () {
                  _navigateToPage('QR Code Management');
                },
              ),
              _buildDrawerItem(
                title: 'Discharge Residents',
                icon: Icons.exit_to_app_rounded,
                onTap: () {
                  _navigateToPage('Discharge Residents');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Drawer Item Widget
  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final bool isSelected = selectedPage == title;

    return Container(
      color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF0D743D) : Colors.black87,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF0D743D) : Colors.black87,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // 🔹 Centralized navigation method
  void _navigateToPage(String title) {
    setState(() => selectedPage = title);
    Navigator.pop(context);

    if (title == 'Dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainDashboard()),
      );
    } else if (title == 'Resident Management') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManageResidentsPage()),
      );
    } else if (title == 'QR Code Management') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DisplayAllQrPage()),
      );
    } else if (title == 'Discharge Residents') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DischargeScanQrPage()),
      );
    }
  }
}
