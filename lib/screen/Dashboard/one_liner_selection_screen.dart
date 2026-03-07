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
import 'upgrade_plan_screen.dart';
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
  String? _selectedMarks;

  // Dropdown Options
  List<String> _subjects = [];
  List<String> _units = [];
  List<String> _titles = [];
  List<String> _marksOptions = [];
  List<String> _takenTestTitles = [];
  bool _isPaid = false;
  int _oneLinerCount = 0;

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

      // Always fetch profile for current status and counts
      final profileResponse = await ApiService.getProfile(forceRefresh: true);
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        final profile = profileData['profile'];
        _isPaid = profileData['user']?['isPaid'] ?? false;
        _oneLinerCount = profileData['examCounts']?['oneLinerExam'] ?? 0;
        debugPrint("[DEBUG] One-Liner _isPaid: $_isPaid, _oneLinerCount: $_oneLinerCount");
        userStandard = profile?['std']?.toString();
        userMedium = profile?['medium']?.toString();
      }

      final response = await ApiService.getAllOneLinerExams(
        std: userStandard,
        medium: userMedium,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Fetch history to see which exams are already taken
        try {
          final historyResponse = await ApiService.getDashboardData();
          if (historyResponse.statusCode == 200) {
            final historyData = jsonDecode(historyResponse.body);
            final List<dynamic> results = historyData['examResults'] ?? [];
            _takenTestTitles = results.map((e) => e['title'].toString().toLowerCase()).toList();
          }
        } catch (e) {
          debugPrint("Error fetching dashboard data for one-liner: $e");
        }

        if (mounted) {
          setState(() {
            _allOneLinerExams = data;
            _subjects = _allOneLinerExams
                .map((e) => e['subject']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList();
            // _isPaid and _oneLinerCount were already set but this ensures they trigger a rebuild
            _isLoading = false;
          });
        }

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
      _selectedMarks = null;
      _selectedExamId = null;
      _units = [];
      _titles = [];
      _marksOptions = [];

      if (subject != null) {
        _units = _allOneLinerExams
            .where((e) => e['subject'] == subject)
            .map((e) => e['unit']?.toString() ?? '1')
            .toSet()
            .toList();
      }
    });
  }

  void _onUnitChanged(String? unit) {
    setState(() {
      _selectedUnit = unit;
      _selectedTitle = null;
      _selectedMarks = null;
      _selectedExamId = null;
      _titles = [];
      _marksOptions = [];

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
      }
    });
  }

  void _onTitleChanged(String? title) {
    String? newMarks;
    String? newExamId;
    List<String> newMarksOptions = [];

    if (title != null) {
      final matchingExams = _allOneLinerExams.where((e) =>
          e['subject'] == _selectedSubject &&
          (e['unit']?.toString() ?? '1') == _selectedUnit &&
          (e['title']?.toString() ?? 'Untitled Exam') == title);

      newMarksOptions = matchingExams
          .map((e) => (e['totalMarks'] ?? 20).toString())
          .toSet()
          .toList();
      debugPrint("newMarksOptions: $newMarksOptions");
      if (newMarksOptions.length == 1) {
        newMarks = newMarksOptions.first;
        try {
          final exam = matchingExams.firstWhere((e) => (e['totalMarks'] ?? 20).toString() == newMarks);
          newExamId = exam['_id'];
        } catch (e) {
          newExamId = null;
        }
      }
    }

    setState(() {
      _selectedTitle = title;
      _marksOptions = newMarksOptions;
      _selectedMarks = newMarks;
      _selectedExamId = newExamId;
    });
  }

  void _onMarksChanged(String? marks) {
    setState(() {
      _selectedMarks = marks;
      if (marks != null && _selectedSubject != null && _selectedUnit != null && _selectedTitle != null) {
        try {
          final exam = _allOneLinerExams.firstWhere((e) =>
              e['subject'] == _selectedSubject &&
              (e['unit']?.toString() ?? '1') == _selectedUnit &&
              (e['title']?.toString() ?? 'Untitled Exam') == _selectedTitle &&
              (e['totalMarks'] ?? 20).toString() == marks);
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

    if (!await GuestUtils.canGuestAccessExam(context, 'ONELINER')) return;
    
    if (!_isPaid && _oneLinerCount >= 1) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Limit Reached", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text("You have already used your 1 free attempt for One-Liner Exams. Please upgrade your plan for unlimited access."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Later", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UpgradePlanScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Upgrade Now", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    if (_takenTestTitles.contains(_selectedTitle?.toLowerCase())) {
      if (mounted) {
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
      }
      return;
    }

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
    ).then((_) => _fetchOneLinerExams());
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
                  blankVerticalSpace16,
                  CustomDropdown<String>(
                    labelText: "Marks",
                    hintText: "Select Marks",
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
