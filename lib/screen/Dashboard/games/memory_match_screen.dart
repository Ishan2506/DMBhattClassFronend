import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart'; 
// Assuming app_images is where we might pull some assets, 
// but we'll use icons or simple text for memory cards.

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("How to Play", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("1. Tap a card to flip it.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("2. Try to find the matching card.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("3. Match all pairs to win!", style: GoogleFonts.poppins()),
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
        title: "Memory Match",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
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
