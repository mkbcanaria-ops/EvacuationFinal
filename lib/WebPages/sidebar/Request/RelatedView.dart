import 'package:evacutaion/WebPages/sidebar/Request/ApprovedUserQRPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RelatedHouseholdsPage extends StatelessWidget {
  final List<Map<String, dynamic>> households;

  const RelatedHouseholdsPage({super.key, required this.households});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Related Households",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D743D),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: households.isEmpty
            ? Center(
                child: Text(
                  "No related household found.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: households.length,
                itemBuilder: (context, index) {
                  final household = households[index];
                  final fullName =
                      "${household['Head_Firstname'] ?? ''} ${household['Head_Middlename'] ?? ''} ${household['Head_Surname'] ?? ''}";
                  final registrationId = household['Registration_ID'] ?? '';

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      shadowColor: Colors.grey.shade300,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApprovedUserQRPage(
                                firstName: household['Head_Firstname'] ?? '',
                                middleName: household['Head_Middlename'] ?? '',
                                lastName: household['Head_Surname'] ?? '',
                                registrationId: registrationId,
                              ),
                            ),
                          );
                        },
                        splashColor: const Color(0xFF0D743D).withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "ID: ${household['Registration_ID'] ?? 'N/A'}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0D743D,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.qr_code,
                                  color: Color(0xFF0D743D),
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
