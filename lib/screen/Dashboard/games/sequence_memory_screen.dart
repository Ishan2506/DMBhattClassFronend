import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class SequenceMemoryScreen extends StatefulWidget {
  const SequenceMemoryScreen({super.key});

  @override
  State<SequenceMemoryScreen> createState() => _SequenceMemoryScreenState();
}

class _SequenceMemoryScreenState extends State<SequenceMemoryScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();

  int _score = 0;
  int _level = 1;

  List<int> _sequence = [];
  int _playerIndex = 0;
  bool _isPlayingSequence = false;
  int? _activePad; // The pad currently highlighted

  final List<Color> _padColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startLevel();
  }

  void _startLevel() {
    _sequence.add(_random.nextInt(4));
    _playerIndex = 0;
    _playSequence();
  }

  void _playSequence() async {
    setState(() {
      _isPlayingSequence = true;
    });

    await Future.delayed(const Duration(seconds: 1)); // Pause before starting

    for (int padIndex in _sequence) {
      if (!mounted) return;
      
      setState(() {
        _activePad = padIndex;
      });
      
      // Light up duration
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      setState(() {
        _activePad = null;
      });
      
      // Gap between lights
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (mounted) {
      setState(() {
        _isPlayingSequence = false;
      });
    }
  }

  void _onPadPressed(int index) {
    if (_isPlayingSequence) return;

    setState(() {
      _activePad = index;
    });

    // Provide immediate visual feedback
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _activePad = null;
        });
      }
    });

    if (index == _sequence[_playerIndex]) {
      // Correct!
      _playerIndex++;
      
      if (_playerIndex == _sequence.length) {
        // Level complete
        setState(() {
           _score += 10 * _level;
           _level++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Good memory!"),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 500),
          ),
        );
        _startLevel();
      }
    } else {
      // Wrong!
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Over!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You reached Level $_level.\nFinal Score: $_score",
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                  _score = 0;
                  _level = 1;
                  _sequence = [];
                  _startLevel();
              });
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit game
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.videogame_asset, color: colorScheme.primary, size: 28),
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
              _buildInstructionRow(theme, "1", "Watch the colored pads light up in a specific sequence."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Wait until the sequence is finished playing."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Tap the pads in the EXACT SAME order."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Each round adds one more step to the sequence. How far can you go?"),
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
                        _buildMiniPad(Colors.red, true),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                        _buildMiniPad(Colors.blue, false),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                        _buildMiniPad(Colors.green, true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Watch the sequence: Red -> Blue -> Green, then tap them in that order.",
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: Text("Let's Play!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPad(Color color, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? Colors.white : Colors.transparent, width: 2),
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
        title: "Sequence Memory",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score Board
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Level $_level",
                    style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Score: $_score",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              _isPlayingSequence ? "Watch carefully..." : "Your turn!",
              style: GoogleFonts.poppins(
                 fontSize: 24, 
                 fontWeight: FontWeight.bold,
                 color: _isPlayingSequence ? Colors.orange : Colors.green
              ),
            ),
            
            const Spacer(),
            
            // The 2x2 Grid Pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    bool isActive = _activePad == index;
                    return GestureDetector(
                      onTap: () => _onPadPressed(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isActive ? _padColors[index] : _padColors[index].withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                             color: isActive ? Colors.white : Colors.transparent, 
                             width: 4
                          ),
                          boxShadow: isActive ? [
                              BoxShadow(color: _padColors[index].withOpacity(0.8), blurRadius: 20, spreadRadius: 5)
                          ] : [],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
