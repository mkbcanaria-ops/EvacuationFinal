import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebRequestsPage extends StatelessWidget {
  const WebRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Requests",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D743D),
      ),
      body: Center(
        child: Text(
          "Requests Page Coming Soon...",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
