// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

class WebReportsPreviewPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDateTime;

  const WebReportsPreviewPage({
    super.key,
    required this.startDate,
    required this.endDateTime,
  });

  @override
  State<WebReportsPreviewPage> createState() => _WebReportsPreviewPageState();
}

class _WebReportsPreviewPageState extends State<WebReportsPreviewPage> {
  final supabase = Supabase.instance.client;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  late double colRegion;
  late double colBarangayName;
  late double colBarangayCount;
  late double colFamilies;
  late double colPersons;
  late double col4PsFamilies;
  late double colEvacuationCenterName;
  late double colAddress;
  late double colOriginBrgyName;
  late double colOriginBrgyCount;
  late double colInsideEcFamiliesCum;
  late double colInsideEcFamiliesNow;
  late double colPersonsActualCum;
  late double colPersonsActualNow;
  late double colPersonsEstimateCum;
  late double colPersonsEstimateNow;

  Map<String, int> barangayCounts = {};
  Map<String, int> familyCounts = {};
  Map<String, int> personCounts = {};
  Map<String, int> fourPsFamilyCounts = {};
  List<Map<String, dynamic>> evacuationCenterRows = [];
  bool isLoading = true;
  String? errorMessage;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchDischargeResidents();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} $hour:$minute $period';
  }

  String _formatDateTimeForFilename(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}_$hour-$minute';
  }

  Future<void> _fetchDischargeResidents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      barangayCounts = {};
      familyCounts = {};
      personCounts = {};
      fourPsFamilyCounts = {};
      evacuationCenterRows = [];
    });

    try {
      final start = DateTime(
        widget.startDate.year,
        widget.startDate.month,
        widget.startDate.day,
        0,
        0,
        0,
      );

      final end = widget.endDateTime;

      // Split point = selected end date/time minus 3 hours
      final splitTime = end.subtract(const Duration(hours: 3));

      DateTime? _parseCustomTimeDischarge(dynamic value) {
        if (value == null) return null;

        final raw = value.toString().trim();
        if (raw.isEmpty) return null;

        try {
          final parts = raw.split('|');
          if (parts.length != 2) return null;

          final datePart = parts[0].trim(); // March 26, 2026
          final timePart = parts[1].trim(); // 2:46 PM

          final datePieces = datePart.split(',');
          if (datePieces.length != 2) return null;

          final monthDayPart = datePieces[0].trim(); // March 26
          final year = int.tryParse(datePieces[1].trim());
          if (year == null) return null;

          final mdParts = monthDayPart.split(' ');
          if (mdParts.length != 2) return null;

          final monthName = mdParts[0].trim().toLowerCase();
          final day = int.tryParse(mdParts[1].trim());
          if (day == null) return null;

          const monthMap = {
            'january': 1,
            'february': 2,
            'march': 3,
            'april': 4,
            'may': 5,
            'june': 6,
            'july': 7,
            'august': 8,
            'september': 9,
            'october': 10,
            'november': 11,
            'december': 12,
          };

          final month = monthMap[monthName];
          if (month == null) return null;

          final timeParts = timePart.split(' ');
          if (timeParts.length != 2) return null;

          final hm = timeParts[0].split(':');
          if (hm.length != 2) return null;

          int hour = int.tryParse(hm[0]) ?? 0;
          final minute = int.tryParse(hm[1]) ?? 0;
          final period = timeParts[1].toUpperCase();

          if (period == 'PM' && hour != 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;

          return DateTime(year, month, day, hour, minute);
        } catch (_) {
          return null;
        }
      }

      final response = await supabase
          .from('Discharge_Resident')
          .select('Barangay, Relation, Time_Discharge, 4Ps_Families, Site')
          .order('Barangay', ascending: true)
          .order('Site', ascending: true);

      final fetched = List<Map<String, dynamic>>.from(response);

      final Map<String, int> totalBarangayCounts = {};
      final Map<String, int> totalFamilies = {};
      final Map<String, int> totalPersons = {};
      final Map<String, int> totalFourPsFamilies = {};

      final Map<String, Map<String, dynamic>> groupedByBarangayAndSite = {};

      for (final row in fetched) {
        final barangay = (row['Barangay'] ?? '').toString().trim();
        final relation = (row['Relation'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final site = (row['Site'] ?? '').toString().trim();

        final raw4Ps = row['4Ps_Families'];
        final is4Ps =
            raw4Ps == true ||
            raw4Ps.toString().trim().toLowerCase() == 'true' ||
            raw4Ps.toString().trim() == '1';

        if (barangay.isEmpty) continue;

        final dischargeTime = _parseCustomTimeDischarge(row['Time_Discharge']);
        if (dischargeTime == null) continue;

        // Only process rows within overall selected range
        if (dischargeTime.isBefore(start) || dischargeTime.isAfter(end)) {
          continue;
        }

        totalBarangayCounts[barangay] =
            (totalBarangayCounts[barangay] ?? 0) + 1;
        totalPersons[barangay] = (totalPersons[barangay] ?? 0) + 1;

        if (relation == 'head of family') {
          totalFamilies[barangay] = (totalFamilies[barangay] ?? 0) + 1;

          if (is4Ps) {
            totalFourPsFamilies[barangay] =
                (totalFourPsFamilies[barangay] ?? 0) + 1;
          }
        }

        final groupKey = '${barangay.toLowerCase()}|||${site.toLowerCase()}';

        if (!groupedByBarangayAndSite.containsKey(groupKey)) {
          groupedByBarangayAndSite[groupKey] = {
            'barangay': barangay,
            'site': site,
            'count': 0,
            'families': 0,
            'persons': 0,
            'fourPsFamilies': 0,
            'insideEcFamiliesCum': 0,
            'insideEcFamiliesNow': 0,
            'personsActualCum': 0,
            'personsActualNow': 0,
          };
        }

        groupedByBarangayAndSite[groupKey]!['count'] =
            (groupedByBarangayAndSite[groupKey]!['count'] as int) + 1;

        groupedByBarangayAndSite[groupKey]!['persons'] =
            (groupedByBarangayAndSite[groupKey]!['persons'] as int) + 1;

        // PERSONS (ACTUAL) = count all rows
        if (!dischargeTime.isBefore(start) &&
            !dischargeTime.isAfter(splitTime)) {
          groupedByBarangayAndSite[groupKey]!['personsActualCum'] =
              (groupedByBarangayAndSite[groupKey]!['personsActualCum'] as int) +
              1;
        }

        if (dischargeTime.isAfter(splitTime) && !dischargeTime.isAfter(end)) {
          groupedByBarangayAndSite[groupKey]!['personsActualNow'] =
              (groupedByBarangayAndSite[groupKey]!['personsActualNow'] as int) +
              1;
        }

        // FAMILIES = head of family only
        if (relation == 'head of family') {
          groupedByBarangayAndSite[groupKey]!['families'] =
              (groupedByBarangayAndSite[groupKey]!['families'] as int) + 1;

          if (is4Ps) {
            groupedByBarangayAndSite[groupKey]!['fourPsFamilies'] =
                (groupedByBarangayAndSite[groupKey]!['fourPsFamilies'] as int) +
                1;
          }

          if (!dischargeTime.isBefore(start) &&
              !dischargeTime.isAfter(splitTime)) {
            groupedByBarangayAndSite[groupKey]!['insideEcFamiliesCum'] =
                (groupedByBarangayAndSite[groupKey]!['insideEcFamiliesCum']
                    as int) +
                1;
          }

          if (dischargeTime.isAfter(splitTime) && !dischargeTime.isAfter(end)) {
            groupedByBarangayAndSite[groupKey]!['insideEcFamiliesNow'] =
                (groupedByBarangayAndSite[groupKey]!['insideEcFamiliesNow']
                    as int) +
                1;
          }
        }
      }

      final sortedBarangays = totalBarangayCounts.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final sortedCounts = <String, int>{};
      final sortedFamilies = <String, int>{};
      final sortedPersons = <String, int>{};
      final sortedFourPsFamilies = <String, int>{};

      for (final barangay in sortedBarangays) {
        sortedCounts[barangay] = totalBarangayCounts[barangay] ?? 0;
        sortedFamilies[barangay] = totalFamilies[barangay] ?? 0;
        sortedPersons[barangay] = totalPersons[barangay] ?? 0;
        sortedFourPsFamilies[barangay] = totalFourPsFamilies[barangay] ?? 0;
      }

      final groupedRows = groupedByBarangayAndSite.values.toList()
        ..sort((a, b) {
          final barangayCompare = (a['barangay'] as String)
              .toLowerCase()
              .compareTo((b['barangay'] as String).toLowerCase());

          if (barangayCompare != 0) return barangayCompare;

          return (a['site'] as String).toLowerCase().compareTo(
            (b['site'] as String).toLowerCase(),
          );
        });

      if (!mounted) return;

      setState(() {
        barangayCounts = sortedCounts;
        familyCounts = sortedFamilies;
        personCounts = sortedPersons;
        fourPsFamilyCounts = sortedFourPsFamilies;
        evacuationCenterRows = groupedRows;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _downloadExcel() async {
    if (barangayCounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export.')),
      );
      return;
    }

    setState(() {
      isDownloading = true;
    });

    try {
      final excel = xls.Excel.createExcel();
      final defaultSheetName = excel.getDefaultSheet();
      if (defaultSheetName == null) {
        throw Exception('No default sheet found.');
      }

      excel.rename(defaultSheetName, 'Preview Report');
      final sheet = excel['Preview Report'];

      final int totalBarangaysAffected = barangayCounts.values.fold(
        0,
        (sum, item) => sum + item,
      );
      final int totalFamilies = familyCounts.values.fold(
        0,
        (sum, item) => sum + item,
      );
      final int totalPersons = personCounts.values.fold(
        0,
        (sum, item) => sum + item,
      );
      final int total4PsFamilies = fourPsFamilyCounts.values.fold(
        0,
        (sum, item) => sum + item,
      );

      sheet.setColumnWidth(0, 34);
      sheet.setColumnWidth(1, 42);
      sheet.setColumnWidth(2, 16);
      sheet.setColumnWidth(3, 14);
      sheet.setColumnWidth(4, 14);
      sheet.setColumnWidth(5, 16);

      sheet.setDefaultRowHeight(22);
      sheet.setRowHeight(0, 22);
      sheet.setRowHeight(1, 22);
      sheet.setRowHeight(2, 22);
      sheet.setRowHeight(4, 30);
      sheet.setRowHeight(5, 22);
      sheet.setRowHeight(6, 24);

      sheet.merge(
        xls.CellIndex.indexByString('A5'),
        xls.CellIndex.indexByString('A7'),
      );
      sheet.merge(
        xls.CellIndex.indexByString('B5'),
        xls.CellIndex.indexByString('F5'),
      );
      sheet.merge(
        xls.CellIndex.indexByString('B6'),
        xls.CellIndex.indexByString('C6'),
      );
      sheet.merge(
        xls.CellIndex.indexByString('D6'),
        xls.CellIndex.indexByString('D7'),
      );
      sheet.merge(
        xls.CellIndex.indexByString('E6'),
        xls.CellIndex.indexByString('E7'),
      );
      sheet.merge(
        xls.CellIndex.indexByString('F6'),
        xls.CellIndex.indexByString('F7'),
      );

      final thickBorder = xls.Border(
        borderStyle: xls.BorderStyle.Thick,
        borderColorHex: xls.ExcelColor.fromHexString('#000000'),
      );

      final mediumBorder = xls.Border(
        borderStyle: xls.BorderStyle.Medium,
        borderColorHex: xls.ExcelColor.fromHexString('#000000'),
      );

      final titleStyle = xls.CellStyle(
        bold: true,
        fontSize: 12,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
      );

      final blueHeaderStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#D9E2F3'),
        textWrapping: xls.TextWrapping.WrapText,
        leftBorder: thickBorder,
        rightBorder: thickBorder,
        topBorder: thickBorder,
        bottomBorder: thickBorder,
      );

      final greenHeaderStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#C6D9B4'),
        textWrapping: xls.TextWrapping.WrapText,
        leftBorder: thickBorder,
        rightBorder: thickBorder,
        topBorder: thickBorder,
        bottomBorder: thickBorder,
      );

      final gray1LeftStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#B7B7B7'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final gray1TextStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#B7B7B7'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final gray1NumberStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Right,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#B7B7B7'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final gray2TextStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#D0D0D0'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final gray2NumberStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Right,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#D0D0D0'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final gray3TextStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#F2F2F2'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final gray3NumberStyle = xls.CellStyle(
        bold: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Right,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#F2F2F2'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final santaLabelStyle = xls.CellStyle(
        italic: true,
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#F4CCCC'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final santaBlankStyle = xls.CellStyle(
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        backgroundColorHex: xls.ExcelColor.fromHexString('#F4CCCC'),
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final bodyTextStyle = xls.CellStyle(
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final bodyNumberStyle = xls.CellStyle(
        fontSize: 11,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Right,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      sheet.cell(xls.CellIndex.indexByString('A1')).value = xls.TextCellValue(
        'Republic of the Philippines',
      );
      sheet.cell(xls.CellIndex.indexByString('A2')).value = xls.TextCellValue(
        'Province of Ilocos Sur',
      );
      sheet.cell(xls.CellIndex.indexByString('A3')).value = xls.TextCellValue(
        'Municipality of Santa',
      );

      sheet.cell(xls.CellIndex.indexByString('A1')).cellStyle = titleStyle;
      sheet.cell(xls.CellIndex.indexByString('A2')).cellStyle = titleStyle;
      sheet.cell(xls.CellIndex.indexByString('A3')).cellStyle = titleStyle;

      sheet.cell(xls.CellIndex.indexByString('A5')).value = xls.TextCellValue(
        'REGION / PROVINCE / MUNICIPALITY',
      );
      sheet.cell(xls.CellIndex.indexByString('B5')).value = xls.TextCellValue(
        'NUMBER OF AFFECTED',
      );

      sheet.cell(xls.CellIndex.indexByString('B6')).value = xls.TextCellValue(
        'Barangays',
      );
      sheet.cell(xls.CellIndex.indexByString('B7')).value = xls.TextCellValue(
        'Name',
      );
      sheet.cell(xls.CellIndex.indexByString('C7')).value = xls.TextCellValue(
        'Count',
      );

      sheet.cell(xls.CellIndex.indexByString('D6')).value = xls.TextCellValue(
        'Families',
      );
      sheet.cell(xls.CellIndex.indexByString('E6')).value = xls.TextCellValue(
        'Persons',
      );
      sheet.cell(xls.CellIndex.indexByString('F6')).value = xls.TextCellValue(
        '4Ps Families',
      );

      for (final ref in ['A5', 'A6', 'A7']) {
        sheet.cell(xls.CellIndex.indexByString(ref)).cellStyle =
            blueHeaderStyle;
      }

      for (final ref in [
        'B5',
        'C5',
        'D5',
        'E5',
        'F5',
        'B6',
        'C6',
        'B7',
        'C7',
        'D6',
        'D7',
        'E6',
        'E7',
        'F6',
        'F7',
      ]) {
        sheet.cell(xls.CellIndex.indexByString(ref)).cellStyle =
            greenHeaderStyle;
      }

      sheet.cell(xls.CellIndex.indexByString('A8')).value = xls.TextCellValue(
        'GRAND TOTAL',
      );
      sheet.cell(xls.CellIndex.indexByString('B8')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('C8')).value = xls.IntCellValue(
        totalBarangaysAffected,
      );
      sheet.cell(xls.CellIndex.indexByString('D8')).value = xls.IntCellValue(
        totalFamilies,
      );
      sheet.cell(xls.CellIndex.indexByString('E8')).value = xls.IntCellValue(
        totalPersons,
      );
      sheet.cell(xls.CellIndex.indexByString('F8')).value = xls.IntCellValue(
        total4PsFamilies,
      );

      sheet.cell(xls.CellIndex.indexByString('A8')).cellStyle = gray1LeftStyle;
      sheet.cell(xls.CellIndex.indexByString('B8')).cellStyle = gray1TextStyle;
      sheet.cell(xls.CellIndex.indexByString('C8')).cellStyle =
          gray1NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('D8')).cellStyle =
          gray1NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('E8')).cellStyle =
          gray1NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('F8')).cellStyle =
          gray1NumberStyle;

      sheet.cell(xls.CellIndex.indexByString('A9')).value = xls.TextCellValue(
        'Ilocos Sur',
      );
      sheet.cell(xls.CellIndex.indexByString('B9')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('C9')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('D9')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('E9')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('F9')).value = xls.TextCellValue(
        '',
      );

      sheet.cell(xls.CellIndex.indexByString('A9')).cellStyle = gray2TextStyle;
      sheet.cell(xls.CellIndex.indexByString('B9')).cellStyle = gray2TextStyle;
      sheet.cell(xls.CellIndex.indexByString('C9')).cellStyle =
          gray2NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('D9')).cellStyle =
          gray2NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('E9')).cellStyle =
          gray2NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('F9')).cellStyle =
          gray2NumberStyle;

      sheet.cell(xls.CellIndex.indexByString('A10')).value = xls.TextCellValue(
        'Province',
      );
      sheet.cell(xls.CellIndex.indexByString('B10')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('C10')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('D10')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('E10')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('F10')).value = xls.TextCellValue(
        '',
      );

      sheet.cell(xls.CellIndex.indexByString('A10')).cellStyle = gray3TextStyle;
      sheet.cell(xls.CellIndex.indexByString('B10')).cellStyle = gray3TextStyle;
      sheet.cell(xls.CellIndex.indexByString('C10')).cellStyle =
          gray3NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('D10')).cellStyle =
          gray3NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('E10')).cellStyle =
          gray3NumberStyle;
      sheet.cell(xls.CellIndex.indexByString('F10')).cellStyle =
          gray3NumberStyle;

      sheet.cell(xls.CellIndex.indexByString('A11')).value = xls.TextCellValue(
        'Santa',
      );
      sheet.cell(xls.CellIndex.indexByString('B11')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('C11')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('D11')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('E11')).value = xls.TextCellValue(
        '',
      );
      sheet.cell(xls.CellIndex.indexByString('F11')).value = xls.TextCellValue(
        '',
      );

      sheet.cell(xls.CellIndex.indexByString('A11')).cellStyle =
          santaLabelStyle;
      sheet.cell(xls.CellIndex.indexByString('B11')).cellStyle =
          santaBlankStyle;
      sheet.cell(xls.CellIndex.indexByString('C11')).cellStyle =
          santaBlankStyle;
      sheet.cell(xls.CellIndex.indexByString('D11')).cellStyle =
          santaBlankStyle;
      sheet.cell(xls.CellIndex.indexByString('E11')).cellStyle =
          santaBlankStyle;
      sheet.cell(xls.CellIndex.indexByString('F11')).cellStyle =
          santaBlankStyle;

      int row = 12;

      for (final entry in barangayCounts.entries) {
        final barangay = entry.key;
        final count = barangayCounts[barangay] ?? 0;
        final families = familyCounts[barangay] ?? 0;
        final persons = personCounts[barangay] ?? 0;
        final fourPs = fourPsFamilyCounts[barangay] ?? 0;

        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row - 1),
            )
            .value = xls.TextCellValue(
          '',
        );

        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1),
            )
            .value = xls.TextCellValue(
          barangay,
        );

        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row - 1),
            )
            .value = xls.IntCellValue(
          count,
        );

        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row - 1),
            )
            .value = xls.IntCellValue(
          families,
        );

        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row - 1),
            )
            .value = xls.IntCellValue(
          persons,
        );

        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row - 1),
            )
            .value = xls.IntCellValue(
          fourPs,
        );

        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: 0,
                    rowIndex: row - 1,
                  ),
                )
                .cellStyle =
            bodyTextStyle;

        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: 1,
                    rowIndex: row - 1,
                  ),
                )
                .cellStyle =
            bodyTextStyle;

        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: 2,
                    rowIndex: row - 1,
                  ),
                )
                .cellStyle =
            bodyNumberStyle;

        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: 3,
                    rowIndex: row - 1,
                  ),
                )
                .cellStyle =
            bodyNumberStyle;

        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: 4,
                    rowIndex: row - 1,
                  ),
                )
                .cellStyle =
            bodyNumberStyle;

        sheet
                .cell(
                  xls.CellIndex.indexByColumnRow(
                    columnIndex: 5,
                    rowIndex: row - 1,
                  ),
                )
                .cellStyle =
            bodyNumberStyle;

        row++;
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to generate Excel file.');
      }

      final fileBytes = Uint8List.fromList(bytes);
      final blob = html.Blob([
        fileBytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final startText = _formatDate(widget.startDate);
      final endText = _formatDateTimeForFilename(widget.endDateTime);

      html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'Preview_Report_${startText}_to_$endText.xlsx',
        )
        ..click();

      html.Url.revokeObjectUrl(url);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel downloaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  Widget _cell({
    required String text,
    required double width,
    required double height,
    bool bold = false,
    bool italic = false,
    Color color = Colors.white,
    TextAlign textAlign = TextAlign.left,
    Alignment alignment = Alignment.centerLeft,
    double fontSize = 15,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10),
  }) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: GoogleFonts.arimo(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: Colors.black,
          height: 1.0,
        ),
      ),
    );
  }

  double _measureTextWidth(
    String text, {
    double fontSize = 15,
    bool bold = false,
    bool italic = false,
    double horizontalPadding = 24,
    double minWidth = 70,
    double maxWidth = 420,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? ' ' : text,
        style: GoogleFonts.arimo(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final calculated = painter.width + horizontalPadding;
    return calculated.clamp(minWidth, maxWidth);
  }

  double _getMaxWidthForValues(
    List<String> values, {
    required String header,
    double fontSize = 15,
    double headerFontSize = 12,
    double minWidth = 70,
    double maxWidth = 420,
  }) {
    double maxValWidth = _measureTextWidth(
      header,
      fontSize: headerFontSize,
      bold: true,
      minWidth: minWidth,
      maxWidth: maxWidth,
    );

    for (final value in values) {
      final width = _measureTextWidth(
        value,
        fontSize: fontSize,
        minWidth: minWidth,
        maxWidth: maxWidth,
      );
      if (width > maxValWidth) {
        maxValWidth = width;
      }
    }

    return maxValWidth;
  }

  void _computeDynamicColumnWidths() {
    final barangayValues = evacuationCenterRows
        .map((e) => (e['barangay'] ?? '').toString())
        .toList();

    final countValues = evacuationCenterRows
        .map((e) => (e['count'] ?? 0).toString())
        .toList();

    final familyValues = evacuationCenterRows
        .map((e) => (e['families'] ?? 0).toString())
        .toList();

    final personValues = evacuationCenterRows
        .map((e) => (e['persons'] ?? 0).toString())
        .toList();

    final fourPsValues = evacuationCenterRows
        .map((e) => (e['fourPsFamilies'] ?? 0).toString())
        .toList();

    final siteValues = evacuationCenterRows
        .map((e) => (e['site'] ?? '').toString())
        .toList();

    final addressValues = List<String>.filled(
      evacuationCenterRows.isEmpty ? 1 : evacuationCenterRows.length,
      'SANTA, ILOCOS SUR',
    );

    final originBarangayValues = evacuationCenterRows
        .map((e) => (e['barangay'] ?? '').toString())
        .toList();

    final originCountValues = evacuationCenterRows.isEmpty
        ? ['0']
        : List<String>.filled(evacuationCenterRows.length, '1');

    colRegion = _getMaxWidthForValues(
      ['GRAND TOTAL', 'Ilocos Sur', 'Province', 'Santa'],
      header: 'REGION / PROVINCE / MUNICIPALITY',
      fontSize: 15,
      headerFontSize: 13,
      minWidth: 220,
      maxWidth: 360,
    );

    colBarangayName = _getMaxWidthForValues(
      barangayValues.isEmpty ? [''] : barangayValues,
      header: 'Name',
      minWidth: 150,
      maxWidth: 360,
    );

    colBarangayCount = _getMaxWidthForValues(
      countValues.isEmpty ? ['0'] : countValues,
      header: 'Count',
      minWidth: 80,
      maxWidth: 150,
    );

    colFamilies = _getMaxWidthForValues(
      familyValues.isEmpty ? ['0'] : familyValues,
      header: 'Families',
      minWidth: 90,
      maxWidth: 150,
    );

    colPersons = _getMaxWidthForValues(
      personValues.isEmpty ? ['0'] : personValues,
      header: 'Persons',
      minWidth: 90,
      maxWidth: 150,
    );

    col4PsFamilies = _getMaxWidthForValues(
      fourPsValues.isEmpty ? ['0'] : fourPsValues,
      header: '4Ps Families',
      minWidth: 110,
      maxWidth: 180,
    );

    colEvacuationCenterName = _getMaxWidthForValues(
      siteValues.isEmpty ? [''] : siteValues,
      header: 'NAME OF EVACUATION CENTER',
      minWidth: 220,
      maxWidth: 420,
    );

    colAddress = _getMaxWidthForValues(
      addressValues,
      header: 'ADDRESS',
      minWidth: 170,
      maxWidth: 260,
    );

    colOriginBrgyName = _getMaxWidthForValues(
      originBarangayValues.isEmpty ? [''] : originBarangayValues,
      header: 'Brgy Name',
      minWidth: 150,
      maxWidth: 320,
    );

    colOriginBrgyCount = _getMaxWidthForValues(
      originCountValues,
      header: 'Brgy Count',
      minWidth: 90,
      maxWidth: 140,
    );

    colInsideEcFamiliesCum = _getMaxWidthForValues(
      ['9999'],
      header: 'CUM',
      minWidth: 70,
      maxWidth: 100,
    );

    colInsideEcFamiliesNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 70,
      maxWidth: 100,
    );

    colPersonsActualCum = _getMaxWidthForValues(
      ['9999'],
      header: 'CUM',
      minWidth: 70,
      maxWidth: 100,
    );

    colPersonsActualNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 70,
      maxWidth: 100,
    );

    colPersonsEstimateCum = _getMaxWidthForValues(
      ['9999'],
      header: 'CUM',
      minWidth: 70,
      maxWidth: 100,
    );

    colPersonsEstimateNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 70,
      maxWidth: 100,
    );
  }

  Widget _buildRow({
    required String region,
    required String barangayName,
    required String barangayCount,
    required String families,
    required String persons,
    required String fourPsFamilies,
    required String evacuationCenterName,
    required String address,
    required String originBrgyName,
    required String originBrgyCount,
    required String insideEcFamiliesCum,
    required String insideEcFamiliesNow,
    required String personsActualCum,
    required String personsActualNow,
    required String personsEstimateCum,
    required String personsEstimateNow,
    bool bold = false,
    bool italicRegion = false,
    Color color = Colors.white,
    double height = 21,
  }) {
    return Row(
      children: [
        _cell(
          text: region,
          width: colRegion,
          height: height,
          bold: bold,
          italic: italicRegion,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerLeft,
          textAlign: TextAlign.left,
          padding: EdgeInsets.only(left: italicRegion ? 18 : 10),
        ),
        _cell(
          text: barangayName,
          width: colBarangayName,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerLeft,
          textAlign: TextAlign.left,
        ),
        _cell(
          text: barangayCount,
          width: colBarangayCount,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: families,
          width: colFamilies,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: persons,
          width: colPersons,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: fourPsFamilies,
          width: col4PsFamilies,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: evacuationCenterName,
          width: colEvacuationCenterName,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerLeft,
          textAlign: TextAlign.left,
        ),
        _cell(
          text: address,
          width: colAddress,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerLeft,
          textAlign: TextAlign.left,
        ),
        _cell(
          text: originBrgyName,
          width: colOriginBrgyName,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerLeft,
          textAlign: TextAlign.left,
        ),
        _cell(
          text: originBrgyCount,
          width: colOriginBrgyCount,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: insideEcFamiliesCum,
          width: colInsideEcFamiliesCum,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: insideEcFamiliesNow,
          width: colInsideEcFamiliesNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: personsActualCum,
          width: colPersonsActualCum,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: personsActualNow,
          width: colPersonsActualNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: personsEstimateCum,
          width: colPersonsEstimateCum,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: personsEstimateNow,
          width: colPersonsEstimateNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  List<Widget> _buildBarangayRows() {
    if (evacuationCenterRows.isEmpty) {
      return [
        _buildRow(
          region: '',
          barangayName: '',
          barangayCount: '0',
          families: '0',
          persons: '0',
          fourPsFamilies: '0',
          evacuationCenterName: '',
          address: 'SANTA, ILOCOS SUR',
          originBrgyName: '',
          originBrgyCount: '0',
          insideEcFamiliesCum: '',
          insideEcFamiliesNow: '',
          personsActualCum: '',
          personsActualNow: '',
          personsEstimateCum: '',
          personsEstimateNow: '',
          color: Colors.white,
        ),
      ];
    }

    final List<Widget> rows = [];
    String lastBarangay = '';

    for (final row in evacuationCenterRows) {
      final barangay = (row['barangay'] ?? '').toString();
      final site = (row['site'] ?? '').toString();

      final count = (row['count'] ?? 0).toString();
      final families = (row['families'] ?? 0).toString();
      final persons = (row['persons'] ?? 0).toString();
      final fourPsFamilies = (row['fourPsFamilies'] ?? 0).toString();

      final bool isFirstRowOfBarangay = barangay != lastBarangay;

      rows.add(
        _buildRow(
          region: '',
          barangayName: isFirstRowOfBarangay ? barangay : '',
          barangayCount: count,
          families: families,
          persons: persons,
          fourPsFamilies: fourPsFamilies,
          evacuationCenterName: site,
          address: 'SANTA, ILOCOS SUR',

          // always show the barangay name here
          originBrgyName: barangay,

          // keep count only on first row if you want
          originBrgyCount: isFirstRowOfBarangay ? '1' : '',

          insideEcFamiliesCum: (row['insideEcFamiliesCum'] ?? 0).toString(),
          insideEcFamiliesNow: (row['insideEcFamiliesNow'] ?? 0).toString(),
          personsActualCum: (row['personsActualCum'] ?? 0).toString(),
          personsActualNow: (row['personsActualNow'] ?? 0).toString(),
          personsEstimateCum: '',
          personsEstimateNow: '',
          color: Colors.white,
        ),
      );

      lastBarangay = barangay;
    }

    return rows;
  }

  Widget _buildReportTable() {
    _computeDynamicColumnWidths();

    const green = Color(0xFFC6D9B4);
    const blue = Color(0xFFD9E2F3);
    const gray1 = Color(0xFFB7B7B7);
    const gray2 = Color(0xFFD0D0D0);
    const gray3 = Color(0xFFF2F2F2);

    const double h1 = 18;
    const double h2 = 18;
    const double h3 = 18;
    const double h4 = 18;
    const double h5 = 18;

    const double totalHeaderHeight = h1 + h2 + h3 + h4 + h5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cell(
                text: 'REGION / PROVINCE /\nMUNICIPALITY',
                width: colRegion,
                height: totalHeaderHeight,
                bold: true,
                color: blue,
                fontSize: 13,
                textAlign: TextAlign.center,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),

              Column(
                children: [
                  _cell(
                    text: 'NUMBER OF AFFECTED',
                    width:
                        colBarangayName +
                        colBarangayCount +
                        colFamilies +
                        colPersons +
                        col4PsFamilies,
                    height: h1,
                    bold: true,
                    color: green,
                    fontSize: 14,
                    textAlign: TextAlign.center,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          _cell(
                            text: '',
                            width: colBarangayName + colBarangayCount,
                            height: h2,
                            bold: true,
                            color: green,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          _cell(
                            text: '',
                            width: colBarangayName + colBarangayCount,
                            height: h3,
                            bold: true,
                            color: green,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          _cell(
                            text: 'Barangays',
                            width: colBarangayName + colBarangayCount,
                            height: h4,
                            bold: true,
                            color: green,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          Row(
                            children: [
                              _cell(
                                text: 'Name',
                                width: colBarangayName,
                                height: h5,
                                bold: true,
                                color: green,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                              _cell(
                                text: 'Count',
                                width: colBarangayCount,
                                height: h5,
                                bold: true,
                                color: green,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                      _cell(
                        text: 'Families',
                        width: colFamilies,
                        height: h2 + h3 + h4 + h5,
                        bold: true,
                        color: green,
                        fontSize: 12,
                        textAlign: TextAlign.center,
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                      ),
                      _cell(
                        text: 'Persons',
                        width: colPersons,
                        height: h2 + h3 + h4 + h5,
                        bold: true,
                        color: green,
                        fontSize: 12,
                        textAlign: TextAlign.center,
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                      ),
                      _cell(
                        text: '4Ps Families',
                        width: col4PsFamilies,
                        height: h2 + h3 + h4 + h5,
                        bold: true,
                        color: green,
                        fontSize: 12,
                        textAlign: TextAlign.center,
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),

              Column(
                children: [
                  _cell(
                    text: 'DISPLACEMENT DATA',
                    width:
                        colEvacuationCenterName +
                        colAddress +
                        colOriginBrgyName +
                        colOriginBrgyCount +
                        colInsideEcFamiliesCum +
                        colInsideEcFamiliesNow +
                        colPersonsActualCum +
                        colPersonsActualNow +
                        colPersonsEstimateCum +
                        colPersonsEstimateNow,
                    height: h1,
                    bold: true,
                    color: green,
                    fontSize: 14,
                    textAlign: TextAlign.center,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                  ),
                  Row(
                    children: [
                      _cell(
                        text: 'NAME OF EVACUATION\nCENTER',
                        width: colEvacuationCenterName,
                        height: h2 + h3 + h4 + h5,
                        bold: true,
                        color: green,
                        fontSize: 12,
                        textAlign: TextAlign.center,
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                      ),
                      _cell(
                        text: 'ADDRESS',
                        width: colAddress,
                        height: h2 + h3 + h4 + h5,
                        bold: true,
                        color: green,
                        fontSize: 12,
                        textAlign: TextAlign.center,
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                      ),
                      Column(
                        children: [
                          _cell(
                            text: 'Origin of IDPs',
                            width: colOriginBrgyName + colOriginBrgyCount,
                            height: h2 + h3 + h4,
                            bold: true,
                            color: green,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          Row(
                            children: [
                              _cell(
                                text: 'Brgy Name',
                                width: colOriginBrgyName,
                                height: h5,
                                bold: true,
                                color: green,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                              _cell(
                                text: 'Brgy Count',
                                width: colOriginBrgyCount,
                                height: h5,
                                bold: true,
                                color: green,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          _cell(
                            text: 'NUMBER OF DISPLACED',
                            width:
                                colInsideEcFamiliesCum +
                                colInsideEcFamiliesNow +
                                colPersonsActualCum +
                                colPersonsActualNow +
                                colPersonsEstimateCum +
                                colPersonsEstimateNow,
                            height: h2,
                            bold: true,
                            color: green,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          _cell(
                            text: 'INSIDE ECs',
                            width:
                                colInsideEcFamiliesCum +
                                colInsideEcFamiliesNow +
                                colPersonsActualCum +
                                colPersonsActualNow +
                                colPersonsEstimateCum +
                                colPersonsEstimateNow,
                            height: h3,
                            bold: true,
                            color: green,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          Row(
                            children: [
                              Column(
                                children: [
                                  _cell(
                                    text: 'Families',
                                    width:
                                        colInsideEcFamiliesCum +
                                        colInsideEcFamiliesNow,
                                    height: h4,
                                    bold: true,
                                    color: green,
                                    fontSize: 12,
                                    textAlign: TextAlign.center,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                  ),
                                  Row(
                                    children: [
                                      _cell(
                                        text: 'CUM',
                                        width: colInsideEcFamiliesCum,
                                        height: h5,
                                        bold: true,
                                        color: green,
                                        fontSize: 12,
                                        textAlign: TextAlign.center,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                      ),
                                      _cell(
                                        text: 'NOW',
                                        width: colInsideEcFamiliesNow,
                                        height: h5,
                                        bold: true,
                                        color: green,
                                        fontSize: 12,
                                        textAlign: TextAlign.center,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  _cell(
                                    text: 'Persons (Actual)',
                                    width:
                                        colPersonsActualCum +
                                        colPersonsActualNow,
                                    height: h4,
                                    bold: true,
                                    color: green,
                                    fontSize: 12,
                                    textAlign: TextAlign.center,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                  ),
                                  Row(
                                    children: [
                                      _cell(
                                        text: 'CUM',
                                        width: colPersonsActualCum,
                                        height: h5,
                                        bold: true,
                                        color: green,
                                        fontSize: 12,
                                        textAlign: TextAlign.center,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                      ),
                                      _cell(
                                        text: 'NOW',
                                        width: colPersonsActualNow,
                                        height: h5,
                                        bold: true,
                                        color: green,
                                        fontSize: 12,
                                        textAlign: TextAlign.center,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  _cell(
                                    text: 'Persons (Estimate)',
                                    width:
                                        colPersonsEstimateCum +
                                        colPersonsEstimateNow,
                                    height: h4,
                                    bold: true,
                                    color: green,
                                    fontSize: 12,
                                    textAlign: TextAlign.center,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                  ),
                                  Row(
                                    children: [
                                      _cell(
                                        text: 'CUM',
                                        width: colPersonsEstimateCum,
                                        height: h5,
                                        bold: true,
                                        color: green,
                                        fontSize: 12,
                                        textAlign: TextAlign.center,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                      ),
                                      _cell(
                                        text: 'NOW',
                                        width: colPersonsEstimateNow,
                                        height: h5,
                                        bold: true,
                                        color: green,
                                        fontSize: 12,
                                        textAlign: TextAlign.center,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          _buildRow(
            region: 'GRAND TOTAL',
            barangayName: '',
            barangayCount: '',
            families: '',
            persons: '',
            fourPsFamilies: '',
            evacuationCenterName: '',
            address: '',
            originBrgyName: '',
            originBrgyCount: '',
            insideEcFamiliesCum: '',
            insideEcFamiliesNow: '',
            personsActualCum: '',
            personsActualNow: '',
            personsEstimateCum: '',
            personsEstimateNow: '',
            bold: true,
            color: gray1,
          ),
          _buildRow(
            region: 'Ilocos Sur',
            barangayName: '',
            barangayCount: '',
            families: '',
            persons: '',
            fourPsFamilies: '',
            evacuationCenterName: '',
            address: '',
            originBrgyName: '',
            originBrgyCount: '',
            insideEcFamiliesCum: '',
            insideEcFamiliesNow: '',
            personsActualCum: '',
            personsActualNow: '',
            personsEstimateCum: '',
            personsEstimateNow: '',
            bold: true,
            color: gray2,
          ),
          _buildRow(
            region: 'Province',
            barangayName: '',
            barangayCount: '',
            families: '',
            persons: '',
            fourPsFamilies: '',
            evacuationCenterName: '',
            address: '',
            originBrgyName: '',
            originBrgyCount: '',
            insideEcFamiliesCum: '',
            insideEcFamiliesNow: '',
            personsActualCum: '',
            personsActualNow: '',
            personsEstimateCum: '',
            personsEstimateNow: '',
            bold: true,
            color: gray3,
          ),
          _buildRow(
            region: 'Santa',
            barangayName: '',
            barangayCount: '',
            families: '',
            persons: '',
            fourPsFamilies: '',
            evacuationCenterName: '',
            address: '',
            originBrgyName: '',
            originBrgyCount: '',
            insideEcFamiliesCum: '',
            insideEcFamiliesNow: '',
            personsActualCum: '',
            personsActualNow: '',
            personsEstimateCum: '',
            personsEstimateNow: '',
            italicRegion: true,
            color: Colors.white,
          ),
          ..._buildBarangayRows(),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: isDownloading ? null : _downloadExcel,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D743D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        icon: isDownloading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download),
        label: Text(
          isDownloading ? 'Downloading...' : 'Download Excel',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E9E9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D743D),
          centerTitle: true,
          title: Text(
            "Preview Report",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error: $errorMessage',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                  ),
                ),
              )
            : Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.depth == 1,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 8, 6, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDownloadButton(),
                            const SizedBox(height: 8),
                            Text(
                              "Republic of the Philippines",
                              style: GoogleFonts.arimo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Province of Ilocos Sur",
                              style: GoogleFonts.arimo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Municipality of Santa",
                              style: GoogleFonts.arimo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start Date: ${_formatDate(widget.startDate)}',
                              style: GoogleFonts.arimo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'End Date & Time: ${_formatDateTime(widget.endDateTime)}',
                              style: GoogleFonts.arimo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildReportTable(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
