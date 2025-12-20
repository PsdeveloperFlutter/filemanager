import 'package:filemanager/StudentManagement/screens/UiHelper.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../db/db_helper.dart';
import 'attendanceSummaryScreen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const AttendanceHistoryScreen({
    required this.studentId,
    required this.studentName,
    super.key,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int selectedIndex = 1; // default = List tab
  List<Map<String, Object?>> attendance = [];
  Map<DateTime, int> attendanceMap = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectDay;

  Future<void> loadAttendance() async {
    final data = await DbHelper.instance.fetchAttendance(widget.studentId);
    attendanceMap.clear();

    for (var record in data) {
      final rawDate = record['date'];
      if (rawDate != null) {
        final date = DateTime.tryParse(rawDate.toString());
        attendanceMap[DateTime(date!.year, date.month, date.day)] =
            record['isPresent'] as int;
      }
    }
    setState(() {
      attendance = data;
    });
  }

  @override
  void initState() {
    super.initState();
    loadAttendance();
    loadAttendanceWithCalendar();
  }

  Future<void> loadAttendanceWithCalendar() async {
    final data = await DbHelper.instance.fetchAttendance(widget.studentId);
    setState(() {
      attendance = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} Attendance'),
      ),

      // 🔹 BODY
      body: IndexedStack(
        index: selectedIndex,
        children: [
          /// TAB 0 → Calendar (next step)
          buildCalendarView(),

          /// TAB 1 → Attendance List (YOUR EXISTING CODE)
          attendance.isEmpty
              ? const Center(child: Text("No Attendance Records"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: attendance.length,
                  itemBuilder: (context, index) {
                    final record = attendance[index];

                    final rawDate = record['date'];
                    String date = rawDate.toString();

                    if (rawDate is String) {
                      final parsed = DateTime.tryParse(rawDate);
                      if (parsed != null) {
                        date = '${parsed.day.toString().padLeft(2, '0')}-'
                            '${parsed.month.toString().padLeft(2, '0')}-'
                            '${parsed.year}';
                      }
                    }

                    final isPresent = record['isPresent'] == 1;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                        title: Text(date),
                        subtitle: Text(isPresent ? "Present" : "Absent"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            confirmDeleteOfAttendanceData(
                              context,
                              record,
                              loadAttendance,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

          /// TAB 2 → Summary (next step)
          AttendanceSummaryScreen(
            studentId: widget.studentId,
            studentName: widget.studentName,
          )
        ],
      ),

      // 🔹 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "Summary",
          ),
        ],
      ),
    );
  }

  Widget buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            selectDay = selected;
            focusedDay = focused;
          });
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final key = DateTime(day.year, day.month, day.day);

            if (attendanceMap.containsKey(key)) {
              final isPresent = attendanceMap[key] == 1;

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isPresent ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            return null;
          },
        ),
      ),
    );
  }
}
