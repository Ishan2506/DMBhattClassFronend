import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/true_false_instruction_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/true_false_history_screen.dart';
import 'upgrade_plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrueFalseSelectionScreen extends StatefulWidget {
  const TrueFalseSelectionScreen({super.key});

  @override
  State<TrueFalseSelectionScreen> createState() => _TrueFalseSelectionScreenState();
}

class _TrueFalseSelectionScreenState extends State<TrueFalseSelectionScreen> {
  String? _selectedSubject;
  String? _selectedUnit;
  String? _selectedTitle;

  List<dynamic> _allExams = [];
  List<String> _subjects = [];
  List<String> _units = [];
  List<String> _titles = [];
  List<String> _takenExamIds = [];
  bool _isPaid = false;
  int _trueFalseCount = 0;
  bool _isLoading = true;

  String? _userStandard;
  String? _userMedium;
  String? _userStream;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userStandard = prefs.getString('std');
      _userMedium = prefs.getString('medium');
      _userStream = prefs.getString('stream');

      final profileResponse = await ApiService.getProfile(forceRefresh: true);
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        final profile = profileData['profile'];
        _isPaid = profileData['user']?['isPaid'] ?? false;
        _trueFalseCount = profileData['examCounts']?['trueFalseExam'] ?? 0;
        _userStandard = profile?['std']?.toString() ?? _userStandard;
        _userMedium = profile?['medium']?.toString() ?? _userMedium;
        _userStream = profile?['stream']?.toString() ?? _userStream;

        // Backward compatibility: If the DB has "11 Science", split it.
        if (_userStandard != null && _userStandard!.contains(' ')) {
           final parts = _userStandard!.split(' ');
           _userStandard = parts[0];
           if (_userStream == null || _userStream == '-' || _userStream!.isEmpty) {
               _userStream = parts.skip(1).join(' ');
           }
        }

        final dashResponse = await ApiService.getDashboardData();
        if (dashResponse.statusCode == 200) {
          final dashData = jsonDecode(dashResponse.body);
          final List<dynamic> results = dashData['examResults'] ?? [];
          _takenExamIds = results
              .where((e) => e['type'] == 'TRUE_FALSE' && e['examId'] != null)
              .map((e) => e['examId'].toString())
              .toList();
        }
      }

      final response = await ApiService.getAllTrueFalseExams(
        std: _userStandard,
        medium: _userMedium,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _allExams = data.where((e) {
              final examStream = e['stream']?.toString();
              
              // Match Stream if Std is 11 or 12
              if (_userStandard != null) {
                final numMatch = RegExp(r'\d+').firstMatch(_userStandard!);
                int stdNum = 0;
                if (numMatch != null) {
                   stdNum = int.tryParse(numMatch.group(0) ?? '0') ?? 0;
                }
                if (stdNum >= 11) {
                   if (_userStream != null && examStream != null && examStream != _userStream && examStream.isNotEmpty && examStream != "-") return false;
                }
              }
              return true;
            }).toList();

            _subjects = _allExams
                .map((e) => e['subject'].toString())
                .toSet()
                .toList();
            _units = [];
            _titles = [];
            _isLoading = false;
          });

          if (_subjects.isEmpty) _showNoExamDialog();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching true/false exams: $e");
    }
  }

  void _showNoExamDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("No Exams Available"),
        content: const Text(
          "No True/False exams available for your standard. Please try again later.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedUnit = null;
      _selectedTitle = null;
      _units = [];
      _titles = [];

      if (subject != null) {
        _units = _allExams
            .where((ex) => ex['subject'] == subject)
            .map((ex) => ex['unit']?.toString() ?? '1')
            .toSet()
            .toList();
      }
    });
  }

  void _onUnitChanged(String? unit) {
    String? newTitle;
    List<String> newTitles = [];

    if (unit != null) {
      newTitles = _allExams
          .where((ex) =>
              ex['subject'] == _selectedSubject &&
              (ex['unit']?.toString() ?? '1') == unit)
          .map((ex) => ex['title']?.toString() ?? ex['unit']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();

      if (newTitles.length == 1) {
        newTitle = newTitles.first;
      }
    }

    setState(() {
      _selectedUnit = unit;
      _titles = newTitles;
      _selectedTitle = null;
    });

    if (newTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onTitleChanged(newTitle);
        }
      });
    }
  }

  void _onTitleChanged(String? title) {
    setState(() {
      _selectedTitle = title;
    });
  }

  List<dynamic> get _filteredExams {
    var result = _allExams;
    if (_selectedSubject != null) {
      result = result.where((t) => t['subject'].toString() == _selectedSubject).toList();
    }
    if (_selectedUnit != null) {
      result = result.where((t) => t['unit'].toString() == _selectedUnit).toList();
    }
    if (_selectedTitle != null) {
      result = result.where((t) => (t['title']?.toString() ?? t['unit']?.toString() ?? '') == _selectedTitle).toList();
    }
    return result;
  }

  bool _isTaken(dynamic exam) =>
      _takenExamIds.contains(exam['_id'].toString());

  Future<void> _startExam(dynamic exam) async {
    if (!await GuestUtils.canGuestAccessExam(context, 'TRUEFALSE')) return;

    if (_isTaken(exam)) {
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

    if (!_isPaid && _trueFalseCount >= 1) {
      if (!mounted) return;
      final theme = Theme.of(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Limit Reached",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "You have already used your 1 free attempt for True/False Exams. "
            "Please upgrade your plan for unlimited access.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Later", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UpgradePlanScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Upgrade Now",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (_isTaken(exam)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Already Taken"),
          content: const Text(
            "You have already performed this exam. "
            "Students can only take each exam once.",
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    CustomLoader.show(context);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    CustomLoader.hide(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrueFalseInstructionScreen(
          subject: exam['subject'].toString(),
          unit: exam['unit']?.toString() ?? '1',
          title: exam['title']?.toString() ?? 'True/False Exam',
          examId: exam['_id'].toString(),
        ),
      ),
    ).then((_) => _fetchExams());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final examSelected = _selectedTitle != null && _filteredExams.isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1626) : const Color(0xFFF2F4F8),
      appBar: CustomAppBar(
        title: "True/False Exam",
      ),
      body: _isLoading
          ? const CustomLoader()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomDropdown<String>(
                    labelText: "Subject",
                    hintText: "Select Subject",
                    value: _selectedSubject,
                    items: _subjects,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onSubjectChanged,
                  ),
                  const SizedBox(height: 16),
                  CustomDropdown<String>(
                    labelText: "Unit",
                    hintText: "Select Unit",
                    value: _selectedUnit,
                    items: _units,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onUnitChanged,
                  ),
                  const SizedBox(height: 16),
                  CustomDropdown<String>(
                    labelText: "Exam Title",
                    hintText: "Select Title",
                    value: _selectedTitle,
                    items: _titles,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onTitleChanged,
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: !examSelected
                          ? null
                          : LinearGradient(
                              colors: [
                                primary,
                                primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: !examSelected
                          ? []
                          : [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: !examSelected
                          ? null
                          : () => _startExam(_filteredExams[0]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "START EXAM",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64,
              color:
                  isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No exams available",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark
                    ? Colors.white38
                    : Colors.grey.shade500,
              )),
        ],
      ),
    );
  }
}
