import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class AnatomyExplorerScreen extends StatefulWidget {
  const AnatomyExplorerScreen({super.key});

  @override
  State<AnatomyExplorerScreen> createState() => _AnatomyExplorerScreenState();
}

class _AnatomyExplorerScreenState extends State<AnatomyExplorerScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  int _timeLeft = 40;
  Timer? _timer;
  bool _gameOver = false;
  
  final List<Map<String, dynamic>> _anatomyQuestions = [
    {
      "q": "Which organ pumps blood throughout the body?",
      "a": "Heart",
      "options": ["Brain", "Lungs", "Heart", "Liver"]
    },
    {
      "q": "What is the largest organ of the human body?",
      "a": "Skin",
      "options": ["Liver", "Skin", "Intestines", "Brain"]
    },
    {
      "q": "Where does oxygen enter the blood?",
      "a": "Lungs",
      "options": ["Heart", "Stomach", "Kidneys", "Lungs"]
    },
    {
      "q": "Which organ is the control center of the nervous system?",
      "a": "Brain",
      "options": ["Spinal Cord", "Heart", "Brain", "Nerves"]
    },
    {
      "q": "Which organs filter waste from the blood to produce urine?",
      "a": "Kidneys",
      "options": ["Kidneys", "Lungs", "Liver", "Pancreas"]
    },
    {
      "q": "Where does most nutrient absorption take place?",
      "a": "Small Intestine",
      "options": ["Stomach", "Large Intestine", "Small Intestine", "Liver"]
    },
  ];

  late Map<String, dynamic> _currentQuestion;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startRound();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _startRound();
  }

  void _startRound() {
    setState(() {
      _timeLeft = 40;
      _gameOver = false;
    });
    _generateQuestion();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _gameOver = true;
        });
      }
    });
  }

  void _generateQuestion() {
    _anatomyQuestions.shuffle();
    _currentQuestion = _anatomyQuestions.first;
    List<String> opts = List<String>.from(_currentQuestion['options']);
    opts.shuffle();
    _currentQuestion['options'] = opts;
    setState(() {});
  }

  void _checkAnswer(String answer) {
    if (_gameOver) return;

    if (answer == _currentQuestion['a']) {
      setState(() {
        _score += 15;
        _timeLeft += 4;
      });
      _generateQuestion();
    } else {
      setState(() {
        _timeLeft = (_timeLeft - 4).clamp(0, 999);
      });
      _generateQuestion();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! -4 seconds", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 500),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Anatomy Explorer", centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.timer, "$_timeLeft s", _timeLeft < 10 ? Colors.red : theme.colorScheme.primary),
                _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
              ],
            ),
            const Spacer(),
            if (_gameOver)
               Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text("Time's Up!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   Text("Final Score: $_score", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600)),
                   const SizedBox(height: 32),
                   ElevatedButton(
                     onPressed: _startNewGame,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                       backgroundColor: theme.colorScheme.primary,
                       foregroundColor: theme.colorScheme.onPrimary,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                     ),
                     child: Text("Play Again", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                   )
                ],
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _currentQuestion['q'], 
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), 
                      textAlign: TextAlign.center
                    ),
                  ),
                  const SizedBox(height: 40),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      String opt = _currentQuestion['options'][index];
                      return ElevatedButton(
                        onPressed: () => _checkAnswer(opt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                        ),
                        child: Text(
                          opt,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ],
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
