import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/app_theme.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class McqScreen extends StatefulWidget {
  const McqScreen({super.key});

  @override
  State<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // QuestionID -> OptionIndex
  final List<int> _skippedQuestionIds = [];
  bool _isReviewingSkipped = false;
  
  // Dummy Data
  final List<McqQuestion> _allQuestions = [
    McqQuestion(
      id: 1,
      question: "Arun goes from station A to station B covering a distance of 10 km. Then he returns back from station B to station A again covering a distance of 10 km. Then",
      options: [
        "total distance covered as well as displacement of Arun is 20 km.",
        "total distance covered as well as displacement of Arun is zero.",
        "total distance covered by Arun is 20 km but his displacement is zero.",
        "total displacement of Arun is 20 km but distance covered by him is zero."
      ],
      correctAnswerIndex: 2,
      solution: "Distance is the total path length (10 + 10 = 20 km). Displacement is the shortest distance between initial and final position. Since he returns to A, displacement is 0.",
    ),
    McqQuestion(
      id: 2,
      question: "Which of the following is a scalar quantity?",
      options: [
        "Displacement",
        "Velocity",
        "Force",
        "Distance"
      ],
      correctAnswerIndex: 3,
      solution: "Distance has only magnitude and no direction, so it is a scalar quantity.",
    ),
    McqQuestion(
      id: 3,
      question: "The rate of change of velocity is known as:",
      options: [
        "Speed",
        "Acceleration",
        "Displacement",
        "Momentum"
      ],
      correctAnswerIndex: 1,
      solution: "Acceleration is defined as the rate of change of velocity with respect to time.",
    ),
      McqQuestion(
      id: 4,
      question: "What is the SI unit of Force?",
      options: [
        "Joule",
        "Watt",
        "Newton",
        "Pascal"
      ],
      correctAnswerIndex: 2,
      solution: "The SI unit of force is the Newton (N).",
    ),
  ];

  List<McqQuestion> get _activeQuestions {
    if (_isReviewingSkipped) {
      return _allQuestions.where((q) => _skippedQuestionIds.contains(q.id)).toList();
    }
    return _allQuestions;
  }

  McqQuestion get _currQuestion => _isReviewingSkipped 
      ? _activeQuestions[_currentQuestionIndex] 
      : _allQuestions[_currentQuestionIndex];

  int get _totalQuestions => _allQuestions.length;
  int get _displayIndex => _isReviewingSkipped 
      ? _allQuestions.indexOf(_currQuestion) + 1 
      : _currentQuestionIndex + 1;

  void _nextQuestion() {
    if (_currentQuestionIndex < (_isReviewingSkipped ? _activeQuestions.length : _allQuestions.length) - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Reached end of current list
      if (!_isReviewingSkipped && _skippedQuestionIds.isNotEmpty) {
        // Start reviewing skipped
        setState(() {
          _isReviewingSkipped = true;
          _currentQuestionIndex = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Reviewing skipped questions", style: GoogleFonts.poppins()), duration: const Duration(seconds: 2)),
        );
      } else {
        // Really finished
        _submit();
      }
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    } else if (_isReviewingSkipped) {
      // Go back to normal flow? Or just stay at 0?
      // Usually "Previous" in skipped mode just goes to prev skipped question.
      // If at start of skipped, maybe go back to end of normal? 
      // For simplicity, let's keep it within current mode logic or switch back if robust.
      // Let's just stop at 0.
    }
  }

  void _skipQuestion() {
    final qId = _currQuestion.id;
    if (!_skippedQuestionIds.contains(qId)) {
      setState(() {
        _skippedQuestionIds.add(qId);
      });
    }
    _nextQuestion();
  }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    // Calculate Score
    int score = 0;
    _selectedAnswers.forEach((qId, optIdx) {
      final question = _allQuestions.firstWhere((q) => q.id == qId);
      if (question.correctAnswerIndex == optIdx) {
        score++;
      }
    });

    try {
         // Token managed internally
         final response = await ApiService.submitExamResult(
           examId: "mcq_general", // Dummy ID for general quizzes
           title: "MCQ Quiz", // Or dynamic title
           obtainedMarks: score,
           totalMarks: _totalQuestions, // Assuming 1 mark per question
           isOnline: true,
         );

         if (response.statusCode == 201) {
            final data = jsonDecode(response.body);
            final earnedPoints = data['earnedPoints'];
             
             if (mounted) {
               showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: Text("Quiz Finished", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("You scored $score out of $_totalQuestions", style: GoogleFonts.poppins()),
                      const SizedBox(height: 10),
                      if (earnedPoints > 0)
                        Text("You earned $earnedPoints Reward Points!", style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold))
                      else 
                        Text("Keep practicing to earn points!", style: GoogleFonts.poppins(color: Colors.orange)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Close dialog
                        Navigator.pop(context); // Close screen
                      },
                      child: Text("OK", style: GoogleFonts.poppins()),
                    )
                  ],
                ),
              );
             }
         } else {
            if(mounted) CustomToast.showError(context, "Failed to submit result");
         }
      } else {
         if(mounted) CustomToast.showError(context, "Session expired");
      }
    } catch (e) {
      if(mounted) CustomToast.showError(context, "Error: $e");
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLastQuestion = _currentQuestionIndex == (_isReviewingSkipped ? _activeQuestions.length : _allQuestions.length) - 1;
    // If it's the last question of normal flow BUT there are skipped questions, it's NOT the "Find Submit".
    // "Submit" button should appear only when NO more questions (skipped or otherwise) are left really.
    // Or users logic: "Skip questions will come in the end".
    // So "Next" becomes "Submit" only if (isLastQuestion AND (isReviewingSkipped OR skippedListIsEmpty))
    
    bool showSubmitButton = isLastQuestion && (_isReviewingSkipped || _skippedQuestionIds.isEmpty);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Question $_displayIndex / $_totalQuestions",
          style: GoogleFonts.poppins(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Question Card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currQuestion.question,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Choose Option:",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_currQuestion.options.length, (index) {
                      final isSelected = _selectedAnswers[_currQuestion.id] == index;
                      final optionLabel = String.fromCharCode(97 + index); // a, b, c, d...
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAnswers[_currQuestion.id] = index;
                            // If user selects an answer, remove from skipped if it was there?
                            // Logic: If they answer it, it's answered.
                             if (_skippedQuestionIds.contains(_currQuestion.id)) {
                               _skippedQuestionIds.remove(_currQuestion.id);
                               // Note: modifying list while iterating might be tricky if we were iterating, but we are just in a view.
                               // However, if we are in "Review Skipped" mode and we remove it, the list shrinks.
                               // This might mess up indices.
                               // Safer: Don't remove immediately from list in UI state to avoid jump, or handle state carefully.
                               // Let's keep it in "skipped" list during review until they move away or just leave it. 
                               // Actually, if they answer, it's treated as answered.
                             }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primaryContainer.withOpacity(0.4) : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colorScheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                                  ),
                                  color: isSelected ? colorScheme.primary : Colors.transparent,
                                ),
                                alignment: Alignment.center,
                                child: isSelected 
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : Text(
                                      "($optionLabel)",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12, 
                                        color: colorScheme.onSurfaceVariant
                                      ),
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currQuestion.options[index],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 24),
                    // Skip Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _skipQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Dark button as per image
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                    ),
                    
                    // Solution placeholder (hidden for now as it's a quiz)
                    // Visibility(visible: false, child: ...)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [
            // Previous Button (replaces Clear)
            if (_currentQuestionIndex > 0 || _isReviewingSkipped) ...[
               IconButton(
                 onPressed: _previousQuestion, 
                 icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                 style: IconButton.styleFrom(
                   backgroundColor: colorScheme.surfaceContainer,
                   padding: const EdgeInsets.all(12),
                 ),
               ),
               const SizedBox(width: 12),
            ],

            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                 style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Previous", style: GoogleFonts.poppins(color: colorScheme.onSurface)),
              ),
            ),

            const SizedBox(width: 16),
            
            // Next / Submit Button
            Expanded(
              child: ElevatedButton(
                onPressed: showSubmitButton ? _submit : _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: showSubmitButton ? Colors.green : Colors.black, // Submit green, Next black/dark
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  showSubmitButton ? "Submit" : "Next",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
             const SizedBox(width: 12),
             IconButton(
                 onPressed: showSubmitButton ? _submit : _nextQuestion, 
                 icon: const Icon(Icons.arrow_forward_ios, size: 20),
                 style: IconButton.styleFrom(
                   backgroundColor: colorScheme.surfaceContainer,
                   padding: const EdgeInsets.all(12),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}

class McqQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String solution;

  McqQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.solution,
  });
}
