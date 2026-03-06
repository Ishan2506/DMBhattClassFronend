import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class MathRiddlesScreen extends StatefulWidget {
  const MathRiddlesScreen({super.key});

  @override
  State<MathRiddlesScreen> createState() => _MathRiddlesScreenState();
}

class MathRiddle {
  final String question;
  final String answer; // Store as string to handle multi-digit input
  final String hint;

  MathRiddle({required this.question, required this.answer, required this.hint});
}

class _MathRiddlesScreenState extends State<MathRiddlesScreen> {
  final MindGameService _gameService = MindGameService();

  int _currentIndex = 0;
  int _score = 0;
  String _currentInput = "";
  bool _showHint = false;

  final List<MathRiddle> _riddles = [
    MathRiddle(
      question: "I am an odd number. Take away a letter and I become even. What number am I?",
      answer: "7", // S-E-V-E-N -> E-V-E-N
      hint: "Think about the English names of numbers, not the digits."
    ),
    MathRiddle(
      question: "If there are 3 apples and you take away 2, how many do you have?",
      answer: "2",
      hint: "Read the question carefully. Action vs Result."
    ),
    MathRiddle(
      question: "A bat and an apple cost \$1.10 in total. The bat costs \$1.00 more than the apple. How much does the apple cost (in cents)?",
      answer: "5",
      hint: "It is not 10 cents. x + (x + 100) = 110"
    ),
    MathRiddle(
      question: "What 3 positive numbers give the same result when multiplied and added together?",
      answer: "123", // 1+2+3 = 6, 1*2*3 = 6. Input order doesn't matter for this UI, we just ask for '123'
      hint: "The numbers are consecutive integers starting from 1."
    ),
    MathRiddle(
      question: "If 1=3, 2=3, 3=5, 4=4, 5=4, then, 6=?",
      answer: "3", // Number of letters in spelling: ONE(3), TWO(3), THREE(5), FOUR(4), FIVE(4), SIX(3)
      hint: "Write down the names of the numbers."
    ),
    MathRiddle(
      question: "When my father was 31 I was 8. Now he is twice as old as me. How old am I?",
      answer: "23", // Difference is 23. Twice 23 is 46, which is 23+23.
      hint: "The age difference between you and your father never changes."
    ),
    MathRiddle(
      question: "A grandfather, two fathers and two sons went to a movie theater together and everyone bought one ticket each. How many tickets did they buy in total?",
      answer: "3", // Grandfather, Father, Son.
      hint: "Think about familial relationships overlapping in a single person."
    ),
    MathRiddle(
      question: "Look at this series: 2, 1, (1/2), (1/4), ... What number should come next?",
      answer: "1/8",
      hint: "The sequence divides the previous number by 2."
    ),
    MathRiddle(
      question: "I add 5 to 9, and get 2. The answer is correct, but how?",
      answer: "12", // 9 AM + 5 hours = 2 PM. Or base 12 clock. We'll accept clock reference if it was text, but here we enforce '12' as the hint base
      hint: "Think about how we measure time. What base do we use?"
    ),
    MathRiddle(
      question: "Eighty-eight times, it is written. What is the sum of the numbers from 1 to 100?",
      answer: "5050",
      hint: "Formula: n(n+1)/2, where n is 100."
    ),
  ];

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _riddles.shuffle(); // Randomize order
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _onNumpadTap(String val) {
    if (val == "C") {
      setState(() => _currentInput = "");
    } else if (val == "<") {
      setState(() {
        if (_currentInput.isNotEmpty) {
           _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
      });
    } else {
      setState(() {
        if (_currentInput.length < 5) {
            _currentInput += val;
        }
      });
    }
  }

  void _checkAnswer() {
    if (_currentInput == _riddles[_currentIndex].answer) {
      _handleCorrectAnswer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect. Try again!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleCorrectAnswer() {
    setState(() {
      _score += _showHint ? 50 : 100; // Less points if hint was used
      
      if (_currentIndex < _riddles.length - 1) {
        _currentIndex++;
        _currentInput = "";
        _showHint = false;
      } else {
        _showWinDialog();
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Genius Level Reached!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You solved all the math riddles!\n\nFinal Score: $_score",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
               setState(() {
                  _riddles.shuffle();
                  _currentIndex = 0;
                  _score = 0;
                  _currentInput = "";
                  _showHint = false;
               });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Math Riddles",
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Riddle ${_currentIndex + 1}/${_riddles.length}", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                  Text("Score: $_score", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      Container(
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                         ),
                         child: Text(
                            _riddles[_currentIndex].question,
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500, height: 1.5),
                            textAlign: TextAlign.center,
                         ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (_showHint)
                        Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                           ),
                           child: Row(
                              children: [
                                 Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
                                 const SizedBox(width: 12),
                                 Expanded(
                                    child: Text(
                                       _riddles[_currentIndex].hint,
                                       style: GoogleFonts.poppins(color: Colors.amber.shade900),
                                    ),
                                 )
                              ],
                           ),
                        )
                      else
                        TextButton.icon(
                           onPressed: () => setState(() => _showHint = true), 
                           icon: const Icon(Icons.help_outline), 
                           label: const Text("Show Hint (-50 pts)")
                        ),
                        
                      const SizedBox(height: 32),
                      
                      // Answer Display
                      Container(
                         width: double.infinity,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 2)),
                         ),
                         child: Center(
                            child: Text(
                               _currentInput.isEmpty ? "?" : _currentInput,
                               style: GoogleFonts.poppins(
                                  fontSize: 32, 
                                  fontWeight: FontWeight.bold,
                                  color: _currentInput.isEmpty ? Colors.grey : theme.textTheme.bodyLarge?.color,
                               ),
                            ),
                         ),
                      ),
                   ],
                ),
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
                           _buildNumpadBtn("C", theme, color: Colors.red.shade100, textColor: Colors.red.shade800),
                           _buildNumpadBtn("0", theme),
                           _buildNumpadBtn("<", theme, color: Colors.grey.shade200, textColor: Colors.grey.shade800),
                        ],
                     ),
                     const SizedBox(height: 12),
                     ElevatedButton(
                        onPressed: _currentInput.isEmpty ? null : _checkAnswer,
                        style: ElevatedButton.styleFrom(
                           minimumSize: const Size(double.infinity, 56),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Submit Answer", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                     )
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
           width: MediaQuery.of(context).size.width * 0.22,
           height: 60,
           decoration: BoxDecoration(
              color: color ?? theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
           ),
           child: Center(
              child: label == "<" 
                 ? Icon(Icons.backspace_outlined, color: textColor ?? theme.textTheme.bodyLarge?.color)
                 : Text(
                     label, 
                     style: GoogleFonts.poppins(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: textColor ?? theme.textTheme.bodyLarge?.color,
                     )
                   ),
           ),
        ),
     );
  }
}
