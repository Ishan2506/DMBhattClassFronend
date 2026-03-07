import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class StroopColor {
  final String name;
  final Color color;

  const StroopColor(this.name, this.color);
}

class StroopEffectChallengeScreen extends StatefulWidget {
  const StroopEffectChallengeScreen({super.key});

  @override
  State<StroopEffectChallengeScreen> createState() => _StroopEffectChallengeScreenState();
}

class _StroopEffectChallengeScreenState extends State<StroopEffectChallengeScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();
  
  static const List<StroopColor> _colors = [
    StroopColor("RED", Colors.red),
    StroopColor("BLUE", Colors.blue),
    StroopColor("GREEN", Colors.green),
    StroopColor("YELLOW", Colors.yellow),
    StroopColor("PURPLE", Colors.purple),
    StroopColor("ORANGE", Colors.orange),
    StroopColor("PINK", Colors.pink),
  ];

  late String _word;
  late Color _wordColor;
  int _score = 0;
  int _timeLeft = 45;
  Timer? _timer;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startGame();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _score = 0;
    _timeLeft = 45;
    _isGameOver = false;
    _generateQuestion();
    _startTimer();
  }

  void _generateQuestion() {
    setState(() {
      _word = _colors[_random.nextInt(_colors.length)].name;
      _wordColor = _colors[_random.nextInt(_colors.length)].color;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        setState(() => _isGameOver = true);
        _timer?.cancel();
      }
    });
  }

  void _checkAnswer(Color selectedColor) {
    if (_isGameOver) return;

    if (selectedColor == _wordColor) {
      setState(() {
        _score += 10;
        _timeLeft += 1;
      });
      _generateQuestion();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correct!"), backgroundColor: Colors.green, duration: Duration(milliseconds: 300)),
      );
    } else {
      setState(() {
        _timeLeft = max(0, _timeLeft - 5);
      });
      _generateQuestion();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong! -5s"), backgroundColor: Colors.red, duration: Duration(milliseconds: 300)),
      );
    }
  }

  void _showHowToPlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.help_outline_rounded, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "How to Play",
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInstructionRow(theme, "1", "A word will appear in a specific color."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Ignore the word's meaning!"),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Tap the circle that matches the FONT COLOR of the word."),
              const SizedBox(height: 24),
              
              // Example Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text("Example:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.tertiary)),
                    const SizedBox(height: 12),
                    Text(
                      "BLUE", 
                      style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red)
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                        const SizedBox(width: 8),
                        Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text("Select RED!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("(Word says BLUE, but font is RED)", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("Got it!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(ThemeData theme, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          child: Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: l10n.stroopEffectChallenge,
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
                _buildStatBadge("Score: $_score", Icons.star, Colors.amber),
                _buildStatBadge("Time: $_timeLeft s", Icons.timer, _timeLeft < 10 ? Colors.red : Colors.blue),
              ],
            ),
            const Spacer(),
            
            Text(
              "Choose the FONT color",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Word Display
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
              ),
              child: Text(
                _word,
                style: GoogleFonts.poppins(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: _wordColor,
                ),
              ),
            ),

            const Spacer(),

            // Color Options
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _colors.map((c) => InkWell(
                onTap: () => _checkAnswer(c.color),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                ),
              )).toList(),
            ),

            const Spacer(),

            if (_isGameOver)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Session Over", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Final Score: $_score", style: GoogleFonts.poppins(fontSize: 18)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Restart"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
