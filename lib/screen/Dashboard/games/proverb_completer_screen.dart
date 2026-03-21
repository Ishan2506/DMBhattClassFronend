import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class ProverbCompleterScreen extends StatefulWidget {
  const ProverbCompleterScreen({super.key});

  @override
  State<ProverbCompleterScreen> createState() => _ProverbCompleterScreenState();
}

class ProverbFact {
  final String start;
  final String end;
  final String missingWord;
  final List<String> options;

  ProverbFact(this.start, this.end, this.missingWord, {this.options = const []});

  factory ProverbFact.fromGameQuestion(GameQuestion q) {
    final parts = q.questionText.split("[BLANK]");
    String start = parts[0];
    String end = parts.length > 1 ? parts[1] : "";
    
    return ProverbFact(
      start, 
      end, 
      q.correctAnswer,
      options: q.options ?? [],
    );
  }
}

class _ProverbCompleterScreenState extends State<ProverbCompleterScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();

  int _currentIndex = 0;
  int _score = 0;
  List<String> _currentOptions = [];
  bool _isLoading = true;

  List<ProverbFact> _allProverbs = [];
  late List<ProverbFact> _sessionProverbs;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Proverb Completer');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allProverbs = data.map((json) => ProverbFact.fromGameQuestion(GameQuestion.fromJson(json))).toList();
          _isLoading = false;
          _startSession();
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching proverb questions: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startSession() {
    if (_allProverbs.isEmpty) return;
    _sessionProverbs = List.from(_allProverbs)..shuffle();
    _currentIndex = 0;
    _score = 0;
    _loadQuestion();
  }

  void _loadQuestion() {
    if (_sessionProverbs.isEmpty) return;
    if (_currentIndex >= _sessionProverbs.length) {
      _showWinDialog();
      return;
    }

    final currentFact = _sessionProverbs[_currentIndex];
    
    if (currentFact.options.isNotEmpty) {
      _currentOptions = List.from(currentFact.options)..shuffle();
    } else {
      // Pick 3 random wrong options from fallback pool
      final wrongOptionsPool = [
        "needle", "thread", "time", "clock", "mind", "heart", "book", "story", 
        "color", "shadow", "truth", "lie", "friend", "enemy", "tree", "leaf",
        "apple", "fruit", "day", "night", "sun", "moon", "star", "sky",
        "water", "fire", "earth", "wind", "gold", "silver", "bronze", "stone"
      ]..shuffle();
          
      // Exclude the correct answer if it happens to be in the pool
      wrongOptionsPool.removeWhere((w) => w.toLowerCase() == currentFact.missingWord.toLowerCase());
          
      _currentOptions = [
        currentFact.missingWord,
        wrongOptionsPool[0],
        wrongOptionsPool[1],
        wrongOptionsPool[2],
      ]..shuffle();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _checkAnswer(String selectedWord) {
    if (selectedWord == _sessionProverbs[_currentIndex].missingWord) {
      setState(() {
        _score += 15;
        _currentIndex++;
        _loadQuestion();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Well said!"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Oops! It was '${_sessionProverbs[_currentIndex].missingWord}'."),
          backgroundColor: Colors.orange,
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
          "You scored $_score out of ${_sessionProverbs.length * 15} points.",
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
              _buildInstructionRow(theme, "1", "A famous English proverb will be shown."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "One key word is missing from the proverb."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Look at the four options provided below."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Select the correct word to complete the sentence!"),
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
                      "Example Proverb",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "An ___ a day keeps the doctor away.",
                      style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic),
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
                        "apple",
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_allProverbs.isEmpty) {
       return Scaffold(
          appBar: const CustomAppBar(title: "Proverb Completer", centerTitle: true),
          body: Center(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.format_quote, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text("No proverbs found.", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                ],
             ),
          ),
       );
    }

    if (_currentIndex >= _sessionProverbs.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final proverb = _sessionProverbs[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Proverb Completer",
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
                    "Proverb ${_currentIndex + 1}/${_sessionProverbs.length}",
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
              
              const Icon(Icons.format_quote, size: 64, color: Colors.purpleAccent),
              const SizedBox(height: 24),
              
              // Proverb Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.lora(fontSize: 26, color: theme.colorScheme.primary, height: 1.5, fontStyle: FontStyle.italic),
                    children: [
                      TextSpan(text: proverb.start),
                      const TextSpan(text: " "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                             border: Border(bottom: BorderSide(color: theme.colorScheme.secondary, width: 3)),
                          ),
                          child: Text(
                             "______________", 
                             style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.3), fontSize: 18)
                          ),
                        ),
                      ),
                      const TextSpan(text: " "),
                      TextSpan(text: proverb.end),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Options Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.0,
                  children: _currentOptions.map((word) {
                    return ElevatedButton(
                      onPressed: () => _checkAnswer(word),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                      ),
                      child: Text(
                        word,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex++;
                    _loadQuestion();
                  });
                },
                child: Text(
                  "Skip",
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
