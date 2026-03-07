import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class DirectionSenseScreen extends StatefulWidget {
  const DirectionSenseScreen({super.key});

  @override
  State<DirectionSenseScreen> createState() => _DirectionSenseScreenState();
}

class DirectionPuzzle {
  final String text;
  final String question;
  final String answer; // North, South, East, West

  DirectionPuzzle(this.text, this.question, this.answer);
}

class _DirectionSenseScreenState extends State<DirectionSenseScreen> {
  final MindGameService _gameService = MindGameService();

  int _currentIndex = 0;
  int _score = 0;

  final List<DirectionPuzzle> _allPuzzles = [
    DirectionPuzzle(
      "Rahul walked 10 meters North. Then he turned left and walked 5 meters. Then he turned left again and walked 10 meters.",
      "In which direction is he facing now?",
      "South"
    ),
    DirectionPuzzle(
      "Priya faces East. She turns 90 degrees clockwise. Then she turns 180 degrees anti-clockwise.",
      "In which direction is she facing now?",
      "North"
    ),
    DirectionPuzzle(
      "Amit walks South. He takes a right turn, walks a bit, then takes a left turn.",
      "In which direction is he walking now?",
      "South"
    ),
    DirectionPuzzle(
      "Sneha is facing North-West. She turns 90 degrees clockwise, then 180 degrees anti-clockwise.",
      "In which general direction is she facing?",
      "South-West" // We'll simplify options to standard 8 later, or stick to N/S/E/W for simplicity. Let's stick to N/S/E/W for this level.
    ),
    DirectionPuzzle(
      "A man walks 5km East, then turns left and walks 5km, then turns right and walks 5km.",
      "In which direction is he walking finally?",
      "East"
    ),
    DirectionPuzzle(
      "You are facing West. You turn 180 degrees.",
      "Which direction are you facing?",
      "East"
    )
  ];

  late List<DirectionPuzzle> _sessionPuzzles;
  final List<String> _options = ["North", "South", "East", "West", "North-East", "North-West", "South-East", "South-West"];
  List<String> _currentOptions = [];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startSession();
  }

  void _startSession() {
    _sessionPuzzles = List.from(_allPuzzles)
      ..removeWhere((p) => p.answer.contains("-")) // Keep it simple to 4 main directions for now
      ..shuffle();
    _currentIndex = 0;
    _score = 0;
    _loadQuestion();
  }

  void _loadQuestion() {
     if (_currentIndex < _sessionPuzzles.length) {
         _currentOptions = ["North", "South", "East", "West"]; // Always show the 4 main directions
     } else {
         _showWinDialog();
     }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _checkAnswer(String selectedDirection) {
    if (selectedDirection == _sessionPuzzles[_currentIndex].answer) {
      setState(() {
        _score += 20;
        _currentIndex++;
        _loadQuestion();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Spot on!"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incorrect! The answer was ${_sessionPuzzles[_currentIndex].answer}."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _currentIndex++;
        _loadQuestion();
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Quest Complete!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You scored $_score out of ${_sessionPuzzles.length * 20} points.",
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _startSession());
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
              _buildInstructionRow(theme, "1", "Read the movement scenario carefully."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Visualize or trace the path described (e.g., turning left, walking North)."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Determine the final direction the person is facing or walking."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Select the correct direction from the options."),
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
                    Text(
                      "Face North. Turn right. Turn right again.",
                      style: GoogleFonts.poppins(fontSize: 14, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Answer: South",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
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
                child: Text("Got it!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        ),
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

  IconData _getDirectionIcon(String direction) {
      switch (direction) {
          case "North": return Icons.arrow_upward;
          case "South": return Icons.arrow_downward;
          case "East": return Icons.arrow_forward;
          case "West": return Icons.arrow_back;
          default: return Icons.explore;
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _sessionPuzzles.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final puzzle = _sessionPuzzles[_currentIndex];

    // Compass Visualization
    Widget compassWidget = Stack(
       alignment: Alignment.center,
       children: [
          Container(
             width: 160,
             height: 160,
             decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor, width: 4),
                color: theme.cardColor,
             ),
          ),
          Positioned(top: 10, child: Text("N", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary))),
          Positioned(bottom: 10, child: Text("S", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary))),
          Positioned(right: 15, child: Text("E", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary))),
          Positioned(left: 15, child: Text("W", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary))),
          Icon(Icons.explore, size: 80, color: theme.colorScheme.secondary.withOpacity(0.5)),
       ],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Direction Sense",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Score Board
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Puzzle ${_currentIndex + 1}/${_sessionPuzzles.length}",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
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
              
              const SizedBox(height: 32),
              
              compassWidget,

              const SizedBox(height: 32),
              
              // Puzzle Text Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      puzzle.text,
                      style: GoogleFonts.poppins(fontSize: 16, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      puzzle.question,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Options Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _currentOptions.map((dir) {
                    return ElevatedButton.icon(
                      onPressed: () => _checkAnswer(dir),
                      icon: Icon(_getDirectionIcon(dir)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        foregroundColor: theme.colorScheme.secondary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                        ),
                      ),
                      label: Text(
                        dir,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
