import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class RhymeTimeScreen extends StatefulWidget {
  const RhymeTimeScreen({super.key});

  @override
  State<RhymeTimeScreen> createState() => _RhymeTimeScreenState();
}

class _RhymeTimeScreenState extends State<RhymeTimeScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  int _timeLeft = 30;
  Timer? _timer;
  bool _gameOver = false;
  
  final List<Map<String, dynamic>> _questions = [
    {"word": "Cat", "rhyme": "Bat", "wrong": ["Car", "Dog", "Sit"]},
    {"word": "Sun", "rhyme": "Bun", "wrong": ["Star", "Moon", "Sip"]},
    {"word": "Light", "rhyme": "Bright", "wrong": ["Dark", "Heavy", "Left"]},
    {"word": "Play", "rhyme": "Day", "wrong": ["Game", "Stop", "Boy"]},
    {"word": "Blue", "rhyme": "Shoe", "wrong": ["Red", "Color", "Foot"]},
    {"word": "Tree", "rhyme": "See", "wrong": ["Leaf", "Wood", "Run"]},
    {"word": "Boat", "rhyme": "Coat", "wrong": ["Ship", "Water", "Cold"]},
    {"word": "Star", "rhyme": "Car", "wrong": ["Moon", "Space", "Bus"]},
  ];

  late Map<String, dynamic> _currentQuestion;
  List<String> _currentOptions = [];

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
    _questions.shuffle();
    _currentQuestion = _questions.first;
    _currentOptions = [_currentQuestion['rhyme'], ...(_currentQuestion['wrong'] as List<String>)];
    _currentOptions.shuffle();
    setState(() {});
  }

  void _checkAnswer(String answer) {
    if (_gameOver) return;

    if (answer == _currentQuestion['rhyme']) {
      setState(() {
        _score += 15;
        _timeLeft += 2;
      });
      _generateQuestion();
    } else {
      setState(() {
        _timeLeft = (_timeLeft - 3).clamp(0, 999);
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
      appBar: const CustomAppBar(title: "Rhyme Time", centerTitle: true),
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
                  Text(
                    "What rhymes with...",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentQuestion['word'], 
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: theme.colorScheme.primary), 
                    textAlign: TextAlign.center
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
                    itemCount: _currentOptions.length,
                    itemBuilder: (context, index) {
                      String opt = _currentOptions[index];
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
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
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
