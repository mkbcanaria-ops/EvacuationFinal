import 'package:evacutaion/App/LandingPage.dart';
import 'package:evacutaion/App/MainDashbaord.dart';
import 'package:evacutaion/ResidentPAges/ResidentDashboard.dart';
import 'package:evacutaion/WebPages/WLandingPage.dart';
import 'package:evacutaion/WebPages/WebMainDashboard.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bvgfiycekixspxkavmhl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2Z2ZpeWNla2l4c3B4a2F2bWhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNDM5ODcsImV4cCI6MjA3NjYxOTk4N30.wQ7gsgVQEaO80_p_ExY1-g6cZ_cxx5drdIhVv7VT-uo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides debug banner
      title: 'Santa Evacuation Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true, // optional modern design
      ),

      home: const LandingPage(),
    );
  }
}
