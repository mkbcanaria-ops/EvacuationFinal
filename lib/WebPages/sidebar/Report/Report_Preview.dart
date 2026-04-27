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
  late double colOutsideEcFamiliesCum;
  late double colOutsideEcFamiliesNow;
  late double colOutsideEcPersonsCum;
  late double colOutsideEcPersonsNow;
  late double colTotalDisplacedFamiliesCum;
  late double colTotalDisplacedFamiliesNow;
  late double colTotalDisplacedPersonsCum;
  late double colTotalDisplacedPersonsNow;
  late double colInfantMaleNow;
  late double colInfantFemaleNow;
  late double colToddlerMaleNow;
  late double colToddlerFemaleNow;
  late double colPreschoolMaleNow;
  late double colPreschoolFemaleNow;
  late double colSchoolAgeMaleNow;
  late double colSchoolAgeFemaleNow;
  late double colTeenageMaleNow;
  late double colTeenageFemaleNow;
  late double colAdultMaleNow;
  late double colAdultFemaleNow;
  late double colSeniorMaleNow;
  late double colSeniorFemaleNow;
  late double colTotalInsideMaleNow;
  late double colTotalInsideFemaleNow;

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
      final splitTime = end.subtract(const Duration(hours: 3));

      DateTime? _parseCustomDateTime(dynamic value) {
        if (value == null) return null;

        final raw = value.toString().trim();
        if (raw.isEmpty) return null;

        try {
          return DateTime.parse(raw);
        } catch (_) {}

        try {
          final parts = raw.split('|');
          if (parts.length != 2) return null;

          final datePart = parts[0].trim();
          final timePart = parts[1].trim();

          final datePieces = datePart.split(',');
          if (datePieces.length != 2) return null;

          final monthDayPart = datePieces[0].trim();
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

      DateTime? _parseBirthDate(dynamic value) {
        if (value == null) return null;

        final raw = value.toString().trim();
        if (raw.isEmpty) return null;

        try {
          return DateTime.parse(raw);
        } catch (_) {}

        final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();

        final isoMatch = RegExp(
          r'^(\d{4})-(\d{1,2})-(\d{1,2})$',
        ).firstMatch(cleaned);
        if (isoMatch != null) {
          final year = int.tryParse(isoMatch.group(1)!);
          final month = int.tryParse(isoMatch.group(2)!);
          final day = int.tryParse(isoMatch.group(3)!);

          if (year != null && month != null && day != null) {
            return DateTime(year, month, day);
          }
        }

        final slashMatch = RegExp(
          r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
        ).firstMatch(cleaned);
        if (slashMatch != null) {
          final month = int.tryParse(slashMatch.group(1)!);
          final day = int.tryParse(slashMatch.group(2)!);
          final year = int.tryParse(slashMatch.group(3)!);

          if (year != null && month != null && day != null) {
            return DateTime(year, month, day);
          }
        }

        final textMatch = RegExp(
          r'^([A-Za-z]+),?\s+(\d{1,2}),?\s+(\d{4})$',
        ).firstMatch(cleaned);

        if (textMatch != null) {
          final monthRaw = textMatch.group(1)!.toLowerCase();
          final day = int.tryParse(textMatch.group(2)!);
          final year = int.tryParse(textMatch.group(3)!);

          const monthMap = {
            'jan': 1,
            'january': 1,
            'feb': 2,
            'february': 2,
            'mar': 3,
            'march': 3,
            'apr': 4,
            'april': 4,
            'may': 5,
            'jun': 6,
            'june': 6,
            'jul': 7,
            'july': 7,
            'aug': 8,
            'august': 8,
            'sep': 9,
            'sept': 9,
            'september': 9,
            'oct': 10,
            'october': 10,
            'nov': 11,
            'november': 11,
            'dec': 12,
            'december': 12,
          };

          final month = monthMap[monthRaw];
          if (month != null && day != null && year != null) {
            return DateTime(year, month, day);
          }
        }

        return null;
      }

      int _monthDifference(DateTime birthDate, DateTime referenceDate) {
        int months =
            (referenceDate.year - birthDate.year) * 12 +
            (referenceDate.month - birthDate.month);

        if (referenceDate.day < birthDate.day) {
          months--;
        }

        return months;
      }

      String _normalizeGender(dynamic value) {
        final raw = (value ?? '').toString().trim().toLowerCase();
        if (raw == 'm' || raw == 'male') return 'male';
        if (raw == 'f' || raw == 'female') return 'female';
        return '';
      }

      String _normalizeBarangay(dynamic value) {
        return (value ?? '').toString().trim().toLowerCase();
      }

      String _normalizeSite(dynamic value) {
        return (value ?? '').toString().trim().toLowerCase();
      }

      bool _isTrue4Ps(dynamic value) {
        final raw = (value ?? '').toString().trim().toLowerCase();
        return value == true || raw == 'true' || raw == '1' || raw == 'yes';
      }

      final evacAResponse = await supabase
          .from('Evacuation_A')
          .select(
            'Registration_ID, Barangay, Site, Time_Deployed, 4Ps_Families, Date_of_Birth, Gender',
          );

      final evacBResponse = await supabase
          .from('Evacuation_B')
          .select(
            'Registration_ID, Barangay, Site, Time_Deployed, 4Ps_Families, Date_of_Birth, Gender',
          );

      final dischargeResponse = await supabase
          .from('Discharge_Resident')
          .select(
            'Registration_ID, Barangay, Site, Time_Discharge, 4Ps_Families, BirthDate, Gender',
          );

      final evacARows = List<Map<String, dynamic>>.from(evacAResponse);
      final evacBRows = List<Map<String, dynamic>>.from(evacBResponse);
      final dischargeRows = List<Map<String, dynamic>>.from(dischargeResponse);

      final List<Map<String, dynamic>> combinedRows = [];

      for (final row in evacARows) {
        combinedRows.add({
          ...row,
          '_sourceTable': 'Evacuation_A',
          '_eventTime': _parseCustomDateTime(row['Time_Deployed']),
          '_birthDateValue': row['Date_of_Birth'],
        });
      }

      for (final row in evacBRows) {
        combinedRows.add({
          ...row,
          '_sourceTable': 'Evacuation_B',
          '_eventTime': _parseCustomDateTime(row['Time_Deployed']),
          '_birthDateValue': row['Date_of_Birth'],
        });
      }

      for (final row in dischargeRows) {
        combinedRows.add({
          ...row,
          '_sourceTable': 'Discharge_Resident',
          '_eventTime': _parseCustomDateTime(row['Time_Discharge']),
          '_birthDateValue': row['BirthDate'],
        });
      }

      final filteredRows = combinedRows.where((row) {
        final eventTime = row['_eventTime'] as DateTime?;
        if (eventTime == null) return false;
        return !eventTime.isBefore(start) && !eventTime.isAfter(end);
      }).toList();

      final Map<String, String> uniqueBarangayDisplayMap = {};
      final Map<String, Set<String>> familyIdsByBarangay = {};
      final Map<String, int> personsByBarangay = {};
      final Map<String, Set<String>> fourPsFamilyIdsByBarangay = {};

      final Map<String, Map<String, dynamic>> groupedByBarangayAndSite = {};

      for (final row in filteredRows) {
        final registrationId = (row['Registration_ID'] ?? '').toString().trim();
        final barangay = (row['Barangay'] ?? '').toString().trim();
        final site = (row['Site'] ?? '').toString().trim();
        final barangayKey = _normalizeBarangay(barangay);
        final siteKey = _normalizeSite(site);

        if (registrationId.isEmpty || barangayKey.isEmpty) continue;

        uniqueBarangayDisplayMap.putIfAbsent(barangayKey, () => barangay);

        familyIdsByBarangay.putIfAbsent(barangayKey, () => <String>{});
        familyIdsByBarangay[barangayKey]!.add(registrationId);

        personsByBarangay[barangayKey] =
            (personsByBarangay[barangayKey] ?? 0) + 1;

        if (_isTrue4Ps(row['4Ps_Families'])) {
          fourPsFamilyIdsByBarangay.putIfAbsent(barangayKey, () => <String>{});
          fourPsFamilyIdsByBarangay[barangayKey]!.add(registrationId);
        }

        final groupKey = '$barangayKey|||$siteKey';

        groupedByBarangayAndSite.putIfAbsent(groupKey, () {
          return {
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
            'personsEstimateCum': 0,
            'personsEstimateNow': 0,
            'outsideEcFamiliesCum': 0,
            'outsideEcFamiliesNow': 0,
            'outsideEcPersonsCum': 0,
            'outsideEcPersonsNow': 0,
            'totalDisplacedFamiliesCum': 0,
            'totalDisplacedFamiliesNow': 0,
            'totalDisplacedPersonsCum': 0,
            'totalDisplacedPersonsNow': 0,
            'infantMaleNow': 0,
            'infantFemaleNow': 0,
            'toddlerMaleNow': 0,
            'toddlerFemaleNow': 0,
            'preschoolMaleNow': 0,
            'preschoolFemaleNow': 0,
            'schoolAgeMaleNow': 0,
            'schoolAgeFemaleNow': 0,
            'teenageMaleNow': 0,
            'teenageFemaleNow': 0,
            'adultMaleNow': 0,
            'adultFemaleNow': 0,
            'seniorMaleNow': 0,
            'seniorFemaleNow': 0,
            'totalInsideMaleNow': 0,
            'totalInsideFemaleNow': 0,
            '_familyIds': <String>{},
            '_fourPsFamilyIds': <String>{},
            '_familyIdsCum': <String>{},
            '_familyIdsNow': <String>{},
          };
        });

        final group = groupedByBarangayAndSite[groupKey]!;
        final familyIdSet = group['_familyIds'] as Set<String>;
        final fourPsFamilyIdSet = group['_fourPsFamilyIds'] as Set<String>;
        final familyIdSetCum = group['_familyIdsCum'] as Set<String>;
        final familyIdSetNow = group['_familyIdsNow'] as Set<String>;
        final eventTime = row['_eventTime'] as DateTime?;

        if (!familyIdSet.contains(registrationId)) {
          familyIdSet.add(registrationId);
          group['families'] = (group['families'] as int) + 1;
        }

        group['persons'] = (group['persons'] as int) + 1;

        if (_isTrue4Ps(row['4Ps_Families']) &&
            !fourPsFamilyIdSet.contains(registrationId)) {
          fourPsFamilyIdSet.add(registrationId);
          group['fourPsFamilies'] = (group['fourPsFamilies'] as int) + 1;
        }

        if (eventTime != null) {
          final isWithinCumRange =
              !eventTime.isBefore(start) && !eventTime.isAfter(splitTime);
          final isWithinNowRange =
              eventTime.isAfter(splitTime) && !eventTime.isAfter(end);

          if (isWithinCumRange) {
            if (!familyIdSetCum.contains(registrationId)) {
              familyIdSetCum.add(registrationId);
              group['insideEcFamiliesCum'] =
                  (group['insideEcFamiliesCum'] as int) + 1;
              group['totalDisplacedFamiliesCum'] =
                  (group['totalDisplacedFamiliesCum'] as int) + 1;
            }
            group['personsActualCum'] = (group['personsActualCum'] as int) + 1;
            group['totalDisplacedPersonsCum'] =
                (group['totalDisplacedPersonsCum'] as int) + 1;
          }

          if (isWithinNowRange) {
            if (!familyIdSetNow.contains(registrationId)) {
              familyIdSetNow.add(registrationId);
              group['insideEcFamiliesNow'] =
                  (group['insideEcFamiliesNow'] as int) + 1;
              group['totalDisplacedFamiliesNow'] =
                  (group['totalDisplacedFamiliesNow'] as int) + 1;
            }
            group['personsActualNow'] = (group['personsActualNow'] as int) + 1;
            group['totalDisplacedPersonsNow'] =
                (group['totalDisplacedPersonsNow'] as int) + 1;
          }
        }

        final gender = _normalizeGender(row['Gender']);
        final birthDate = _parseBirthDate(row['_birthDateValue']);

        if (gender == 'male') {
          group['totalInsideMaleNow'] =
              (group['totalInsideMaleNow'] as int) + 1;
        } else if (gender == 'female') {
          group['totalInsideFemaleNow'] =
              (group['totalInsideFemaleNow'] as int) + 1;
        }

        if (birthDate != null && gender.isNotEmpty) {
          final ageInMonths = _monthDifference(birthDate, end);

          if (ageInMonths >= 0 && ageInMonths <= 11) {
            if (gender == 'male') {
              group['infantMaleNow'] = (group['infantMaleNow'] as int) + 1;
            } else {
              group['infantFemaleNow'] = (group['infantFemaleNow'] as int) + 1;
            }
          }

          if (ageInMonths >= 12 && ageInMonths <= 47) {
            if (gender == 'male') {
              group['toddlerMaleNow'] = (group['toddlerMaleNow'] as int) + 1;
            } else {
              group['toddlerFemaleNow'] =
                  (group['toddlerFemaleNow'] as int) + 1;
            }
          }

          if (ageInMonths >= 48 && ageInMonths <= 71) {
            if (gender == 'male') {
              group['preschoolMaleNow'] =
                  (group['preschoolMaleNow'] as int) + 1;
            } else {
              group['preschoolFemaleNow'] =
                  (group['preschoolFemaleNow'] as int) + 1;
            }
          }

          if (ageInMonths >= 72 && ageInMonths <= 155) {
            if (gender == 'male') {
              group['schoolAgeMaleNow'] =
                  (group['schoolAgeMaleNow'] as int) + 1;
            } else {
              group['schoolAgeFemaleNow'] =
                  (group['schoolAgeFemaleNow'] as int) + 1;
            }
          }

          if (ageInMonths >= 156 && ageInMonths <= 239) {
            if (gender == 'male') {
              group['teenageMaleNow'] = (group['teenageMaleNow'] as int) + 1;
            } else {
              group['teenageFemaleNow'] =
                  (group['teenageFemaleNow'] as int) + 1;
            }
          }

          if (ageInMonths >= 240 && ageInMonths <= 719) {
            if (gender == 'male') {
              group['adultMaleNow'] = (group['adultMaleNow'] as int) + 1;
            } else {
              group['adultFemaleNow'] = (group['adultFemaleNow'] as int) + 1;
            }
          }

          if (ageInMonths >= 720) {
            if (gender == 'male') {
              group['seniorMaleNow'] = (group['seniorMaleNow'] as int) + 1;
            } else {
              group['seniorFemaleNow'] = (group['seniorFemaleNow'] as int) + 1;
            }
          }
        }
      }

      final Map<String, int> totalBarangayCounts = {};
      final Map<String, int> totalFamilies = {};
      final Map<String, int> totalPersons = {};
      final Map<String, int> totalFourPsFamilies = {};

      for (final barangayKey in uniqueBarangayDisplayMap.keys) {
        final barangayDisplay = uniqueBarangayDisplayMap[barangayKey]!;
        totalBarangayCounts[barangayDisplay] = 1;
        totalFamilies[barangayDisplay] =
            familyIdsByBarangay[barangayKey]?.length ?? 0;
        totalPersons[barangayDisplay] = personsByBarangay[barangayKey] ?? 0;
        totalFourPsFamilies[barangayDisplay] =
            fourPsFamilyIdsByBarangay[barangayKey]?.length ?? 0;
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

      String previousBarangay = '';
      for (final row in groupedRows) {
        final currentBarangay = (row['barangay'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (currentBarangay != previousBarangay) {
          row['count'] = 1;
          previousBarangay = currentBarangay;
        } else {
          row['count'] = '';
        }

        row.remove('_familyIds');
        row.remove('_fourPsFamilyIds');
        row.remove('_familyIdsCum');
        row.remove('_familyIdsNow');
      }

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
    if (evacuationCenterRows.isEmpty) {
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

      void setCellRC(
        int row,
        int col,
        xls.CellValue value,
        xls.CellStyle style,
      ) {
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = value;
        cell.cellStyle = style;
      }

      void mergeRC(int startRow, int startCol, int endRow, int endCol) {
        sheet.merge(
          xls.CellIndex.indexByColumnRow(
            columnIndex: startCol,
            rowIndex: startRow,
          ),
          xls.CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: endRow),
        );
      }

      final thickBorder = xls.Border(
        borderStyle: xls.BorderStyle.Thick,
        borderColorHex: xls.ExcelColor.fromHexString('#000000'),
      );

      final mediumBorder = xls.Border(
        borderStyle: xls.BorderStyle.Medium,
        borderColorHex: xls.ExcelColor.fromHexString('#000000'),
      );

      xls.CellStyle style({
        bool bold = false,
        bool italic = false,
        int fontSize = 11,
        String bg = '#FFFFFF',
        xls.HorizontalAlign hAlign = xls.HorizontalAlign.Center,
        xls.VerticalAlign vAlign = xls.VerticalAlign.Center,
        bool wrap = true,
        bool thick = false,
      }) {
        return xls.CellStyle(
          bold: bold,
          italic: italic,
          fontSize: fontSize,
          fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
          horizontalAlign: hAlign,
          verticalAlign: vAlign,
          backgroundColorHex: xls.ExcelColor.fromHexString(bg),
          textWrapping: wrap
              ? xls.TextWrapping.WrapText
              : xls.TextWrapping.Clip,
          leftBorder: thick ? thickBorder : mediumBorder,
          rightBorder: thick ? thickBorder : mediumBorder,
          topBorder: thick ? thickBorder : mediumBorder,
          bottomBorder: thick ? thickBorder : mediumBorder,
        );
      }

      final titleStyle = xls.CellStyle(
        bold: true,
        fontSize: 12,
        fontFamily: xls.getFontFamily(xls.FontFamily.Arial),
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
      );

      final blueHeaderStyle = style(
        bold: true,
        fontSize: 11,
        bg: '#D9E2F3',
        thick: true,
        wrap: true,
      );

      final greenHeaderStyle = style(
        bold: true,
        fontSize: 11,
        bg: '#C6D9B4',
        thick: true,
        wrap: true,
      );

      final yellowHeaderStyle = style(
        bold: true,
        fontSize: 11,
        bg: '#E1C761',
        thick: true,
        wrap: true,
      );

      final beigeHeaderStyle = style(
        bold: true,
        fontSize: 11,
        bg: '#DDD5B3',
        thick: true,
        wrap: true,
      );

      final gray1LeftStyle = style(
        bold: true,
        bg: '#B7B7B7',
        hAlign: xls.HorizontalAlign.Left,
      );

      final gray1NumberStyle = style(
        bold: true,
        bg: '#B7B7B7',
        hAlign: xls.HorizontalAlign.Right,
      );

      final gray3TextStyle = style(
        italic: true,
        bg: '#FFFFFF',
        hAlign: xls.HorizontalAlign.Left,
      );

      final gray3NumberStyle = style(
        bg: '#FFFFFF',
        hAlign: xls.HorizontalAlign.Right,
      );

      final bodyTextStyle = style(
        bg: '#FFFFFF',
        hAlign: xls.HorizontalAlign.Left,
        wrap: true,
      );

      final bodyNumberStyle = style(
        bg: '#FFFFFF',
        hAlign: xls.HorizontalAlign.Right,
        wrap: true,
      );

      // Increased all widths by 10%
      final widths = <int, double>{
        0: 35.2,
        1: 30.8,
        2: 13.2,
        3: 13.2,
        4: 13.2,
        5: 13.2,
        6: 41.8,
        7: 26.4,
        8: 24.2,
        9: 19.8,
        10: 14.3,
        11: 11.0,
        12: 14.3,
        13: 11.0,
        14: 14.3,
        15: 11.0,
        16: 14.3,
        17: 11.0,
        18: 14.3,
        19: 11.0,
        20: 12.1,
        21: 12.1,
        22: 12.1,
        23: 12.1,
        24: 14.3,
        25: 14.3,
        26: 14.3,
        27: 14.3,
        28: 15.4,
        29: 15.4,
        30: 15.4,
        31: 15.4,
        32: 15.4,
        33: 15.4,
        34: 15.4,
        35: 15.4,
        36: 17.6,
        37: 17.6,
        38: 19.8,
        39: 19.8,
      };

      widths.forEach((col, width) {
        sheet.setColumnWidth(col, width);
      });

      for (int r = 0; r < 200; r++) {
        sheet.setRowHeight(r, 24);
      }

      sheet.setRowHeight(3, 34);
      sheet.setRowHeight(4, 24);
      sheet.setRowHeight(5, 22);
      sheet.setRowHeight(6, 26);

      final int totalBarangayAffected = barangayCounts.length;
      final int totalFamilies = familyCounts.values.fold(0, (a, b) => a + b);
      final int totalPersons = personCounts.values.fold(0, (a, b) => a + b);
      final int total4PsFamilies = fourPsFamilyCounts.values.fold(
        0,
        (a, b) => a + b,
      );

      final int totalInsideEcFamiliesCum = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['insideEcFamiliesCum'] ?? 0) as int),
      );
      final int totalInsideEcFamiliesNow = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['insideEcFamiliesNow'] ?? 0) as int),
      );
      final int totalPersonsActualCum = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['personsActualCum'] ?? 0) as int),
      );
      final int totalPersonsActualNow = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['personsActualNow'] ?? 0) as int),
      );

      final int grandInfantMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['infantMaleNow'] ?? 0) as int),
      );
      final int grandInfantFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['infantFemaleNow'] ?? 0) as int),
      );
      final int grandToddlerMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['toddlerMaleNow'] ?? 0) as int),
      );
      final int grandToddlerFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['toddlerFemaleNow'] ?? 0) as int),
      );
      final int grandPreschoolMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['preschoolMaleNow'] ?? 0) as int),
      );
      final int grandPreschoolFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['preschoolFemaleNow'] ?? 0) as int),
      );
      final int grandSchoolAgeMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['schoolAgeMaleNow'] ?? 0) as int),
      );
      final int grandSchoolAgeFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['schoolAgeFemaleNow'] ?? 0) as int),
      );
      final int grandTeenageMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['teenageMaleNow'] ?? 0) as int),
      );
      final int grandTeenageFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['teenageFemaleNow'] ?? 0) as int),
      );
      final int grandAdultMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['adultMaleNow'] ?? 0) as int),
      );
      final int grandAdultFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['adultFemaleNow'] ?? 0) as int),
      );
      final int grandSeniorMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['seniorMaleNow'] ?? 0) as int),
      );
      final int grandSeniorFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['seniorFemaleNow'] ?? 0) as int),
      );
      final int grandTotalInsideMale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['totalInsideMaleNow'] ?? 0) as int),
      );
      final int grandTotalInsideFemale = evacuationCenterRows.fold(
        0,
        (sum, row) => sum + ((row['totalInsideFemaleNow'] ?? 0) as int),
      );

      setCellRC(
        0,
        0,
        xls.TextCellValue('Republic of the Philippines'),
        titleStyle,
      );
      setCellRC(1, 0, xls.TextCellValue('Province of Ilocos Sur'), titleStyle);

      mergeRC(3, 0, 6, 0);

      mergeRC(3, 1, 3, 5);
      mergeRC(4, 1, 5, 2);
      mergeRC(6, 1, 6, 1);
      mergeRC(6, 2, 6, 2);
      mergeRC(4, 3, 6, 3);
      mergeRC(4, 4, 6, 4);
      mergeRC(4, 5, 6, 5);

      mergeRC(3, 6, 3, 19);
      mergeRC(4, 6, 6, 6);
      mergeRC(4, 7, 6, 7);
      mergeRC(4, 8, 5, 9);
      mergeRC(6, 8, 6, 8);
      mergeRC(6, 9, 6, 9);

      mergeRC(4, 10, 4, 19);
      mergeRC(5, 10, 5, 15);
      mergeRC(5, 16, 5, 19);

      for (int c = 10; c <= 19; c++) {
        mergeRC(6, c, 6, c);
      }

      mergeRC(3, 20, 3, 23);
      mergeRC(4, 20, 4, 21);
      mergeRC(4, 22, 4, 23);
      mergeRC(5, 20, 5, 21);
      mergeRC(5, 22, 5, 23);

      mergeRC(3, 24, 3, 39);
      for (int c = 24; c <= 39; c += 2) {
        mergeRC(4, c, 4, c + 1);
      }

      for (int r = 3; r <= 6; r++) {
        setCellRC(r, 0, xls.TextCellValue(''), blueHeaderStyle);
      }
      for (int r = 3; r <= 6; r++) {
        for (int c = 1; c <= 19; c++) {
          setCellRC(r, c, xls.TextCellValue(''), greenHeaderStyle);
        }
      }
      for (int r = 3; r <= 6; r++) {
        for (int c = 20; c <= 23; c++) {
          setCellRC(r, c, xls.TextCellValue(''), yellowHeaderStyle);
        }
      }
      for (int r = 3; r <= 6; r++) {
        for (int c = 24; c <= 39; c++) {
          setCellRC(r, c, xls.TextCellValue(''), beigeHeaderStyle);
        }
      }

      setCellRC(
        3,
        0,
        xls.TextCellValue('REGION / PROVINCE /'),
        blueHeaderStyle,
      );

      setCellRC(
        3,
        1,
        xls.TextCellValue('NUMBER OF AFFECTED'),
        greenHeaderStyle,
      );
      setCellRC(4, 1, xls.TextCellValue('Barangays'), greenHeaderStyle);
      setCellRC(6, 1, xls.TextCellValue('Name'), greenHeaderStyle);
      setCellRC(6, 2, xls.TextCellValue('Count'), greenHeaderStyle);
      setCellRC(4, 3, xls.TextCellValue('Families'), greenHeaderStyle);
      setCellRC(4, 4, xls.TextCellValue('Persons'), greenHeaderStyle);
      setCellRC(4, 5, xls.TextCellValue('4Ps\nFamilies'), greenHeaderStyle);

      setCellRC(3, 6, xls.TextCellValue('DISPLACEMENT DATA'), greenHeaderStyle);
      setCellRC(
        4,
        6,
        xls.TextCellValue('NAME OF EVACUATION'),
        greenHeaderStyle,
      );
      setCellRC(4, 7, xls.TextCellValue('ADDRESS'), greenHeaderStyle);
      setCellRC(4, 8, xls.TextCellValue('Origin of IDPs'), greenHeaderStyle);
      setCellRC(6, 8, xls.TextCellValue('Brgy Name'), greenHeaderStyle);
      setCellRC(6, 9, xls.TextCellValue('Brgy Count'), greenHeaderStyle);

      setCellRC(
        4,
        10,
        xls.TextCellValue('NUMBER OF DISPLACED'),
        greenHeaderStyle,
      );
      setCellRC(5, 10, xls.TextCellValue('INSIDE ECs'), greenHeaderStyle);
      setCellRC(5, 16, xls.TextCellValue('OUTSIDE ECs'), greenHeaderStyle);

      setCellRC(6, 10, xls.TextCellValue('Families'), greenHeaderStyle);
      setCellRC(6, 11, xls.TextCellValue('NOW'), greenHeaderStyle);
      setCellRC(6, 12, xls.TextCellValue('Persons'), greenHeaderStyle);
      setCellRC(6, 13, xls.TextCellValue('NOW'), greenHeaderStyle);
      setCellRC(6, 14, xls.TextCellValue('Estimate'), greenHeaderStyle);
      setCellRC(6, 15, xls.TextCellValue('NOW'), greenHeaderStyle);

      setCellRC(6, 16, xls.TextCellValue('Families'), greenHeaderStyle);
      setCellRC(6, 17, xls.TextCellValue('NOW'), greenHeaderStyle);
      setCellRC(6, 18, xls.TextCellValue('Persons'), greenHeaderStyle);
      setCellRC(6, 19, xls.TextCellValue('NOW'), greenHeaderStyle);

      setCellRC(3, 20, xls.TextCellValue('TOTAL DISPLACED'), yellowHeaderStyle);
      setCellRC(4, 20, xls.TextCellValue('Families'), yellowHeaderStyle);
      setCellRC(4, 22, xls.TextCellValue('Persons'), yellowHeaderStyle);
      setCellRC(5, 20, xls.TextCellValue('Total Families'), yellowHeaderStyle);
      setCellRC(5, 22, xls.TextCellValue('Total Persons'), yellowHeaderStyle);
      setCellRC(6, 20, xls.TextCellValue('CUM'), yellowHeaderStyle);
      setCellRC(6, 21, xls.TextCellValue('NOW'), yellowHeaderStyle);
      setCellRC(6, 22, xls.TextCellValue('CUM'), yellowHeaderStyle);
      setCellRC(6, 23, xls.TextCellValue('NOW'), yellowHeaderStyle);

      setCellRC(
        3,
        24,
        xls.TextCellValue('SEX & AGE DISTRIBUTION OF IDPS INSIDE ECS'),
        beigeHeaderStyle,
      );

      final ageTitles = <int, String>{
        24: 'INFANT >1 y/o (0-11mos)',
        26: 'TODDLERS 1-3 y/o',
        28: 'PRESCHOOLERS 4-5 y/o',
        30: 'SCHOOL AGE 6-12 y/o',
        32: 'TEENAGE 13-19 y/o',
        34: 'ADULT 20-59 y/o',
        36: 'SENIOR CITIZENS 60 and above',
        38: 'Total Number of IDPs Inside ECs',
      };

      ageTitles.forEach((col, title) {
        setCellRC(4, col, xls.TextCellValue(title), beigeHeaderStyle);
        setCellRC(5, col, xls.TextCellValue('Male'), beigeHeaderStyle);
        setCellRC(5, col + 1, xls.TextCellValue('Female'), beigeHeaderStyle);
        setCellRC(6, col, xls.TextCellValue('NOW'), beigeHeaderStyle);
        setCellRC(6, col + 1, xls.TextCellValue('NOW'), beigeHeaderStyle);
      });

      int rowIndex = 7;

      void fillRowBackground(
        int row,
        xls.CellStyle leftStyle,
        xls.CellStyle numberStyle,
      ) {
        for (int c = 0; c <= 39; c++) {
          setCellRC(
            row,
            c,
            xls.TextCellValue(''),
            c == 0 ? leftStyle : numberStyle,
          );
        }
      }

      fillRowBackground(rowIndex, gray1LeftStyle, gray1NumberStyle);
      setCellRC(rowIndex, 0, xls.TextCellValue('GRAND TOTAL'), gray1LeftStyle);
      setCellRC(
        rowIndex,
        2,
        xls.IntCellValue(totalBarangayAffected),
        gray1NumberStyle,
      );
      setCellRC(rowIndex, 3, xls.IntCellValue(totalFamilies), gray1NumberStyle);
      setCellRC(rowIndex, 4, xls.IntCellValue(totalPersons), gray1NumberStyle);
      setCellRC(
        rowIndex,
        5,
        xls.IntCellValue(total4PsFamilies),
        gray1NumberStyle,
      );

      setCellRC(
        rowIndex,
        10,
        xls.IntCellValue(totalInsideEcFamiliesCum),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        11,
        xls.IntCellValue(totalInsideEcFamiliesNow),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        12,
        xls.IntCellValue(totalPersonsActualCum),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        13,
        xls.IntCellValue(totalPersonsActualNow),
        gray1NumberStyle,
      );
      setCellRC(rowIndex, 14, xls.IntCellValue(0), gray1NumberStyle);
      setCellRC(rowIndex, 15, xls.IntCellValue(0), gray1NumberStyle);
      setCellRC(rowIndex, 16, xls.IntCellValue(0), gray1NumberStyle);
      setCellRC(rowIndex, 17, xls.IntCellValue(0), gray1NumberStyle);
      setCellRC(rowIndex, 18, xls.IntCellValue(0), gray1NumberStyle);
      setCellRC(rowIndex, 19, xls.IntCellValue(0), gray1NumberStyle);

      setCellRC(
        rowIndex,
        20,
        xls.IntCellValue(totalInsideEcFamiliesCum),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        21,
        xls.IntCellValue(totalInsideEcFamiliesNow),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        22,
        xls.IntCellValue(totalPersonsActualCum),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        23,
        xls.IntCellValue(totalPersonsActualNow),
        gray1NumberStyle,
      );

      setCellRC(
        rowIndex,
        24,
        xls.IntCellValue(grandInfantMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        25,
        xls.IntCellValue(grandInfantFemale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        26,
        xls.IntCellValue(grandToddlerMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        27,
        xls.IntCellValue(grandToddlerFemale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        28,
        xls.IntCellValue(grandPreschoolMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        29,
        xls.IntCellValue(grandPreschoolFemale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        30,
        xls.IntCellValue(grandSchoolAgeMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        31,
        xls.IntCellValue(grandSchoolAgeFemale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        32,
        xls.IntCellValue(grandTeenageMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        33,
        xls.IntCellValue(grandTeenageFemale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        34,
        xls.IntCellValue(grandAdultMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        35,
        xls.IntCellValue(grandAdultFemale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        36,
        xls.IntCellValue(grandSeniorMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        37,
        xls.IntCellValue(grandSeniorFemale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        38,
        xls.IntCellValue(grandTotalInsideMale),
        gray1NumberStyle,
      );
      setCellRC(
        rowIndex,
        39,
        xls.IntCellValue(grandTotalInsideFemale),
        gray1NumberStyle,
      );

      rowIndex++;

      fillRowBackground(rowIndex, gray3TextStyle, gray3NumberStyle);
      setCellRC(rowIndex, 0, xls.TextCellValue('Santa'), gray3TextStyle);
      rowIndex++;

      String lastBarangay = '';

      for (final row in evacuationCenterRows) {
        final String barangay = (row['barangay'] ?? '').toString();
        final String site = (row['site'] ?? '').toString();
        final bool isFirstRowOfBarangay = barangay != lastBarangay;

        fillRowBackground(rowIndex, bodyTextStyle, bodyNumberStyle);

        setCellRC(
          rowIndex,
          1,
          xls.TextCellValue(isFirstRowOfBarangay ? barangay : ''),
          bodyTextStyle,
        );
        setCellRC(
          rowIndex,
          2,
          xls.TextCellValue(
            isFirstRowOfBarangay ? (row['count'] ?? '').toString() : '',
          ),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          3,
          xls.TextCellValue(
            isFirstRowOfBarangay ? (row['families'] ?? 0).toString() : '',
          ),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          4,
          xls.TextCellValue(
            isFirstRowOfBarangay ? (row['persons'] ?? 0).toString() : '',
          ),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          5,
          xls.TextCellValue(
            isFirstRowOfBarangay ? (row['fourPsFamilies'] ?? 0).toString() : '',
          ),
          bodyNumberStyle,
        );

        setCellRC(rowIndex, 6, xls.TextCellValue(site), bodyTextStyle);
        setCellRC(
          rowIndex,
          7,
          xls.TextCellValue('SANTA, ILOCOS SUR'),
          bodyTextStyle,
        );
        setCellRC(rowIndex, 8, xls.TextCellValue(barangay), bodyTextStyle);
        setCellRC(
          rowIndex,
          9,
          xls.TextCellValue(isFirstRowOfBarangay ? '1' : ''),
          bodyNumberStyle,
        );

        setCellRC(
          rowIndex,
          10,
          xls.IntCellValue((row['insideEcFamiliesCum'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          11,
          xls.IntCellValue((row['insideEcFamiliesNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          12,
          xls.IntCellValue((row['personsActualCum'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          13,
          xls.IntCellValue((row['personsActualNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(rowIndex, 14, xls.TextCellValue(''), bodyNumberStyle);
        setCellRC(rowIndex, 15, xls.TextCellValue(''), bodyNumberStyle);
        setCellRC(rowIndex, 16, xls.TextCellValue(''), bodyNumberStyle);
        setCellRC(rowIndex, 17, xls.TextCellValue(''), bodyNumberStyle);
        setCellRC(rowIndex, 18, xls.TextCellValue(''), bodyNumberStyle);
        setCellRC(rowIndex, 19, xls.TextCellValue(''), bodyNumberStyle);

        setCellRC(
          rowIndex,
          20,
          xls.IntCellValue((row['totalDisplacedFamiliesCum'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          21,
          xls.IntCellValue((row['totalDisplacedFamiliesNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          22,
          xls.IntCellValue((row['totalDisplacedPersonsCum'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          23,
          xls.IntCellValue((row['totalDisplacedPersonsNow'] ?? 0) as int),
          bodyNumberStyle,
        );

        setCellRC(
          rowIndex,
          24,
          xls.IntCellValue((row['infantMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          25,
          xls.IntCellValue((row['infantFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          26,
          xls.IntCellValue((row['toddlerMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          27,
          xls.IntCellValue((row['toddlerFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          28,
          xls.IntCellValue((row['preschoolMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          29,
          xls.IntCellValue((row['preschoolFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          30,
          xls.IntCellValue((row['schoolAgeMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          31,
          xls.IntCellValue((row['schoolAgeFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          32,
          xls.IntCellValue((row['teenageMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          33,
          xls.IntCellValue((row['teenageFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          34,
          xls.IntCellValue((row['adultMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          35,
          xls.IntCellValue((row['adultFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          36,
          xls.IntCellValue((row['seniorMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          37,
          xls.IntCellValue((row['seniorFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          38,
          xls.IntCellValue((row['totalInsideMaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );
        setCellRC(
          rowIndex,
          39,
          xls.IntCellValue((row['totalInsideFemaleNow'] ?? 0) as int),
          bodyNumberStyle,
        );

        lastBarangay = barangay;
        rowIndex++;
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to encode excel file.');
      }

      final data = Uint8List.fromList(bytes);
      final blob = html.Blob([
        data,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final filename =
          'Preview_Report_${_formatDate(widget.startDate)}_to_${_formatDateTimeForFilename(widget.endDateTime)}.xlsx';

      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
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
      if (!mounted) return;
      setState(() {
        isDownloading = false;
      });
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

    colOutsideEcFamiliesCum = _getMaxWidthForValues(
      ['9999'],
      header: 'CUM',
      minWidth: 70,
      maxWidth: 100,
    );

    colOutsideEcFamiliesNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 70,
      maxWidth: 100,
    );

    colOutsideEcPersonsCum = _getMaxWidthForValues(
      ['9999'],
      header: 'CUM',
      minWidth: 70,
      maxWidth: 100,
    );

    colOutsideEcPersonsNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 70,
      maxWidth: 100,
    );

    colTotalDisplacedFamiliesCum = _getMaxWidthForValues(
      ['9999'],
      header: 'CUM',
      minWidth: 70,
      maxWidth: 100,
    );

    colTotalDisplacedFamiliesNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 70,
      maxWidth: 100,
    );

    colTotalDisplacedPersonsCum = _getMaxWidthForValues(
      ['9999'],
      header: 'CUM',
      minWidth: 70,
      maxWidth: 100,
    );

    colTotalDisplacedPersonsNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 70,
      maxWidth: 100,
    );

    colInfantMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colInfantFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colToddlerMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colToddlerFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colPreschoolMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colPreschoolFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colSchoolAgeMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colSchoolAgeFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colTeenageMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colTeenageFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colAdultMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colAdultFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 90,
      maxWidth: 110,
    );

    colSeniorMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 110,
      maxWidth: 140,
    );

    colSeniorFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 110,
      maxWidth: 140,
    );

    colTotalInsideMaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 130,
      maxWidth: 170,
    );

    colTotalInsideFemaleNow = _getMaxWidthForValues(
      ['9999'],
      header: 'NOW',
      minWidth: 130,
      maxWidth: 170,
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
    required String outsideEcFamiliesCum,
    required String outsideEcFamiliesNow,
    required String outsideEcPersonsCum,
    required String outsideEcPersonsNow,
    required String totalDisplacedFamiliesCum,
    required String totalDisplacedFamiliesNow,
    required String totalDisplacedPersonsCum,
    required String totalDisplacedPersonsNow,
    required String infantMaleNow,
    required String infantFemaleNow,
    required String toddlerMaleNow,
    required String toddlerFemaleNow,
    required String preschoolMaleNow,
    required String preschoolFemaleNow,
    required String schoolAgeMaleNow,
    required String schoolAgeFemaleNow,
    required String teenageMaleNow,
    required String teenageFemaleNow,
    required String adultMaleNow,
    required String adultFemaleNow,
    required String seniorMaleNow,
    required String seniorFemaleNow,
    required String totalInsideMaleNow,
    required String totalInsideFemaleNow,
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
        _cell(
          text: outsideEcFamiliesCum,
          width: colOutsideEcFamiliesCum,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: outsideEcFamiliesNow,
          width: colOutsideEcFamiliesNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: outsideEcPersonsCum,
          width: colOutsideEcPersonsCum,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: outsideEcPersonsNow,
          width: colOutsideEcPersonsNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: totalDisplacedFamiliesCum,
          width: colTotalDisplacedFamiliesCum,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: totalDisplacedFamiliesNow,
          width: colTotalDisplacedFamiliesNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: totalDisplacedPersonsCum,
          width: colTotalDisplacedPersonsCum,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: totalDisplacedPersonsNow,
          width: colTotalDisplacedPersonsNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: infantMaleNow,
          width: colInfantMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: infantFemaleNow,
          width: colInfantFemaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: toddlerMaleNow,
          width: colToddlerMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: toddlerFemaleNow,
          width: colToddlerFemaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: preschoolMaleNow,
          width: colPreschoolMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: preschoolFemaleNow,
          width: colPreschoolFemaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: schoolAgeMaleNow,
          width: colSchoolAgeMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: schoolAgeFemaleNow,
          width: colSchoolAgeFemaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: teenageMaleNow,
          width: colTeenageMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: teenageFemaleNow,
          width: colTeenageFemaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: adultMaleNow,
          width: colAdultMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: adultFemaleNow,
          width: colAdultFemaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: seniorMaleNow,
          width: colSeniorMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: seniorFemaleNow,
          width: colSeniorFemaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: totalInsideMaleNow,
          width: colTotalInsideMaleNow,
          height: height,
          bold: bold,
          color: color,
          fontSize: 15,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        _cell(
          text: totalInsideFemaleNow,
          width: colTotalInsideFemaleNow,
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
          outsideEcFamiliesCum: '',
          outsideEcFamiliesNow: '',
          outsideEcPersonsCum: '',
          outsideEcPersonsNow: '',
          totalDisplacedFamiliesCum: '',
          totalDisplacedFamiliesNow: '',
          totalDisplacedPersonsCum: '',
          totalDisplacedPersonsNow: '',
          infantMaleNow: '0',
          infantFemaleNow: '0',
          toddlerMaleNow: '0',
          toddlerFemaleNow: '0',
          preschoolMaleNow: '0',
          preschoolFemaleNow: '0',
          schoolAgeMaleNow: '0',
          schoolAgeFemaleNow: '0',
          teenageMaleNow: '0',
          teenageFemaleNow: '0',
          adultMaleNow: '0',
          adultFemaleNow: '0',
          seniorMaleNow: '0',
          seniorFemaleNow: '0',
          totalInsideMaleNow: '0',
          totalInsideFemaleNow: '0',
          color: Colors.white,
        ),
      ];
    }

    final List<Widget> rows = [];
    String lastBarangay = '';

    for (final row in evacuationCenterRows) {
      final barangay = (row['barangay'] ?? '').toString();
      final site = (row['site'] ?? '').toString();

      final count = (row['count'] ?? '').toString();
      final families = (row['families'] ?? 0).toString();
      final persons = (row['persons'] ?? 0).toString();
      final fourPsFamilies = (row['fourPsFamilies'] ?? 0).toString();
      final insideEcFamiliesCum = (row['insideEcFamiliesCum'] ?? 0).toString();
      final insideEcFamiliesNow = (row['insideEcFamiliesNow'] ?? 0).toString();
      final personsActualCum = (row['personsActualCum'] ?? 0).toString();
      final personsActualNow = (row['personsActualNow'] ?? 0).toString();

      final totalDisplacedFamiliesCum =
          ((row['insideEcFamiliesCum'] ?? 0) as int).toString();
      final totalDisplacedFamiliesNow =
          ((row['insideEcFamiliesNow'] ?? 0) as int).toString();
      final totalDisplacedPersonsCum = ((row['personsActualCum'] ?? 0) as int)
          .toString();
      final totalDisplacedPersonsNow = ((row['personsActualNow'] ?? 0) as int)
          .toString();

      final bool isFirstRowOfBarangay = barangay != lastBarangay;

      rows.add(
        _buildRow(
          region: '',
          barangayName: isFirstRowOfBarangay ? barangay : '',
          barangayCount: isFirstRowOfBarangay ? count : '',
          families: isFirstRowOfBarangay ? families : '',
          persons: isFirstRowOfBarangay ? persons : '',
          fourPsFamilies: isFirstRowOfBarangay ? fourPsFamilies : '',
          evacuationCenterName: site,
          address: 'SANTA, ILOCOS SUR',
          originBrgyName: barangay,
          originBrgyCount: isFirstRowOfBarangay ? '1' : '',
          insideEcFamiliesCum: insideEcFamiliesCum,
          insideEcFamiliesNow: insideEcFamiliesNow,
          personsActualCum: personsActualCum,
          personsActualNow: personsActualNow,
          personsEstimateCum: '',
          personsEstimateNow: '',
          outsideEcFamiliesCum: '',
          outsideEcFamiliesNow: '',
          outsideEcPersonsCum: '',
          outsideEcPersonsNow: '',
          totalDisplacedFamiliesCum: totalDisplacedFamiliesCum,
          totalDisplacedFamiliesNow: totalDisplacedFamiliesNow,
          totalDisplacedPersonsCum: totalDisplacedPersonsCum,
          totalDisplacedPersonsNow: totalDisplacedPersonsNow,

          // fixed only this part: align to same site row
          infantMaleNow: (row['infantMaleNow'] ?? 0).toString(),
          infantFemaleNow: (row['infantFemaleNow'] ?? 0).toString(),
          toddlerMaleNow: (row['toddlerMaleNow'] ?? 0).toString(),
          toddlerFemaleNow: (row['toddlerFemaleNow'] ?? 0).toString(),
          preschoolMaleNow: (row['preschoolMaleNow'] ?? 0).toString(),
          preschoolFemaleNow: (row['preschoolFemaleNow'] ?? 0).toString(),
          schoolAgeMaleNow: (row['schoolAgeMaleNow'] ?? 0).toString(),
          schoolAgeFemaleNow: (row['schoolAgeFemaleNow'] ?? 0).toString(),
          teenageMaleNow: (row['teenageMaleNow'] ?? 0).toString(),
          teenageFemaleNow: (row['teenageFemaleNow'] ?? 0).toString(),
          adultMaleNow: (row['adultMaleNow'] ?? 0).toString(),
          adultFemaleNow: (row['adultFemaleNow'] ?? 0).toString(),
          seniorMaleNow: (row['seniorMaleNow'] ?? 0).toString(),
          seniorFemaleNow: (row['seniorFemaleNow'] ?? 0).toString(),
          totalInsideMaleNow: (row['totalInsideMaleNow'] ?? 0).toString(),
          totalInsideFemaleNow: (row['totalInsideFemaleNow'] ?? 0).toString(),

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
    const yellowMain = Color(0xFFE9C95F);
    const yellowSub = Color(0xFFF0D56E);
    const gray1 = Color(0xFFB7B7B7);
    const gray2 = Color(0xFFD0D0D0);
    const gray3 = Color(0xFFF2F2F2);
    const ageColor = Color(0xFFEFE6C4);

    const double h1 = 18;
    const double h2 = 18;
    const double h3 = 18;
    const double h4 = 18;
    const double h5 = 18;

    const double totalHeaderHeight = h1 + h2 + h3 + h4 + h5;

    final double numberAffectedWidth =
        colBarangayName +
        colBarangayCount +
        colFamilies +
        colPersons +
        col4PsFamilies;

    final double displacementWidth =
        colEvacuationCenterName +
        colAddress +
        colOriginBrgyName +
        colOriginBrgyCount +
        colInsideEcFamiliesCum +
        colInsideEcFamiliesNow +
        colPersonsActualCum +
        colPersonsActualNow +
        colPersonsEstimateCum +
        colPersonsEstimateNow +
        colOutsideEcFamiliesCum +
        colOutsideEcFamiliesNow +
        colOutsideEcPersonsCum +
        colOutsideEcPersonsNow;

    final double totalDisplacedWidth =
        colTotalDisplacedFamiliesCum +
        colTotalDisplacedFamiliesNow +
        colTotalDisplacedPersonsCum +
        colTotalDisplacedPersonsNow;

    final double sexAgeWidth =
        colInfantMaleNow +
        colInfantFemaleNow +
        colToddlerMaleNow +
        colToddlerFemaleNow +
        colPreschoolMaleNow +
        colPreschoolFemaleNow +
        colSchoolAgeMaleNow +
        colSchoolAgeFemaleNow +
        colTeenageMaleNow +
        colTeenageFemaleNow +
        colAdultMaleNow +
        colAdultFemaleNow +
        colSeniorMaleNow +
        colSeniorFemaleNow +
        colTotalInsideMaleNow +
        colTotalInsideFemaleNow;

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
                    width: numberAffectedWidth,
                    height: h1 + h2,
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
                            text: 'Barangays',
                            width: colBarangayName + colBarangayCount,
                            height: h3 + h4,
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
                        height: h3 + h4 + h5,
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
                        height: h3 + h4 + h5,
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
                        height: h3 + h4 + h5,
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
                    width: displacementWidth,
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
                                colPersonsEstimateNow +
                                colOutsideEcFamiliesCum +
                                colOutsideEcFamiliesNow +
                                colOutsideEcPersonsCum +
                                colOutsideEcPersonsNow,
                            height: h2,
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
                              _cell(
                                text: 'OUTSIDE ECs',
                                width:
                                    colOutsideEcFamiliesCum +
                                    colOutsideEcFamiliesNow +
                                    colOutsideEcPersonsCum +
                                    colOutsideEcPersonsNow,
                                height: h3,
                                bold: true,
                                color: green,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                            ],
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
                              Column(
                                children: [
                                  _cell(
                                    text: 'Families',
                                    width:
                                        colOutsideEcFamiliesCum +
                                        colOutsideEcFamiliesNow,
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
                                        width: colOutsideEcFamiliesCum,
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
                                        width: colOutsideEcFamiliesNow,
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
                                    text: 'Persons',
                                    width:
                                        colOutsideEcPersonsCum +
                                        colOutsideEcPersonsNow,
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
                                        width: colOutsideEcPersonsCum,
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
                                        width: colOutsideEcPersonsNow,
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

              Column(
                children: [
                  _cell(
                    text: 'TOTAL DISPLACED',
                    width: totalDisplacedWidth,
                    height: h1 + h2,
                    bold: true,
                    color: yellowMain,
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
                            text: 'Families',
                            width:
                                colTotalDisplacedFamiliesCum +
                                colTotalDisplacedFamiliesNow,
                            height: h3,
                            bold: true,
                            color: yellowSub,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          _cell(
                            text: 'Total Families',
                            width:
                                colTotalDisplacedFamiliesCum +
                                colTotalDisplacedFamiliesNow,
                            height: h4,
                            bold: true,
                            color: yellowSub,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          Row(
                            children: [
                              _cell(
                                text: 'CUM',
                                width: colTotalDisplacedFamiliesCum,
                                height: h5,
                                bold: true,
                                color: yellowSub,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                              _cell(
                                text: 'NOW',
                                width: colTotalDisplacedFamiliesNow,
                                height: h5,
                                bold: true,
                                color: yellowSub,
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
                            text: 'Persons',
                            width:
                                colTotalDisplacedPersonsCum +
                                colTotalDisplacedPersonsNow,
                            height: h3,
                            bold: true,
                            color: yellowSub,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          _cell(
                            text: 'Total Persons',
                            width:
                                colTotalDisplacedPersonsCum +
                                colTotalDisplacedPersonsNow,
                            height: h4,
                            bold: true,
                            color: yellowSub,
                            fontSize: 12,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            padding: EdgeInsets.zero,
                          ),
                          Row(
                            children: [
                              _cell(
                                text: 'CUM',
                                width: colTotalDisplacedPersonsCum,
                                height: h5,
                                bold: true,
                                color: yellowSub,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                              _cell(
                                text: 'NOW',
                                width: colTotalDisplacedPersonsNow,
                                height: h5,
                                bold: true,
                                color: yellowSub,
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

              Column(
                children: [
                  _cell(
                    text: 'SEX & AGE DISTRIBUTION OF IDPS INSIDE ECS',
                    width: sexAgeWidth,
                    height: h1 + h2,
                    bold: true,
                    color: ageColor,
                    fontSize: 13,
                    textAlign: TextAlign.center,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                  ),
                  Row(
                    children: [
                      _buildAgeGroupHeader(
                        title: 'INFANT >1 y/o (0-11mos)',
                        maleWidth: colInfantMaleNow,
                        femaleWidth: colInfantFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
                      ),
                      _buildAgeGroupHeader(
                        title: 'TODDLERS 1-3 y/o',
                        maleWidth: colToddlerMaleNow,
                        femaleWidth: colToddlerFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
                      ),
                      _buildAgeGroupHeader(
                        title: 'PRESCHOOLERS 4-5 y/o',
                        maleWidth: colPreschoolMaleNow,
                        femaleWidth: colPreschoolFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
                      ),
                      _buildAgeGroupHeader(
                        title: 'SCHOOL AGE 6-12 y/o',
                        maleWidth: colSchoolAgeMaleNow,
                        femaleWidth: colSchoolAgeFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
                      ),
                      _buildAgeGroupHeader(
                        title: 'TEENAGE 13-19 y/o',
                        maleWidth: colTeenageMaleNow,
                        femaleWidth: colTeenageFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
                      ),
                      _buildAgeGroupHeader(
                        title: 'ADULT 20-59 y/o',
                        maleWidth: colAdultMaleNow,
                        femaleWidth: colAdultFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
                      ),
                      _buildAgeGroupHeader(
                        title: 'SENIOR CITIZENS 60 and above',
                        maleWidth: colSeniorMaleNow,
                        femaleWidth: colSeniorFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
                      ),
                      _buildAgeGroupHeader(
                        title: 'Total Number of IDPs Inside ECs',
                        maleWidth: colTotalInsideMaleNow,
                        femaleWidth: colTotalInsideFemaleNow,
                        color: ageColor,
                        h3: h3,
                        h4: h4,
                        h5: h5,
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
            outsideEcFamiliesCum: '',
            outsideEcFamiliesNow: '',
            outsideEcPersonsCum: '',
            outsideEcPersonsNow: '',
            totalDisplacedFamiliesCum: '',
            totalDisplacedFamiliesNow: '',
            totalDisplacedPersonsCum: '',
            totalDisplacedPersonsNow: '',
            infantMaleNow: '',
            infantFemaleNow: '',
            toddlerMaleNow: '',
            toddlerFemaleNow: '',
            preschoolMaleNow: '',
            preschoolFemaleNow: '',
            schoolAgeMaleNow: '',
            schoolAgeFemaleNow: '',
            teenageMaleNow: '',
            teenageFemaleNow: '',
            adultMaleNow: '',
            adultFemaleNow: '',
            seniorMaleNow: '',
            seniorFemaleNow: '',
            totalInsideMaleNow: '',
            totalInsideFemaleNow: '',
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
            outsideEcFamiliesCum: '',
            outsideEcFamiliesNow: '',
            outsideEcPersonsCum: '',
            outsideEcPersonsNow: '',
            totalDisplacedFamiliesCum: '',
            totalDisplacedFamiliesNow: '',
            totalDisplacedPersonsCum: '',
            totalDisplacedPersonsNow: '',
            infantMaleNow: '',
            infantFemaleNow: '',
            toddlerMaleNow: '',
            toddlerFemaleNow: '',
            preschoolMaleNow: '',
            preschoolFemaleNow: '',
            schoolAgeMaleNow: '',
            schoolAgeFemaleNow: '',
            teenageMaleNow: '',
            teenageFemaleNow: '',
            adultMaleNow: '',
            adultFemaleNow: '',
            seniorMaleNow: '',
            seniorFemaleNow: '',
            totalInsideMaleNow: '',
            totalInsideFemaleNow: '',
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
            outsideEcFamiliesCum: '',
            outsideEcFamiliesNow: '',
            outsideEcPersonsCum: '',
            outsideEcPersonsNow: '',
            totalDisplacedFamiliesCum: '',
            totalDisplacedFamiliesNow: '',
            totalDisplacedPersonsCum: '',
            totalDisplacedPersonsNow: '',
            infantMaleNow: '',
            infantFemaleNow: '',
            toddlerMaleNow: '',
            toddlerFemaleNow: '',
            preschoolMaleNow: '',
            preschoolFemaleNow: '',
            schoolAgeMaleNow: '',
            schoolAgeFemaleNow: '',
            teenageMaleNow: '',
            teenageFemaleNow: '',
            adultMaleNow: '',
            adultFemaleNow: '',
            seniorMaleNow: '',
            seniorFemaleNow: '',
            totalInsideMaleNow: '',
            totalInsideFemaleNow: '',
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
            outsideEcFamiliesCum: '',
            outsideEcFamiliesNow: '',
            outsideEcPersonsCum: '',
            outsideEcPersonsNow: '',
            totalDisplacedFamiliesCum: '',
            totalDisplacedFamiliesNow: '',
            totalDisplacedPersonsCum: '',
            totalDisplacedPersonsNow: '',
            infantMaleNow: '',
            infantFemaleNow: '',
            toddlerMaleNow: '',
            toddlerFemaleNow: '',
            preschoolMaleNow: '',
            preschoolFemaleNow: '',
            schoolAgeMaleNow: '',
            schoolAgeFemaleNow: '',
            teenageMaleNow: '',
            teenageFemaleNow: '',
            adultMaleNow: '',
            adultFemaleNow: '',
            seniorMaleNow: '',
            seniorFemaleNow: '',
            totalInsideMaleNow: '',
            totalInsideFemaleNow: '',
            italicRegion: true,
            color: Colors.white,
          ),
          ..._buildBarangayRows(),
        ],
      ),
    );
  }

  Widget _buildAgeGroupHeader({
    required String title,
    required double maleWidth,
    required double femaleWidth,
    required Color color,
    required double h3,
    required double h4,
    required double h5,
  }) {
    return Column(
      children: [
        _cell(
          text: title,
          width: maleWidth + femaleWidth,
          height: h3,
          bold: true,
          color: color,
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
                  text: 'Male',
                  width: maleWidth,
                  height: h4,
                  bold: true,
                  color: color,
                  fontSize: 12,
                  textAlign: TextAlign.center,
                  alignment: Alignment.center,
                  padding: EdgeInsets.zero,
                ),
                _cell(
                  text: 'NOW',
                  width: maleWidth,
                  height: h5,
                  bold: true,
                  color: color,
                  fontSize: 12,
                  textAlign: TextAlign.center,
                  alignment: Alignment.center,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            Column(
              children: [
                _cell(
                  text: 'Female',
                  width: femaleWidth,
                  height: h4,
                  bold: true,
                  color: color,
                  fontSize: 12,
                  textAlign: TextAlign.center,
                  alignment: Alignment.center,
                  padding: EdgeInsets.zero,
                ),
                _cell(
                  text: 'NOW',
                  width: femaleWidth,
                  height: h5,
                  bold: true,
                  color: color,
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
