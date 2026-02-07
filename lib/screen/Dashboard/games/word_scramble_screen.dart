import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  final List<String> _words = [
    "EDUCATION", "FLUTTER", "SCHOOL", "STUDENT", "TEACHER", 
    "HOMEWORK", "EXAM", "LIBRARY", "SCISSORS", "HISTORY",
    "SCIENCE", "MATH", "ENGLISH", "PHYSICS", "CHEMISTRY"
  ];
  
  String _currentWord = "";
  String _scrambledWord = "";
  String _userGuess = "";
  int _score = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isGameOver = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _startRound();
  }
  
  void _startRound() {
    _timeLeft = 60;
    _isGameOver = false;
    _nextWord();
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
        });
      }
    });
  }




  void _nextWord() {
    _currentWord = _words[Random().nextInt(_words.length)];
    List<String> chars = _currentWord.split('');
    chars.shuffle();
    _scrambledWord = chars.join();
    // Ensure it's not same
    if (_scrambledWord == _currentWord) {
      _nextWord(); 
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
       });
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Correct! +5s"), backgroundColor: Colors.green, duration: Duration(milliseconds: 500))
       );
       _nextWord();
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
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildBadge(Icons.timer, "$_timeLeft", Colors.orange),
                 _buildBadge(Icons.star, "$_score", Colors.deepPurple),
               ],
             ),
             
             const Spacer(),
             
             Text(
               _isGameOver ? "Time Up!" : "Unscramble:",
               style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
             ),
             const SizedBox(height: 16),
             Text(
               _scrambledWord,
               style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.deepPurple),
               textAlign: TextAlign.center,
             ),
             
             const SizedBox(height: 48),
             
             if (!_isGameOver)
             TextField(
               controller: _controller,
               textCapitalization: TextCapitalization.characters,
               textAlign: TextAlign.center,
               style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
               decoration: InputDecoration(
                 hintText: "Enter Word",
                 filled: true,
                 fillColor: Colors.white,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
                   backgroundColor: Colors.deepPurple,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
                 child: Text("Check", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
               ),
             ),
             
             if (_isGameOver) ...[
                 Text("The word was: $_currentWord", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500)),
                 const SizedBox(height: 24),
                 ElevatedButton(
                   onPressed: () {
                     _timer?.cancel();
                     _startRound(); // Restart
                   }, 
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
