import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class GrammarSorterScreen extends StatefulWidget {
  const GrammarSorterScreen({super.key});

  @override
  State<GrammarSorterScreen> createState() => _GrammarSorterScreenState();
}

class GrammarWord {
  final String word;
  final String category; // 'Noun', 'Verb', 'Adjective'

  GrammarWord(this.word, this.category);
}

class _GrammarSorterScreenState extends State<GrammarSorterScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();
  
  int _score = 0;
  int _level = 1;
  int _lives = 3;
  
  List<GrammarWord> _wordsToFall = [];
  List<GrammarWord> _fallingWords = [];
  
  // A master list of words
  final List<GrammarWord> _allWords = [
    GrammarWord("Apple", "Noun"), GrammarWord("Dog", "Noun"), GrammarWord("City", "Noun"),
    GrammarWord("Table", "Noun"), GrammarWord("River", "Noun"), GrammarWord("Ocean", "Noun"),
    GrammarWord("Run", "Verb"), GrammarWord("Jump", "Verb"), GrammarWord("Speak", "Verb"),
    GrammarWord("Eat", "Verb"), GrammarWord("Sleep", "Verb"), GrammarWord("Think", "Verb"),
    GrammarWord("Happy", "Adjective"), GrammarWord("Blue", "Adjective"), GrammarWord("Tall", "Adjective"),
    GrammarWord("Fast", "Adjective"), GrammarWord("Bright", "Adjective"), GrammarWord("Loud", "Adjective"),
  ];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startSession();
  }

  void _startSession() {
    _score = 0;
    _level = 1;
    _lives = 3;
    _generateLevel();
  }

  void _generateLevel() {
    _wordsToFall = List.from(_allWords)..shuffle();
    _fallingWords = [_wordsToFall.removeLast()];
    // Normally we'd use an AnimationController for real falling pieces,
    // but a simpler drag-and-drop bucket system is better for this minigame
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _checkDrop(String bucketCategory, GrammarWord word) {
    if (bucketCategory == word.category) {
      setState(() {
        _score += 10;
        _fallingWords.remove(word);
        if (_wordsToFall.isNotEmpty) {
           _fallingWords.add(_wordsToFall.removeLast());
        } else {
           // Level complete
           _level++;
           _generateLevel();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("+10 Points!"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      setState(() {
        _lives--;
        if (_lives <= 0) {
            _showGameOverDialog();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! It's a ${word.category}. LIVES: $_lives"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Over!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You ran out of lives.\nFinal Score: $_score\nLevel Reached: $_level",
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
              _buildInstructionRow(theme, "1", "A word will appear in the center of the screen."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Determine if the word is a NOUN, VERB, or ADJECTIVE."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Drag the word into the correct bucket at the bottom."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "You have 3 lives. Make sure you drop it in the right bucket!"),
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
                      "Example Idea",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "'Happy' -> Drop into ADJECTIVE bucket",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "'Run' -> Drop into VERB bucket",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
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
    if (_lives <= 0) {
        return const Scaffold();
    }
  
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Grammar Sorter",
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
            // Header Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (index) => Icon(
                      Icons.favorite,
                      color: index < _lives ? Colors.red : Colors.grey.shade300,
                      size: 28,
                    )),
                  ),
                  Text(
                    "Lvl $_level",
                    style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      "$_score pt",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: Stack(
                 alignment: Alignment.center,
                 children: _fallingWords.map((wordObj) {
                    return Positioned(
                       top: MediaQuery.of(context).size.height * 0.2, // Simplified for drag and drop
                       child: Draggable<GrammarWord>(
                         data: wordObj,
                         feedback: Material(
                           color: Colors.transparent,
                           child: _buildWordChip(wordObj.word, theme, isDragging: true),
                         ),
                         childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildWordChip(wordObj.word, theme),
                         ),
                         child: _buildWordChip(wordObj.word, theme),
                       ),
                    );
                 }).toList(),
              )
            ),
            
            // Buckets
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBucket("Noun", Colors.blue),
                  _buildBucket("Verb", Colors.green),
                  _buildBucket("Adjective", Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWordChip(String text, ThemeData theme, {bool isDragging = false}) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
             color: theme.colorScheme.primary,
             borderRadius: BorderRadius.circular(24),
             boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: isDragging ? 20 : 10, offset: Offset(0, isDragging ? 10 : 4))
             ],
          ),
          child: Text(
             text,
             style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                decoration: TextDecoration.none,
             ),
          ),
      );
  }

  Widget _buildBucket(String title, Color color) {
    return DragTarget<GrammarWord>(
      onWillAccept: (data) => true,
      onAccept: (data) => _checkDrop(title, data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: 100,
          height: 120,
          decoration: BoxDecoration(
            color: isHovered ? color.withOpacity(0.4) : color.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
               bottomLeft: Radius.circular(32),
               bottomRight: Radius.circular(32),
               topLeft: Radius.circular(8),
               topRight: Radius.circular(8),
            ),
            border: Border.all(color: color, width: isHovered ? 4 : 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.archive_outlined, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
