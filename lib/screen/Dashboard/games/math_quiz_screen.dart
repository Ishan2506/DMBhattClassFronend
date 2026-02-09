import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class MathQuizScreen extends StatefulWidget {
  const MathQuizScreen({super.key});

  @override
  State<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends State<MathQuizScreen> {
  int _score = 0;
  int _timeLeft = 30; // 30 seconds per round
  Timer? _timer;
  
  String _question = "";
  List<int> _options = [];
  int _correctAnswer = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    MindGameService().startSession(context);
    _generateQuestion();
    _startRound();
  }

  @override
  void dispose() {
    MindGameService().stopSession();
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _startRound();
  }

  void _startRound() {
    setState(() {
      _timeLeft = 30;
      _gameOver = false;
    });
    _generateQuestion();
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
    final random = Random();
    int a = random.nextInt(20) + 1;
    int b = random.nextInt(20) + 1;
    int operator = random.nextInt(3); // 0: +, 1: -, 2: *

    switch (operator) {
      case 0:
        _correctAnswer = a + b;
        _question = "$a + $b = ?";
        break;
      case 1:
        _correctAnswer = a - b;
        _question = "$a - $b = ?";
        break;
      case 2:
        a = random.nextInt(12) + 1; // Smaller numbers for multiplication
        b = random.nextInt(12) + 1;
        _correctAnswer = a * b;
        _question = "$a × $b = ?";
        break;
    }

    _generateOptions();
  }

  void _generateOptions() {
    final random = Random();
    Set<int> optionsSet = {_correctAnswer};
    
    while (optionsSet.length < 4) {
      int drift = random.nextInt(10) + 1;
      optionsSet.add(random.nextBool() ? _correctAnswer + drift : _correctAnswer - drift);
    }
    
    _options = optionsSet.toList()..shuffle();
  }

  void _checkAnswer(int answer) {
    if (_gameOver) return;

    if (answer == _correctAnswer) {
      setState(() {
        _score += 10;
        _timeLeft += 2; // Bonus time
      });
      _generateQuestion(); // Next question immediately
    } else {
      // Wrong answer deducts time or just shakes? Let's deduct time.
      setState(() {
        _timeLeft = max(0, _timeLeft - 5);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! -5 seconds", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 500),
        )
      );
    }
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("How to Play", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("1. You have 30 seconds.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("2. Solve the math problem shown.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("3. Correct answer: +10 points & +2 seconds.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("4. Wrong answer: -5 seconds penalty!", style: GoogleFonts.poppins()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Speed Math",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Score and Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.timer, "$_timeLeft s", _timeLeft < 10 ? Colors.red : theme.primaryColor),
                _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
              ],
            ),
            const Spacer(),
            
            if (_gameOver)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                     "Time's Up!", 
                     style: GoogleFonts.poppins(
                       fontSize: 32, 
                       fontWeight: FontWeight.bold, 
                       color: theme.textTheme.headlineMedium?.color ?? Colors.blueGrey
                     )
                   ),
                   const SizedBox(height: 16),
                   Text(
                     "Final Score: $_score", 
                     style: GoogleFonts.poppins(
                       fontSize: 24, 
                       fontWeight: FontWeight.w600,
                       color: theme.textTheme.titleLarge?.color
                     )
                   ),
                   const SizedBox(height: 32),
                   ElevatedButton(
                     onPressed: _startRound,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                       backgroundColor: theme.primaryColor,
                       foregroundColor: Colors.white,
                       elevation: 8,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                     ),
                     child: Text("Play Again", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                   )
                ],
              )
            else
              Column(
                children: [
                  FittedBox(
                    child: Text(
                      _question, 
                      style: GoogleFonts.poppins(
                        fontSize: 48, 
                        fontWeight: FontWeight.bold, 
                        color: theme.primaryColor
                      )
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
                      return ElevatedButton(
                        onPressed: () => _checkAnswer(_options[index]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.primaryColor,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${_options[index]}",
                              style: GoogleFonts.poppins(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color
                              ),
                            ),
                          ),
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
