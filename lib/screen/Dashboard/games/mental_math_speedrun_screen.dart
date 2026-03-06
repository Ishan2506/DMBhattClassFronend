import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class MentalMathSpeedrunScreen extends StatefulWidget {
  const MentalMathSpeedrunScreen({super.key});

  @override
  State<MentalMathSpeedrunScreen> createState() => _MentalMathSpeedrunScreenState();
}

class SpeedrunProblem {
  final String text;
  final int answer;
  SpeedrunProblem(this.text, this.answer);
}

class _MentalMathSpeedrunScreenState extends State<MentalMathSpeedrunScreen> {
  final MindGameService _gameService = MindGameService();

  late SpeedrunProblem _currentProblem;
  int _score = 0;
  int _streak = 0;
  String _currentInput = "";
  final Random _rand = Random();

  Timer? _timer;
  int _timeLeft = 60; // 60 seconds speedrun
  bool _isPlaying = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _generateProblem();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameService.stopSession();
    super.dispose();
  }

  void _startGame() {
    setState(() {
       _isPlaying = true;
       _hasStarted = true;
       _score = 0;
       _streak = 0;
       _timeLeft = 60;
       _currentInput = "";
    });
    _generateProblem();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
         if (_timeLeft > 0) {
            _timeLeft--;
         } else {
            _endGame();
         }
      });
    });
  }

  void _endGame() {
    _isPlaying = false;
    _timer?.cancel();
    _showResultDialog();
  }

  void _generateProblem() {
     int difficulty = min((_score ~/ 100) + 1, 5); // Max difficulty 5
     
     int type = _rand.nextInt(4); // 0: +, 1: -, 2: *, 3: /
     
     int a, b, ans;
     String text;

     switch (type) {
        case 0: // Add
            a = _rand.nextInt(20 * difficulty) + (5 * difficulty);
            b = _rand.nextInt(20 * difficulty) + (5 * difficulty);
            ans = a + b;
            text = "$a + $b";
            break;
        case 1: // Subtract
            a = _rand.nextInt(30 * difficulty) + (10 * difficulty);
            b = _rand.nextInt(a - 1) + 1; // Ensure positive result
            ans = a - b;
            text = "$a - $b";
            break;
        case 2: // Multiply
            a = _rand.nextInt(4 + difficulty * 2) + 2;
            b = _rand.nextInt(4 + difficulty * 2) + 2;
            ans = a * b;
            text = "$a × $b";
            break;
        case 3: // Divide
            b = _rand.nextInt(5 + difficulty) + 2;
            ans = _rand.nextInt(10 + difficulty * 2) + 2;
            a = ans * b; // Ensure clean division
            text = "$a ÷ $b";
            break;
        default:
            a = 1; b = 1; ans = 2; text = "1 + 1";
     }

     setState(() {
        _currentProblem = SpeedrunProblem(text, ans);
     });
  }

  void _onNumpadTap(String val) {
    if (!_isPlaying) return;
    
    if (val == "C") {
      setState(() => _currentInput = "");
    } else if (val == "<") {
      setState(() {
        if (_currentInput.isNotEmpty) {
           _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
      });
    } else {
      if (_currentInput.length < 5) {
         setState(() {
            _currentInput += val;
            _checkAutoSubmit(); // Auto check to be fast!
         });
      }
    }
  }

  void _checkAutoSubmit() {
     int? inputInt = int.tryParse(_currentInput);
     if (inputInt == _currentProblem.answer) {
        // Correct! Add points and gen new instantly
        setState(() {
           _streak++;
           _score += 10 + (_streak * 2); // Streak bonuses
           _currentInput = "";
           _generateProblem();
        });
     } else if (_currentInput.length >= _currentProblem.answer.toString().length) {
        // If they typed expected length and it's wrong, punish mildly or just don't accept
        if (inputInt != null && inputInt != _currentProblem.answer) {
           // We don't auto clear, manually clear, breaks streak
           setState(() {
              _streak = 0;
           });
        }
     }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Time's Up!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Your brain is fast!\n\nFinal Score: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text("Play Again"),
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
            Text("1. You have exactly 60 seconds.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("2. Solve as many math problems as you can.", style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text("3. Type the answer. It will AUTO-SUBMIT as soon as you type the correct number. You don't need to press enter.", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("4. Build up a long streak for bonus points!", style: GoogleFonts.poppins()),
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
        title: "Mental Math Speedrun",
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
                  Row(
                     children: [
                        Icon(Icons.timer_outlined, color: _timeLeft < 10 ? Colors.red : theme.dividerColor),
                        const SizedBox(width: 8),
                        Text(
                           "$_timeLeft s", 
                           style: GoogleFonts.poppins(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: _timeLeft < 10 ? Colors.red : theme.textTheme.bodyLarge?.color,
                           )
                        ),
                     ],
                  ),
                  Text("Score: $_score\nStreak: $_streak🔥", textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                      if (!_hasStarted)
                         ElevatedButton.icon(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 32),
                            label: Text("Start 60s Speedrun", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                         )
                      else if (_isPlaying) ...[
                         Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                               color: theme.cardColor,
                               borderRadius: BorderRadius.circular(24),
                               boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                               border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 2),
                            ),
                            child: Center(
                               child: Text(
                                  _currentProblem.text,
                                  style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold),
                               ),
                            ),
                         ),
                         
                         const SizedBox(height: 48),
                         
                         // Answer Display
                         Container(
                            width: 200,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                               border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 2)),
                            ),
                            child: Center(
                               child: Text(
                                  _currentInput,
                                  style: GoogleFonts.poppins(
                                     fontSize: 48, 
                                     fontWeight: FontWeight.bold,
                                     color: theme.colorScheme.primary,
                                  ),
                               ),
                            ),
                         ),
                      ],
                   ],
                ),
              ),
            ),
            
            // Custom Numpad
            Container(
               padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
               child: Column(
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("1", theme),
                           _buildNumpadBtn("2", theme),
                           _buildNumpadBtn("3", theme),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("4", theme),
                           _buildNumpadBtn("5", theme),
                           _buildNumpadBtn("6", theme),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("7", theme),
                           _buildNumpadBtn("8", theme),
                           _buildNumpadBtn("9", theme),
                        ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           _buildNumpadBtn("C", theme, color: Colors.blue.shade50, textColor: Colors.blue.shade800),
                           _buildNumpadBtn("0", theme),
                           _buildNumpadBtn("<", theme, color: Colors.red.shade50, textColor: Colors.red.shade800),
                        ],
                     ),
                  ],
               ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadBtn(String label, ThemeData theme, {Color? color, Color? textColor}) {
     return InkWell(
        onTap: () => _onNumpadTap(label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
           width: MediaQuery.of(context).size.width * 0.22,
           height: 65,
           decoration: BoxDecoration(
              color: color ?? theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
           ),
           child: Center(
              child: label == "<" 
                 ? Icon(Icons.backspace_outlined, color: textColor ?? theme.textTheme.bodyLarge?.color)
                 : Text(
                     label, 
                     style: GoogleFonts.poppins(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        color: textColor ?? theme.textTheme.bodyLarge?.color,
                     )
                   ),
           ),
        ),
     );
  }
}
