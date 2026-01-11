import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_instruction_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
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

  final List<String> _units = ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4'];
  final List<String> _subjects = ['Math', 'Science', 'English'];
  final List<String> _marks = ['30', '40', '50', '60', '70', '100'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(lblStartNewExam),
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
            const Spacer(),
            CustomFilledButton(
              label: lblStartExam,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExamInstructionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
