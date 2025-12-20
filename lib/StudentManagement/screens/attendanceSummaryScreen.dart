import 'package:flutter/material.dart';
import '../db/db_helper.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const AttendanceSummaryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} Summary'),
      ),
      body: Column(
        children: [
          /// Month & Year Selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text('Month ${index + 1}'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                    loadSummary();
                  },
                ),
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(5, (index) {
                    int year = DateTime.now().year - index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                    loadSummary();
                  },
                ),
              ],
            ),
          ),

          summary == null
              ? const CircularProgressIndicator()
              : Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                summaryTile('Total Days', summary!['totalDays']),
                summaryTile('Sundays', summary!['sundays']),
                summaryTile('Holidays', summary!['holidays']),
                summaryTile('Working Days', summary!['workingDays']),
                summaryTile('Present Days', summary!['presentDays']),
                summaryTile('Absent Days', summary!['absentDays']),
                summaryTile(
                  'Attendance %',
                  '${summary!['percentage']}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryTile(String title, dynamic value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
