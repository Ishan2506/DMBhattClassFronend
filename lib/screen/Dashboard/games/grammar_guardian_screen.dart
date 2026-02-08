import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class GrammarGuardianScreen extends StatefulWidget {
  const GrammarGuardianScreen({super.key});

  @override
  State<GrammarGuardianScreen> createState() => _GrammarGuardianScreenState();
}

class _GrammarGuardianScreenState extends State<GrammarGuardianScreen> {
  final MindGameService _gameService = MindGameService();

  final List<Map<String, dynamic>> _questions = [
    {"q": "The cat is sitting ___ the table.", "options": ["on", "in"], "a": "on"},
    {"q": "She ___ to the market yesterday.", "options": ["go", "went"], "a": "went"},
    {"q": "___ house is beautiful.", "options": ["Their", "There", "They're"], "a": "Their"},
    {"q": "I ___ breakfast every morning.", "options": ["eat", "ate"], "a": "eat"},
    {"q": "He is ___ tallest boy in class.", "options": ["a", "an", "the"], "a": "the"},
    {"q": "They have ___ played this game.", "options": ["already", "yet"], "a": "already"},
    {"q": "___ you like some coffee?", "options": ["Wood", "Would"], "a": "Would"},
    {"q": "The sun ___ in the east.", "options": ["rise", "rises"], "a": "rises"},
    {"q": "I have ___ money left.", "options": ["little", "a few"], "a": "little"},
    {"q": "Please ___ the door.", "options": ["close", "closed"], "a": "close"},
  ];

  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _questions.shuffle();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _handleAnswer(String option) {
    if (_isAnswered) return;

    bool correct = option == _questions[_currentIndex]['a'];
    setState(() {
      _isAnswered = true;
      _selectedOption = option;
      _isCorrect = correct;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        if (_currentIndex < _questions.length - 1) {
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
            Text("You scored $_score / ${_questions.length}", style: GoogleFonts.poppins(fontSize: 18)),
            const SizedBox(height: 10),
            if (_score == _questions.length)
              const Text("Perfect Grammar!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            else if (_score > _questions.length / 2)
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
                _questions.shuffle();
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
    final question = _questions[_currentIndex];

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
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade300,
              color: theme.primaryColor,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 40),
            
            Text(
              "Question ${_currentIndex + 1}",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Text(
                question['q'],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
            ),
            
            const Spacer(),
            
            ...question['options'].map<Widget>((option) {
              bool isSelected = _selectedOption == option;
              bool showColor = _isAnswered && (isSelected || option == question['a']);
              Color color = Colors.white;
              Color textColor = Colors.black87;

              if (showColor) {
                if (option == question['a']) {
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
                      border: Border.all(color: showColor ? Colors.transparent : Colors.grey.shade300),
                      boxShadow: [
                         if (!showColor) BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
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
                             option == question['a'] ? Icons.check_circle : Icons.cancel,
                             color: Colors.white,
                           )
                         else
                           const Icon(Icons.circle_outlined, color: Colors.grey),
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
