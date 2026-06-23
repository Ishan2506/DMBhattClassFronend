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
            _updateUnitsAndTitles();
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

  void _updateUnitsAndTitles() {
    List<String> units = [];
    List<String> titles = [];

    final filtered = _selectedSubject == null
        ? _allExams
        : _allExams.where((t) => t['subject'].toString() == _selectedSubject).toList();

    units = filtered.map((e) => e['unit'].toString()).toSet().toList();

    final unitFiltered = _selectedUnit == null
        ? filtered
        : filtered.where((t) => t['unit'].toString() == _selectedUnit).toList();

    titles = unitFiltered.map((e) => e['title']?.toString() ?? e['unit']?.toString() ?? '').where((t) => t.isNotEmpty).toSet().toList();

    setState(() {
      _units = units;
      _titles = titles;
      if (!_units.contains(_selectedUnit)) _selectedUnit = null;
      if (!_titles.contains(_selectedTitle)) _selectedTitle = null;
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
                const Spacer(),
                if (_filteredExams.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _startExam(_filteredExams[0]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
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
                  )
                else
                  Expanded(child: _buildEmpty(isDark)),
              ],
            ),
    );
  }

  Widget _buildSubjectFilter(Color primary, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A2340) : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          CustomDropdown<String>(
            labelText: "Subject",
            hintText: "All Subjects",
            value: _selectedSubject,
            items: _subjects,
            itemLabelBuilder: (String item) => item,
            onChanged: (val) {
              setState(() {
                _selectedSubject = val;
                _updateUnitsAndTitles();
              });
            },
          ),
          const SizedBox(height: 12),
          CustomDropdown<String>(
            labelText: "Unit",
            hintText: "All Units",
            value: _selectedUnit,
            items: _units,
            itemLabelBuilder: (String item) => item,
            onChanged: (val) {
              setState(() {
                _selectedUnit = val;
                _updateUnitsAndTitles();
              });
            },
          ),
          const SizedBox(height: 12),
          CustomDropdown<String>(
            labelText: "Exam Title",
            hintText: "All Titles",
            value: _selectedTitle,
            items: _titles,
            itemLabelBuilder: (String item) => item,
            onChanged: (val) {
              setState(() {
                _selectedTitle = val;
              });
            },
          ),
        ],
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
