import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    
    if (_controller.text.trim().toUpperCase() == _currentWord) {
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
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Wrong! Try again."), backgroundColor: Colors.red, duration: Duration(milliseconds: 500))
       );
    }
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
             Text("1. Unscramble the letters to form a word.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("2. All words are related to School/Education.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("3. Type the word and tap Check.", style: GoogleFonts.poppins()),
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
