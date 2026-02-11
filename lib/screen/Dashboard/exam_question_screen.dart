import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamQuestionScreen extends StatefulWidget {
  final String subject;
  final String examId;
  final String title;
  
  const ExamQuestionScreen({super.key, required this.subject, required this.examId, required this.title});

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
                
                final optionsList = (q['options'] as List).map((o) => o['text'].toString()).toList();
                
                return {
                  'question': q['questionText'],
                  'answers': optionsList, 
                  'correctAnswer': q['correctAnswer'], 
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
        
        final q = _questions[i];
        final correctKey = q['correctAnswerKey']; // 'A'
        final optionsRaw = q['optionsRaw'] as List; // [{key:'A', text:'...'}, ...]
        
        String? correctText;
        try {
            final correctOption = optionsRaw.firstWhere((o) => o['key'] == correctKey);
            correctText = correctOption['text'];
        } catch (e) {
            // Fallback
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

    Future<void> submitAndNavigate() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          final response = await ApiService.submitExamResult(
            token: token,
            examId: widget.examId,
            title: widget.title,
            obtainedMarks: correct,
            totalMarks: _questions.length,
          );
          
          if (response.statusCode != 201) {
             debugPrint("Submit failed: ${response.body}");
             if (mounted) {
               // Show toast or some feedback if it failed
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text("Failed to save result to server: ${response.statusCode}")),
               );
             }
          }
        }
      } catch (e) {
        debugPrint("Error submitting result: $e");
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
              questions: _questions,
              selectedAnswers: _selectedAnswers,
              subject: widget.subject,
              unit: "Full Exam",
            ),
          ),
        );
      }
    }

    submitAndNavigate();
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
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
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      l10n.questionProgress(_currentQuestionIndex + 1, _questions.length),
                      style: textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question Card with Gradient
            Expanded( 
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
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
                      backgroundColor: theme.colorScheme.primary, 
                      foregroundColor: theme.colorScheme.onPrimary,
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

  List<Widget> _buildAnswerOptions(List<dynamic> answers) { 
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

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
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.5) : Colors.grey[200]!,
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
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
