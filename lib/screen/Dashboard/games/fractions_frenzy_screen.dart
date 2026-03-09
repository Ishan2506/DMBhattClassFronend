import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class FractionsFrenzyScreen extends StatefulWidget {
  const FractionsFrenzyScreen({super.key});

  @override
  State<FractionsFrenzyScreen> createState() => _FractionsFrenzyScreenState();
}

class _FractionsFrenzyScreenState extends State<FractionsFrenzyScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  int _timeLeft = 30;
  Timer? _timer;
  bool _gameOver = false;
  
  String _question = "";
  List<String> _options = [];
  String _correctAnswer = "";

  final Random _random = Random();

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
      _timeLeft = 30;
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
    // Generate two basic fractions and ask which is larger or ask an addition map
    int type = _random.nextInt(2);
    if (type == 0) {
      // Comparison
      int num1 = _random.nextInt(5) + 1;
      int den1 = _random.nextInt(6) + 2; // 2..7
      int num2 = _random.nextInt(5) + 1;
      int den2 = _random.nextInt(6) + 2;
      
      double val1 = num1 / den1;
      double val2 = num2 / den2;
      
      // Ensure they aren't exactly equal for simplicity
      if (val1 == val2) {
        num1++; 
        val1 = num1 / den1;
      }
      
      _question = "Which is larger?";
      String f1 = "$num1/$den1";
      String f2 = "$num2/$den2";
      _options = [f1, f2];
      _correctAnswer = val1 > val2 ? f1 : f2;
    } else {
      // Common denominator addition
      int den = _random.nextInt(5) + 3; // 3..7
      int num1 = _random.nextInt(3) + 1;
      int num2 = _random.nextInt(3) + 1;
      int sum = num1 + num2;
      
      _question = "$num1/$den + $num2/$den = ?";
      _correctAnswer = "$sum/$den";
      
      _options = [
        "$sum/$den",
        "${sum + 1}/$den",
        "${num1 * num2}/$den",
        "${sum - 1}/$den"
      ];
      _options.shuffle();
    }
    setState(() {});
  }

  void _checkAnswer(String answer) {
    if (_gameOver) return;

    if (answer == _correctAnswer) {
      setState(() {
        _score += 10;
        _timeLeft += 2; // Bonus time
      });
      _generateQuestion();
    } else {
      setState(() {
        _timeLeft = max(0, _timeLeft - 3);
      });
      _generateQuestion();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! -3 seconds", style: GoogleFonts.poppins()),
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
      appBar: const CustomAppBar(title: "Fractions Frenzy", centerTitle: true),
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
                  Text(_question, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      return ElevatedButton(
                        onPressed: () => _checkAnswer(_options[index]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                        ),
                        child: Text(
                          _options[index],
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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
