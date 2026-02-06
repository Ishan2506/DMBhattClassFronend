import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_instruction_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_history_data.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentStartExamForm extends StatefulWidget {
  const StudentStartExamForm({super.key});

  @override
  State<StudentStartExamForm> createState() => _StudentStartExamFormState();
}

class _StudentStartExamFormState extends State<StudentStartExamForm> {
  List<dynamic> _allExams = [];
  bool _isLoading = true;

  // Dropdown Selections
  String? _selectedSubject;
  String? _selectedExamName; // Previously "Unit"
  String? _selectedMarks;
  final TextEditingController _titleController = TextEditingController();

  // Dropdown Options
  List<String> _subjects = [];
  List<String> _examNames = [];
  List<String> _marksOptions = [];

  String? _selectedExamId;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final response = await ApiService.getAllExams();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allExams = data;
          // Extract unique subjects
          _subjects = _allExams
              .map((e) => e['subject'].toString())
              .toSet()
              .toList();
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching exams: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedExamName = null;
      _selectedMarks = null;
      _selectedExamId = null;

      if (subject != null) {
        // Filter exams for this subject to get exam names
        _examNames = _allExams
            .where((e) => e['subject'] == subject)
            .map((e) => e['name'].toString())
            .toSet()
            .toList();
      } else {
        _examNames = [];
      }
      _marksOptions = [];
    });
  }

  void _onExamNameChanged(String? name) {
    setState(() {
      _selectedExamName = name;
      _selectedMarks = null;
      _selectedExamId = null;

      if (name != null) {
        // Filter exams for this subject and name to get marks
        // In theory there should be only one, but we handle multiple just in case
        final matchingExams = _allExams.where((e) =>
            e['subject'] == _selectedSubject && e['name'] == name);

        _marksOptions = matchingExams
            .map((e) => e['totalMarks'].toString())
            .toSet()
            .toList();
        
        // If there's only one match (likely), auto-select it or wait for user?
        // Let's populate the marks dropdown.
        if (_marksOptions.length == 1) {
           _selectedMarks = _marksOptions.first;
           _onMarksChanged(_selectedMarks);
        }
      } else {
        _marksOptions = [];
      }
    });
  }

  void _onMarksChanged(String? marks) {
    setState(() {
      _selectedMarks = marks;
      if (marks != null && _selectedSubject != null && _selectedExamName != null) {
         // Find the exact exam ID
         try {
           final exam = _allExams.firstWhere((e) => 
             e['subject'] == _selectedSubject &&
             e['name'] == _selectedExamName &&
             e['totalMarks'].toString() == marks
           );
           _selectedExamId = exam['_id'];
         } catch (e) {
           _selectedExamId = null;
         }
      }
    });
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                    onChanged: _onSubjectChanged,
                  ),
                  blankVerticalSpace16,
                  CustomDropdown<String>(
                    labelText: "Exam Name", // Reusing "Unit" logic but renaming to Exam Name matches model better, or keep 'Unit' label if preferred
                    hintText: "Select Exam Name",
                    value: _selectedExamName,
                    items: _examNames,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onExamNameChanged,
                  ),
                  blankVerticalSpace16,
                  CustomDropdown<String>(
                    labelText: lblMarks,
                    hintText: lblSelectMarks,
                    value: _selectedMarks,
                    items: _marksOptions,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onMarksChanged,
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: S.s48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(S.s12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _selectedExamId == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExamInstructionScreen(
                                    subject: _selectedSubject ?? 'Math',
                                    examId: _selectedExamId!, 
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
