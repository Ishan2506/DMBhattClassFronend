import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class HigherLowerScreen extends StatefulWidget {
  const HigherLowerScreen({super.key});

  @override
  State<HigherLowerScreen> createState() => _HigherLowerScreenState();
}

class _HigherLowerScreenState extends State<HigherLowerScreen> {
  final MindGameService _gameService = MindGameService();
  
  int _currentNumber = 0;
  int _nextNumber = 0;
  int _score = 0;
  int _highScore = 0;
  bool _showNext = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startNewGame();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _currentNumber = Random().nextInt(100) + 1;
    _generateNext();
    setState(() => _showNext = false);
  }

  void _generateNext() {
    _nextNumber = Random().nextInt(100) + 1;
    while (_nextNumber == _currentNumber) {
      _nextNumber = Random().nextInt(100) + 1;
    }
  }

  void _makeGuess(bool isHigher) {
    if (_showNext) return;

    bool correct = false;
    if (isHigher && _nextNumber > _currentNumber) correct = true;
    if (!isHigher && _nextNumber < _currentNumber) correct = true;

    setState(() {
      _showNext = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (correct) {
        setState(() {
          _score++;
          if (_score > _highScore) _highScore = _score;
          _currentNumber = _nextNumber;
          _generateNext();
          _showNext = false;
        });
      } else {
        _gameOver();
      }
    });
  }

  void _gameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Over", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("The next number was $_nextNumber!\nYour score: $_score", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
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
            Text("1. A number from 1 to 100 is shown.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. Guess if the next hidden number is Higher or Lower than the current one.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("3. Get it right to increase your score and continue.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("4. One wrong guess and the game ends!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
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
        title: "Higher or Lower",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Current Score: $_score",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCard(_currentNumber.toString(), "CURRENT", theme),
                const SizedBox(width: 24),
                _buildCard(_showNext ? _nextNumber.toString() : "?", "NEXT", theme, isHidden: !_showNext),
              ],
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGuessButton(true, theme),
                const SizedBox(width: 24),
                _buildGuessButton(false, theme),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "High Score: $_highScore",
              style: GoogleFonts.poppins(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String value, String label, ThemeData theme, {bool isHidden = false}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary.withOpacity(0.5))),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: isHidden ? theme.colorScheme.primary.withOpacity(0.1) : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))]
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 48, 
                fontWeight: FontWeight.bold, 
                color: isHidden ? theme.colorScheme.primary.withOpacity(0.3) : theme.colorScheme.primary
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuessButton(bool isHigher, ThemeData theme) {
    return SizedBox(
      width: 140,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _makeGuess(isHigher),
        style: ElevatedButton.styleFrom(
          backgroundColor: isHigher ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isHigher ? Icons.arrow_upward : Icons.arrow_downward),
            Text(isHigher ? "HIGHER" : "LOWER", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
