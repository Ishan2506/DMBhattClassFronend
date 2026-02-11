import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class FactOrFictionScreen extends StatefulWidget {
  const FactOrFictionScreen({super.key});

  @override
  State<FactOrFictionScreen> createState() => _FactOrFictionScreenState();
}

class _FactOrFictionScreenState extends State<FactOrFictionScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [
    {"q": "The Great Wall of China is visible from space.", "a": false, "fact": "It's a myth! You can't see it with the naked eye from low Earth orbit."},
    {"q": "Water boils at 100°C at sea level.", "a": true, "fact": "Correct! Boiling point decreases with altitude."},
    {"q": "Sharks have bones.", "a": false, "fact": "Sharks have skeletons made of cartilage, not bone."},
    {"q": "Lightning never strikes the same place twice.", "a": false, "fact": "It often does, especially tall buildings."},
    {"q": "The sun is a star.", "a": true, "fact": "Yes, it is a G-type main-sequence star."},
    {"q": "Penguins can fly.", "a": false, "fact": "Penguins are flightless birds adapted for swimming."},
    {"q": "Honey never spoils.", "a": true, "fact": "Archaeologists have found edible honey in ancient Egyptian tombs."},
    {"q": "Venus is the hottest planet in our solar system.", "a": true, "fact": "True, due to its thick atmosphere (greenhouse effect)."},
    {"q": "The human body has 206 bones.", "a": true, "fact": "An adult human skeleton has 206 bones."},
    {"q": "Bats are blind.", "a": false, "fact": "Bats can see quite well, but rely on echolocation in the dark."},
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _timeLeft = 10;
  Timer? _timer;
  bool _isGameOver = false;
  String? _lastFact;
  bool? _lastAnswerCorrect;

  late AnimationController _animationController;
  final MindGameService _gameService = MindGameService();

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _questions.shuffle();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _startTimer();
  }

  void _startTimer() {
    _timeLeft = 10;
    _animationController.reset();
    _animationController.forward();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _handleAnswer(null); // Time's up
        }
      });
    });
  }

  void _handleAnswer(bool? userAnswer) {
    _timer?.cancel();
    _animationController.stop();

    bool correct = false;
    if (userAnswer != null) {
      if (userAnswer == _questions[_currentIndex]['a']) {
        correct = true;
        _score++;
      }
    }

    setState(() {
      _lastAnswerCorrect = correct;
      _lastFact = _questions[_currentIndex]['fact'];
    });

    Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (_currentIndex < _questions.length - 1) {
          setState(() {
            _currentIndex++;
            _lastFact = null;
            _lastAnswerCorrect = null;
          });
          _startTimer();
        } else {
          _endGame();
        }
    });
  }

  void _endGame() {
    setState(() {
      _isGameOver = true;
    });
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Fact or Fiction?",
        centerTitle: true,
      ),
      body: _isGameOver ? _buildGameOver() : _buildGame(theme),
    );
  }

  Widget _buildGame(ThemeData theme) {
    final question = _questions[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                 "Score: $_score", 
                 style: GoogleFonts.poppins(
                   color: theme.colorScheme.primary, 
                   fontSize: 18, 
                   fontWeight: FontWeight.bold
                 )
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: theme.dividerColor.withOpacity(0.1), 
                   borderRadius: BorderRadius.circular(12)
                 ),
                 child: Text(
                   "$_timeLeft s", 
                   style: GoogleFonts.poppins(
                     color: theme.colorScheme.primary, 
                     fontWeight: FontWeight.bold
                   )
                 ),
               )
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _animationController.value,
              backgroundColor: theme.dividerColor.withOpacity(0.1),
              color: Colors.amber,
              minHeight: 8,
            ),
          ),
          const Spacer(),
          
          if (_lastFact != null)
             _buildFeedbackCard(theme)
          else
             _buildQuestionCard(question['q'], theme),

          const Spacer(),
          
          if (_lastFact == null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: Text("FICTION", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                   child: ElevatedButton(
                    onPressed: () => _handleAnswer(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: Text("FACT", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String text, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            "Question ${_currentIndex + 1}",
            style: GoogleFonts.poppins(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), 
              fontSize: 14
            ),
          ),
          const SizedBox(height: 24),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: theme.textTheme.bodyLarge?.color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(ThemeData theme) {
    bool isCorrect = _lastAnswerCorrect ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCorrect ? Colors.green : Colors.red, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            isCorrect ? "Correct!" : "Wrong!",
            style: GoogleFonts.poppins(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: isCorrect ? Colors.green : Colors.red
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _lastFact!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16, 
              color: theme.textTheme.bodyMedium?.color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Game Over!", 
            style: GoogleFonts.poppins(
              fontSize: 32, 
              fontWeight: FontWeight.bold, 
              color: theme.textTheme.titleLarge?.color
            )
          ),
          const SizedBox(height: 16),
          Text(
            "You scored $_score / ${_questions.length}", 
            style: GoogleFonts.poppins(
              fontSize: 20, 
              color: theme.textTheme.bodyMedium?.color
            )
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
               setState(() {
                 _currentIndex = 0;
                 _score = 0;
                 _isGameOver = false;
                 _questions.shuffle();
                 _startTimer();
               });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary, 
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text("Play Again", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          )
        ],
      ),
    );
  }
}
