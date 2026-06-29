import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/true_false_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class TrueFalseExamScreen extends StatefulWidget {
  final String subject;
  final String unit;
  final String title;
  final String examId;

  const TrueFalseExamScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.title,
    required this.examId,
  });

  @override
  State<TrueFalseExamScreen> createState() => _TrueFalseExamScreenState();
}

class _TrueFalseExamScreenState extends State<TrueFalseExamScreen>
    with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  final Map<int, bool> _selectedAnswers = {};

  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  int _violationCount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchQuestions();
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
        examId: widget.examId,
        examType: 'TRUEFALSE',
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
      _showResult();
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

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getTrueFalseExamById(widget.examId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> backendQuestions = data['questions'] ?? [];

        setState(() {
          _questions = backendQuestions.map((q) {
            return {
              "question": {
                "en": q['question'] ?? q['questionText'] ?? "",
                "gu": q['question'] ?? q['questionText'] ?? "",
              },
              "questionImage": q['questionImage'],
              "isTrue": q['isTrue'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        _useFallbackQuestions();
      }
    } catch (e) {
      debugPrint("Error fetching true/false questions: $e");
      _useFallbackQuestions();
    }
  }

  void _useFallbackQuestions() {
    setState(() {
      _questions = [
        {
          "question": {"en": "The Earth is flat.", "gu": "પૃથ્વી સપાટ છે."},
          "isTrue": false,
        },
        {
          "question": {
            "en": "Water boils at 100 degrees Celsius.",
            "gu": "પાણી 100 ડિગ્રી સેલ્સિયસ તાપમાને ઉકળે છે.",
          },
          "isTrue": true,
        },
      ];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _showResult();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  String _getQuestion() {
    // only english language currenyly we are working on
    final lang = context.read<ThemeCubit>().state.locale.languageCode;
    return _questions[_currentQuestionIndex]['question'][lang] ??
        _questions[_currentQuestionIndex]['question']['en'];
  }

  void _selectAnswer(bool isTrue) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = isTrue;
    });
  }

  void _showResult() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    int score = 0;
    List<Map<String, dynamic>> answersList = [];

    for (int i = 0; i < _questions.length; i++) {
      final selected = _selectedAnswers[i];
      final actual = _questions[i]['isTrue'] as bool;
      final qText = _questions[i]['question']['en'];
      
      final isCorrect = selected != null && selected == actual;
      if (isCorrect) score++;

      answersList.add({
        'questionIndex': i,
        'studentAnswer': selected ?? false,
        'correctAnswer': actual,
        'isCorrect': isCorrect,
        'questionText': qText,
      });
    }

    final double avgAccuracy = (_questions.isEmpty ? 0 : score / _questions.length) * 100;
    final int accuracyInt = avgAccuracy.round();

    // Save to local history
    _saveToHistory(score, accuracyInt);

    // Sync to backend
    try {
      bool isGuest = await GuestUtils.isGuest();
      if (!isGuest) {
        if (context.mounted) CustomLoader.show(context);
        await ApiService.submitTrueFalseExamResult(
          examId: widget.examId,
          title: widget.title,
          obtainedMarks: score,
          totalMarks: _questions.length,
          accuracy: avgAccuracy,
          type: 'TRUE_FALSE',
          violationCount: _violationCount,
          answers: answersList,
        );
      }

      if (isGuest) {
        await GuestUtils.incrementGuestExamCount('TRUEFALSE');
      }
    } catch (e) {
      debugPrint("Error syncing true/false result: $e");
    } finally {
      if (context.mounted) CustomLoader.hide(context);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrueFalseResultScreen(
            totalQuestions: _questions.length,
            correctAnswers: score,
            averageAccuracy: avgAccuracy,
            questions: _questions,
            selectedAnswers: _selectedAnswers,
            subject: widget.subject,
            title: widget.title,
            unit: widget.unit,
          ),
        ),
      );
    }
  }

  Future<void> _saveToHistory(int score, int accuracy) async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString('true_false_history') ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr);

    final newEntry = {
      'subject': widget.subject,
      'unit': widget.unit,
      'title': widget.title,
      'score': score,
      'total': _questions.length,
      'accuracy': accuracy,
      'date': DateTime.now().toIso8601String(),
    };

    history.add(newEntry);
    await prefs.setString('true_false_history', jsonEncode(history));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // only english language currenyly we are working on
    final lang = context.select((ThemeCubit c) => c.state.locale.languageCode);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleViolation("Back navigation is not allowed during the exam.");
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(
          title: lang == 'gu' ? "સાચું/ખોટું પરીક્ષા" : "True/False Exam",
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CustomLoader())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress Indicator
                      LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        backgroundColor: colorScheme.primaryContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang == 'gu'
                            ? "પ્રશ્ન ${_currentQuestionIndex + 1} માંથી ${_questions.length}"
                            : "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_questions[_currentQuestionIndex]['questionImage'] != null &&
                                _questions[_currentQuestionIndex]['questionImage'].toString().isNotEmpty &&
                                _questions[_currentQuestionIndex]['questionImage'] != "null")
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    ApiService.getFileUrl(_questions[_currentQuestionIndex]['questionImage']),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      height: 100,
                                      color: Colors.white24,
                                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                    ),
                                  ),
                                ),
                              ),
                            Text(
                              _getQuestion(),
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // True/False Buttons
                      Column(
                        children: [
                          _buildOptionButton(
                            context: context,
                            label: "True",
                            isTrueValue: true,
                            optionLabel: "A",
                          ),
                          const SizedBox(height: 16),
                          _buildOptionButton(
                            context: context,
                            label: "False",
                            isTrueValue: false,
                            optionLabel: "B",
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),

                      // Navigation Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentQuestionIndex > 0)
                            TextButton.icon(
                              onPressed: _previousQuestion,
                              icon: const Icon(Icons.arrow_back_ios, size: 16),
                              label: Text(lang == 'gu' ? "પાછળ" : "Previous"),
                            )
                          else
                            const Spacer(),
                          ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentQuestionIndex == _questions.length - 1
                                      ? (lang == 'gu' ? "પૂર્ણ" : "Finish")
                                      : (lang == 'gu' ? "આગળ" : "Next"),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
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

  Widget _buildOptionButton({
    required BuildContext context,
    required String label,
    required bool isTrueValue,
    required String optionLabel,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    bool isSelected = _selectedAnswers[_currentQuestionIndex] == isTrueValue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.5)
              : Colors.grey[200]!,
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
        onTap: () => _selectAnswer(isTrueValue),
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
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
