import 'package:flutter/material.dart';

import '../db/db_helper.dart';

class AddHolidayScreen extends StatefulWidget {
  const AddHolidayScreen({super.key});

  @override
  State<AddHolidayScreen> createState() => _AddHolidayScreenState();
}

class _AddHolidayScreenState extends State<AddHolidayScreen> {
  DateTime? selectedDate;
  final TextEditingController reasonController = TextEditingController();
  bool isLoading = false;

  /// Date Picker
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// Save Holiday
  Future<void> saveHoliday() async {
    if (selectedDate == null || reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and enter reason")),
      );
      return;
    }

    setState(() => isLoading = true);

    await DbHelper.instance.addHoliday(
      date: selectedDate!.toIso8601String(),
      reason: reasonController.text.trim(),
    );

    setState(() => isLoading = false);
    reasonController.clear();
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Add Holiday",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xffabfff0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Date Picker
              Text("Holiday Date",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: pickDate,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white.withOpacity(0.95),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? "Select Date"
                            : "${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}",
                        style: TextStyle(
                          color: selectedDate == null
                              ? Colors.grey.shade600
                              : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.calendar_today,
                          size: 18, color: Colors.blue),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Reason Field
              Text("Reason", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: reasonController,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Eg: National Holiday",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixIcon:
                        Icon(Icons.event_note, color: Colors.blue.shade700),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () {
                        setState(() => reasonController.clear());
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text("Existing Holidays",
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),

              /// Holiday List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DbHelper.instance.getHolidays(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No holidays added"));
                    }
                    final holidays = snapshot.data!;
                    return ListView.builder(
                      itemCount: holidays.length,
                      itemBuilder: (context, index) {
                        final item = holidays[index];
                        final id = item['id'];
                        final dateStr = item['date'] ?? '';
                        DateTime? date;
                        try {
                          date = DateTime.parse(dateStr);
                        } catch (_) {}
                        final formattedDate = date == null
                            ? dateStr
                            : '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                        return Dismissible(
                          key: ValueKey(id ?? index),
                          direction: DismissDirection.endToStart,
                          background: Card(
                            elevation: 1,
                            child: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                          onDismissed: (_) async {
                            if (id != null)
                              await DbHelper.instance.deleteHolidays(id);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Holiday deleted")),
                            );
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(item['reason'] ?? 'No reason'),
                              subtitle: Text(formattedDate),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  if (id != null)
                                    await DbHelper.instance.deleteHolidays(id);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Holiday deleted")),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: Colors.green.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.green.shade700, width: 1),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: isLoading ? null : saveHoliday,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text("Save Holiday"),
                          ],
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
