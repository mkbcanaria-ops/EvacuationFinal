// ignore_for_file: unnecessary_type_check
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/WebDischargeScanner.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:evacutaion/WebPages/sidebar/Request/Request.dart';
import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:evacutaion/WebPages/Web_Registration.dart';
import 'package:evacutaion/WebPages/sidebar/WebArchiveUsers.dart';
import 'package:evacutaion/WebPages/sidebar/WebEditResident/WebEditResidentDetails.dart';
import 'package:evacutaion/WebPages/sidebar/WebManageQr.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class WebManageResidentsPage extends StatefulWidget {
  const WebManageResidentsPage({super.key});

  @override
  State<WebManageResidentsPage> createState() => _WebManageResidentsPageState();
}

class _WebManageResidentsPageState extends State<WebManageResidentsPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _residents = [];
  List<Map<String, dynamic>> _filteredResidents = [];
  bool _isLoading = true;

  String selectedPage = 'Resident Management';

  @override
  void initState() {
    super.initState();
    _fetchResidents();
    _searchController.addListener(_filterResidents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _archiveResident(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.archive, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Archive Resident',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to archive this resident?',
                style: GoogleFonts.poppins(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D743D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('Registration_Table')
          .update({'Status': 'Archived'})
          .eq('UID', uid);

      await _fetchResidents();
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Error',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Failed to archive resident: $error',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fetchResidents() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('Registration_Table')
          .select(
            'UID, Head_Firstname, Head_Middlename, Head_Surname, Head_Image, Date_Registered',
          )
          .eq('Status', 'Active')
          .order('Date_Registered', ascending: false);

      setState(() {
        _residents = List<Map<String, dynamic>>.from(response);
        _filteredResidents = _residents;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching residents: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterResidents() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredResidents = _residents);
      return;
    }

    setState(() {
      _filteredResidents = _residents.where((resident) {
        final fullName =
            '${resident['Head_Firstname']} ${resident['Head_Middlename'] ?? ''} ${resident['Head_Surname']}'
                .toLowerCase();
        final uid = resident['UID'].toString().toLowerCase();
        return fullName.contains(query) || uid.contains(query);
      }).toList();
    });
  }

  String? _getPublicImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    // Check if it's already a full URL (starts with http or https)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Otherwise, construct the public URL from Supabase storage
    final publicUrl = supabase.storage.from('headimage').getPublicUrl(path);
    return publicUrl;
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error, size: 50, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (screenWidth > 1200) {
      crossAxisCount = 5;
    } else if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    }

    double cardHeight = screenWidth / crossAxisCount * 1.5;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        title: Text(
          'Manage Residents',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by first, middle, or last name',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D743D)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WebArchiveUsers()),
                  );
                },
                child: Text(
                  'Archive Users',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D743D)),
                  )
                : _filteredResidents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No residents found.',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchResidents,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredResidents.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            screenWidth / crossAxisCount / cardHeight,
                      ),
                      itemBuilder: (context, index) {
                        final resident = _filteredResidents[index];
                        final fullName =
                            '${resident['Head_Firstname']} ${resident['Head_Middlename'] ?? ''} ${resident['Head_Surname']}'
                                .trim();
                        final date = resident['Date_Registered'] ?? '';
                        final imagePath = resident['Head_Image'];
                        final imageUrl = _getPublicImageUrl(imagePath);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (imageUrl != null) {
                                        _showFullImage(imageUrl);
                                      }
                                    },
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: 220, // fixed smaller width
                                        height: cardHeight * 0.55,
                                        child: imageUrl != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: 220,
                                                  height: cardHeight * 0.55,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        width: 220,
                                                        height:
                                                            cardHeight * 0.55,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                        child: const Icon(
                                                          Icons.person,
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.grey.shade300,
                                                ),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    fullName,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0D743D,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    WebEditResidentsDetailsPage(
                                                      uid: resident['UID']
                                                          .toString(),
                                                    ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            "Edit",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed: () {
                                            _archiveResident(
                                              resident['UID'].toString(),
                                            );
                                          },
                                          child: const Text(
                                            'Archive',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
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
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D743D),
        child: const Icon(
          Icons.add,
          color: Colors.white, // ✅ Make the icon white
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const WebRegistrationPage(), // ✅ Navigate to RegistrationPage
            ),
          );
        },
      ),
    );
  }
}
