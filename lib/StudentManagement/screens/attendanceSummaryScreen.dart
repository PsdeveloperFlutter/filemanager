import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../db/db_helper.dart';
import 'package:open_filex/open_filex.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String?studentPhoto;
  const AttendanceSummaryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentPhoto
  });

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<String> monthsList = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  Map<String, dynamic>? summary;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Future<void> loadSummary() async {
    final data = await DbHelper.instance.getMonthlyAttendanceSummary(
      studentId: widget.studentId,
      month: selectedMonth,
      year: selectedYear,
    );
    setState(() {
      summary = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xffabfff0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              /// ================= STUDENT NAME CARD =================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:widget.studentPhoto!=null && widget.studentPhoto!.isNotEmpty? FileImage(File(  widget.studentPhoto!)):null,
                          radius: 24,
                          backgroundColor: Colors.teal,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.studentName,
                            style: GoogleFonts.habibi(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// ================= MONTH & YEAR SELECTOR =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        /// MONTH
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: InputDecoration(
                              labelText: "Month",
                              labelStyle: GoogleFonts.habibi(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(
                                  monthsList[index],
                                  style: GoogleFonts.habibi(),
                                ),
                              );
                            }),
                            onChanged: (value) {
                              setState(() => selectedMonth = value!);
                              loadSummary();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        /// YEAR
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedYear,
                            decoration: InputDecoration(
                              labelText: "Year",
                              labelStyle: GoogleFonts.habibi(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: List.generate(5, (index) {
                              int year = DateTime.now().year - index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text(
                                  year.toString(),
                                  style: GoogleFonts.habibi(),
                                ),
                              );
                            }),
                            onChanged: (value) {
                              setState(() => selectedYear = value!);
                              loadSummary();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// ================= SUMMARY LIST =================
              summary == null
                  ? const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
                  : Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    summaryTile('Total Days', summary!['totalDays']),
                    summaryTile('Sundays', summary!['sundays']),
                    summaryTile('Holidays', summary!['holidays']),
                    summaryTile(
                        'Working Days', summary!['workingDays']),
                    summaryTile(
                        'Present Days', summary!['presentDays']),
                    summaryTile(
                        'Absent Days', summary!['absentDays']),
                    summaryTile(
                      'Attendance %',
                      '${summary!['percentage']}%',
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// ================= BOTTOM ACTION BUTTONS =================
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      generatePdf(summary);
                    },
                    icon: const Icon(Icons.picture_as_pdf,color: Colors.white),
                    label: Text(
                      "Create PDF",
                      style: GoogleFonts.habibi(fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: summary == null ? null : sharePdf,
                    icon: const Icon(Icons.share,color: Colors.white),
                    label: Text(
                      "Share",
                      style: GoogleFonts.habibi(fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= SUMMARY TILE =================
  Widget summaryTile(String title, dynamic value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline, color: Colors.teal),
        title: Text(
          title,
          style: GoogleFonts.habibi(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          value.toString(),
          style: GoogleFonts.abyssinicaSil(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// ================= PDF GENERATION (UNCHANGED) =================
  Future<void> generatePdf(Map<String, dynamic>? summary) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Attendance Summary',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Student: ${widget.studentName}'),
              pw.Text(
                  'Month: ${monthsList[selectedMonth - 1]} $selectedYear'),
              pw.Divider(),
              summaryRow('Total Days', summary!['totalDays']),
              summaryRow('Sundays', summary!['sundays']),
              summaryRow('Holidays', summary!['holidays']),
              summaryRow('Working Days', summary!['workingDays']),
              summaryRow('Present Days', summary!['presentDays']),
              summaryRow('Absent Days', summary!['absentDays']),
              summaryRow(
                  'Attendance %', '${summary!['percentage']}%'),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/Attendance_${widget.studentName}_$selectedMonth-$selectedYear.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  pw.Widget summaryRow(String title, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title),
          pw.Text(
            value.toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ================= SHARE PDF (UNCHANGED) =================
  Future<void> sharePdf() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        "${dir.path}/Attendance_${widget.studentName}_$selectedMonth-$selectedYear.pdf");

    if (file.existsSync() == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please generate PDF first",
            style: GoogleFonts.habibi(),
          ),
        ),
      );
      return;
    } else {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
        'Attendance Summary of ${widget.studentName} for ${monthsList[selectedMonth - 1]} $selectedYear',
      );
    }
  }
}
