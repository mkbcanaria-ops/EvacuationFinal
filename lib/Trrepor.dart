import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MobileExcelDownloadPage extends StatefulWidget {
  const MobileExcelDownloadPage({super.key});

  @override
  State<MobileExcelDownloadPage> createState() =>
      _MobileExcelDownloadPageState();
}

class _MobileExcelDownloadPageState extends State<MobileExcelDownloadPage> {
  bool isDownloading = false;

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return false;

    final manageStatus = await Permission.manageExternalStorage.status;

    if (manageStatus.isGranted) {
      return true;
    }

    final requestedManageStatus = await Permission.manageExternalStorage
        .request();

    if (requestedManageStatus.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.status;

    if (storageStatus.isGranted) {
      return true;
    }

    final requestedStorageStatus = await Permission.storage.request();

    return requestedStorageStatus.isGranted;
  }

  Future<void> _downloadSampleExcelToDownloads() async {
    setState(() {
      isDownloading = true;
    });

    try {
      if (!Platform.isAndroid) {
        throw Exception('This test is for Android only.');
      }

      final hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Storage Permission Needed'),
              content: const Text(
                'Please allow storage access so the Excel file can be saved in your Downloads folder.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D743D),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );

        throw Exception('Storage permission was not granted.');
      }

      final excel = xls.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.rename(defaultSheet, 'Sample Report');
      }

      final sheet = excel['Sample Report'];

      final titleStyle = xls.CellStyle(
        bold: true,
        fontSize: 14,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#0D743D'),
        fontColorHex: xls.ExcelColor.fromHexString('#FFFFFF'),
      );

      final headerStyle = xls.CellStyle(
        bold: true,
        fontSize: 12,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#C6D9B4'),
      );

      final bodyStyle = xls.CellStyle(
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
      );

      void setCell(String cell, xls.CellValue value, {xls.CellStyle? style}) {
        final selectedCell = sheet.cell(xls.CellIndex.indexByString(cell));
        selectedCell.value = value;

        if (style != null) {
          selectedCell.cellStyle = style;
        }
      }

      sheet.setColumnWidth(0, 24);
      sheet.setColumnWidth(1, 34);
      sheet.setColumnWidth(2, 16);
      sheet.setColumnWidth(3, 16);

      sheet.setRowHeight(0, 28);
      sheet.setRowHeight(2, 24);
      sheet.setRowHeight(3, 22);
      sheet.setRowHeight(4, 22);
      sheet.setRowHeight(5, 22);
      sheet.setRowHeight(7, 24);

      setCell(
        'A1',
        xls.TextCellValue('Sample Excel Report'),
        style: titleStyle,
      );

      sheet.merge(
        xls.CellIndex.indexByString('A1'),
        xls.CellIndex.indexByString('D1'),
      );

      setCell('A3', xls.TextCellValue('Barangay'), style: headerStyle);
      setCell('B3', xls.TextCellValue('Evacuation Center'), style: headerStyle);
      setCell('C3', xls.TextCellValue('Families'), style: headerStyle);
      setCell('D3', xls.TextCellValue('Persons'), style: headerStyle);

      setCell('A4', xls.TextCellValue('Mabilbila Sur'), style: bodyStyle);
      setCell('B4', xls.TextCellValue('RHU'), style: bodyStyle);
      setCell('C4', xls.IntCellValue(5), style: bodyStyle);
      setCell('D4', xls.IntCellValue(20), style: bodyStyle);

      setCell('A5', xls.TextCellValue('Rancho'), style: bodyStyle);
      setCell(
        'B5',
        xls.TextCellValue('Farmers Multipurpose Building'),
        style: bodyStyle,
      );
      setCell('C5', xls.IntCellValue(3), style: bodyStyle);
      setCell('D5', xls.IntCellValue(12), style: bodyStyle);

      setCell('A6', xls.TextCellValue('Damacuag'), style: bodyStyle);
      setCell(
        'B6',
        xls.TextCellValue('Municipal Evacuation Center'),
        style: bodyStyle,
      );
      setCell('C6', xls.IntCellValue(2), style: bodyStyle);
      setCell('D6', xls.IntCellValue(8), style: bodyStyle);

      setCell('A8', xls.TextCellValue('TOTAL'), style: headerStyle);
      setCell('C8', xls.IntCellValue(10), style: headerStyle);
      setCell('D8', xls.IntCellValue(40), style: headerStyle);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to create Excel file.');
      }

      final Uint8List excelBytes = Uint8List.fromList(bytes);

      final now = DateTime.now();
      final fileName =
          'Sample_Report_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}.xlsx';

      final downloadsDirectory = Directory(
        '/storage/emulated/0/Download/MSWDO_Reports',
      );

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      final filePath = '${downloadsDirectory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excelBytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel saved to Downloads/MSWDO_Reports/$fileName'),
          backgroundColor: const Color(0xFF0D743D),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF0D743D);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Excel Download Test',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width < 500
              ? MediaQuery.of(context).size.width * 0.88
              : 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: primaryGreen,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Download Excel Report',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to generate a sample Excel file. It will be saved in Downloads/MSWDO_Reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isDownloading
                      ? null
                      : _downloadSampleExcelToDownloads,
                  icon: isDownloading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: Text(
                    isDownloading ? 'Saving Excel...' : 'Download Excel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: primaryGreen.withOpacity(0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
