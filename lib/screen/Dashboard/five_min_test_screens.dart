import 'dart:async';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Screen 1: Selection ---
class FiveMinTestSelectionScreen extends StatefulWidget {
  const FiveMinTestSelectionScreen({super.key});

  @override
  State<FiveMinTestSelectionScreen> createState() => _FiveMinTestSelectionScreenState();
}

class _FiveMinTestSelectionScreenState extends State<FiveMinTestSelectionScreen> {
  String? _selectedUnit;
  String? _selectedSubject;
  // Standard can be assumed or added if needed, sticking to StartExamForm pattern
  
  final List<String> _subjects = ['Math', 'Science', 'English', 'Account'];
  final List<String> _units = ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "5 Min Test - Select"),
      body: Padding(
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
              onChanged: (value) => setState(() => _selectedSubject = value),
            ),
            const SizedBox(height: 16),
            CustomDropdown<String>(
              labelText: "Unit / Chapter",
              hintText: "Select Unit",
              value: _selectedUnit,
              items: _units,
              itemLabelBuilder: (String item) => item,
              onChanged: (value) => setState(() => _selectedUnit = value),
            ),
            const Spacer(),
            CustomFilledButton(
              label: "Next",
              onPressed: () {
                if (_selectedSubject != null && _selectedUnit != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FiveMinTestInstructionScreen(
                        subject: _selectedSubject!,
                        unit: _selectedUnit!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select all fields")),
                  );
                }
              },
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

  const FiveMinTestInstructionScreen({super.key, required this.subject, required this.unit});

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
             _buildInstructionItem("The quiz contains 5 questions (MCQ/True-False)."),
             _buildInstructionItem("Do your best!"),
            const Spacer(),
            CustomFilledButton(
              label: "Start Study Timer",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FiveMinStudyScreen(subject: subject, unit: unit),
                  ),
                );
              },
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

  const FiveMinStudyScreen({super.key, required this.subject, required this.unit});

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
                     builder: (context) => const FiveMinQuizScreen(),
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
                    "Here is the summary of ${widget.unit} for ${widget.subject}. \n\n"
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n"
                    "• Key Concept 1: Description of key concept.\n"
                    "• Key Concept 2: Formulas and definitions.\n"
                    "• Key Concept 3: Important dates and events.\n\n"
                     "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                    style: GoogleFonts.poppins(fontSize: 15, height: 1.6),
                  ),
                  // Placeholder for more content
                ],
              ),
            ),
          ),
          
          Padding(
             padding: const EdgeInsets.all(24),
             child: CustomFilledButton(
               label: "Start Quiz (5 Questions)",
               onPressed: _canProceed ? () {
                 Navigator.pushReplacement(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const FiveMinQuizScreen(),
                   ),
                 );
               } : null, // Disabled until timer ends
             ),
          ),
        ],
      ),
    );
  }
}

// --- Screen 4: Quiz ---
class FiveMinQuizScreen extends StatefulWidget {
  const FiveMinQuizScreen({super.key});

  @override
  State<FiveMinQuizScreen> createState() => _FiveMinQuizScreenState();
}

class _FiveMinQuizScreenState extends State<FiveMinQuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {}; // Track user answers

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'The overview mentioned Key Concept 1. Is this True?',
      'type': 'TF', // True/False
      'options': ['True', 'False'],
      'answer': 'True',
      'correctAnswer': 'True' // Added for consistency with result screen
    },
    {
       'question': 'What represents Key Concept 2?',
       'type': 'MCQ',
       'options': ['Formulas', 'History', 'Geography', 'Sports'],
       'answer': 'Formulas',
       'correctAnswer': 'Formulas'
    },
    {
      'question': 'Is studying for 5 minutes helpful?',
      'type': 'TF',
      'options': ['True', 'False'],
      'answer': 'True',
      'correctAnswer': 'True'
    },
     {
       'question': 'Which screen comes after Instruction?',
       'type': 'MCQ',
       'options': ['Result', 'Overview', 'Home', 'Settings'],
       'answer': 'Overview',
       'correctAnswer': 'Overview'
    },
    {
      'question': 'We are testing the "5 Min Test" feature.',
      'type': 'TF',
      'options': ['True', 'False'],
      'answer': 'True',
      'correctAnswer': 'True'
    },
  ];

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

    for (int i = 0; i < _questions.length; i++) {
       final userAnswer = _selectedAnswers[i];
       if (userAnswer == null) {
         skipped++;
       } else if (userAnswer == _questions[i]['correctAnswer']) {
         correct++;
       } else {
         wrong++;
       }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          totalQuestions: _questions.length,
          correctAnswers: correct,
          wrongAnswers: wrong,
          skippedAnswers: skipped,
          questions: _questions,
          selectedAnswers: _selectedAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final selectedOption = _selectedAnswers[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Use CustomAppBar to match app theme
      appBar: CustomAppBar(
        title: "Rapid Quiz",
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber), // Amber progress for visibility
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade800,
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
                    colors: [Colors.blue.shade800, Colors.indigo.shade900], // Consistent with App Theme
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      question['question'],
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
                  itemCount: (question['options'] as List<String>).length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = (question['options'] as List<String>)[index];
                    final isSelected = selectedOption == option;

                    return InkWell(
                      onTap: () => _selectAnswer(option),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
                            width: isSelected ? 2 : 1
                          ),
                          boxShadow: [
                             if (!isSelected)
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C...
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey.shade700
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                               Icon(Icons.check_circle, color: Colors.blue.shade700),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Previous / Skip
                   if (_currentQuestionIndex > 0)
                     TextButton(
                       onPressed: () => _navigate(-1),
                       child: Text("Previous", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                     )
                   else
                      TextButton(
                       onPressed: () => _navigate(1), // Skip behaves like Next without selection (handled by map)
                       child: Text("Skip", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                     ),

                   // Next / Finish
                   CustomFilledButton(
                     label: _currentQuestionIndex == _questions.length - 1 ? "Finish" : "Next",
                     onPressed: () => _navigate(1),
                     icon: Icons.arrow_forward_rounded,
                     // Make button smaller or fit
                   ).widthBox(width: 140), // Requires extension or specific width
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension WidthBox on Widget {
   Widget widthBox({required double width}) {
     return SizedBox(width: width, child: this);
   }
}
