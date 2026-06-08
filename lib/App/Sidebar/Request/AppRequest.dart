import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:evacutaion/App/Sidebar/AppManageResidents/ManageResidents.dart';
import 'package:evacutaion/App/Sidebar/AppViewQR/ManageQR.dart';
import 'package:evacutaion/App/Sidebar/Discharge%20Residents/DischargeResidentScanner.dart';
import 'package:evacutaion/App/Sidebar/Request/AppRalatedView.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRequestsPage extends StatefulWidget {
  const AppRequestsPage({super.key});

  @override
  State<AppRequestsPage> createState() => _AppRequestsPageState();
}

class _AppRequestsPageState extends State<AppRequestsPage> {
  String selectedPage = "Requests";
  String selectedStatus = "Pending";

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  bool isSearchingRelated = false;

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

  final List<String> firstNameKeys = const [
    'Head_Firstname',
    'Head_FirstName',
    'Head_First_Name',
    'HeadFirstName',
    'First_Name',
    'FirstName',
    'Firstname',
    'first_name',
    'firstName',
    'firstname',
  ];

  final List<String> middleNameKeys = const [
    'Head_Middlename',
    'Head_MiddleName',
    'Head_Middle_Name',
    'HeadMiddleName',
    'Middle_Name',
    'MiddleName',
    'Middlename',
    'middle_name',
    'middleName',
    'middlename',
  ];

  final List<String> lastNameKeys = const [
    'Head_Surname',
    'Head_Lastname',
    'Head_LastName',
    'Head_Last_Name',
    'HeadSurname',
    'HeadLastName',
    'Last_Name',
    'LastName',
    'Lastname',
    'Surname',
    'surname',
    'last_name',
    'lastName',
    'lastname',
  ];

  final List<String> fullNameKeys = const [
    'Full_Name',
    'FullName',
    'Name',
    'Resident_Name',
    'ResidentName',
    'Head_Name',
    'HeadName',
    'Household_Head',
    'HouseholdHead',
    'full_name',
    'fullName',
    'name',
  ];

  final List<String> registrationIdKeys = const [
    'Registration_ID',
    'RegistrationId',
    'registration_id',
    'registrationId',
    'Reg_ID',
    'reg_id',
    'id',
  ];

  final List<String> qrCodeKeys = const [
    'QR_Code',
    'QRCode',
    'Qr_Code',
    'qr_code',
    'qrCode',
    'QR',
  ];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  String formatRequestDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('MM-dd-yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  String safeText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Not provided' : text;
  }

  String cleanText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    if (text.toLowerCase() == 'null') return '';
    if (text == 'Not provided') return '';
    return text;
  }

  String readAny(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      if (row.containsKey(key)) {
        final value = cleanText(row[key]);
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  String normalizeName(dynamic value) {
    return cleanText(value)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9ñ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> nameTokens(String value) {
    final normalized = normalizeName(value);
    if (normalized.isEmpty) return [];

    return normalized
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
  }

  String buildFullName({
    required dynamic firstName,
    required dynamic middleName,
    required dynamic lastName,
  }) {
    final first = cleanText(firstName);
    final middle = cleanText(middleName);
    final last = cleanText(lastName);

    return '$first ${middle.isNotEmpty ? '$middle ' : ''}$last'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String requestFullName(Map<String, dynamic> request) {
    return buildFullName(
      firstName: request['First_Name'],
      middleName: request['Middle_Name'],
      lastName: request['Last_Name'],
    );
  }

  String registrationFirstName(Map<String, dynamic> row) {
    return readAny(row, firstNameKeys);
  }

  String registrationMiddleName(Map<String, dynamic> row) {
    return readAny(row, middleNameKeys);
  }

  String registrationLastName(Map<String, dynamic> row) {
    return readAny(row, lastNameKeys);
  }

  String registrationId(Map<String, dynamic> row) {
    return readAny(row, registrationIdKeys);
  }

  String registrationQrCode(Map<String, dynamic> row) {
    return readAny(row, qrCodeKeys);
  }

  String registrationFullName(Map<String, dynamic> row) {
    final full = readAny(row, fullNameKeys);
    if (full.isNotEmpty) return full;

    return buildFullName(
      firstName: registrationFirstName(row),
      middleName: registrationMiddleName(row),
      lastName: registrationLastName(row),
    );
  }

  String registrationNameSearchText(Map<String, dynamic> row) {
    final fullName = registrationFullName(row);

    if (fullName.isNotEmpty) {
      return normalizeName(fullName);
    }

    final possibleNameValues = <String>[];

    for (final entry in row.entries) {
      final key = entry.key.toLowerCase();
      final value = cleanText(entry.value);

      if (value.isEmpty) continue;

      if (key.contains('name') ||
          key.contains('firstname') ||
          key.contains('middlename') ||
          key.contains('surname') ||
          key.contains('lastname') ||
          key.contains('head')) {
        possibleNameValues.add(value);
      }
    }

    return normalizeName(possibleNameValues.join(' '));
  }

  bool containsAllTokens(String text, List<String> tokens) {
    if (text.isEmpty || tokens.isEmpty) return false;

    final textTokens = text.split(' ');

    return tokens.every((token) => textTokens.contains(token));
  }

  bool containsImportantNameTokens(String text, List<String> tokens) {
    if (text.isEmpty || tokens.isEmpty) return false;

    final textTokens = text.split(' ');
    int found = 0;

    for (final token in tokens) {
      if (textTokens.contains(token)) {
        found++;
      }
    }

    if (tokens.length == 1) return found == 1;
    if (tokens.length == 2) return found >= 2;
    return found >= 2;
  }

  int scoreRegistrationMatch({
    required Map<String, dynamic> request,
    required Map<String, dynamic> registration,
  }) {
    final reqFirst = normalizeName(request['First_Name']);
    final reqMiddle = normalizeName(request['Middle_Name']);
    final reqLast = normalizeName(request['Last_Name']);
    final reqFull = normalizeName(requestFullName(request));
    final reqTokens = nameTokens(requestFullName(request));

    final regFirst = normalizeName(registrationFirstName(registration));
    final regMiddle = normalizeName(registrationMiddleName(registration));
    final regLast = normalizeName(registrationLastName(registration));
    final regFull = normalizeName(registrationFullName(registration));
    final regSearchText = registrationNameSearchText(registration);

    if (reqTokens.isEmpty) return 0;
    if (regSearchText.isEmpty) return 0;

    final searchTokens = regSearchText.split(' ');

    final firstMatch =
        reqFirst.isNotEmpty &&
        (regFirst == reqFirst || searchTokens.contains(reqFirst));

    final middleMatch =
        reqMiddle.isNotEmpty &&
        (regMiddle == reqMiddle || searchTokens.contains(reqMiddle));

    final lastTokens = nameTokens(reqLast);
    final lastToken = lastTokens.isNotEmpty ? lastTokens.last : '';

    final lastMatch =
        reqLast.isNotEmpty &&
        (regLast == reqLast ||
            regSearchText.contains(reqLast) ||
            containsImportantNameTokens(regSearchText, lastTokens));

    final lastTokenMatch =
        lastToken.isNotEmpty && searchTokens.contains(lastToken);

    if (reqFull.isNotEmpty && regFull == reqFull) return 100;

    if (containsAllTokens(regSearchText, reqTokens)) {
      return 98;
    }

    if (firstMatch && middleMatch && lastTokenMatch) {
      return 96;
    }

    if (firstMatch && lastMatch) {
      return 94;
    }

    if (firstMatch && lastTokenMatch) {
      return 92;
    }

    if (containsImportantNameTokens(regSearchText, reqTokens)) {
      return 88;
    }

    if (firstMatch && reqTokens.length >= 2) {
      return 75;
    }

    return 0;
  }

  Map<String, dynamic> normalizeHouseholdForRelatedView(
    Map<String, dynamic> row,
    int score,
  ) {
    final item = Map<String, dynamic>.from(row);

    item['Head_Firstname'] = registrationFirstName(row);
    item['Head_Middlename'] = registrationMiddleName(row);
    item['Head_Surname'] = registrationLastName(row);
    item['Registration_ID'] = registrationId(row);
    item['QR_Code'] = registrationQrCode(row);
    item['Match_Score'] = score;

    final full = registrationFullName(row);

    item['Full_Name'] = full.isNotEmpty
        ? full
        : buildFullName(
            firstName: item['Head_Firstname'],
            middleName: item['Head_Middlename'],
            lastName: item['Head_Surname'],
          );

    return item;
  }

  Future<List<Map<String, dynamic>>> fetchAllRegistrationRows() async {
    const int pageSize = 1000;
    const int maxRows = 20000;

    final List<Map<String, dynamic>> allRows = [];

    for (int from = 0; from < maxRows; from += pageSize) {
      final int to = from + pageSize - 1;

      final data = await supabase
          .from('Registration_Table')
          .select('*')
          .range(from, to);

      final batch = List<Map<String, dynamic>>.from(data);
      allRows.addAll(batch);

      if (batch.length < pageSize) break;
    }

    return allRows;
  }

  Future<List<Map<String, dynamic>>> findRelatedHouseholds(
    Map<String, dynamic> request,
  ) async {
    final allRegistrations = await fetchAllRegistrationRows();
    final List<Map<String, dynamic>> matches = [];

    for (final registration in allRegistrations) {
      final score = scoreRegistrationMatch(
        request: request,
        registration: registration,
      );

      if (score >= 75) {
        matches.add(normalizeHouseholdForRelatedView(registration, score));
      }
    }

    matches.sort((a, b) {
      final aScore = int.tryParse(a['Match_Score']?.toString() ?? '0') ?? 0;
      final bScore = int.tryParse(b['Match_Score']?.toString() ?? '0') ?? 0;
      return bScore.compareTo(aScore);
    });

    debugPrint('APP REQUEST NAME: ${requestFullName(request)}');
    debugPrint('APP REGISTRATION ROWS FETCHED: ${allRegistrations.length}');
    debugPrint('APP RELATED HOUSEHOLDS FOUND: ${matches.length}');

    return matches;
  }

  Future<void> _showErrorDialog(String title, String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    if (!mounted) return false;

    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 600 ? 430 : screenWidth * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: iconColor),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: confirmColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
    );
  }

  Future<void> _showResultDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 600 ? 430 : screenWidth * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: iconColor),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "OK",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  Future<void> approveRequest(Map<String, dynamic> request) async {
    if (!mounted || isSearchingRelated) return;

    final reqName = requestFullName(request);
    final requestId = safeText(request['Request_ID']);
    final requestEmail = safeText(request['Email_Address']);

    final bool? confirm = await _showConfirmDialog(
      icon: Icons.manage_search_rounded,
      iconColor: primaryGreen,
      title: "Find Related Household?",
      message:
          "The system will get all records from Registration_Table, then match the request name \"$reqName\" based on the resident name details.",
      confirmText: "Continue",
      confirmColor: primaryGreen,
    );

    if (confirm != true) return;

    _safeSetState(() {
      isSearchingRelated = true;
    });

    List<Map<String, dynamic>> relatedHouseholds = [];

    try {
      relatedHouseholds = await findRelatedHouseholds(request);
    } catch (e) {
      if (mounted) {
        await _showErrorDialog(
          "Error",
          "Failed to fetch details from Registration_Table:\n$e",
        );
      }
      return;
    } finally {
      if (mounted) {
        _safeSetState(() {
          isSearchingRelated = false;
        });
      }
    }

    if (!mounted) return;

    if (relatedHouseholds.isEmpty) {
      final bool? reject = await _showConfirmDialog(
        icon: Icons.cancel_rounded,
        iconColor: Colors.red.shade600,
        title: "No Related Households",
        message:
            "No related household records were found for \"$reqName\" in Registration_Table.\n\nPlease check if the name in Request_Table and Registration_Table are spelled the same.",
        confirmText: "Reject",
        confirmColor: Colors.red.shade600,
      );

      if (reject == true) {
        try {
          await supabase
              .from('Request_Table')
              .update({'Status': 'Declined'})
              .eq('Request_ID', request['Request_ID']);

          if (!mounted) return;

          await _showResultDialog(
            icon: Icons.cancel_rounded,
            iconColor: Colors.red.shade600,
            title: "Request Rejected",
            message: "The request has been declined successfully.",
          );

          await fetchRequests();
        } catch (e) {
          await _showErrorDialog("Error", "Failed to decline request:\n$e");
        }
      }

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppRelatedHouseholdsPage(
          households: relatedHouseholds,
          requestId: requestId,
          requestEmail: requestEmail,
        ),
      ),
    );

    if (mounted) {
      await fetchRequests();
    }
  }

  Future<void> declineRequest(String requestId) async {
    if (!mounted) return;

    final bool? confirm = await _showConfirmDialog(
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.red.shade600,
      title: "Decline Request?",
      message:
          "Are you sure you want to decline this request? This action cannot be undone.",
      confirmText: "Yes, Decline",
      confirmColor: Colors.red.shade600,
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('Request_Table')
          .update({'Status': 'Declined'})
          .eq('Request_ID', requestId);

      if (!mounted) return;

      await _showResultDialog(
        icon: Icons.check_circle,
        iconColor: Colors.green.shade600,
        title: "Request Declined",
        message: "The request has been successfully declined.",
      );

      await fetchRequests();
    } catch (e) {
      await _showErrorDialog("Error", "Failed to decline request:\n$e");
    }
  }

  Future<void> fetchRequests() async {
    if (!mounted) return;

    _safeSetState(() {
      isLoading = true;
    });

    try {
      final data = await supabase
          .from('Request_Table')
          .select()
          .eq('Status', selectedStatus)
          .order('Request_Date', ascending: false);

      if (!mounted) return;

      _safeSetState(() {
        requests = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching requests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        _safeSetState(() {
          isLoading = false;
        });
      }
    }
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
            _safeSetState(() {
              selectedPage = title;
            });

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
            } else if (title == 'Reports') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebReportsPage()),
              );
            } else if (title == 'Requests') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppRequestsPage()),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: ["Pending", "Approved", "Declined"].map((status) {
          final isSelected = selectedStatus == status;
          final color = status == "Pending"
              ? Colors.orange
              : status == "Approved"
              ? Colors.green
              : Colors.red;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _safeSetState(() {
                  selectedStatus = status;
                });

                fetchRequests();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconForStatus(status),
                      size: 18,
                      color: isSelected ? color : Colors.black45,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData iconForStatus(String status) {
    switch (status) {
      case "Approved":
        return Icons.check_circle;
      case "Declined":
        return Icons.cancel;
      default:
        return Icons.hourglass_top;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green.shade700;
      case "Declined":
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: "$label ",
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final fullName = requestFullName(req).isEmpty
        ? 'Unnamed Request'
        : requestFullName(req);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullName,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.email_outlined,
            "Email:",
            safeText(req['Email_Address']),
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.help_outline, "Reason:", safeText(req['Reason'])),
          const SizedBox(height: 8),
          _infoRow(
            Icons.calendar_today_outlined,
            "Date Requested:",
            formatRequestDate(safeText(req['Request_Date'])),
          ),
          const SizedBox(height: 14),
          if (selectedStatus == "Pending")
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: isSearchingRelated
                          ? null
                          : () => approveRequest(req),
                      icon: isSearchingRelated
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                      label: Text(
                        isSearchingRelated ? "Searching..." : "Find QR",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: primaryGreen.withOpacity(0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: isSearchingRelated
                          ? null
                          : () => declineRequest(req['Request_ID'].toString()),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(
                        "Decline",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor(selectedStatus).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selectedStatus,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor(selectedStatus),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      drawer: _buildAdminDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Requests",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "QR Code Requests",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Review resident QR requests. The email will be passed automatically to the QR sending page.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildStatusToggle(),
            const SizedBox(height: 18),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    )
                  : requests.isEmpty
                  ? Center(
                      child: Text(
                        "No $selectedStatus requests found.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: primaryGreen,
                      onRefresh: fetchRequests,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: requests.length,
                        itemBuilder: (context, i) {
                          final req = requests[i];
                          return _buildRequestCard(req);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
