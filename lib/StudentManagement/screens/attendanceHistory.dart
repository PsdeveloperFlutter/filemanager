import 'package:filemanager/StudentManagement/screens/UiHelper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../db/db_helper.dart';
import 'attendanceSummaryScreen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String? studentImage;

  const AttendanceHistoryScreen({
    required this.studentId,
    required this.studentName,
    this.studentImage,
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
        backgroundColor: Colors.blue,
        title: Text(
          '${widget.studentName} Attendance',
          style: GoogleFonts.habibi(color: Colors.white),
        ),
        actions: [
          selectedIndex == 1
              ? IconButton(
                  icon: const Icon(
                    Icons.sort,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    showSortDialog(
                      context,
                      attendance,
                      (sortedList) {
                        setState(() {
                          attendance = sortedList;
                        });
                      },
                    );
                  },
                )
              : Container(),
        ],
      ),

      // 🔹 BODY
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xffabfff0)],
          ),
        ),
        child: IndexedStack(
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
                          title: Text(
                            date,
                            style: GoogleFonts.abyssinicaSil(),
                          ),
                          subtitle: Text(isPresent ? "Present" : "Absent",
                              style: GoogleFonts.habibi()),
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
              studentPhoto: widget.studentImage,
            ),
          ],
        ),
      ),

// 🔹 PROFESSIONAL BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        /// UI SETTINGS
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,

        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey.shade500,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),

        showUnselectedLabels: true,
        iconSize: 22,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: "Summary",
          ),
        ],
      ),
    );
  }

  Widget buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
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

            /// 🔹 Calendar Style
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(fontSize: 14),
              weekendTextStyle: const TextStyle(color: Colors.redAccent),
              outsideDaysVisible: false,
            ),

            /// 🔹 Header Style
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left),
              rightChevronIcon: const Icon(Icons.chevron_right),
            ),

            /// 🔹 Attendance Color Logic (UNCHANGED)
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final key = DateTime(day.year, day.month, day.day);

                if (attendanceMap.containsKey(key)) {
                  final isPresent = attendanceMap[key] == 1;

                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return null;
              },
            ),
          ),
        ),
      ),
    );
  }
}
