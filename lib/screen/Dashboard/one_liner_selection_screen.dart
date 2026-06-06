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
import 'package:google_fonts/google_fonts.dart';

class OneLinerSelectionScreen extends StatefulWidget {
  const OneLinerSelectionScreen({super.key});

  @override
  State<OneLinerSelectionScreen> createState() => _OneLinerSelectionScreenState();
}

class _OneLinerSelectionScreenState extends State<OneLinerSelectionScreen> {
  List<dynamic> _allOneLinerExams = [];
  bool _isLoading = true;

  // Subject Filter
  String? _selectedSubject;
  List<String> _subjects = [];

  List<String> _takenExamIds = [];
  bool _isPaid = false;
  int _oneLinerCount = 0;

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
            _takenExamIds = results
                .where((e) => e['examId'] != null)
                .map((e) => e['examId'].toString())
                .toList();
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
    });
  }

  List<dynamic> get _filteredExams {
    if (_selectedSubject == null) return _allOneLinerExams;
    return _allOneLinerExams.where((e) => e['subject'] == _selectedSubject).toList();
  }

  bool _isTaken(dynamic exam) => _takenExamIds.contains(exam['_id'].toString());

  Future<void> _startExamFromCard(dynamic exam) async {
    if (!await GuestUtils.canGuestAccessExam(context, 'ONELINER')) return;

    if (!_isPaid && _oneLinerCount >= 1) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Limit Reached",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "You have already used your 1 free attempt for One-Liner Exams. "
            "Please upgrade your plan for unlimited access.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UpgradePlanScreen())).then((_) {
                  _fetchOneLinerExams();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              "You have already performed this exam. Students can only take each exam once."),
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

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneLinerInstructionScreen(
          subject: exam['subject'] ?? 'Exam',
          unit: exam['unit']?.toString() ?? '1',
          title: exam['title'] ?? 'Exam',
          examId: exam['_id'],
        ),
      ),
    ).then((_) => _fetchOneLinerExams());
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

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
          : Column(
              children: [
                _buildSubjectFilter(primary, isDark),
                Expanded(
                  child: _filteredExams.isEmpty
                      ? _buildEmpty(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          itemCount: _filteredExams.length,
                          itemBuilder: (context, index) {
                            final exam = _filteredExams[index];
                            return _buildExamCard(exam, theme, isDark);
                          },
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
        labelText: "Subject",
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
          Icon(Icons.quiz_outlined,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No exams available",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              )),
        ],
      ),
    );
  }

  Widget _buildExamCard(dynamic exam, ThemeData theme, bool isDark) {
    final taken = _isTaken(exam);
    final primary = theme.colorScheme.primary;
    final title = exam['title']?.toString().trim().isNotEmpty ?? false
        ? exam['title'].toString()
        : 'Exam';
    final subject = exam['subject']?.toString() ?? '';
    final unit = exam['unit']?.toString() ?? '';
    final marks = exam['totalMarks']?.toString() ?? '0';

    return GestureDetector(
      onTap: () => _startExamFromCard(exam),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2340) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: taken
                ? Colors.green.withOpacity(0.4)
                : (isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        color: taken ? Colors.green : primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subject & Unit
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    unit.isNotEmpty ? "$subject  •  Unit $unit" : subject,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Marks chip
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (marks.isNotEmpty) _chip("$marks Marks", isDark),
                ],
              ),
            ),

            // Bottom row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  const Spacer(),
                  Icon(
                    taken ? Icons.check_circle : Icons.play_circle_outline,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white60 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
