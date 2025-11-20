import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({Key? key}) : super(key: key);

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  String? scannedResult;
  String? foundName;
  bool _isSearching = false;

  Future<void> _searchInSupabase(String qrCode) async {
    setState(() {
      _isSearching = true;
      foundName = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('Sample_Table')
          .select('Name')
          .eq('QR_Code', qrCode)
          .maybeSingle();

      if (response != null) {
        setState(() => foundName = response['Name']);
      } else {
        setState(() => foundName = '❌ No matching name found.');
      }
    } catch (error) {
      setState(() => foundName = '⚠️ Error: $error');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      final value = capture.barcodes.first.rawValue;
      if (value != null && value != scannedResult) {
        setState(() => scannedResult = value);
        _searchInSupabase(value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3C6E47),
      ),
      body: Column(
        children: [
          // Camera scanner view
          Expanded(flex: 3, child: MobileScanner(onDetect: _onDetect)),
          // Display name only
          Expanded(
            flex: 2,
            child: Center(
              child: _isSearching
                  ? const CircularProgressIndicator()
                  : scannedResult == null
                  ? const Text(
                      'Point your camera at a QR code 📷',
                      style: TextStyle(fontSize: 16),
                    )
                  : Text(
                      foundName ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
