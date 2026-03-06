import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class CodeBreakerScreen extends StatefulWidget {
  const CodeBreakerScreen({super.key});

  @override
  State<CodeBreakerScreen> createState() => _CodeBreakerScreenState();
}

class _CodeBreakerScreenState extends State<CodeBreakerScreen> {
  final MindGameService _gameService = MindGameService();
  // Logic: 4-digit code (1-6)
  List<int> _secretCode = [];
  List<List<int>> _guesses = [];
  List<Map<String, int>> _guessResults = []; // {Bulls: X, Cows: Y}
  
  final int _maxAttempts = 10;
  bool _isGameOver = false;
  bool _won = false;
  int _hintsRemaining = 2;

  final List<Color> _digitColors = [
    Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple, Colors.orange
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
    _gameService.startSession(context);
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _startNewGame() {
    _guesses.clear();
    _guessResults.clear();
    _isGameOver = false;
    _won = false;
    _hintsRemaining = 2; // Reset hints
    // Generate code: 4 distinct digits 1..6
    final list = [1, 2, 3, 4, 5, 6]..shuffle();
    _secretCode = list.sublist(0, 4);
    setState(() {});
  }

  void _useHint() {
    if (_hintsRemaining <= 0 || _isGameOver) return;
    
    // Reveal a digit that is NOT yet correctly guessed in the last guess (if any)
    // Or just reveal a random position
    int revealIndex = -1;
    
    // Simple logic: Find first index where user hasn't guessed correctly 4 times in a row? 
    // No, just reveal a random index.
    
    // Better: Reveal the first position that isn't 'bull' in previous guess? 
    // Since we don't track position-specific correctness in UI (just total bulls), just pick a random index.
    
    // Let's pick an index 0..3
    revealIndex = Random().nextInt(4);
    
    setState(() {
      _hintsRemaining--;
    });
    
    final colorNames = ["Red", "Green", "Blue", "Yellow", "Purple", "Orange"];
    final digit = _secretCode[revealIndex];
    final colorName = colorNames[digit-1];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hint"),
        content: Text("The digit at position ${revealIndex + 1} is $digit ($colorName)."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _makeGuess(List<int> guess) {
    if (_isGameOver) return;

    int bulls = 0; // Correct Digit, Correct Position
    int cows = 0; // Correct Digit, Wrong Position

    for (int i = 0; i < 4; i++) {
        if (guess[i] == _secretCode[i]) {
          bulls++;
        } else if (_secretCode.contains(guess[i])) {
          cows++;
        }
    }

    setState(() {
      _guesses.add(guess);
      _guessResults.add({"Bulls": bulls, "Cows": cows});

      if (bulls == 4) {
        _isGameOver = true;
        _won = true;
        _showWinDialog();
      } else if (_guesses.length >= _maxAttempts) {
        _isGameOver = true;
        _showLoseDialog();
      }
    });
  }
  
  void _showWinDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("You Broke the Code!"),
          content: Text("Congratulations! You guessed the code in ${_guesses.length} attempts."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              child: const Text("Play Again"),
            )
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
             Text("1. Guess the 4-digit secret code using the colors.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("2. Each digit is between 1-6.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("3. Red dot (Bull): Correct digit in the correct position.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("4. Empty circle (Cow): Correct digit but in the wrong position.", style: GoogleFonts.poppins()),
             const SizedBox(height: 8),
             Text("5. You have 10 attempts to break the code!", style: GoogleFonts.poppins()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))
        ],
      ),
    );
  }

  void _showLoseDialog() {
       showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Game Over"),
          content: Text("You ran out of attempts! The code was $_secretCode."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              child: const Text("Try Again"),
            )
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
        title: "Code Breaker", // Mastermind
        centerTitle: true,
        actions: [
             IconButton(
               icon: const Icon(Icons.info_outline, color: Colors.white),
               onPressed: _showHowToPlay,
             ),
             IconButton(
               icon: Badge(
                 label: Text("$_hintsRemaining"),
                 isLabelVisible: _hintsRemaining > 0,
                 child: const Icon(Icons.lightbulb, color: Colors.amber),
               ),
               onPressed: !_isGameOver && _hintsRemaining > 0 ? _useHint : null,
            ),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _startNewGame)
        ],
      ),
      body: Column(
        children: [
           // Game Info
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   "Attempts: ${_guesses.length} / $_maxAttempts", 
                   style: GoogleFonts.poppins(
                     color: theme.textTheme.bodyLarge?.color, 
                     fontWeight: FontWeight.bold
                   )
                 ),
                 // Hidden Code Placeholder
                 Row(
                   children: List.generate(4, (index) => Container(
                     margin: const EdgeInsets.only(left: 4),
                     width: 30, height: 30,
                     decoration: BoxDecoration(
                       color: _isGameOver ? _digitColors[_secretCode[index]-1] : theme.dividerColor.withOpacity(0.1),
                       shape: BoxShape.circle,
                       border: Border.all(color: theme.dividerColor.withOpacity(0.2))
                     ),
                     child: Center(
                       child: Text(
                         _isGameOver ? "${_secretCode[index]}" : "?", 
                         style: TextStyle(
                           color: _isGameOver ? Colors.white : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                           fontWeight: FontWeight.bold
                         )
                       )
                     ),
                   )),
                 )
               ],
             ),
           ),
           Expanded(
             child: ListView.builder(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               itemCount: _guesses.length,
               itemBuilder: (context, index) {
                  final guess = _guesses[index];
                  final result = _guessResults[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)))
                    ),
                    child: Row(
                      children: [
                        Text("${index + 1}.", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                        const SizedBox(width: 12),
                        // Guess Pegs
                        ...guess.map((digit) => Container(
                             margin: const EdgeInsets.only(right: 8),
                             width: 24, height: 24,
                             decoration: BoxDecoration(
                               color: _digitColors[digit-1],
                               shape: BoxShape.circle,
                             ),
                             child: Center(
                               child: Text(
                                 "$digit", 
                                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                               )
                             ),
                        )),
                        const Spacer(),
                        // Feedback Pegs
                        Row(
                          children: [
                            // Bulls (Correct position)
                            ...List.generate(result['Bulls']!, (i) => const Icon(Icons.circle, size: 12, color: Colors.red)),
                            // Cows (Wrong position)
                            ...List.generate(result['Cows']!, (i) => Icon(Icons.circle_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                          ],
                        )
                      ],
                    ),
                  );
               },
             ),
           ),
           // Input Area
           Container(
             decoration: BoxDecoration(
               color: theme.cardColor,
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.05),
                   blurRadius: 10,
                   offset: const Offset(0, -2)
                 )
               ]
             ),
             padding: const EdgeInsets.all(16),
             child: _DigitInput(
                colors: _digitColors,
                onSubmit: (guess) => _makeGuess(guess),
                enabled: !_isGameOver,
                theme: theme,
             ),
           ),
        ],
      ),
    );
  }
}

class _DigitInput extends StatefulWidget {
  final List<Color> colors;
  final Function(List<int>) onSubmit;
  final bool enabled;
  final ThemeData theme;

  const _DigitInput({required this.colors, required this.onSubmit, required this.enabled, required this.theme});

  @override
  State<_DigitInput> createState() => _DigitInputState();
}

class _DigitInputState extends State<_DigitInput> {
  final List<int> _currentInput = [];

  void _addInput(int d) {
    if (_currentInput.length < 4) {
      setState(() {
         _currentInput.add(d);
      });
    }
  }

  void _backspace() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput.removeLast();
      });
    }
  }

  void _submit() {
    if (_currentInput.length == 4) {
      widget.onSubmit(List.from(_currentInput));
      setState(() {
        _currentInput.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
      return Column(
        children: [
          // Current Input Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
               if (index < _currentInput.length) {
                 final val = _currentInput[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: widget.colors[val-1],
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Center(
                    child: Text(
                      "$val", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                    )
                  ),
                );
              } else {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: widget.theme.dividerColor.withOpacity(0.1),
                    border: Border.all(color: widget.theme.dividerColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8)
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 16),
          // Keypad
          Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(6, (index) {
                return GestureDetector(
                  onTap: widget.enabled ? () => _addInput(index + 1) : null,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: widget.colors[index],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(widget.theme.brightness == Brightness.dark ? 0.3 : 0.1), 
                          blurRadius: 4, 
                          offset: const Offset(2,2)
                        )
                      ]
                    ),
                    child: Center(child: Text("${index+1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white))),
                  ),
                );
            }),
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _backspace,
                icon: const Icon(Icons.backspace, color: Colors.grey),
                iconSize: 32,
              ),
              ElevatedButton(
                onPressed: _currentInput.length == 4 && widget.enabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.colorScheme.primary,
                  foregroundColor: widget.theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
                ),
                child: const Text("GUESS", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      );
  }
}
