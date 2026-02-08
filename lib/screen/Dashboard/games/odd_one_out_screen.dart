import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class OddOneOutScreen extends StatefulWidget {
  const OddOneOutScreen({super.key});

  @override
  State<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends State<OddOneOutScreen> {
  final MindGameService _gameService = MindGameService();

  final List<Map<String, dynamic>> _levels = [
    {
      "options": ["Apple", "Banana", "Carrot", "Orange"],
      "answer": "Carrot", // Vegetable vs Fruits
      "reason": "It's a vegetable, others are fruits."
    },
    {
      "options": ["Car", "Bus", "Bike", "Plane"],
      "answer": "Plane", // Air vs Land
      "reason": "It travels in air, others on land."
    },
    {
      "options": ["Python", "Java", "HTML", "C++"],
      "answer": "HTML", // Markup vs Programming
      "reason": "HTML is a markup language, not a programming language."
    },
    {
      "options": ["Ear", "Eye", "Nose", "Hand"],
      "answer": "Hand", // Sense organs vs Limb
      "reason": "Others are sensory organs of the face."
    },
    {
      "options": ["3", "5", "9", "7"],
      "answer": "9", // Composite vs Prime
      "reason": "9 is not a prime number (3x3)."
    },
    {
       "options": ["Tennis", "Badminton", "Cricket", "Squash"],
       "answer": "Cricket", // Racket sports vs Bat/Ball
       "reason": "Others are racket sports."
    }
  ];

  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    MindGameService().startSession(context);
    _levels.shuffle();
  }

  @override
  void dispose() {
    MindGameService().stopSession();
    super.dispose();
  }

  void _handleOption(String option) {
    if (_isAnswered) return;

    final level = _levels[_currentIndex];
    String correctAnswer = level["answer"];
    bool correct = (option == correctAnswer);

    setState(() {
      _isAnswered = true;
      _selectedOption = option;
      _isCorrect = correct;
      if (correct) _score += 10;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex < _levels.length - 1) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
          _selectedOption = null;
        });
      } else {
        _showGameOver();
      }
    });
  }
  
  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Over", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Final Score: $_score", style: GoogleFonts.poppins()),
        actions: [
          ElevatedButton(
            onPressed: () {Navigator.pop(context); Navigator.pop(context);},
            child: const Text("Exit"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = _levels[_currentIndex];
    final List<String> options = List<String>.from(level["options"]);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Odd One Out",
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _levels.length,
              color: theme.primaryColor,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 40),
            Text(
              "Which one does not belong?",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                   final opt = options[index];
                   Color bg = Colors.white;
                   Color border = Colors.grey.shade300;
                   Color text = Colors.black87;
                   
                   if (_isAnswered) {
                     if (opt == level["answer"] || (opt == "Carrrot" && level["answer"] == "Carrot")) {
                       bg = Colors.green;
                       text = Colors.white;
                       border = Colors.green;
                     } else if (opt == _selectedOption) {
                       bg = Colors.red;
                       text = Colors.white;
                       border = Colors.red;
                     } else {
                       bg = Colors.grey.shade100;
                       text = Colors.grey;
                     }
                   }

                   return GestureDetector(
                     onTap: () => _handleOption(opt),
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 300),
                       decoration: BoxDecoration(
                         color: bg,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: border, width: 2),
                         boxShadow: [
                           if (!_isAnswered) BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4))
                         ]
                       ),
                       child: Center(
                         child: Text(
                           opt,
                           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: text),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     ),
                   );
                },
              ),
            ),
            
            if (_isAnswered)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _isCorrect ? "Correct! ${level['reason']}" : "Wrong! ${level['reason']}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.blue[800], fontWeight: FontWeight.w600),
                ),
              ),
              
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
