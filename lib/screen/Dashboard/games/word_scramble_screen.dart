import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  final MindGameService _gameService = MindGameService();
  
  String _currentWord = "";
  String _scrambledWord = "";
  int _score = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isGameOver = false;
  final TextEditingController _controller = TextEditingController();
  
  List<GameQuestion> _allQuestions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
     try {
      final response = await ApiService.getGameQuestions('Word Scramble');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allQuestions = data.map((json) => GameQuestion.fromJson(json)).toList();
          _allQuestions.shuffle();
          _isLoading = false;
        });
        if (_allQuestions.isNotEmpty) {
          _startRound();
        }
      } else {
         setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching questions: $e");
       setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _currentQuestionIndex = 0;
    _allQuestions.shuffle();
    _startRound();
  }
  
  void _startRound() {
    if (_allQuestions.isEmpty) return;
    
    _timeLeft = 60;
    _isGameOver = false;
    _loadQuestion();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isGameOver = true;
          _scrambledWord = _currentWord; // Reveal
          _controller.clear(); 
        });
      }
    });
  }

  void _loadQuestion() {
    if (_currentQuestionIndex >= _allQuestions.length) {
      _currentQuestionIndex = 0;
      _allQuestions.shuffle();
    }
    
    final q = _allQuestions[_currentQuestionIndex];
    
    _currentWord = q.correctAnswer;
    
    // Logic: If questionText is same as answer, we scramble it. 
    // If different, we assume questionText is already scrambled or instructions.
    if (q.questionText == q.correctAnswer) {
      List<String> chars = _currentWord.split('');
      chars.shuffle();
      _scrambledWord = chars.join();
      // Ensure it's not same
      if (_scrambledWord == _currentWord && _currentWord.length > 1) {
         _loadQuestion(); // Retry scrambling (recursive but simple)
         return;
      }
    } else {
      _scrambledWord = q.questionText;
    }

    setState(() {});
  }
  
  void _submitAnswer() {
    if (_isGameOver) return;
    
    final input = _controller.text.trim().toUpperCase();
    if (input == _currentWord) {
       setState(() {
         _score += 10;
         _timeLeft += 5; // Bonus time
         _controller.clear();
         _currentQuestionIndex++;
       });
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Correct! +5s"), backgroundColor: Colors.green, duration: Duration(milliseconds: 500))
       );
       _loadQuestion();
    } else {
       setState(() {
         _timeLeft = max(0, _timeLeft - 3); // Penalty
         _controller.clear();
         _currentQuestionIndex++;
       });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Wrong! The word was $_currentWord (-3s)"), backgroundColor: Colors.red, duration: const Duration(seconds: 1))
       );
       _loadQuestion();
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
              _buildInstructionRow(theme, "1", "Unscramble the given letters to form a valid word."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "All words are related to School and Education."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Type the word and tap Check."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", "Correct answers give bonus time. Wrong answers give a time penalty!"),
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
                      "CHLOOS",
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_downward_rounded, color: theme.dividerColor, size: 20),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "SCHOOL",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16, letterSpacing: 2),
                      ),
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
        title: "Word Scramble",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
       body: _isLoading 
        ? const CustomLoader()
        : _allQuestions.isEmpty 
            ? Center(child: Text("No questions available", style: GoogleFonts.poppins()))
            : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildBadge(Icons.timer, "$_timeLeft", Colors.orange),
                 _buildBadge(Icons.star, "$_score", theme.colorScheme.primary),
               ],
             ),
             
             const Spacer(),
             
             Text(
               _isGameOver ? "Time Up!" : "Unscramble:",
               style: GoogleFonts.poppins(
                 fontSize: 18, 
                 color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
               ),
             ),
             const SizedBox(height: 16),
             Text(
               _scrambledWord,
               style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4, color: theme.colorScheme.primary),
               textAlign: TextAlign.center,
             ),
             
             const SizedBox(height: 48),
             
             if (!_isGameOver)
             TextField(
               controller: _controller,
               textCapitalization: TextCapitalization.characters,
               textAlign: TextAlign.center,
               style: GoogleFonts.poppins(
                 fontSize: 24, 
                 fontWeight: FontWeight.bold,
                 color: theme.textTheme.bodyLarge?.color
               ),
               decoration: InputDecoration(
                 hintText: "Enter Word",
                 hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                 filled: true,
                 fillColor: theme.cardColor,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(16), 
                   borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))
                 ),
                 enabledBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(16), 
                   borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))
                 ),
               ),
               onSubmitted: (_) => _submitAnswer(),
             ),
             
             if (!_isGameOver)
             const SizedBox(height: 24),
             
             if (!_isGameOver)
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _submitAnswer,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: theme.colorScheme.primary,
                   foregroundColor: theme.colorScheme.onPrimary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
                 child: Text("Check", style: GoogleFonts.poppins(fontSize: 18)),
               ),
             ),
             
             if (_isGameOver) ...[
                  Text(
                    "The word was: $_currentWord", 
                    style: GoogleFonts.poppins(
                      fontSize: 20, 
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color
                    )
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _startNewGame();
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text("Play Again")
                  )
             ],
             
             const Spacer(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
