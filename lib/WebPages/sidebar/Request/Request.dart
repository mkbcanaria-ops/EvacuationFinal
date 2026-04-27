import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:evacutaion/WebPages/sidebar/Discharge%20Function/WebDischargeScanner.dart';
import 'package:evacutaion/WebPages/sidebar/Report/Report.dart';
import 'package:evacutaion/WebPages/sidebar/Request/RelatedView.dart';
import 'package:evacutaion/WebPages/sidebar/ViewQRcode/WebManageQr.dart';
import 'package:evacutaion/WebPages/sidebar/WebEditResident/WebManageResidents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebRequestsPage extends StatefulWidget {
  const WebRequestsPage({super.key});

  @override
  State<WebRequestsPage> createState() => _WebRequestsPageState();
}

class _WebRequestsPageState extends State<WebRequestsPage> {
  String selectedPage = "Requests";
  String selectedStatus = "Pending";

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  final Color primaryGreen = const Color(0xFF0D743D);
  final Color darkGreen = const Color(0xFF095B30);
  final Color softBg = const Color(0xFFF4F7F6);
  final Color cardBorder = const Color(0xFFE3EAE6);

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

  @override
  void initState() {
    super.initState();
    fetchRequests();
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
    if (!mounted) return;

    final headSurname = safeText(request['Last_Name']);
    final headFirstName = safeText(request['First_Name']);
    final headMiddleName = safeText(request['Middle_Name']);

    final requestId = safeText(request['Request_ID']);
    final requestEmail = safeText(request['Email_Address']);

    final bool? confirm = await _showConfirmDialog(
      icon: Icons.manage_search_rounded,
      iconColor: primaryGreen,
      title: "Find Related Household?",
      message:
          "The system will search for matching registered households first. The request will only be approved after the correct QR code is selected and sent to the resident email.",
      confirmText: "Continue",
      confirmColor: primaryGreen,
    );

    if (confirm != true) return;

    List<Map<String, dynamic>> relatedHouseholds = [];

    try {
      if (headMiddleName == 'Not provided') {
        relatedHouseholds = await supabase
            .from('Registration_Table')
            .select(
              'Head_Firstname, Head_Middlename, Head_Surname, Registration_ID, QR_Code',
            )
            .ilike('Head_Surname', '%$headSurname%')
            .ilike('Head_Firstname', '%$headFirstName%');
      } else {
        relatedHouseholds = await supabase
            .from('Registration_Table')
            .select(
              'Head_Firstname, Head_Middlename, Head_Surname, Registration_ID, QR_Code',
            )
            .ilike('Head_Surname', '%$headSurname%')
            .ilike('Head_Firstname', '%$headFirstName%')
            .ilike('Head_Middlename', '%$headMiddleName%');
      }
    } catch (e) {
      await _showErrorDialog(
        "Error",
        "Failed to fetch related households:\n$e",
      );
      return;
    }

    if (!mounted) return;

    if (relatedHouseholds.isEmpty) {
      final bool? reject = await _showConfirmDialog(
        icon: Icons.cancel_rounded,
        iconColor: Colors.red.shade600,
        title: "No Related Households",
        message:
            "No related household records were found for this name. Do you want to reject this request?",
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

          fetchRequests();
        } catch (e) {
          await _showErrorDialog("Error", "Failed to decline request:\n$e");
        }
      }

      return;
    }

    /*
      IMPORTANT:
      We do NOT update Status to Approved here anymore.

      New process:
      1. Admin clicks Find QR.
      2. System searches related households.
      3. Admin selects the correct household.
      4. QR preview page opens.
      5. Email is already passed from this request.
      6. QR page sends QR to that email.
      7. Request becomes Approved only after sending succeeds.
    */

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RelatedHouseholdsPage(
          households: relatedHouseholds,
          requestId: requestId,
          requestEmail: requestEmail,
        ),
      ),
    );

    if (mounted) {
      fetchRequests();
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

      fetchRequests();
    } catch (e) {
      await _showErrorDialog("Error", "Failed to decline request:\n$e");
    }
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);

    try {
      final data = await supabase
          .from('Request_Table')
          .select()
          .eq('Status', selectedStatus)
          .order('Request_Date', ascending: false);

      setState(() {
        requests = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching requests: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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
                MaterialPageRoute(
                  builder: (_) => const WebManageResidentsPage(),
                ),
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
            } else if (title == 'Reports') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebReportsPage()),
              );
            } else if (title == 'Requests') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebRequestsPage()),
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
                setState(() => selectedStatus = status);
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
    final middleName = safeText(req['Middle_Name']);
    final fullName =
        "${safeText(req['First_Name'])} ${middleName == 'Not provided' ? '' : middleName} ${safeText(req['Last_Name'])}"
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

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
            fullName.isEmpty ? 'Unnamed Request' : fullName,
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
                      onPressed: () => approveRequest(req),
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        "Find QR",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryGreen,
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
                      onPressed: () =>
                          declineRequest(req['Request_ID'].toString()),
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
