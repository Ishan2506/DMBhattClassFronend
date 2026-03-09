import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class PrefixSuffixMakerScreen extends StatefulWidget {
  const PrefixSuffixMakerScreen({super.key});

  @override
  State<PrefixSuffixMakerScreen> createState() => _PrefixSuffixMakerScreenState();
}

class _PrefixSuffixMakerScreenState extends State<PrefixSuffixMakerScreen> {
  final MindGameService _gameService = MindGameService();
  int _score = 0;
  int _timeLeft = 45;
  Timer? _timer;
  bool _gameOver = false;
  
  final List<Map<String, dynamic>> _questions = [
    {"root": "Happy", "affix": "un", "type": "prefix", "wrong": ["re", "pre", "dis"]},
    {"root": "Comfortable", "affix": "un", "type": "prefix", "wrong": ["dis", "im", "in"]},
    {"root": "Possible", "affix": "im", "type": "prefix", "wrong": ["un", "in", "dis"]},
    {"root": "Agree", "affix": "dis", "type": "prefix", "wrong": ["un", "im", "re"]},
    {"root": "Build", "affix": "re", "type": "prefix", "wrong": ["un", "dis", "im"]},
    {"root": "Help", "affix": "ful", "type": "suffix", "wrong": ["less", "ness", "ish"]},
    {"root": "Care", "affix": "less", "type": "suffix", "wrong": ["ful", "ment", "tion"]},
    {"root": "Sad", "affix": "ness", "type": "suffix", "wrong": ["ly", "ment", "ful"]},
    {"root": "Act", "affix": "ion", "type": "suffix", "wrong": ["ment", "ness", "ly"]},
    {"root": "Develop", "affix": "ment", "type": "suffix", "wrong": ["ion", "ness", "ful"]},
  ];

  late Map<String, dynamic> _currentQuestion;
  List<String> _currentOptions = [];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startRound();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _startRound();
  }

  void _startRound() {
    setState(() {
      _timeLeft = 45;
      _gameOver = false;
    });
    _generateQuestion();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _gameOver = true;
        });
      }
    });
  }

  void _generateQuestion() {
    _questions.shuffle();
    _currentQuestion = _questions.first;
    _currentOptions = [_currentQuestion['affix'], ...(_currentQuestion['wrong'] as List<String>)];
    _currentOptions.shuffle();
    setState(() {});
  }

  void _checkAnswer(String answer) {
    if (_gameOver) return;

    if (answer == _currentQuestion['affix']) {
      setState(() {
        _score += 10;
        _timeLeft += 3;
      });
      _generateQuestion();
    } else {
      setState(() {
        _timeLeft = (_timeLeft - 3).clamp(0, 999);
      });
      _generateQuestion();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! -3 seconds", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 500),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isPrefix = _currentQuestion['type'] == 'prefix';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Prefix & Suffix Maker", centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(Icons.timer, "$_timeLeft s", _timeLeft < 10 ? Colors.red : theme.colorScheme.primary),
                _buildInfoBadge(Icons.star, "Score: $_score", Colors.amber[800]!),
              ],
            ),
            const Spacer(),
            if (_gameOver)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text("Time's Up!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   Text("Final Score: $_score", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600)),
                   const SizedBox(height: 32),
                   ElevatedButton(
                     onPressed: _startNewGame,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                       backgroundColor: theme.colorScheme.primary,
                       foregroundColor: theme.colorScheme.onPrimary,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                     ),
                     child: Text("Play Again", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                   )
                ],
              )
            else
              Column(
                children: [
                   Text(
                    isPrefix ? "Choose the correct PREFIX" : "Choose the correct SUFFIX",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPrefix)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 2, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("?", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ),
                      Text(
                        _currentQuestion['root'], 
                        style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      if (!isPrefix)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 2, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("?", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 2,
                       crossAxisSpacing: 16,
                       mainAxisSpacing: 16,
                       childAspectRatio: 2.5,
                    ),
                    itemCount: _currentOptions.length,
                    itemBuilder: (context, index) {
                      String opt = _currentOptions[index];
                      return ElevatedButton(
                        onPressed: () => _checkAnswer(opt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                          ),
                        ),
                        child: Text(
                          isPrefix ? "$opt-" : "-$opt",
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                        ),
                      );
                    },
                  ),
                ],
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
