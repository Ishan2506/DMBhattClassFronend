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
  String? _selectedUnit;
  String? _selectedMarks;
  final TextEditingController _titleController = TextEditingController();

  // Dropdown Options
  List<String> _subjects = [];
  List<String> _units = [];
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
      _selectedUnit = null;
      _selectedMarks = null;
      _selectedExamId = null;

      if (subject != null) {
        // Filter exams for this subject to get units
        _units = _allExams
            .where((e) => e['subject'] == subject)
            .map((e) => e['unit']?.toString() ?? 'Default Unit')
            .toSet()
            .toList();
      } else {
        _units = [];
      }
      _marksOptions = [];
    });
  }

  void _onUnitChanged(String? unit) {
    setState(() {
      _selectedUnit = unit;
      _selectedMarks = null;
      _selectedExamId = null;

      if (unit != null) {
        // Filter exams for this subject and unit to get marks
        final matchingExams = _allExams.where((e) =>
            e['subject'] == _selectedSubject && (e['unit']?.toString() ?? 'Default Unit') == unit);

        _marksOptions = matchingExams
            .map((e) => e['totalMarks'].toString())
            .toSet()
            .toList();
        
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
      if (marks != null && _selectedSubject != null && _selectedUnit != null) {
         // Find the exact exam ID
         try {
           final exam = _allExams.firstWhere((e) => 
             e['subject'] == _selectedSubject &&
             (e['unit']?.toString() ?? 'Default Unit') == _selectedUnit &&
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
                    labelText: "Unit",
                    hintText: "Select Unit",
                    value: _selectedUnit,
                    items: _units,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onUnitChanged,
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
