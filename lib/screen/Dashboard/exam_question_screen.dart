import 'dart:async';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';

class ExamQuestionScreen extends StatefulWidget {
  const ExamQuestionScreen({super.key});

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  Timer? _timer;
  int _remainingSeconds = 30;
  bool _isTimerActive = true;

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
  void initState() {
    super.initState();
    _startTimer();
  }

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
      // TODO: Navigate to results screen
    }
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
      appBar: AppBar(
        title: Text('$lblQuestion ${_currentQuestionIndex + 1}/${_questions.length}'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.timer, color: colorScheme.primary),
                const SizedBox(width: 8.0),
                Text(_isTimerActive ? _formatDuration(_remainingSeconds) : '--:--',
                    style: textTheme.titleMedium),
              ],
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
                      child: const Text(lblPrevious),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 16.0),
                Expanded(
                  child: CustomFilledButton(
                    label: isLastQuestion ? lblSubmit : lblNext,
                    onPressed: _selectedAnswers.containsKey(_currentQuestionIndex)
                        ? _nextQuestion
                        : null,
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
      final bool isSelected = _selectedAnswers[_currentQuestionIndex] == answer;
      return Card(
        margin: EdgeInsets.symmetric(vertical: S.s4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(S.s12),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? S.s2 : S.s1,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedAnswers[_currentQuestionIndex] = answer;
            });
          },
          borderRadius: BorderRadius.circular(S.s12),
          child: Padding(
            padding: P.h16v8,
            child: Row(
              children: [
                Expanded(child: Text(answer, style: textTheme.bodyMedium)),
                Radio<String>(
                  value: answer,
                  groupValue: _selectedAnswers[_currentQuestionIndex],
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswers[_currentQuestionIndex] = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
