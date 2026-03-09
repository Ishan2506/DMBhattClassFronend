import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class AudioRecallScreen extends StatefulWidget {
  const AudioRecallScreen({super.key});

  @override
  State<AudioRecallScreen> createState() => _AudioRecallScreenState();
}

class _AudioRecallScreenState extends State<AudioRecallScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  bool _gameOver = false;
  
  final List<String> _words = ["Cat", "Dog", "Bird", "Fish", "Sun", "Moon", "Star", "Sky"];
  List<String> _sequence = [];
  List<String> _currentInput = [];
  bool _isPlayingSequence = false;
  int _sequenceLength = 3;

  String _flashWord = "";

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startRound();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _sequenceLength = 3;
    _startRound();
  }

  void _startRound() {
    setState(() {
      _gameOver = false;
      _currentInput.clear();
      _sequence.clear();
    });
    _generateSequence();
  }

  void _generateSequence() async {
    final rand = Random();
    for (int i = 0; i < _sequenceLength; i++) {
        _sequence.add(_words[rand.nextInt(_words.length)]);
    }

    setState(() {
      _isPlayingSequence = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    for (String word in _sequence) {
      if (!mounted) return;
      setState(() {
        _flashWord = word;
      });
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _flashWord = "";
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    setState(() {
      _isPlayingSequence = false;
    });
  }

  void _handleInput(String word) {
    if (_isPlayingSequence || _gameOver) return;

    setState(() {
      _currentInput.add(word);
    });

    int index = _currentInput.length - 1;
    if (_currentInput[index] != _sequence[index]) {
      setState(() {
        _gameOver = true;
      });
      return;
    }

    if (_currentInput.length == _sequence.length) {
      // Completed sequence
      setState(() {
        _score += 10 * _sequenceLength;
        _sequenceLength++;
      });
      _startRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Audio/Visual Recall", centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.format_list_numbered, "Level: ${_sequenceLength - 2}", theme.colorScheme.primary),
                _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
              ],
            ),
            const Spacer(),
            if (_gameOver)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text("Game Over!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
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
            else if (_isPlayingSequence)
               Center(
                 child: Text(
                   _flashWord, 
                   style: GoogleFonts.poppins(fontSize: 64, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                 ),
               )
            else
              Column(
                children: [
                  Text("Repeat the sequence!", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text("Progress: ${_currentInput.length} / ${_sequence.length}", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _words.map((word) {
                      return ElevatedButton(
                        onPressed: () => _handleInput(word),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                          ),
                        ),
                        child: Text(word, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      );
                    }).toList(),
                  )
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
