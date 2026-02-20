import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/game_question.dart';

class EmojiDecoderScreen extends StatefulWidget {
  const EmojiDecoderScreen({super.key});

  @override
  State<EmojiDecoderScreen> createState() => _EmojiDecoderScreenState();
}

class _EmojiDecoderScreenState extends State<EmojiDecoderScreen> {
  final MindGameService _gameService = MindGameService();

  List<GameQuestion> _allQuestions = [];
  int _currentIndex = 0;
  String _userAnswer = "";
  bool _isGameOver = false;
  int _score = 0;
  int _hintsRemaining = 3;
  TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    MindGameService().startSession(context);
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await ApiService.getGameQuestions('Emoji Decoder');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allQuestions = data.map((json) => GameQuestion.fromJson(json)).toList();
          _allQuestions.shuffle();
          _isLoading = false;
        });
        if (_allQuestions.isNotEmpty) {
           _startLevel();
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
    _controller.dispose();
    super.dispose();
  }

  void _startLevel() {
    setState(() {
      _userAnswer = "";
      _controller.clear();
      _isGameOver = false;
    });
  }

  void _checkAnswer() {
    if (_allQuestions.isEmpty) return;
    
    final question = _allQuestions[_currentIndex];
    String correct = question.correctAnswer.toLowerCase();
    String user = _controller.text.trim().toLowerCase();

    // Simple containment check for keywords or exact match
    List<String> keyWords = correct.split(' ').where((w) => w.length > 2).toList();
    int matches = 0;
    for (var k in keyWords) {
      if (user.contains(k)) matches++;
    }

    bool isCorrect = (user == correct) || (matches >= keyWords.length && keyWords.isNotEmpty);

    if (isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correct! +20 Points"), backgroundColor: Colors.green)
      );
      setState(() {
        _score += 20;
      });
      _nextLevel();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not quite! Try again."), backgroundColor: Colors.red)
      );
    }
  }

  void _nextLevel() {
    if (_currentIndex < _allQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _startLevel();
      });
    } else {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Decoder Master!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("You decoded all the emojis!\nFinal Score: $_score", style: GoogleFonts.poppins()),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text("Exit"),
          ),
          TextButton(
             onPressed: () {
               Navigator.pop(context);
               _restartGame();
             },
             child: const Text("Play Again"),
          )
        ],
      ),
    );
  }
  
  void _restartGame() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _hintsRemaining = 3;
      _isGameOver = false;
      _allQuestions.shuffle();
      _isLoading = false;
    });
    _startLevel();
  }

  void _useHint() {
    if (_allQuestions.isEmpty) return;
    
    if (_hintsRemaining > 0) {
      setState(() {
         _hintsRemaining--;
      });
      
      final question = _allQuestions[_currentIndex];
      // Use meta hint if available, else show first letter or part of answer
      String hintText = question.meta['hint'] ?? "Answer starts with '${question.correctAnswer[0]}...'";
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Hint"),
          content: Text(hintText),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hints remaining!"), backgroundColor: Colors.red)
      );
    }
  }

  void _skipLevel() {
    _nextLevel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Emoji Decoder", centerTitle: true),
        body: const CustomLoader(),
      );
    }
    
    if (_allQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: "Emoji Decoder", centerTitle: true),
        body: Center(child: Text("No questions available", style: GoogleFonts.poppins())),
      );
    }

    final question = _allQuestions[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Emoji Decoder",
        centerTitle: true,
        actions: [
          IconButton(
             icon: Badge(
               isLabelVisible: _hintsRemaining > 0, 
               label: Text("$_hintsRemaining"), 
               child: const Icon(Icons.lightbulb, color: Colors.amber)
             ),
             onPressed: _useHint
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16), 
              child: Text(
                "Score: $_score", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
              )
            )
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const SizedBox(height: 40),
               Text(
                 "Guess the Phrase:",
                 style: GoogleFonts.poppins(
                   color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), 
                   fontSize: 18
                 ),
               ),
               const SizedBox(height: 24),
               Container(
                 padding: const EdgeInsets.all(32),
                 decoration: BoxDecoration(
                   color: theme.cardColor,
                   borderRadius: BorderRadius.circular(24),
                   border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), 
                       blurRadius: 15, 
                       offset: const Offset(0, 8)
                     )
                   ],
                 ),
                 child: Text(
                   question.questionText,
                   style: const TextStyle(fontSize: 64),
                   textAlign: TextAlign.center,
                 ),
               ),
               const SizedBox(height: 48),
               
               TextField(
                 controller: _controller,
                 textAlign: TextAlign.center,
                 style: GoogleFonts.poppins(
                   fontSize: 22, 
                   fontWeight: FontWeight.bold,
                   color: theme.textTheme.bodyLarge?.color
                 ),
                 decoration: InputDecoration(
                   hintText: "Type the phrase...",
                   hintStyle: GoogleFonts.poppins(color: theme.dividerColor),
                   filled: true,
                   fillColor: theme.cardColor,
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(16), 
                     borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2))
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(16), 
                     borderSide: BorderSide(color: theme.colorScheme.primary)
                   ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                 ),
                 onSubmitted: (_) => _checkAnswer(),
               ),
               
               const SizedBox(height: 32),
               
               SizedBox(
                 width: double.infinity,
                 height: 55,
                 child: ElevatedButton(
                   onPressed: _checkAnswer,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: theme.colorScheme.primary,
                     foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     elevation: 8,
                   ),
                   child: Text("Decode", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                 ),
               ),

               const SizedBox(height: 24),
               TextButton(
                 onPressed: _useHint,
                 child: Text(
                   "Need a Hint? ($_hintsRemaining left)", 
                   style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                 ),
               ),
               
               const SizedBox(height: 12),
               TextButton(
                 onPressed: _skipLevel,
                 child: Text(
                   "Skip Level", 
                   style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }
}
