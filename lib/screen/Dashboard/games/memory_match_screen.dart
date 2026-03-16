import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart'; 
// Assuming app_images is where we might pull some assets, 
// but we'll use icons or simple text for memory cards.

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  // Game Configuration
  final MindGameService _gameService = MindGameService();
  final int _gridSize = 4; // 4x4 grid = 16 cards
  late List<String> _cardContents;
  late List<bool> _cardFlipped;
  late List<bool> _cardMatched;
  
  List<int> _flippedIndices = [];
  int _score = 0;
  bool _isProcessing = false;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
    _gameService.startSession(context);
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _score = 0;
    _startTimer();

    // 8 pairs of icons for 16 cards
    final List<String> icons = [
      "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼"
    ];
    
    _cardContents = [...icons, ...icons];
    _cardContents.shuffle();
    
    _cardFlipped = List.generate(16, (_) => false);
    _cardMatched = List.generate(16, (_) => false);
    _flippedIndices = [];
    _isProcessing = false;
    
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing || _cardFlipped[index] || _cardMatched[index]) return;

    setState(() {
      _cardFlipped[index] = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      _checkForMatch();
    }
  }

  void _checkForMatch() async {
    _isProcessing = true;
    final index1 = _flippedIndices[0];
    final index2 = _flippedIndices[1];

    if (_cardContents[index1] == _cardContents[index2]) {
      // Match found
      setState(() {
        _cardMatched[index1] = true;
        _cardMatched[index2] = true;
        _score += 100; // Points for match
        _flippedIndices.clear();
        _isProcessing = false;
      });

      if (_cardMatched.every((element) => element)) {
        _timer?.cancel();
        _showWinDialog();
      }
    } else {
      // No match
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _cardFlipped[index1] = false;
          _cardFlipped[index2] = false;
          _flippedIndices.clear();
          _isProcessing = false;
        });
      }
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Congratulations!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("You matched all pairs!", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Text("Time: $_secondsElapsed seconds", style: GoogleFonts.poppins()),
              Text("Score: $_score", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to menu
              },
              child: const Text("Exit"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              child: const Text("Play Again"),
            ),
          ],
        );
      },
    );
  }

  void _showHowToPlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videogame_asset,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "How to Play",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Instructions
              _buildInstructionRow(theme, "1", "Tap a card to flip it over and reveal the icon."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Try to find the matching card by remembering where icons are located."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Match all pairs as quickly as possible to win!"),
              const SizedBox(height: 24),
              // Example Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.tertiary.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Example",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniCard(theme, "🐼", isFlipped: true),
                        const SizedBox(width: 8),
                        _buildMiniCard(theme, "", isFlipped: false),
                        const SizedBox(width: 8),
                        _buildMiniCard(theme, "🐼", isFlipped: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Find the matching pairs! (🐼 & 🐼)",
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Got it button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: Text(
                  "Let's Play!",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCard(ThemeData theme, String content, {bool isFlipped = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isFlipped ? theme.cardColor : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
        border: isFlipped ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Center(
        child: isFlipped
            ? Text(content, style: const TextStyle(fontSize: 20))
            : Icon(Icons.question_mark_rounded, color: theme.colorScheme.onPrimary, size: 20),
      ),
    );
  }

  Widget _buildInstructionRow(ThemeData theme, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Memory Match",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
          TextButton.icon(
            onPressed: () {
              // Mark all as matched to skip or just restart
              // Better to just show win dialog to go to next if game logic supports it
              // For this simple game, we'll just restart a new grid
              _startNewGame();
            },
            icon: const Icon(Icons.skip_next, color: Colors.white),
            label: Text(
              AppLocalizations.of(context)!.skip,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _startNewGame(),
          )
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "$_secondsElapsed s", 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, 
                          color: theme.colorScheme.primary
                        )
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Score: $_score", 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, 
                          color: Colors.amber[800]
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                return _buildCard(index);
              },
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final theme = Theme.of(context);
    bool isFlipped = _cardFlipped[index] || _cardMatched[index];
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isFlipped ? theme.cardColor : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isFlipped 
              ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 2) 
              : null,
        ),
        child: Center(
          child: isFlipped
              ? Text(
                  _cardContents[index],
                  style: const TextStyle(fontSize: 32),
                )
              : Icon(
                  Icons.question_mark_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 32,
                ),
        ),
      ),
    );
  }
}
