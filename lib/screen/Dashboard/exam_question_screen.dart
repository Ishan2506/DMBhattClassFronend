import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_result_screen.dart';
import 'package:flutter/material.dart';

class ExamQuestionScreen extends StatefulWidget {
  final String subject;
  final String examId;
  
  const ExamQuestionScreen({super.key, required this.subject, required this.examId});

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  Timer? _timer;
  int _remainingSeconds = 30; // Will be set from API if available
  bool _isTimerActive = true;
  
  // Audio Feedback
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAudioEnabled = true;

  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchExamDetails();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _fetchExamDetails() async {
    try {
      final response = await ApiService.getExamById(widget.examId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questionsData = data['questions'] as List;
        
        if (mounted) {
          setState(() {
            _questions = questionsData.map((q) {
                // Parse options which might be List<dynamic> of objects {key, text}
                // or might need adaptation based on backend response structure.
                // Assuming backend returns: options: [{key: 'A', text: 'Option A'}]
                // But the UI expects List<String> for answers.
                // Let's adapt it.
                
                final optionsList = (q['options'] as List).map((o) => o['text'].toString()).toList();
                
                return {
                  'question': q['questionText'],
                  'answers': optionsList, 
                  'correctAnswer': q['correctAnswer'], // Might be 'A' or 'Option Text'. 
                  // If backend returns 'A', we need to map it to the text.
                  // For now assuming correctAnswer matches one of the options text or key.
                  // Actually backend model says 'correctAnswer: String'. Let's check logic.
                  // If correctAnswer is 'A', we need to check which option has key 'A'.
                  'correctAnswerKey': q['correctAnswer'], 
                  'optionsRaw': q['options']
                };
            }).toList();
            _isLoading = false;
          });
          _startTimer();
        }
      } else {
        // Handle error
         if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching exam questions: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_questions.isEmpty) return;

    setState(() {
      _remainingSeconds = 30; // 30 seconds for each question
      _isTimerActive = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
          // Speak when 5 seconds remain
          if (_remainingSeconds == 5 && _isAudioEnabled) {
            _flutterTts.speak("5 seconds left");
          }
        }
      } else {
        timer.cancel();
        if (mounted) _nextQuestion();
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    return duration.toString().substring(2, 7);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (int i = 0; i < _questions.length; i++) {
        final userAns = _selectedAnswers[i];
        
        // Correct Answer Logic
        // We stored the answer TEXT in _selectedAnswers.
        // We need to compare it with the correct answer from backend.
        // The backend `correctAnswer` might be 'A', 'B', etc.
        // The option list has keys 'A', 'B'.
        
        final q = _questions[i];
        final correctKey = q['correctAnswerKey']; // 'A'
        final optionsRaw = q['optionsRaw'] as List; // [{key:'A', text:'...'}, ...]
        
        String? correctText;
        try {
            final correctOption = optionsRaw.firstWhere((o) => o['key'] == correctKey);
            correctText = correctOption['text'];
        } catch (e) {
            // Fallback if structure is different
            correctText = q['correctAnswer']; 
        }

        if (userAns == null) {
          skipped++;
        } else if (userAns == correctText) {
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
          subject: widget.subject,
          unit: "Full Exam", 
        ),
      ),
    );
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _timer?.cancel();
      setState(() {
        _currentQuestionIndex--;
        _isTimerActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
       return Scaffold(
         appBar: const CustomAppBar(title: "Exam"),
         body: Center(child: Text("No questions found for this exam."))
       );
    }

    final question = _questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: '${l10n.question} ${_currentQuestionIndex + 1}/${_questions.length}',
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isAudioEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isAudioEnabled = !_isAudioEnabled;
                    });
                  },
                ),
                const Icon(Icons.timer, color: Colors.white),
                const SizedBox(width: 8.0),
                Text(_isTimerActive ? _formatDuration(_remainingSeconds) : '--:--',
                    style: textTheme.titleMedium?.copyWith(color: Colors.white)),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question X of Y Chip
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      "${l10n.question} ${_currentQuestionIndex + 1} ${l10n.locale.languageCode == 'en' ? 'of' : (l10n.locale.languageCode == 'hi' ? 'में से' : 'માંથી')} ${_questions.length}",
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question Card with Gradient
            Expanded( // Changed to Expanded to allow scrolling if text is long, or just flexible
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[900]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      question['question'],
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            // Options List
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: _buildAnswerOptions(question['answers']),
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // SKIP Button
                   TextButton(
                    onPressed: _currentQuestionIndex < _questions.length - 1 ? _nextQuestion : null,
                    child: Text(
                      l10n.skip,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // NEXT/SUBMIT Button
                  ElevatedButton(
                    onPressed: _selectedAnswers.containsKey(_currentQuestionIndex)
                        ? _nextQuestion // This goes to next or submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6495), 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastQuestion ? l10n.submit : l10n.next,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnswerOptions(List<dynamic> answers) { // Changed to List<dynamic> as we might have cast earlier
    final textTheme = Theme.of(context).textTheme;
    // final l10n = AppLocalizations.of(context);

    return List.generate(answers.length, (index) {
      final answer = answers[index].toString();
      final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
      final String? selectedAns = _selectedAnswers[_currentQuestionIndex];
      final bool isSelected = selectedAns == answer;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedAnswers[_currentQuestionIndex] = answer;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    optionLabel,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    answer,
                    style: textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.blue[900] : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
