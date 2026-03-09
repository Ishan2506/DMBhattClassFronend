import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class PeriodicTableQuestScreen extends StatefulWidget {
  const PeriodicTableQuestScreen({super.key});

  @override
  State<PeriodicTableQuestScreen> createState() => _PeriodicTableQuestScreenState();
}

class _PeriodicTableQuestScreenState extends State<PeriodicTableQuestScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  int _timeLeft = 30;
  Timer? _timer;
  bool _gameOver = false;
  
  final List<Map<String, dynamic>> _elements = [
    {"sym": "H", "name": "Hydrogen", "options": ["Helium", "Hydrogen", "Hafnium", "Holmium"]},
    {"sym": "O", "name": "Oxygen", "options": ["Osmium", "Oxygen", "Oganesson", "Gold"]},
    {"sym": "Na", "name": "Sodium", "options": ["Nitrogen", "Neon", "Sodium", "Nickel"]},
    {"sym": "Fe", "name": "Iron", "options": ["Fluorine", "Francium", "Iron", "Fermium"]},
    {"sym": "Au", "name": "Gold", "options": ["Silver", "Gold", "Argon", "Aluminum"]},
    {"sym": "C", "name": "Carbon", "options": ["Calcium", "Carbon", "Copper", "Cobalt"]},
    {"sym": "He", "name": "Helium", "options": ["Hydrogen", "Hafnium", "Helium", "Neon"]},
    {"sym": "K", "name": "Potassium", "options": ["Krypton", "Potassium", "Phosphorus", "Polonium"]},
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
    _elements.shuffle();
    _currentQuestion = _elements.first;
    List<String> opts = List<String>.from(_currentQuestion['options']);
    opts.shuffle();
    _currentQuestion['options'] = opts;
    setState(() {});
  }

  void _checkAnswer(String answer) {
    if (_gameOver) return;

    if (answer == _currentQuestion['name']) {
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
      appBar: const CustomAppBar(title: "Periodic Table Quest", centerTitle: true),
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
                  Text("What element is this?", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                      border: Border.all(color: theme.colorScheme.primary, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _currentQuestion['sym'], 
                        style: GoogleFonts.poppins(fontSize: 64, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), 
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
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
