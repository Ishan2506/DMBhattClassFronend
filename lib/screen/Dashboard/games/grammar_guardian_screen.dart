import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class GrammarGuardianScreen extends StatefulWidget {
  const GrammarGuardianScreen({super.key});

  @override
  State<GrammarGuardianScreen> createState() => _GrammarGuardianScreenState();
}

class _GrammarGuardianScreenState extends State<GrammarGuardianScreen> {
  final MindGameService _gameService = MindGameService();
  List<GameQuestion> _allQuestions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _isCorrect = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Grammar Guardian');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allQuestions = data.map((json) => GameQuestion.fromJson(json)).toList();
          _allQuestions.shuffle();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching questions: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _handleAnswer(String option) {
    if (_isAnswered || _allQuestions.isEmpty) return;

    final question = _allQuestions[_currentIndex];
    bool correct = option == question.correctAnswer;
    setState(() {
      _isAnswered = true;
      _selectedOption = option;
      _isCorrect = correct;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_currentIndex < _allQuestions.length - 1) {
          setState(() {
            _currentIndex++;
            _isAnswered = false;
            _selectedOption = null;
          });
        } else {
          _showGameOver();
        }
      }
    });
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Quiz Complete!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("You scored $_score / ${_allQuestions.length}", style: GoogleFonts.poppins(fontSize: 18)),
            const SizedBox(height: 10),
            if (_score == _allQuestions.length)
              const Text("Perfect Grammar!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            else if (_score > _allQuestions.length / 2)
              const Text("Good Job!", style: TextStyle(color: Colors.blue))
            else
              const Text("Keep Practicing!", style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _isAnswered = false;
                _allQuestions.shuffle();
              });
            },
            child: const Text("Replay"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Grammar Guardian", centerTitle: true),
        body: const CustomLoader(),
      );
    }
    
    if (_allQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Grammar Guardian", centerTitle: true),
        body: Center(child: Text("No questions available", style: GoogleFonts.poppins())),
      );
    }

    final question = _allQuestions[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Grammar Guardian",
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _allQuestions.length,
                backgroundColor: theme.dividerColor.withOpacity(0.1),
                color: theme.colorScheme.primary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 40),
            
            Text(
              "Question ${_currentIndex + 1}",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                    blurRadius: 10, 
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: Text(
                question.questionText,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: theme.colorScheme.primary
                ),
              ),
            ),
            
            const Spacer(),
            
            ...question.options.map<Widget>((option) {
              bool isSelected = _selectedOption == option;
              bool showColor = _isAnswered && (isSelected || option == question.correctAnswer);
              Color color = theme.cardColor;
              Color textColor = theme.colorScheme.onSurface;

              if (showColor) {
                if (option == question.correctAnswer) {
                  color = Colors.green;
                  textColor = Colors.white;
                } else if (isSelected) {
                  color = Colors.red;
                  textColor = Colors.white;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () => _handleAnswer(option),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showColor ? Colors.transparent : theme.dividerColor.withOpacity(0.2)
                      ),
                      boxShadow: [
                         if (!showColor) 
                           BoxShadow(
                             color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                             blurRadius: 4, 
                             offset: const Offset(0, 2)
                           )
                      ]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
                        ),
                        if (showColor)
                           Icon(
                             option == question.correctAnswer ? Icons.check_circle : Icons.cancel,
                             color: Colors.white,
                           )
                         else
                           Icon(Icons.circle_outlined, color: theme.dividerColor),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
