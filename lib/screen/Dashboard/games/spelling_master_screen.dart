import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class SpellingMasterScreen extends StatefulWidget {
  const SpellingMasterScreen({super.key});

  @override
  State<SpellingMasterScreen> createState() => _SpellingMasterScreenState();
}

class SpellingWord {
  final String word;
  final String definition;

  SpellingWord(this.word, this.definition);

  factory SpellingWord.fromGameQuestion(GameQuestion q) {
    return SpellingWord(
      q.correctAnswer, // Correct word
      q.questionText,  // Definition
    );
  }
}

class _SpellingMasterScreenState extends State<SpellingMasterScreen> {
  final MindGameService _gameService = MindGameService();
  final TextEditingController _textController = TextEditingController();
  
  int _score = 0;
  int _currentIndex = 0;
  
  List<SpellingWord> _sessionWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startSession();
  }

  void _startSession() {
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Spelling Master');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sessionWords = data.map((json) => SpellingWord.fromGameQuestion(GameQuestion.fromJson(json))).toList();
          if (_sessionWords.isNotEmpty) {
            _sessionWords.shuffle();
          }
          _score = 0;
          _currentIndex = 0;
          _isLoading = false;
          _textController.clear();
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching spelling words: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _textController.dispose();
    super.dispose();
  }

  void _checkWord() {
    final input = _textController.text.trim().toUpperCase();
    final correctWord = _sessionWords[_currentIndex].word.toUpperCase();
    
    if (input == correctWord) {
      setState(() {
        _score += 15;
        _currentIndex++;
        _textController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfect Spelling!"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1000),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incorrect! The correct spelling is $correctWord."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _currentIndex++;
        _textController.clear();
      });
    }
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
              _buildInstructionRow(theme, "1", "Read the definition provided on the screen."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Identify the word that matches the definition."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Type the word with the correct spelling."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Tap Submit. Watch out for tricky double letters!"),
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
                      "Definition: To provide lodging or sufficient space for.",
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
                        "ACCOMMODATE",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
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
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sessionWords.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: "Spelling Master", centerTitle: true),
        body: Center(child: Text("No spelling words found.", style: GoogleFonts.poppins())),
      );
    }

    if (_currentIndex >= _sessionWords.length) {
       return Scaffold(
          appBar: CustomAppBar(title: "Spelling Master", centerTitle: true),
          body: Center(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text("Game Over!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                   const SizedBox(height: 16),
                   Text("Final Score: $_score", style: GoogleFonts.poppins(fontSize: 24)),
                   const SizedBox(height: 32),
                   ElevatedButton(
                      onPressed: () => setState(() => _startSession()),
                      style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                         backgroundColor: theme.colorScheme.primary,
                         foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: Text("Play Again", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                   )
                ],
             ),
          )
       );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Spelling Master",
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score Board
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Word ${_currentIndex + 1}/${_sessionWords.length}",
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
              
              const Spacer(),
              
              // Definition Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      "Definition",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _sessionWords[_currentIndex].definition,
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Text Input
              TextField(
                controller: _textController,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: "TYPE SPELLING HERE",
                  hintStyle: GoogleFonts.poppins(fontSize: 16, letterSpacing: 2, color: Colors.grey),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                onSubmitted: (_) => _checkWord(),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _checkWord,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("Submit Spelling", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex++;
                    _textController.clear();
                  });
                },
                child: Text(
                  AppLocalizations.of(context)!.skip,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
