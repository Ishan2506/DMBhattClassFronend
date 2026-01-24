import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final question = _questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Scaffold(
      appBar: CustomAppBar(
        title: '$lblQuestion ${_currentQuestionIndex + 1}/${_questions.length}',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
      ),
      body: Padding(
        padding: P.all24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question['question'],
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ..._buildAnswerOptions(question['answers']),
            const Spacer(),
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Previous", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAnswers.containsKey(_currentQuestionIndex)
                        ? _nextQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    child: Text(
                      isLastQuestion ? lblSubmit : lblNext,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }




  List<Widget> _buildAnswerOptions(List<String> answers) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return answers.map((answer) {
      final String? selectedAns = _selectedAnswers[_currentQuestionIndex];
      // final bool isSelected = selectedAns == answer;
      final String correctAns = _questions[_currentQuestionIndex]['correctAnswer'];

      Color borderColor = colorScheme.outline;
      Color? optionColor; // background if needed

      if (selectedAns != null) {
        if (answer == correctAns) {
           // Correct Answer -> Green Highlight
           borderColor = Colors.green;
           optionColor = Colors.green.withOpacity(0.1);
        } else if (answer == selectedAns && answer != correctAns) {
           // Wrong Selection -> Red Highlight
           borderColor = Colors.red;
           optionColor = Colors.red.withOpacity(0.1);
        }
      }

      return Card(
        margin: EdgeInsets.symmetric(vertical: S.s4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(S.s12),
          side: BorderSide(
            color: borderColor,
            width: selectedAns != null && (answer == correctAns || answer == selectedAns) ? S.s2 : S.s1,
          ),
        ),
        color: optionColor,
        child: InkWell(
          onTap: () {
            // Uncomment to disable changing answer after selection
            // if (_selectedAnswers.containsKey(_currentQuestionIndex)) return; 
            
            setState(() {
              _selectedAnswers[_currentQuestionIndex] = answer;
            });
          },
          borderRadius: BorderRadius.circular(S.s12),
          child: Padding(
            padding: P.h16v8,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    answer, 
                    style: textTheme.bodyMedium?.copyWith(
                      color: selectedAns != null && answer == correctAns 
                        ? Colors.green 
                        : (selectedAns == answer && answer != correctAns 
                            ? Colors.red 
                            : textTheme.bodyMedium?.color),
                      fontWeight: selectedAns != null && (answer == correctAns || answer == selectedAns) 
                        ? FontWeight.bold 
                        : FontWeight.normal
                    )
                  )
                ),
                Radio<String>(
                  value: answer,
                  groupValue: _selectedAnswers[_currentQuestionIndex],
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswers[_currentQuestionIndex] = value!;
                    });
                  },
                  activeColor: answer == correctAns 
                      ? Colors.green 
                      : (answer == selectedAns ? Colors.red : colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}


