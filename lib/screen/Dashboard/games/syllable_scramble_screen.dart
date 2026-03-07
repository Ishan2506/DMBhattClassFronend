import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class ScrambledWord {
  final String fullWord;
  final List<String> syllables;

  const ScrambledWord(this.fullWord, this.syllables);
}

class SyllableScrambleScreen extends StatefulWidget {
  const SyllableScrambleScreen({super.key});

  @override
  State<SyllableScrambleScreen> createState() => _SyllableScrambleScreenState();
}

class _SyllableScrambleScreenState extends State<SyllableScrambleScreen> {
  final MindGameService _gameService = MindGameService();
  
  static const List<ScrambledWord> _allWords = [
    ScrambledWord("EDUCATION", ["ED", "U", "CA", "TION"]),
    ScrambledWord("COMPUTER", ["COM", "PU", "TER"]),
    ScrambledWord("UNIVERSITY", ["U", "NI", "VER", "SI", "TY"]),
    ScrambledWord("MOTIVATION", ["MO", "TI", "VA", "TION"]),
    ScrambledWord("COMMUNICATION", ["COM", "MU", "NI", "CA", "TION"]),
    ScrambledWord("UNDERSTAND", ["UN", "DER", "STAND"]),
    ScrambledWord("GOVERNMENT", ["GOV", "ERN", "MENT"]),
    ScrambledWord("WONDERFUL", ["WON", "DER", "FUL"]),
    ScrambledWord("FANTASTIC", ["FAN", "TAS", "TIC"]),
    ScrambledWord("RELIABLE", ["RE", "LI", "A", "BLE"]),
    ScrambledWord("VOCABULARY", ["VO", "CA", "BU", "LA", "RY"]),
    ScrambledWord("CHALLENGE", ["CHAL", "LENGE"]),
    ScrambledWord("SYLLABLE", ["SYL", "LA", "BLE"]),
    ScrambledWord("KNOWLEDGE", ["KNOW", "LEDGE"]),
    ScrambledWord("LEARNING", ["LEARN", "ING"]),
  ];

  late List<ScrambledWord> _sessionWords;
  int _currentIndex = 0;
  int _score = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isGameOver = false;
  
  List<String> _shuffledSyllables = [];
  List<String> _selectedSyllables = [];

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
    _sessionWords = List.from(_allWords)..shuffle();
    _currentIndex = 0;
    _score = 0;
    _timeLeft = 60;
    _isGameOver = false;
    _loadQuestion();
    _startTimer();
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

  void _loadQuestion() {
    if (_currentIndex >= _sessionWords.length) {
      _sessionWords.shuffle();
      _currentIndex = 0;
    }
    
    final word = _sessionWords[_currentIndex];
    _shuffledSyllables = List.from(word.syllables)..shuffle();
    _selectedSyllables.clear();
    setState(() {});
  }

  void _onSyllableTap(String syllable) {
    if (_isGameOver) return;

    setState(() {
      _selectedSyllables.add(syllable);
      _shuffledSyllables.remove(syllable);
      
      final currentWord = _selectedSyllables.join("");
      final targetWord = _sessionWords[_currentIndex].fullWord;

      if (currentWord == targetWord) {
        _score += 10;
        _timeLeft += 3;
        _currentIndex++;
        _loadQuestion();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Correct!"), backgroundColor: Colors.green, duration: Duration(milliseconds: 300)),
        );
      } else if (!targetWord.startsWith(currentWord)) {
        // Wrong sequence
        _timeLeft = max(0, _timeLeft - 5);
        _selectedSyllables.clear();
        _shuffledSyllables = List.from(_sessionWords[_currentIndex].syllables)..shuffle();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wrong sequence! -5s"), backgroundColor: Colors.red, duration: Duration(milliseconds: 500)),
        );
      }
    });
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
              _buildInstructionRow(theme, "1", "Words are broken into syllables."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Tap the syllables in the CORRECT order to form the word."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Complete the word to score points and gain bonus time."),
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
                    Text("Example: EDUCATION", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.tertiary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniSyllable(theme, "ED", true),
                        const SizedBox(width: 8),
                        _buildMiniSyllable(theme, "U", true),
                        const SizedBox(width: 8),
                        _buildMiniSyllable(theme, "CA", true),
                        const SizedBox(width: 8),
                        _buildMiniSyllable(theme, "TION", true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("Tap them in sequence!", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
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

  Widget _buildMiniSyllable(ThemeData theme, String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? theme.colorScheme.primary : theme.dividerColor),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? theme.colorScheme.primary : Colors.grey)),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedSyllables.clear();
      _shuffledSyllables = List.from(_sessionWords[_currentIndex].syllables)..shuffle();
    });
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
        title: l10n.syllableScramble,
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
            
            // Selected Syllables (Constructed Word)
            Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _selectedSyllables.isEmpty 
                      ? [Text("Construct the word...", style: TextStyle(color: theme.hintColor, fontSize: 18))]
                      : _selectedSyllables.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Chip(label: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                        )).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedSyllables.isNotEmpty)
              TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text("Clear Selection"),
              ),

            const Spacer(),

            // Scrambled Syllables
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _shuffledSyllables.map((s) => InkWell(
                onTap: () => _onSyllableTap(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
              )).toList(),
            ),

            const Spacer(),

            if (_isGameOver)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Time's Up!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Final Score: $_score", style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Text("Play Again"),
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
