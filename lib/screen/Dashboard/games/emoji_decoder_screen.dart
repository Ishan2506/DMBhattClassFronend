import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class EmojiDecoderScreen extends StatefulWidget {
  const EmojiDecoderScreen({super.key});

  @override
  State<EmojiDecoderScreen> createState() => _EmojiDecoderScreenState();
}

class _EmojiDecoderScreenState extends State<EmojiDecoderScreen> {
  final MindGameService _gameService = MindGameService();

  final List<Map<String, dynamic>> _levels = [
    {
      "emoji": "🤐 🥈 🥇", 
      "phrase": "Silence is Golden",
      "hint": "Sometimes not speaking is better."
    },
    {
      "emoji": "🥶 🦃", 
      "phrase": "Cold Turkey",
      "hint": "Stopping a habit suddenly."
    },
    {
      "emoji": "🍰 🚶", 
      "phrase": "Piece of Cake", // or Cake Walk
      "hint": "Something very easy."
    },
    {
      "emoji": "🌧️ 🐱 🐶", 
      "phrase": "Raining Cats and Dogs",
      "hint": "Heavy rain."
    },
    {
      "emoji": "💔 🥚", 
      "phrase": "Break a Leg", // Wait no, Heart + Egg? Break an egg? 
      // Let's use simpler ones.
      "phrase": "Heart of Gold",
      "emoji": "💛 🏆",
      "hint": "Very kind person."
    },
    {
      "emoji": "👀 🍎",
      "phrase": "Apple of my Eye",
      "hint": "Someone cherished."
    },
  ];

  int _currentIndex = 0;
  String _userAnswer = "";
  bool _isGameOver = false;
  int _score = 0;
  int _hintsRemaining = 3; // Limited hints for the game
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    MindGameService().startSession(context);
    _levels.shuffle(); // Randomize order
    _startLevel();
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
    String correct = _levels[_currentIndex]["phrase"].toString().toLowerCase();
    String user = _controller.text.trim().toLowerCase();

    // Check for "almost correct" or exact
    // Idioms can vary (e.g. piece of cake vs a piece of cake).
    // Let's check if user contains key words
    
    // Using simple exact match for now, maybe Levenshtein later but keeping it simple.
    // Or key words check.
    List<String> keyWords = correct.split(' ').where((w) => w.length > 2).toList();
    int matches = 0;
    for (var k in keyWords) {
      if (user.contains(k)) matches++;
    }

    // Heuristic: If they get > 70% of keywords right?
    bool isCorrect = (user == correct) || (matches >= keyWords.length);

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
    if (_currentIndex < _levels.length - 1) {
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          )
        ],
      ),
    );
  }

  void _useHint() {
    if (_hintsRemaining > 0) {
      setState(() {
         _hintsRemaining--;
      });
      // Show the ANSWER directly as requested
      final answer = _levels[_currentIndex]["phrase"];
      _controller.text = answer;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Hint Used"),
          content: Text("The answer is:\n\n$answer"),
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
    final level = _levels[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Emoji Decoder",
        centerTitle: true,
        actions: [
          IconButton(
             icon: Badge(isLabelVisible: _hintsRemaining > 0, label: Text("$_hintsRemaining"), child: const Icon(Icons.lightbulb, color: Colors.amber)),
             onPressed: _useHint
          ),
          Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text("Score: $_score", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))))
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
                 "Guess the Idiom:",
                 style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 18),
               ),
               const SizedBox(height: 24),
               Container(
                 padding: const EdgeInsets.all(32),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(24),
                   boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))],
                 ),
                 child: Text(
                   level["emoji"],
                   style: const TextStyle(fontSize: 64), // Emojis need big font
                   textAlign: TextAlign.center,
                 ),
               ),
               const SizedBox(height: 48),
               
               TextField(
                 controller: _controller,
                 textAlign: TextAlign.center,
                 style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                 decoration: InputDecoration(
                   hintText: "Type the phrase...",
                   filled: true,
                   fillColor: Colors.grey.shade100,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                 ),
                 onSubmitted: (_) => _checkAnswer(),
               ),
               
               const SizedBox(height: 24),
               
               SizedBox(
                 width: double.infinity,
                 height: 55,
                 child: ElevatedButton(
                   onPressed: _checkAnswer,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: theme.primaryColor,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     elevation: 8,
                   ),
                   child: Text("Decode", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ),

               const SizedBox(height: 24),
               TextButton(
                 onPressed: () {
                    // Reveal answer cost points? 
                    // For now just show hint
                    _useHint();
                 },
                 child: Text("Need a Hint? ($_hintsRemaining left)", style: TextStyle(color: theme.primaryColor)),
               ),
               
               const SizedBox(height: 12),
               TextButton(
                 onPressed: _skipLevel,
                 child: Text("Skip Level", style: TextStyle(color: Colors.grey[600])),
               )
            ],
          ),
        ),
      ),
    );
  }
}
