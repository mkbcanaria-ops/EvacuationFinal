// ignore_for_file: unused_local_variable

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class WebReportsTablePage extends StatelessWidget {
  WebReportsTablePage({super.key});

  final List<String> tableData = [
    'Sample Municipality',
    'Another Municipality',
  ];

  // ----------------------------------------------------------------------
  // DOWNLOAD EXACT TABLE AS EXCEL
  // ----------------------------------------------------------------------
  void _downloadExcel(BuildContext context) {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Column width (single column)
    sheet.setColumnWidth(0, 45);

    // ---------- HEADER ----------
    sheet.appendRow([xls.TextCellValue('Region / Province / Municipality')]);

    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = xls.CellStyle(
      bold: true,
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
    );

    // ---------- DATA ----------
    for (int i = 0; i < tableData.length; i++) {
      sheet.appendRow([xls.TextCellValue(tableData[i])]);
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Excel generation failed')));
      return;
    }

    if (kIsWeb) {
      final blob = html.Blob([
        Uint8List.fromList(bytes),
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', 'Evacuation_Report.xlsx')
        ..click();

      html.Url.revokeObjectUrl(url);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel downloaded successfully')),
    );
  }

  Widget _subHeaderCell(String text) {
    return Expanded(
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _lastSubHeaderCell(String text) {
    return Expanded(
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _dataCell({String text = '', Border? border}) {
    return Expanded(
      child: Container(
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: border),
        child: Text(text),
      ),
    );
  }

  Widget _barangaysDataCell({String nameText = '', String countsText = ''}) {
    return Expanded(
      flex: 4,
      child: Container(
        height: 25,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.black)),
                ),
                child: Text(nameText), // Name sub-cell
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(countsText), // Counts sub-cell
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D743D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Evacuation Population Report',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _downloadExcel(context),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D743D),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(250),
                1: FixedColumnWidth(1200),
              },
              border: TableBorder.all(color: Colors.black, width: 1),
              children: [
                // ================= HEADER =================
                TableRow(
                  children: [
                    // FIRST COLUMN HEADER
                    Container(
                      height: 90,
                      alignment: Alignment.center,
                      child: const Text(
                        'REGION / PROVINCE / MUNICIPALITY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // SECOND COLUMN HEADER
                    Container(
                      height: 90,
                      child: Column(
                        children: [
                          // TOP ROW
                          Container(
                            height: 45,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.black),
                              ),
                            ),
                            child: const Text(
                              'NUMBERS AFFECTED',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          // BOTTOM ROW (SUB HEADERS)
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: 45,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Colors.black),
                                      bottom: BorderSide(color: Colors.black),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Barangays',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    right: BorderSide(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Name',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  'Counts',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: _subHeaderCell('Families'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _subHeaderCell('Persons'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _lastSubHeaderCell('4Ps Families'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= GRAND TOTAL =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      alignment: Alignment.center,
                      child: const Text(
                        'GRAND TOTAL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(
                            nameText: '#REF!',
                            countsText: '#REF!',
                          ),
                          _dataCell(
                            text: '#REF!',
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            text: '#REF!',
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            text: '#REF!',
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= ILOCOS SUR =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text('Ilocos Sur'),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(
                            nameText: '#REF!',
                            countsText: '#REF!',
                          ),
                          _dataCell(
                            text: '#REF!',
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            text: '#REF!',
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            text: '#REF!',
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= PROVINCE =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text('Province'),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= SANTA =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text('Santa'),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= NEW ROW 1 =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text(''),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= NEW ROW 2 =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text(''),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= NEW ROW 3 =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text(''),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= NEW ROW 4 =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text(''),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= NEW ROW 5 =================
                TableRow(
                  children: [
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Text(''),
                    ),

                    Container(
                      height: 25,
                      child: Row(
                        children: [
                          _barangaysDataCell(),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              right: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          _dataCell(
                            border: const Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
