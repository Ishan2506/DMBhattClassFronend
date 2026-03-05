import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_instruction_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_history_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OneLinerSelectionScreen extends StatefulWidget {
  const OneLinerSelectionScreen({super.key});

  @override
  State<OneLinerSelectionScreen> createState() => _OneLinerSelectionScreenState();
}

class _OneLinerSelectionScreenState extends State<OneLinerSelectionScreen> {
  List<dynamic> _allOneLinerExams = [];
  bool _isLoading = true;

  // Dropdown Selections
  String? _selectedSubject;
  String? _selectedUnit;
  String? _selectedTitle;

  // Dropdown Options
  List<String> _subjects = [];
  List<String> _units = [];
  List<String> _titles = [];

  String? _selectedExamId;

  @override
  void initState() {
    super.initState();
    _fetchOneLinerExams();
  }

  Future<void> _fetchOneLinerExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userStandard = prefs.getString('std');
      String? userMedium = prefs.getString('medium');

      // Fetch user profile if prefs are empty (robustness)
      if (userStandard == null || userMedium == null) {
        final profileResponse = await ApiService.getProfile();
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          final profile = profileData['profile'];
          userStandard = profile?['std']?.toString();
          userMedium = profile?['medium']?.toString();
        }
      }

      final response = await ApiService.getAllOneLinerExams(
        std: userStandard,
        medium: userMedium,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allOneLinerExams = data;
          _subjects = _allOneLinerExams
              .map((e) => e['subject']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
          _isLoading = false;
        });

        if (_subjects.isEmpty) {
          _showNoExamDialog();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching one-liner exams: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showNoExamDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("No One-Liner Exam Available"),
          content: const Text("No one-liner exam available for your standard. Please try again later."),
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

  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedUnit = null;
      _selectedTitle = null;
      _selectedExamId = null;

      if (subject != null) {
        _units = _allOneLinerExams
            .where((e) => e['subject'] == subject)
            .map((e) => e['unit']?.toString() ?? '1')
            .toSet()
            .toList();
      } else {
        _units = [];
      }
      _titles = [];
    });
  }

  void _onUnitChanged(String? unit) {
    setState(() {
      _selectedUnit = unit;
      _selectedTitle = null;
      _selectedExamId = null;

      if (unit != null) {
        _titles = _allOneLinerExams
            .where((e) =>
                e['subject'] == _selectedSubject &&
                (e['unit']?.toString() ?? '1') == unit)
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
    });
  }

  void _onTitleChanged(String? title) {
    setState(() {
      _selectedTitle = title;
      if (title != null && _selectedSubject != null && _selectedUnit != null) {
        try {
          final exam = _allOneLinerExams.firstWhere((e) =>
              e['subject'] == _selectedSubject &&
              (e['unit']?.toString() ?? '1') == _selectedUnit &&
              (e['title']?.toString() ?? 'Untitled Exam') == title);
          _selectedExamId = exam['_id'];
        } catch (e) {
          _selectedExamId = null;
        }
      }
    });
  }

  Future<void> _startExam() async {
    if (_selectedExamId == null) {
      CustomToast.showError(context, "Please select all details");
      return;
    }

    if (!await GuestUtils.canGuestAccessExam(context)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneLinerInstructionScreen(
          subject: _selectedSubject!,
          unit: _selectedUnit!,
          title: _selectedTitle!,
          examId: _selectedExamId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "One-Liner Exam",
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OneLinerHistoryScreen()),
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
                      onPressed: _selectedExamId == null ? null : _startExam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
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
