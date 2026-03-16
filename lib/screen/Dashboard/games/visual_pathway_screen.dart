import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class VisualPathwayScreen extends StatefulWidget {
  const VisualPathwayScreen({super.key});

  @override
  State<VisualPathwayScreen> createState() => _VisualPathwayScreenState();
}

class _VisualPathwayScreenState extends State<VisualPathwayScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  bool _gameOver = false;
  
  List<int> _sequence = [];
  List<int> _currentInput = [];
  bool _isPlayingSequence = false;
  int _sequenceLength = 3;
  int _flashIndex = -1;

  final int _gridSize = 3;

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
      _flashIndex = -1;
    });
    _generateSequence();
  }

  void _generateSequence() async {
    final rand = Random();
    int lastTile = -1;
    
    // Generate sequence ensuring no immediate direct repeats for clarity
    for (int i = 0; i < _sequenceLength; i++) {
        int nextTile;
        do {
            nextTile = rand.nextInt(_gridSize * _gridSize);
        } while (nextTile == lastTile);
        _sequence.add(nextTile);
        lastTile = nextTile;
    }

    setState(() {
      _isPlayingSequence = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    for (int tileIndex in _sequence) {
      if (!mounted) return;
      setState(() {
        _flashIndex = tileIndex;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _flashIndex = -1;
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() {
      _isPlayingSequence = false;
    });
  }

  void _handleInput(int index) {
    if (_isPlayingSequence || _gameOver) return;

    setState(() {
      _currentInput.add(index);
    });

    int curLen = _currentInput.length - 1;
    if (_currentInput[curLen] != _sequence[curLen]) {
      setState(() {
        _gameOver = true;
      });
      return;
    }

    if (_currentInput.length == _sequence.length) {
      setState(() {
        _score += 15 * _sequenceLength;
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
      appBar: const CustomAppBar(title: "Visual Pathway", centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.route, "Path Len: $_sequenceLength", theme.colorScheme.primary),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
                    TextButton.icon(
                      onPressed: () {
                         _startRound();
                      },
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: Text(
                        AppLocalizations.of(context)!.skip,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_gameOver)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text("Wrong Path!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
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
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isPlayingSequence ? "Watch the path..." : "Trace the exact path!", 
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: _isPlayingSequence ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 48),
                    AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _gridSize * _gridSize,
                        itemBuilder: (context, index) {
                          bool isFlashed = index == _flashIndex;
                          bool isSelected = !_isPlayingSequence && _currentInput.contains(index);
                          
                          return GestureDetector(
                            onTap: () => _handleInput(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isFlashed || isSelected ? theme.colorScheme.primary : theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor.withOpacity(0.3), width: 2),
                                boxShadow: isFlashed || isSelected ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ] : [],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
