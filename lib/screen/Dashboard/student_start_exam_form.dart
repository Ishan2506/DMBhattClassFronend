import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_instruction_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_history_data.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> _titles = [];
  List<String> _marksOptions = [];

  String? _selectedExamId;
  String? _selectedTitle;
  List<String> _takenTestTitles = [];
  String? _userRole;
  String? _userMedium;

  Future<void> _fetchExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString('user_role');
      final token = ApiService.userToken;

      // Fetch user profile to filter exams
      if (token != null) {
        final profileResponse = await ApiService.getProfile();
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          final profile = profileData['profile'];
          _userStandard = profile?['std']?.toString();
          _userMedium = profile?['medium']?.toString();
          _userStream = profile?['stream']?.toString();
        }
      }

      // Fetch history to check for taken tests
      final historyResponse = await ApiService.getDashboardData();
      if (historyResponse.statusCode == 200) {
        final historyData = jsonDecode(historyResponse.body);
        final List<dynamic> results = historyData['examResults'] ?? [];
        _takenTestTitles = results.map((e) => e['title'].toString().toLowerCase()).toList();
      }

      // Use backend filters if possible, or fetch all and filter locally
      final response = await ApiService.getAllExams(
        std: _userStandard,
        medium: _userMedium,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          // Filter locally for stream if necessary (backend doesn't support stream filter yet)
          _allExams = data.where((e) {
            final examStream = e['stream']?.toString();
            
            // Match Stream if Std is 11 or 12
            if (_userStandard != null && (int.tryParse(_userStandard!) ?? 0) >= 11) {
               if (_userStream != null && examStream != null && examStream != _userStream) return false;
            }
            return true;
          }).toList();

          // Extract unique subjects from filtered exams
          _subjects = _allExams
              .map((e) => e['subject'].toString())
              .toSet()
              .toList();
          
          _isLoading = false;
        });

        if (_subjects.isEmpty) {
           if (mounted) {
             showDialog(
               context: context, 
               barrierDismissible: false,
               builder: (context) => AlertDialog(
                 title: const Text("No Exam Available"),
                 content: const Text("No exam available please try after some days"),
                 actions: [
                   TextButton(
                     onPressed: () {
                       Navigator.pop(context); // Close dialog
                       Navigator.pop(context); // Go back
                     }, 
                     child: const Text("OK"),
                   )
                 ],
               ),
             );
           }
        }
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
      _selectedTitle = null;
      _selectedMarks = null;
      _selectedExamId = null;

      if (unit != null) {
        // Filter exams for this subject and unit to get titles
        final matchingExams = _allExams.where((e) =>
            e['subject'] == _selectedSubject && (e['unit']?.toString() ?? 'Default Unit') == unit);

        _titles = matchingExams
            .map((e) => e['title']?.toString() ?? 'Untitled Exam')
            .toSet()
            .toList();
        
        if (_titles.length == 1) {
           _selectedTitle = _titles.first;
           _onTitleChanged(_selectedTitle);
        }
      } else {
        _titles = [];
      }
      _marksOptions = [];
    });
  }

  void _onTitleChanged(String? title) {
    setState(() {
      _selectedTitle = title;
      _selectedMarks = null;
      _selectedExamId = null;

      if (title != null) {
        // Filter exams for this subject, unit and title to get marks
        final matchingExams = _allExams.where((e) =>
            e['subject'] == _selectedSubject && 
            (e['unit']?.toString() ?? 'Default Unit') == _selectedUnit &&
            (e['title']?.toString() ?? 'Untitled Exam') == title);

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
      if (marks != null && _selectedSubject != null && _selectedUnit != null && _selectedTitle != null) {
         // Find the exact exam ID
         try {
           final exam = _allExams.firstWhere((e) => 
             e['subject'] == _selectedSubject &&
             (e['unit']?.toString() ?? 'Default Unit') == _selectedUnit &&
             (e['title']?.toString() ?? 'Untitled Exam') == _selectedTitle &&
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
          ? const CustomLoader()
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
                    labelText: "Title",
                    hintText: "Select Title",
                    value: _selectedTitle,
                    items: _titles,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onTitleChanged,
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
                    height: MediaQuery.of(context).size.height * 0.065,
                    decoration: BoxDecoration(
                      gradient: _selectedExamId == null
                          ? null
                          : LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      // Removed color property to let Button handle disabled state
                      borderRadius: BorderRadius.circular(S.s12),
                      boxShadow: _selectedExamId == null
                          ? []
                          : [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _selectedExamId == null
                          ? null
                          : () async {
                              if (_userRole == 'guest' && _takenTestTitles.length >= 2) {
                                GuestUtils.showGuestRestrictionDialog(
                                  context, 
                                  message: "Guests are limited to 2 free exams. Please register as a student to unlock unlimited exams."
                                );
                                return;
                              }
                              if (_takenTestTitles.contains(_selectedTitle?.toLowerCase())) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Already Taken"),
                                    content: const Text("You have already performed this exam. Students can only take each exam once."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              
                              CustomLoader.show(context);
                              await Future.delayed(const Duration(milliseconds: 500));
                              if (context.mounted) {
                                CustomLoader.hide(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExamInstructionScreen(
                                      subject: _selectedSubject ?? 'Math',
                                      examId: _selectedExamId!, 
                                      title: _selectedTitle ?? 'Untitled Exam',
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey.shade400, // Explicit disabled color
                        disabledForegroundColor: Colors.white, // Explicit disabled text color
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(S.s12)),
                      ),
                      child: Text(
                        lblStartExam,
                        style: TextStyle(
                            letterSpacing: 0.5,
                            fontSize: MediaQuery.of(context).size.width * 0.045,
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
