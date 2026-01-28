import 'dart:async';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class McqDetailScreen extends StatefulWidget {
  const McqDetailScreen({super.key});

  @override
  State<McqDetailScreen> createState() => _McqDetailScreenState();
}

class _McqDetailScreenState extends State<McqDetailScreen> {
  int _currentIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  Timer? _timer;
  int _secondsRemaining = 1620; // 27:00 minutes example

  // Mock Questions Data
  final List<Map<String, dynamic>> _questions = [
    {
      "id": 1,
      "q": "What is the capital of France?",
      "options": ["Paris", "London", "Berlin", "Madrid"],
      "correct_ans": "Paris"
    },
    {
      "id": 2,
      "q": "Which planet is known as the Red Planet?",
      "options": ["Venus", "Mars", "Jupiter", "Saturn"],
      "correct_ans": "Mars"
    },
    {
      "id": 3,
      "q": "What is 5 + 7?",
      "options": ["10", "11", "12", "13"],
      "correct_ans": "12"
    },
    {
      "id": 4,
      "q": "Who wrote the national anthem of India?",
      "options": ["Rabindranath Tagore", "Bankim Chandra", "Sarojini Naidu", "Subhash Chandra Bose"],
      "correct_ans": "Rabindranath Tagore"
    },
  ];

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
        _handleExamEnd(autoSubmit: true);
        Navigator.pop(context);
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleExamEnd({bool autoSubmit = false}) {
    _timer?.cancel();
    if (autoSubmit) {
      CustomToast.showSuccess(context, "Exam Auto-Submitted");
    } else {
      CustomToast.showSuccess(context, "Exam Submitted Successfully!");
    }
  }

  void _submitExam() {
    _handleExamEnd(autoSubmit: false);
    Navigator.pop(context); 
  }

  Future<bool> _onWillPop() async {
    _handleExamEnd(autoSubmit: true); 
    return true; 
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    
    // Using explicit colors from the screenshot
    final Color headerColor = const Color(0xFF1565C0); // Dark Blue
    final Color backgroundColor = const Color(0xFF121212); // Very Dark Grey/Black
    final Color cardBorderColor = Colors.grey.shade600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: headerColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
               _handleExamEnd(autoSubmit: true);
               Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: Text(
            "Question ${_currentIndex + 1}/${_questions.length}",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 16),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_secondsRemaining),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar (top thin line as seen in typical quizzes, optional based on image but good for UX)
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: headerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Question Text
                    Text(
                      question['q'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Options List
                    ...List.generate(question['options'].length, (index) {
                      final option = question['options'][index];
                      final isSelected = _selectedAnswers[_currentIndex] == option;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAnswers[_currentIndex] = option;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(30), // Rounded pill shape
                            border: Border.all(
                              color: isSelected ? Colors.white : cardBorderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Radio Circle on the RIGHT
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected 
                                    ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentIndex < _questions.length - 1) {
                      setState(() {
                        _currentIndex++;
                      });
                    } else {
                      _submitExam();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C), // Dark grey button
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1 ? "Next" : "Submit",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
}