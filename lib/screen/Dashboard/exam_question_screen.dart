import 'dart:async';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/exam_result_screen.dart';
import 'package:flutter/material.dart';

class ExamQuestionScreen extends StatefulWidget {
  final String subject;
  
  const ExamQuestionScreen({super.key, required this.subject});

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  Timer? _timer;
  int _remainingSeconds = 30;
  bool _isTimerActive = true;
  
  // Audio Feedback
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAudioEnabled = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _startTimer();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  final List<Map<String, dynamic>> _questions = [
    {
      'question': lblQuestion1,
      'answers': [lblAnswer1_1, lblAnswer1_2, lblAnswer1_3, lblAnswer1_4],
      'correctAnswer': lblAnswer1_1,
    },
    {
      'question': lblQuestion2,
      'answers': [lblAnswer2_1, lblAnswer2_2, lblAnswer2_3, lblAnswer2_4],
      'correctAnswer': lblAnswer2_2,
    },
    {
      'question': lblQuestion3,
      'answers': [lblAnswer3_1, lblAnswer3_2, lblAnswer3_3, lblAnswer3_4],
      'correctAnswer': lblAnswer3_3,
    },
    {
      'question': lblQuestion4,
      'answers': [lblAnswer4_1, lblAnswer4_2, lblAnswer4_3, lblAnswer4_4],
      'correctAnswer': lblAnswer4_2,
    },
    {
      'question': lblQuestion5,
      'answers': [lblAnswer5_1, lblAnswer5_2, lblAnswer5_3, lblAnswer5_4],
      'correctAnswer': lblAnswer5_2,
    },
    {
      'question': lblQuestion6,
      'answers': [lblAnswer6_1, lblAnswer6_2, lblAnswer6_3, lblAnswer6_4],
      'correctAnswer': lblAnswer6_4,
    },
    {
      'question': lblQuestion7,
      'answers': [lblAnswer7_1, lblAnswer7_2, lblAnswer7_3, lblAnswer7_4],
      'correctAnswer': lblAnswer7_1,
    },
    {
      'question': lblQuestion8,
      'answers': [lblAnswer8_1, lblAnswer8_2, lblAnswer8_3, lblAnswer8_4],
      'correctAnswer': lblAnswer8_3,
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
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
        final correctAns = _questions[i]['correctAnswer'];

        if (userAns == null) {
          skipped++;
        } else if (userAns == correctAns) {
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
          unit: "Full Exam", // Or handle dynamic unit if available
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
            Container(
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

            // Options List
            Expanded(
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
                  ElevatedButton(
                    onPressed: _selectedAnswers.containsKey(_currentQuestionIndex)
                        ? _nextQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6495), // Matching the image's button color
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

  List<Widget> _buildAnswerOptions(List<String> answers) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return List.generate(answers.length, (index) {
      final answer = answers[index];
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


