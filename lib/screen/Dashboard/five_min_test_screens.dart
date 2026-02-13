import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_five_min_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_history_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Screen 1: Selection ---
class FiveMinTestSelectionScreen extends StatefulWidget {
  const FiveMinTestSelectionScreen({super.key});

  @override
  State<FiveMinTestSelectionScreen> createState() => _FiveMinTestSelectionScreenState();
}

class _FiveMinTestSelectionScreenState extends State<FiveMinTestSelectionScreen> {
  String? _selectedUnit;
  String? _selectedSubject;
  String? _selectedTitle;
  
  List<dynamic> _allTests = [];
  List<String> _subjects = [];
  List<String> _units = [];
  List<String> _titles = [];
  List<String> _takenTestTitles = [];
  
  bool _isLoading = true;
  dynamic _selectedTest; // The full test object from API

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
        
        // Fetch history to check for taken tests
        // Fetch history to check for taken tests
        // Token managed internally
        final historyResponse = await ApiService.getDashboardData();
        if (historyResponse.statusCode == 200) {
             final historyData = jsonDecode(historyResponse.body);
             final List<dynamic> results = historyData['examResults'] ?? [];
             _takenTestTitles = results.map((e) => e['title'].toString().toLowerCase()).toList();
        }

        if (mounted) {
           setState(() {
            _allTests = data;
            // Extract unique subjects
            _subjects = _allTests.map((e) => e['subject'].toString()).toSet().toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
        debugPrint("Failed to fetch 5 min tests: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching 5 min tests: $e");
    }
  }

  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedUnit = null;
      _selectedTitle = null;
      _selectedTest = null;
      if (subject != null) {
        _units = _allTests
            .where((t) => t['subject'] == subject)
            .map((t) => t['unit'].toString())
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
      _selectedTest = null;
      if (unit != null && _selectedSubject != null) {
        _titles = _allTests
            .where((t) => t['subject'] == _selectedSubject && t['unit'] == unit)
            .map((t) => t['title']?.toString() ?? 'Untitled Test')
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
          _selectedTest = _allTests.firstWhere(
            (t) => t['subject'] == _selectedSubject && 
                   t['unit'] == _selectedUnit &&
                   (t['title']?.toString() ?? 'Untitled Test') == title
          );
        } catch (e) {
          _selectedTest = null;
        }
      } else {
        _selectedTest = null;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: "5 Min Test - Select",
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentFiveMinHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _allTests.isEmpty 
           ? const Center(child: Text("No tests available."))
           : Padding(
            padding: const EdgeInsets.all(24),
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
                  labelText: "Unit / Chapter",
                  hintText: "Select Unit",
                  value: _selectedUnit,
                  items: _units,
                  itemLabelBuilder: (String item) => item,
                  onChanged: _onUnitChanged,
                ),
                const SizedBox(height: 16),
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
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
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
                    onPressed: _selectedTest != null 
                        ? () {
                            if (_takenTestTitles.contains(_selectedTitle?.toLowerCase())) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Already Taken"),
                                  content: const Text("You have already performed this test. Students can only take each test once."),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FiveMinTestInstructionScreen(
                                  subject: _selectedSubject!,
                                  unit: _selectedUnit!,
                                  testData: _selectedTest,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(S.s12)),
                    ),
                    child: Text(
                      "Next",
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

// --- Screen 2: Instruction ---
class FiveMinTestInstructionScreen extends StatelessWidget {
  final String subject;
  final String unit;
  final dynamic testData; // Full object containing overview and questions

  const FiveMinTestInstructionScreen({super.key, required this.subject, required this.unit, required this.testData});

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
             Icon(Icons.timer_outlined, size: 80, color: theme.colorScheme.primary),
             const SizedBox(height: 24),
            Text(
              "5 Min Rapid Test",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
             _buildInstructionItem("You will have 5 minutes to study the overview."),
             _buildInstructionItem("After 5 minutes, the 'Start Quiz' button will unlock."),
             _buildInstructionItem("The quiz contains ${(testData['questions'] as List).length} questions."),
             _buildInstructionItem("Do your best!"),
            const Spacer(),
            Container(
              width: double.infinity,
              height: S.s48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
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
                      borderRadius: BorderRadius.circular(S.s12)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Start Study Timer",
                    style: TextStyle(
                        letterSpacing: 0.5,
                        fontSize: S.s16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
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

  const FiveMinStudyScreen({super.key, required this.subject, required this.unit, required this.testData});

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              child: Text("Skip", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
              _canProceed ? "Time's Up! You can start the test." : "Study Time Remaining: $_timerString",
              style: GoogleFonts.poppins(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 16
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
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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
                       colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     )
                   : null, // No gradient when disabled
                 color: _canProceed ? null : Colors.grey.shade300, // Grey color when disabled
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
                 onPressed: _canProceed ? () {
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
                 } : null, // Functionally disabled
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.transparent,
                   shadowColor: Colors.transparent,
                   disabledBackgroundColor: Colors.transparent, // Ensure container color shows
                   shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(S.s12)),
                 ),
                 child: Text(
                   "Start Quiz (${(widget.testData['questions'] as List).length} Questions)",
                   style: TextStyle(
                       letterSpacing: 0.5,
                       fontSize: S.s16,
                       color: _canProceed ? Colors.white : Colors.grey.shade600,
                       fontWeight: FontWeight.bold),
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
  
  const FiveMinQuizScreen({super.key, required this.subject, required this.unit, required this.testData});

  @override
  State<FiveMinQuizScreen> createState() => _FiveMinQuizScreenState();
}

class _FiveMinQuizScreenState extends State<FiveMinQuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {}; // Track user answers
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    // Safely cast or assume structure
    _questions = widget.testData['questions'] ?? [];
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
  
  void _finishQuiz() {
    int correct = 0;
    int wrong = 0;
    int skipped = 0;
    
    // Prepare questions list for Result Screen format
    List<Map<String, dynamic>> mappedQuestions = [];

    for (int i = 0; i < _questions.length; i++) {
       final q = _questions[i];
       
       // Construct options list based on type
       List<String> options = [];
       if (q['type'] == 'MCQ' || q['type'] == null) {
          if (q['optionA'] != null) options.add(q['optionA']);
          if (q['optionB'] != null) options.add(q['optionB']);
          if (q['optionC'] != null) options.add(q['optionC']);
          if (q['optionD'] != null) options.add(q['optionD']);
       } else {
         // TF
          if (q['optionA'] != null) options.add(q['optionA']);
          if (q['optionB'] != null) options.add(q['optionB']);
       }

       final userAnswer = _selectedAnswers[i];
       final correctAnswer = q['correctAnswer'];

       if (userAnswer == null) {
         skipped++;
       } else if (userAnswer == correctAnswer) {
         correct++;
       } else {
         wrong++;
       }
       
       mappedQuestions.add({
         'question': q['question'],
         'answers': options,
         'correctAnswer': correctAnswer
       });
    }

    Future<void> _submitAndNavigate() async {
      try {
        // Token managed internally
        await ApiService.submitExamResult(
          examId: widget.testData['_id'],
          title: widget.testData['title'] ?? widget.unit,
          obtainedMarks: correct,
          totalMarks: _questions.length,
          isOnline: false,
        );
      } catch (e) {
        debugPrint("Error submitting 5 min result: $e");
      }

      if (mounted) {
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

    _submitAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text("No questions in this test.")));
    }
    
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final selectedOption = _selectedAnswers[_currentQuestionIndex];
    
    // Build options list dynamically
    List<String> options = [];
    if (question['type'] == 'MCQ' || question['type'] == null) {
        if (question['optionA'] != null) options.add(question['optionA']);
        if (question['optionB'] != null) options.add(question['optionB']);
        if (question['optionC'] != null) options.add(question['optionC']);
        if (question['optionD'] != null) options.add(question['optionD']);
    } else {
        if (question['optionA'] != null) options.add(question['optionA']);
        if (question['optionB'] != null) options.add(question['optionB']);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Use CustomAppBar to match app theme
      appBar: CustomAppBar(
        title: "Rapid Quiz",
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary), // Dynamic progress
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
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
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)], // Consistent with App Theme
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
              
              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selectedOption == option;

                    return InkWell(
                      onTap: () => _selectAnswer(option),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
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
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: isSelected ? theme.colorScheme.primary : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                      icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                      label: Text("Previous", style: TextStyle(color: Colors.grey.shade700)),
                    )
                  else 
                    const SizedBox.shrink(),

                  ElevatedButton(
                    onPressed: () => _navigate(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_currentQuestionIndex == _questions.length - 1 ? "Finish" : "Next"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
