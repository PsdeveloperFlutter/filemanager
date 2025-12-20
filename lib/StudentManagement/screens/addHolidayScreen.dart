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

    Navigator.pop(context, true); // return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Holiday"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Date Picker
            Text("Holiday Date", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Reason Field
            Text("Reason", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Eg: National Holiday",
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            /// Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveHoliday,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Holiday"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
