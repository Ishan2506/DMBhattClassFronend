import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_instruction_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_history_data.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class StudentStartExamForm extends StatefulWidget {
  const StudentStartExamForm({super.key});

  @override
  State<StudentStartExamForm> createState() => _StudentStartExamFormState();
}

class _StudentStartExamFormState extends State<StudentStartExamForm> {
  String? _selectedUnit;
  String? _selectedSubject;
  String? _selectedMarks;
  final TextEditingController _titleController = TextEditingController();

  final List<String> _units = ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4'];
  final List<String> _subjects = ['Math', 'Science', 'English'];
  final List<String> _marks =['20','30', '40', '50'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: lblStartNewExam,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentExamHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: P.all24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomDropdown<String>(
              labelText: lblSubject,
              hintText: lblSelectSubject,
              value: _selectedSubject,
              items: _subjects,
              itemLabelBuilder: (String item) => item,
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
            blankVerticalSpace16,
            CustomDropdown<String>(
              labelText: lblUnit,
              hintText: lblSelectUnit,
              value: _selectedUnit,
              items: _units,
              itemLabelBuilder: (String item) => item,
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value;
                });
              },
            ),
            blankVerticalSpace16,
            CustomDropdown<String>(
              labelText: lblMarks,
              hintText: lblSelectMarks,
              value: _selectedMarks,
              items: _marks,
              itemLabelBuilder: (String item) => item,
              onChanged: (value) {
                setState(() {
                  _selectedMarks = value;
                });
              },
            ),
            blankVerticalSpace16,
             // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Exam Title",
                hintText: "Enter a unique title",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(S.s12)),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: S.s48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(S.s12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (_selectedSubject == null || _selectedUnit == null || _selectedMarks == null || title.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  if (ExamHistoryData().isRegularExamTaken(title)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You have already taken an exam with this title!")),
                    );
                    return;
                  }
                  
                  // In a real app, you might save the intention to start this exam here or pass the title
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamInstructionScreen(
                        subject: _selectedSubject ?? 'Math', // Default fallback
                        // Pass title if needed by ExamInstructionScreen, typically via constructor
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(S.s12)),
                ),
                child: Text(
                  lblStartExam,
                  style: const TextStyle(
                      letterSpacing: 0.5,
                      fontSize: S.s16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
