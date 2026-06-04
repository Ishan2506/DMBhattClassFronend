import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_instruction_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'upgrade_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentStartExamForm extends StatefulWidget {
  const StudentStartExamForm({super.key});

  @override
  State<StudentStartExamForm> createState() => _StudentStartExamFormState();
}

class _StudentStartExamFormState extends State<StudentStartExamForm> {
  List<dynamic> _allExams = [];
  bool _isLoading = true;

  // Subject Filter
  String? _selectedSubject;
  List<String> _subjects = [];

  // Unit/Title/Marks filters
  String? _selectedUnit;
  String? _selectedTitle;
  String? _selectedMarks;
  String? _selectedExamId;
  List<String> _titles = [];
  List<String> _units = [];
  List<String> _marksOptions = [];

  List<String> _takenExamIds = [];
  String? _userRole;
  String? _userMedium;
  String? _userStandard;
  String? _userStream;
  bool _isPaid = false;
  int _mainExamCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    final stopwatch = Stopwatch()..start();
    debugPrint("=== START EXAM FETCH TIMING ===");
    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString('user_role');
      final token = ApiService.userToken;

      // Fetch user profile to filter exams
      if (token != null) {
        debugPrint("[Timing] Starting getProfile at ${stopwatch.elapsedMilliseconds}ms");
        final profileResponse = await ApiService.getProfile(forceRefresh: true);
        debugPrint("[Timing] Finished getProfile at ${stopwatch.elapsedMilliseconds}ms");
        
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          final profile = profileData['profile'];
          _isPaid = profileData['user']?['isPaid'] ?? false;
          _mainExamCount = profileData['examCounts']?['mainExam'] ?? 0;
          _userStandard = profile?['std']?.toString();
          // Backward compatibility: If the DB has "11 Science", split it.
          if (_userStandard != null && _userStandard!.contains(' ')) {
             final parts = _userStandard!.split(' ');
             _userStandard = parts[0];
             if (_userStream == null || _userStream == '-' || _userStream!.isEmpty) {
                 _userStream = parts.skip(1).join(' ');
             }
          }
          _userMedium = profile?['medium']?.toString();
          _userStream = profile?['stream']?.toString() ?? _userStream;
        }
      }

      // Fetch history to check for taken tests
      debugPrint("[Timing] Starting getDashboardData at ${stopwatch.elapsedMilliseconds}ms");
      final historyResponse = await ApiService.getDashboardData();
      debugPrint("[Timing] Finished getDashboardData at ${stopwatch.elapsedMilliseconds}ms");
      
      if (historyResponse.statusCode == 200) {
        final historyData = jsonDecode(historyResponse.body);
        final List<dynamic> results = historyData['examResults'] ?? [];
        _takenExamIds = results
            .where((e) => e['examId'] != null)
            .map((e) => e['examId'].toString())
            .toList();
      }

      // Use backend filters if possible, or fetch all and filter locally
      debugPrint("[Timing] Starting getAllExams at ${stopwatch.elapsedMilliseconds}ms");
      final response = await ApiService.getAllExams(
        std: _userStandard,
        medium: _userMedium,
      );
      debugPrint("[Timing] Finished getAllExams at ${stopwatch.elapsedMilliseconds}ms");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          // Filter locally for stream if necessary (backend doesn't support stream filter yet)
          _allExams = data.where((e) {
            final examStream = e['stream']?.toString();
            
            // Match Stream if Std is 11 or 12
            if (_userStandard != null) {
              // Extract numeric part of standard (e.g. from "11 Science" to "11" if user still has old data)
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

          // Extract unique subjects from filtered exams
          _subjects = _allExams
              .map((e) => e['subject'].toString())
              .toSet()
              .toList();
          
          _isLoading = false;
        });
        
        debugPrint("=== END EXAM FETCH TIMING: Total ${stopwatch.elapsedMilliseconds}ms ===");

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
      _selectedTitle = null;
      _selectedMarks = null;
      _selectedExamId = null;
      _titles = [];

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

  List<dynamic> get _filteredExams {
    if (_selectedSubject == null) return _allExams;
    return _allExams.where((e) => e['subject'] == _selectedSubject).toList();
  }

  bool _isTaken(dynamic exam) => _takenExamIds.contains(exam['_id'].toString());

  Future<void> _startExam(dynamic exam) async {
    if (!await GuestUtils.canGuestAccessExam(context, 'REGULAR')) return;

    if (!_isPaid && _mainExamCount >= 1) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Limit Reached",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "You have already used your 1 free attempt for Regular Exams. "
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
                    MaterialPageRoute(builder: (_) => UpgradePlanScreen()));
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
        builder: (context) => ExamInstructionScreen(
          subject: exam['subject'] ?? 'Exam',
          examId: exam['_id'],
          title: exam['title'] ?? 'Exam',
        ),
      ),
    ).then((_) => _fetchExams());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

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
    final duration = exam['duration']?.toString() ?? '';

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

            // Marks & Duration chips
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (marks.isNotEmpty) _chip("$marks Marks", isDark),
                  if (duration.isNotEmpty) _chip("$duration min", isDark),
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
