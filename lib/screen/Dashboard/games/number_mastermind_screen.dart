import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class NumberMastermindScreen extends StatefulWidget {
  const NumberMastermindScreen({super.key});

  @override
  State<NumberMastermindScreen> createState() => _NumberMastermindScreenState();
}

class MastermindGuess {
  final List<int> digits;
  final int exactMatches; // Right digit, right place
  final int numberMatches; // Right digit, wrong place

  MastermindGuess(this.digits, this.exactMatches, this.numberMatches);
}

class _NumberMastermindScreenState extends State<NumberMastermindScreen> {
  final MindGameService _gameService = MindGameService();

  late List<int> _secretCode;
  List<MastermindGuess> _guesses = [];
  List<int> _currentGuess = [];
  int _score = 0;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _initGame();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _initGame() {
    // Generate 4 unique digits code
    List<int> digits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    digits.shuffle();
    _secretCode = digits.sublist(0, 4);
    
    _guesses.clear();
    _currentGuess.clear();
    _isGameOver = false;
    setState(() {});
  }

  void _onNumpadTap(int val) {
    if (_isGameOver) return;
    
    if (_currentGuess.length < 4) {
      if (_currentGuess.contains(val)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code digits must be unique!'), backgroundColor: Colors.orange, duration: Duration(milliseconds: 500)));
         return;
      }
      setState(() {
        _currentGuess.add(val);
      });
    }
  }

  void _onBackspaceTap() {
    if (_isGameOver) return;
    setState(() {
      if (_currentGuess.isNotEmpty) {
        _currentGuess.removeLast();
      }
    });
  }

  void _submitGuess() {
     if (_currentGuess.length != 4 || _isGameOver) return;

     int exact = 0;
     int near = 0;

     for (int i = 0; i < 4; i++) {
        if (_currentGuess[i] == _secretCode[i]) {
           exact++;
        } else if (_secretCode.contains(_currentGuess[i])) {
           near++;
        }
     }

     setState(() {
        _guesses.add(MastermindGuess(List.from(_currentGuess), exact, near));
        
        if (exact == 4) {
           _isGameOver = true;
           int pointsEarned = 100 - (_guesses.length * 5);
           if (pointsEarned < 20) pointsEarned = 20;
           _score += pointsEarned;
           _showWinDialog(pointsEarned);
        } else if (_guesses.length >= 10) {
           _isGameOver = true;
           _showLoseDialog();
        }
        
        _currentGuess.clear();
     });
  }

  void _showWinDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Code Broken!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
        content: Text(
          "You cracked the 4-digit code in ${_guesses.length} attempts.\n\nPoints Earned: $points\nTotal Score: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text("Next Code"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  void _showLoseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Out of Attempts!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
          "You failed to crack the code.\n\nThe secret code was: ${_secretCode.join('')}",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
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
            Text("1. Guess the secret 4-digit code. All digits are unique (0-9).", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. After each guess, you get feedback:", style: GoogleFonts.poppins()),
            Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 16), const SizedBox(width: 8), Expanded(child: Text("Green: Right digit, RIGHT place.", style: GoogleFonts.poppins()))]),
            Row(children: [const Icon(Icons.check_circle_outline, color: Colors.orange, size: 16), const SizedBox(width: 8), Expanded(child: Text("Orange: Right digit, WRONG place.", style: GoogleFonts.poppins()))]),
            const SizedBox(height: 8),
            Text("3. You have 10 attempts to break the code.", style: GoogleFonts.poppins()),
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
        title: "Number Mastermind",
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Score: $_score", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Attempts: ${_guesses.length}/10", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 itemCount: _guesses.length,
                 itemBuilder: (context, index) {
                    MastermindGuess guess = _guesses[index];
                    return Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                       ),
                       child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Row(
                                children: guess.digits.map((d) => Container(
                                   margin: const EdgeInsets.only(right: 8),
                                   width: 40, height: 40,
                                   decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: theme.dividerColor),
                                   ),
                                   child: Center(child: Text(d.toString(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold))),
                                )).toList(),
                             ),
                             Row(
                                children: [
                                   Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(16)),
                                      child: Row(children: [Text(guess.exactMatches.toString(), style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Icon(Icons.check_circle, size: 16, color: Colors.green.shade800)]),
                                   ),
                                   const SizedBox(width: 8),
                                   Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(16)),
                                      child: Row(children: [Text(guess.numberMatches.toString(), style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Icon(Icons.check_circle_outline, size: 16, color: Colors.orange.shade800)]),
                                   ),
                                ]
                             )
                          ],
                       ),
                    );
                 },
              ),
            ),
            
            // Current input row
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
               child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                     bool hasDigit = index < _currentGuess.length;
                     return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                           border: Border(bottom: BorderSide(color: hasDigit ? theme.colorScheme.primary : theme.dividerColor, width: 3)),
                        ),
                        child: Center(
                           child: Text(
                              hasDigit ? _currentGuess[index].toString() : "",
                              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                           ),
                        ),
                     );
                  }),
               ),
            ),
            
            // Custom Numpad
            Container(
               padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
               child: Column(
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn(1, theme),
                           _buildNumpadBtn(2, theme),
                           _buildNumpadBtn(3, theme),
                           _buildNumpadBtn(4, theme),
                           _buildNumpadBtn(5, theme),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn(6, theme),
                           _buildNumpadBtn(7, theme),
                           _buildNumpadBtn(8, theme),
                           _buildNumpadBtn(9, theme),
                           _buildNumpadBtn(0, theme),
                        ],
                     ),
                     const SizedBox(height: 16),
                     Row(
                        children: [
                           Expanded(
                              flex: 1,
                              child: ElevatedButton.icon(
                                 onPressed: _currentGuess.isEmpty ? null : _onBackspaceTap,
                                 icon: const Icon(Icons.backspace_outlined),
                                 label: const Text("Clear"),
                                 style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    foregroundColor: Colors.red.shade900,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                 ),
                              ),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                 onPressed: _currentGuess.length == 4 ? _submitGuess : null,
                                 style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                 ),
                                 child: Text("Submit Guess", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                           )
                        ],
                     )
                  ],
               ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadBtn(int label, ThemeData theme) {
     bool isDisabled = _currentGuess.contains(label);
     return InkWell(
        onTap: isDisabled ? null : () => _onNumpadTap(label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
           width: MediaQuery.of(context).size.width * 0.15,
           height: 55,
           decoration: BoxDecoration(
              color: isDisabled ? theme.dividerColor.withOpacity(0.1) : theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDisabled ? Colors.transparent : theme.dividerColor.withOpacity(0.3)),
              boxShadow: isDisabled ? [] : const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
           ),
           child: Center(
              child: Text(
                 label.toString(), 
                 style: GoogleFonts.poppins(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: isDisabled ? Colors.grey : theme.textTheme.bodyLarge?.color,
                 )
              ),
           ),
        ),
     );
  }
}
