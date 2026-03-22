import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class SynonymAntonymScreen extends StatefulWidget {
  const SynonymAntonymScreen({super.key});

  @override
  State<SynonymAntonymScreen> createState() => _SynonymAntonymScreenState();
}

class WordPair {
  final String word1;
  final String word2;
  final bool isSynonym;

  WordPair(this.word1, this.word2, this.isSynonym);

  factory WordPair.fromGameQuestion(GameQuestion q) {
    return WordPair(
      q.questionText, // Word 1
      q.options.isNotEmpty ? q.options[0] : "", // Word 2
      q.correctAnswer.toLowerCase() == 'synonym', // Relationship
    );
  }
}

class _SynonymAntonymScreenState extends State<SynonymAntonymScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();
  
  int _score = 0;
  int _currentIndex = 0;
  
  List<WordPair> _sessionPairs = [];
  bool _isLoading = true;
  bool? _selectedIsSynonym; // For radio buttons

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
      final response = await ApiService.getGameQuestions('Synonym & Antonym');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sessionPairs = data.map((json) => WordPair.fromGameQuestion(GameQuestion.fromJson(json))).toList();
          if (_sessionPairs.isNotEmpty) {
            _sessionPairs.shuffle();
          }
          _score = 0;
          _currentIndex = 0;
          _isLoading = false;
          _selectedIsSynonym = null;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching synonym pairs: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _checkAnswer(bool guessIsSynonym) {
    if (guessIsSynonym == _sessionPairs[_currentIndex].isSynonym) {
      setState(() {
        _score += 10;
        _currentIndex++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correct!"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect! Think about their meanings."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {
        _currentIndex++;
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
              _buildInstructionRow(theme, "1", "Two words will be presented on the screen."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Synonym means the words have SIMILAR meanings."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Antonym means the words have OPPOSITE meanings."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Determine the relationship and tap the correct button!"),
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
                      "Happy - Joyful",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Synonyms",
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
      return CustomLoader();
    }

    if (_sessionPairs.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: "Synonym & Antonym", centerTitle: true),
        body: Center(child: Text("No word pairs found.", style: GoogleFonts.poppins())),
      );
    }

    if (_currentIndex >= _sessionPairs.length) {
       return Scaffold(
          appBar: CustomAppBar(title: "Synonym & Antonym", centerTitle: true),
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
    final pair = _sessionPairs[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Synonym & Antonym",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: _isLoading 
        ? CustomLoader()
        : _sessionPairs.isEmpty
          ? Center(child: Text("No word pairs found.", style: GoogleFonts.poppins()))
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Score Board
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pair ${_currentIndex + 1}/${_sessionPairs.length}",
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
              
              // Word Pair Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      pair.word1,
                      style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Icon(Icons.sync_alt, size: 40, color: Colors.grey.shade400),
                    ),
                    Text(
                      pair.word2,
                      style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex++;
                  });
                },
                child: Text(
                  AppLocalizations.of(context)!.skip,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                ),
              ),
              const Spacer(),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _checkAnswer(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("SYNONYM", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _checkAnswer(false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("ANTONYM", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
