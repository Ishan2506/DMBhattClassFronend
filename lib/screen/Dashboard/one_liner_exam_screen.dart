import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/matching_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_result_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class OneLinerExamScreen extends StatefulWidget {
  final String subject;
  final String unit;
  final String title;
  final String examId;

  const OneLinerExamScreen({
    super.key,
    required this.subject,
    required this.unit,
    required this.title,
    required this.examId,
  });

  @override
  State<OneLinerExamScreen> createState() => _OneLinerExamScreenState();
}

class _OneLinerExamScreenState extends State<OneLinerExamScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();
  double _confidence = 1.0;

  int _currentQuestionIndex = 0;
  final Map<int, String> _spokenAnswers = {};
  
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _checkPermission();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getOneLinerExamById(widget.examId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> backendQuestions = data['questions'] ?? [];
        
        setState(() {
          _questions = backendQuestions.map((q) {
            return {
              "question": {
                "en": q['questionText'] ?? "",
                "gu": q['questionText'] ?? ""
              },
              "answer": {
                "en": q['correctAnswer'] ?? "",
                "gu": q['correctAnswer'] ?? ""
              }
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        _useFallbackQuestions();
      }
    } catch (e) {
      debugPrint("Error fetching one-liner questions: $e");
      _useFallbackQuestions();
    }
  }

  void _useFallbackQuestions() {
    setState(() {
      _questions = [
        {
          "question": {"en": "What is matter?", "gu": "દ્રવ્ય એટલે શું?"},
          "answer": {"en": "Matter is anything that has mass and occupies space.", "gu": "દ્રવ્ય એ એવી વસ્તુ છે જે દળ ધરાવે છે અને જગ્યા રોકે છે."}
        },
        {
          "question": {"en": "What are the three states of matter?", "gu": "દ્રવ્યની ત્રણ અવસ્થાઓ કઈ છે?"},
          "answer": {"en": "The three states of matter are solid, liquid and gas.", "gu": "દ્રવ્યની ત્રણ અવસ્થાઓ ઘન, પ્રવાહી અને વાયુ છે."}
        }
      ];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      await Permission.microphone.request();
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        final locale = context.read<ThemeCubit>().state.locale.languageCode;
        _speech.listen(
          localeId: locale == 'gu' ? 'gu_IN' : 'en_US',
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _spokenAnswers[_currentQuestionIndex] = _textController.text;
      }
    }
  }

  void _nextQuestion() {
    if (_textController.text.isNotEmpty) {
      _spokenAnswers[_currentQuestionIndex] = _textController.text;
    }
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _textController.text = _spokenAnswers[_currentQuestionIndex] ?? "";
        _isListening = false;
      });
      _speech.stop();
    } else {
      _showResult();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _textController.text = _spokenAnswers[_currentQuestionIndex] ?? "";
        _isListening = false;
      });
      _speech.stop();
    }
  }

  String _getQuestion() {
    final lang = context.read<ThemeCubit>().state.locale.languageCode;
    return _questions[_currentQuestionIndex]['question'][lang] ?? _questions[_currentQuestionIndex]['question']['en'];
  }

  String _getAnswer(int index) {
    final lang = context.read<ThemeCubit>().state.locale.languageCode;
    return _questions[index]['answer'][lang] ?? _questions[index]['answer']['en'];
  }

  void _showResult() async {
    int score = 0;
    double totalPartialScore = 0.0;
    for (int i = 0; i < _questions.length; i++) {
      final matchScore = MatchingUtils.getMatchScore(_spokenAnswers[i] ?? "", _getAnswer(i));
      totalPartialScore += matchScore;
      if (matchScore >= 0.5) {
        score++;
      }
    }

    final double avgAccuracy = totalPartialScore / _questions.length * 100;
    final int accuracyInt = avgAccuracy.round();
    
    // Save to local history
    _saveToHistory(score, accuracyInt);

    // Sync to backend (Fire and forget or wait? Better wait for better UX)
    try {
      await ApiService.submitOneLinerExamResult(
        examId: widget.examId,
        title: widget.title,
        obtainedMarks: score,
        totalMarks: _questions.length,
        accuracy: avgAccuracy,
      );
    } catch (e) {
      debugPrint("Error syncing one-liner result: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OneLinerResultScreen(
            totalQuestions: _questions.length,
            correctAnswers: score,
            averageAccuracy: avgAccuracy,
            questions: _questions,
            spokenAnswers: _spokenAnswers,
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
    final historyStr = prefs.getString('one_liner_history') ?? '[]';
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
    await prefs.setString('one_liner_history', jsonEncode(history));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.select((ThemeCubit c) => c.state.locale.languageCode);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: lang == 'gu' ? "એક લીટી પરીક્ષા" : "One-Liner Exam",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OneLinerHistoryScreen()),
              );
            },
          ),
        ],
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
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'gu' ? "પ્રશ્ન ${_currentQuestionIndex + 1} માંથી ${_questions.length}" : "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Question Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Text(
                  _getQuestion(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              
              // Editing Field (TextFormField)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isListening ? Colors.red.shade300 : Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 3,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: lang == 'gu' ? "માઇક્રોફોન ટેપ કરો અને બોલો, અથવા અહીં ટાઇપ કરો..." : "Tap microphone and speak, or type here...",
                    hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                     _spokenAnswers[_currentQuestionIndex] = val;
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              // Microphone Button
              Center(
                child: GestureDetector(
                  onTap: _listen,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : colorScheme.primary).withOpacity(0.4),
                          blurRadius: _isListening ? 30 : 20,
                          spreadRadius: _isListening ? 10 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    lang == 'gu' ? "સાંભળી રહ્યા છીએ..." : "Listening...",
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 40),
              
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
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentQuestionIndex == _questions.length - 1 
                          ? (lang == 'gu' ? "પૂર્ણ" : "Finish") 
                          : (lang == 'gu' ? "આગળ" : "Next")),
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
    );
  }
}
