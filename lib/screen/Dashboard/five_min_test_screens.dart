import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_five_min_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_history_data.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'upgrade_plan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Screen 1: Selection ---
class FiveMinTestSelectionScreen extends StatefulWidget {
  const FiveMinTestSelectionScreen({super.key});

  @override
  State<FiveMinTestSelectionScreen> createState() =>
      _FiveMinTestSelectionScreenState();
}

class _FiveMinTestSelectionScreenState
    extends State<FiveMinTestSelectionScreen> {
  String? _selectedSubject;

  List<dynamic> _allTests = [];
  List<String> _subjects = [];
  List<String> _takenTestIds = [];
  bool _isPaid = false;
  int _fiveMinTestCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    try {
      final response = await ApiService.getAllFiveMinTests();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final historyResponse = await ApiService.getProfile(forceRefresh: true);
        if (historyResponse.statusCode == 200) {
          final profileData = jsonDecode(historyResponse.body);
          _isPaid = profileData['user']?['isPaid'] ?? false;
          _fiveMinTestCount = profileData['examCounts']?['fiveMinTest'] ?? 0;

          final dashResponse = await ApiService.getDashboardData();
          if (dashResponse.statusCode == 200) {
            final dashData = jsonDecode(dashResponse.body);
            final List<dynamic> results = dashData['examResults'] ?? [];
            _takenTestIds = results.map((e) => e['examId'].toString()).toList();
          }
        }

        if (mounted) {
          setState(() {
            _allTests = data;
            _subjects = _allTests
                .map((e) => e['subject'].toString())
                .toSet()
                .toList();
            _isLoading = false;
          });

          if (_subjects.isEmpty) _showNoTestDialog();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching 5 min tests: $e");
    }
  }

  void _showNoTestDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("No 5 Min Tests Available"),
        content: const Text(
          "No 5 min tests available for your standard. Please try again later.",
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

  List<dynamic> get _filteredTests {
    if (_selectedSubject == null) return _allTests;
    return _allTests
        .where((t) => t['subject'].toString() == _selectedSubject)
        .toList();
  }

  bool _isTaken(dynamic test) =>
      _takenTestIds.contains(test['_id'].toString());

  Future<void> _startTest(dynamic test) async {
    if (!await GuestUtils.canGuestAccessExam(context, 'FIVEMIN')) return;

    if (!_isPaid && _fiveMinTestCount >= 1) {
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
            "You have already used your 1 free attempt for 5-Min Tests. "
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
                    MaterialPageRoute(builder: (_) => UpgradePlanScreen()));
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

    if (_isTaken(test)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Already Taken"),
          content: const Text(
            "You have already performed this test. "
            "Students can only take each test once.",
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
        builder: (_) => FiveMinTestInstructionScreen(
          subject: test['subject'].toString(),
          unit: test['unit'].toString(),
          testData: test,
        ),
      ),
    ).then((_) => _fetchTests());
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
      backgroundColor:
          isDark ? const Color(0xFF0F1626) : const Color(0xFFF2F4F8),
      appBar: CustomAppBar(
        title: "5 Min Test",
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StudentFiveMinHistoryScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : Column(
              children: [
                // ── Subject filter chips ──
                _buildSubjectFilter(primary, isDark),
                // ── Test card list ──
                Expanded(
                  child: _filteredTests.isEmpty
                      ? _buildEmpty(isDark)
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filteredTests.length,
                          itemBuilder: (_, i) => _buildTestCard(
                              _filteredTests[i], theme, isDark),
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
          Icon(Icons.quiz_outlined,
              size: 64,
              color:
                  isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No tests available",
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

  Widget _buildTestCard(
      dynamic test, ThemeData theme, bool isDark) {
    final taken = _isTaken(test);
    final primary = theme.colorScheme.primary;
    final title = (test['title']?.toString().trim().isNotEmpty ?? false)
        ? test['title'].toString()
        : (test['unit']?.toString() ?? '5 Min Test');
    final subject = test['subject']?.toString() ?? '';
    final unit = test['unit']?.toString() ?? '';
    final board = test['board']?.toString() ?? '';
    final std = test['std']?.toString() ??
        test['standard']?.toString() ?? '';
    final medium = test['medium']?.toString() ?? '';
    final qCount =
        (test['questions'] as List?)?.length ?? 0;

    return GestureDetector(
      onTap: () => _startTest(test),
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

            // Bottom row: question count + action icon
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

// --- Screen 2: Instruction ---
class FiveMinTestInstructionScreen extends StatelessWidget {
  final String subject;
  final String unit;
  final dynamic testData; // Full object containing overview and questions

  const FiveMinTestInstructionScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.testData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: "Instructions"),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              Icons.timer_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              "5 Min Rapid Test",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildInstructionItem(
              "You will have 5 minutes to study the overview.",
            ),
            _buildInstructionItem(
              "After 5 minutes, the 'Start Quiz' button will unlock.",
            ),
            _buildInstructionItem(
              "The quiz contains ${(testData['questions'] as List).length} questions.",
            ),
            _buildInstructionItem("Do your best!"),
            const Spacer(),
            Container(
              width: double.infinity,
              height: S.s48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(S.s12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FiveMinStudyScreen(
                        subject: subject,
                        unit: unit,
                        testData: testData,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(S.s12),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Start Study Timer",
                    style: TextStyle(
                      letterSpacing: 0.5,
                      fontSize: S.s16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }
}

// --- Screen 3: Study / Overview + Timer ---
class FiveMinStudyScreen extends StatefulWidget {
  final String subject;
  final String unit;
  final dynamic testData;

  const FiveMinStudyScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.testData,
  });

  @override
  State<FiveMinStudyScreen> createState() => _FiveMinStudyScreenState();
}

class _FiveMinStudyScreenState extends State<FiveMinStudyScreen> {
  // Timer State
  int _secondsRemaining = 5 * 60; // 5 minutes
  Timer? _timer;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _canProceed = true; // Unlock button
        });
      }
    });
  }

  String get _timerString {
    final minutes = (_secondsRemaining / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Overview: ${widget.unit}",
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FiveMinQuizScreen(
                      subject: widget.subject,
                      unit: widget.unit,
                      testData: widget.testData,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
              child: Text(
                "Skip",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer Widget
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: _canProceed ? Colors.green : Colors.orange,
            alignment: Alignment.center,
            child: Text(
              _canProceed
                  ? "Time's Up! You can start the test."
                  : "Study Time Remaining: $_timerString",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chapter Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.testData['overview'] ?? "No overview available.",
                    style: GoogleFonts.poppins(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              height: S.s48,
              decoration: BoxDecoration(
                gradient: _canProceed
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null, // No gradient when disabled
                color: _canProceed
                    ? null
                    : Colors.grey.shade300, // Grey color when disabled
                borderRadius: BorderRadius.circular(S.s12),
                boxShadow: _canProceed
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: _canProceed
                    ? () async {
                        CustomLoader.show(context);
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (context.mounted) {
                          CustomLoader.hide(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FiveMinQuizScreen(
                                subject: widget.subject,
                                unit: widget.unit,
                                testData: widget.testData,
                              ),
                            ),
                          );
                        }
                      }
                    : null, // Functionally disabled
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor:
                      Colors.transparent, // Ensure container color shows
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(S.s12),
                  ),
                ),
                child: Text(
                  "Start Quiz (${(widget.testData['questions'] as List).length} Questions)",
                  style: TextStyle(
                    letterSpacing: 0.5,
                    fontSize: S.s16,
                    color: _canProceed ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Screen 4: Quiz ---
class FiveMinQuizScreen extends StatefulWidget {
  final String subject;
  final String unit;
  final dynamic testData;

  const FiveMinQuizScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.testData,
  });

  @override
  State<FiveMinQuizScreen> createState() => _FiveMinQuizScreenState();
}

class _FiveMinQuizScreenState extends State<FiveMinQuizScreen>
    with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {}; // Track user answers
  final Map<int, TextEditingController> _textControllers =
      {}; // Controllers for Fill in the Blanks
  List<dynamic> _questions = [];

  int _violationCount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Safely cast or assume structure
    _questions = widget.testData['questions'] ?? [];

    // Initialize controllers for Fill in the Blanks
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i]['type'] == 'Fill in the Blanks') {
        _textControllers[i] = TextEditingController();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _handleViolation("You left the app during the exam.");
    }
  }

  Future<void> _handleViolation(String message) async {
    if (_isSubmitting) return;

    _violationCount++;
    try {
      await ApiService.updateViolationCount(
        examId: widget.testData['_id'].toString(),
        examType: 'FIVEMIN',
      );
    } catch (e) {
      debugPrint("Error updating violation: $e");
    }

    if (_violationCount >= 2) {
      if (mounted) {
        CustomToast.showError(
          context,
          "Multiple violations detected. Auto-submitting exam.",
        );
      }
      _finishQuiz();
    } else {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text(
              "Warning",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text(
              "$message\n\nReturning or leaving the app again will result in automatic submission of the exam.",
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("I Understand"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectAnswer(String option) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = option;
    });
  }

  void _navigate(int direction) {
    if (direction == 1) {
      // Next
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() => _currentQuestionIndex++);
      } else {
        _finishQuiz();
      }
    } else {
      // Previous
      if (_currentQuestionIndex > 0) {
        setState(() => _currentQuestionIndex--);
      }
    }
  }

  Future<void> _finishQuiz() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    // Prepare questions list for Result Screen format
    List<Map<String, dynamic>> mappedQuestions = [];

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];

      // Construct options list based on type
      List<String> options = [];
      if (q['type']?.toString().trim().toUpperCase() == 'MCQ' ||
          q['type'] == null) {
        if (q['optionA'] != null && q['optionA'].toString().trim().isNotEmpty)
          options.add(q['optionA'].toString().trim());
        if (q['optionB'] != null && q['optionB'].toString().trim().isNotEmpty)
          options.add(q['optionB'].toString().trim());
        if (q['optionC'] != null && q['optionC'].toString().trim().isNotEmpty)
          options.add(q['optionC'].toString().trim());
        if (q['optionD'] != null && q['optionD'].toString().trim().isNotEmpty)
          options.add(q['optionD'].toString().trim());
      } else if (q['type']?.toString().trim().toUpperCase() == 'TRUE/FALSE' ||
          q['type']?.toString().trim().toUpperCase() == 'TF' ||
          q['type']?.toString().trim().toUpperCase() == 'T/F' ||
          q['type'] == 'True/False') {
        options.add(
          (q['optionA'] != null && q['optionA'].toString().trim().isNotEmpty)
              ? q['optionA'].toString().trim()
              : "True",
        );
        options.add(
          (q['optionB'] != null && q['optionB'].toString().trim().isNotEmpty)
              ? q['optionB'].toString().trim()
              : "False",
        );
      } else {
        // Fallback for other types or implicit TF
        if (q['optionA'] != null && q['optionA'].toString().trim().isNotEmpty)
          options.add(q['optionA'].toString().trim());
        if (q['optionB'] != null && q['optionB'].toString().trim().isNotEmpty)
          options.add(q['optionB'].toString().trim());
      }

      final userAnswer = _selectedAnswers[i];
      final correctAnswer = q['correctAnswer'];

      if (userAnswer == null || userAnswer.trim().isEmpty) {
        skipped++;
      } else if (userAnswer.trim().toLowerCase() ==
          correctAnswer.toString().trim().toLowerCase()) {
        correct++;
      } else {
        wrong++;
      }

      mappedQuestions.add({
        'question': q['question'] ?? '',
        'answers': options,
        'correctAnswer': correctAnswer ?? '',
      });
    }

    Future<void> _submitAndNavigate() async {
      try {
        CustomLoader.show(context);
        // Token managed internally
        String finalTitle = widget.testData['title'] ?? '';
        if (finalTitle.trim().isEmpty) finalTitle = widget.unit;
        if (finalTitle.trim().isEmpty) finalTitle = 'Untitled Test';

        bool isGuest = await GuestUtils.isGuest();
        if (!isGuest) {
          await ApiService.submitFiveMinTestResult(
            examId: widget.testData['_id'].toString(),
            title: finalTitle,
            obtainedMarks: correct,
            totalMarks: _questions.length,
            isOnline: false,
            type: 'QUIZ',
            violationCount: _violationCount,
          );
        }

        // Increment local guest counter if applicable
        if (isGuest) {
          await GuestUtils.incrementGuestExamCount('FIVEMIN');
        }
      } catch (e) {
        debugPrint("Error submitting 5 min result: $e");
      }

      if (mounted) {
        CustomLoader.hide(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultScreen(
              totalQuestions: _questions.length,
              correctAnswers: correct,
              wrongAnswers: wrong,
              skippedAnswers: skipped,
              questions: mappedQuestions,
              selectedAnswers: _selectedAnswers,
              subject: widget.subject,
              unit: widget.unit,
            ),
          ),
        );
      }
    }

    await _submitAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No questions in this test.")),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final selectedOption = _selectedAnswers[_currentQuestionIndex];

    // Build options list dynamically
    List<String> options = [];
    if (question['type']?.toString().trim().toUpperCase() == 'MCQ' ||
        question['type'] == null) {
      if (question['optionA'] != null &&
          question['optionA'].toString().trim().isNotEmpty)
        options.add(question['optionA'].toString().trim());
      if (question['optionB'] != null &&
          question['optionB'].toString().trim().isNotEmpty)
        options.add(question['optionB'].toString().trim());
      if (question['optionC'] != null &&
          question['optionC'].toString().trim().isNotEmpty)
        options.add(question['optionC'].toString().trim());
      if (question['optionD'] != null &&
          question['optionD'].toString().trim().isNotEmpty)
        options.add(question['optionD'].toString().trim());
    } else if (question['type']?.toString().trim().toUpperCase() ==
            'TRUE/FALSE' ||
        question['type']?.toString().trim().toUpperCase() == 'TF' ||
        question['type']?.toString().trim().toUpperCase() == 'T/F') {
      options.add(
        (question['optionA'] != null &&
                question['optionA'].toString().trim().isNotEmpty)
            ? question['optionA'].toString().trim()
            : "True",
      );
      options.add(
        (question['optionB'] != null &&
                question['optionB'].toString().trim().isNotEmpty)
            ? question['optionB'].toString().trim()
            : "False",
      );
    } else {
      // Fallback
      if (question['optionA'] != null &&
          question['optionA'].toString().trim().isNotEmpty)
        options.add(question['optionA'].toString().trim());
      if (question['optionB'] != null &&
          question['optionB'].toString().trim().isNotEmpty)
        options.add(question['optionB'].toString().trim());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleViolation("Back navigation is not allowed during the exam.");
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        // Use CustomAppBar to match app theme
        appBar: CustomAppBar(
          title: "Rapid Quiz",
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ), // Dynamic progress
              minHeight: 6,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question Count Badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Question Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ], // Consistent with App Theme
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        question['question'] ?? "",
                        style: GoogleFonts.poppins(
                          fontSize: 18, // Adjusted font size
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // Reduced spacing

                if (question['type'] == 'Fill in the Blanks')
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Answer:",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller:
                                  _textControllers[_currentQuestionIndex],
                              onChanged: (val) {
                                _selectedAnswers[_currentQuestionIndex] = val;
                              },
                              decoration: InputDecoration(
                                hintText: "Type your answer here...",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = selectedOption == option;

                        return InkWell(
                          onTap: () => _selectAnswer(option),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentQuestionIndex > 0)
                      TextButton.icon(
                        onPressed: () => _navigate(-1),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.grey.shade700,
                        ),
                        label: Text(
                          "Previous",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    ElevatedButton(
                      onPressed: () => _navigate(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentQuestionIndex == _questions.length - 1
                            ? "Finish"
                            : "Next",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
