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

  List<dynamic> _allExams = [];
  List<String> _subjects = [];
  List<String> _takenExamIds = [];
  bool _isPaid = false;
  int _trueFalseCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userStandard = prefs.getString('std');
      String? userMedium = prefs.getString('medium');

      final profileResponse = await ApiService.getProfile(forceRefresh: true);
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        final profile = profileData['profile'];
        _isPaid = profileData['user']?['isPaid'] ?? false;
        _trueFalseCount = profileData['examCounts']?['trueFalseExam'] ?? 0;
        userStandard = profile?['std']?.toString() ?? userStandard;
        userMedium = profile?['medium']?.toString() ?? userMedium;

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
        std: userStandard,
        medium: userMedium,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _allExams = data;
            _subjects = _allExams
                .map((e) => e['subject'].toString())
                .toSet()
                .toList();
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

  List<dynamic> get _filteredExams {
    if (_selectedSubject == null) return _allExams;
    return _allExams
        .where((t) => t['subject'].toString() == _selectedSubject)
        .toList();
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

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1626) : const Color(0xFFF2F4F8),
      appBar: CustomAppBar(
        title: "True/False Exam",
      ),
      body: _isLoading
          ? const CustomLoader()
          : Column(
              children: [
                _buildSubjectFilter(primary, isDark),
                Expanded(
                  child: _filteredExams.isEmpty
                      ? _buildEmpty(isDark)
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filteredExams.length,
                          itemBuilder: (_, i) => _buildExamCard(
                              _filteredExams[i], theme, isDark),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubjectFilter(Color primary, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A2340) : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: CustomDropdown<String>(
        labelText: "Field (Subject)",
        hintText: "All Subjects",
        value: _selectedSubject,
        items: _subjects,
        itemLabelBuilder: (String item) => item,
        onChanged: (val) {
          setState(() {
            _selectedSubject = val;
          });
        },
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

  Widget _buildExamCard(
      dynamic exam, ThemeData theme, bool isDark) {
    final taken = _isTaken(exam);
    final primary = theme.colorScheme.primary;
    final title = (exam['title']?.toString().trim().isNotEmpty ?? false)
        ? exam['title'].toString()
        : (exam['unit']?.toString() ?? 'True/False Exam');
    final subject = exam['subject']?.toString() ?? '';
    final unit = exam['unit']?.toString() ?? '';
    final board = exam['board']?.toString() ?? '';
    final std = exam['std']?.toString() ??
        exam['standard']?.toString() ?? '';
    final medium = exam['medium']?.toString() ?? '';
    final qCount =
        (exam['questions'] as List?)?.length ?? 0;
    final marks = exam['totalMarks']?.toString() ?? '0';

    return GestureDetector(
      onTap: () => _startExam(exam),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2340) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: taken
                ? Colors.green.withOpacity(0.4)
                : (isDark
                    ? Colors.white10
                    : Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Status badge
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: taken
                          ? Colors.green.withOpacity(0.12)
                          : primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      taken ? "DONE" : "START",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            taken ? Colors.green : primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subject & Unit
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.tag,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "$subject  •  Unit $unit",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white70
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Board / Std / Medium chips
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (board.isNotEmpty) _chip(board, isDark),
                  if (std.isNotEmpty)
                    _chip("Std $std", isDark),
                  if (medium.isNotEmpty)
                    _chip(medium, isDark),
                ],
              ),
            ),

            // Bottom row: question count + marks + action icon
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.help_outline,
                      size: 14,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    "$qCount Questions",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.stars_outlined,
                      size: 14,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    "$marks Marks",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey.shade400,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    taken
                        ? Icons.check_circle
                        : Icons.play_circle_outline,
                    size: 20,
                    color: taken ? Colors.green : primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark
              ? Colors.white60
              : Colors.grey.shade700,
        ),
      ),
    );
  }
}
