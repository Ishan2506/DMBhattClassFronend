import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/memory_match_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/math_quiz_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/word_scramble_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/odd_one_out_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/code_breaker_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/fact_or_fiction_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/sentence_builder_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/grammar_guardian_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/word_bridge_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/emoji_decoder_screen.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class MindGamesScreen extends StatefulWidget {
  const MindGamesScreen({super.key});

  @override
  State<MindGamesScreen> createState() => _MindGamesScreenState();
}

class _MindGamesScreenState extends State<MindGamesScreen> {
  final MindGameService _gameService = MindGameService();

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await _gameService.init();
    setState(() {}); // Refresh UI to show correct time
  }

  void _handleGameTap(Widget gameScreen) {
    if (_gameService.canPlay()) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => gameScreen)
      ).then((_) {
        // Refresh when they come back (to update remaining time display)
        setState(() {});
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Daily Limit Reached"),
          content: const Text("You have used your 1 hour quota for today. Come back tomorrow!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: "Mind Games",
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _gameService.getRemainingTime(),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            
            // Warning Note logic could go here, but it's in the AppBar now as requested.

            _buildGameCard(
              context,
              title: "Memory Match",
              description: "Improve your memory by finding matching pairs of cards.",
              icon: Icons.grid_view_rounded,
              color: Colors.blue,
              onTap: () => _handleGameTap(const MemoryMatchGameScreen()),
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              title: "Speed Math",
              description: "Test your calculation speed! Good for mental agility.",
              icon: Icons.calculate_outlined,
              color: Colors.red,
              onTap: () => _handleGameTap(const MathQuizScreen()),
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              title: "Word Scramble",
              description: "Unscramble the educational words.",
              icon: Icons.text_fields_rounded,
              color: Colors.deepPurple,
              onTap: () => _handleGameTap(const WordScrambleScreen()),
            ),
            const SizedBox(height: 16),
             _buildGameCard(
              context,
              title: "Odd One Out",
              description: "Identify the item that doesn't belong in the group.",
              icon: Icons.filter_list_off,
              color: Colors.brown,
              onTap: () => _handleGameTap(const OddOneOutScreen()),
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              title: "Code Breaker",
              description: "Use logic to guess the secret color code.",
              icon: Icons.lock_open_rounded,
              color: Colors.grey.shade800,
              onTap: () => _handleGameTap(const CodeBreakerScreen()),
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              title: "Fact or Fiction?",
              description: "Test your knowledge with quick true or false questions.",
              icon: Icons.thumbs_up_down_rounded,
              color: Colors.deepPurpleAccent,
              onTap: () => _handleGameTap(const FactOrFictionScreen()),
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              title: "Sentence Builder",
              description: "Form correct sentences from the jumbled words.",
              icon: Icons.segment_rounded,
              color: Colors.orange,
              onTap: () => _handleGameTap(const SentenceBuilderScreen()),
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              title: "Grammar Guardian",
              description: "Master English grammar by spotting the correct usage.",
              icon: Icons.spellcheck,
              color: Colors.teal,
              onTap: () => _handleGameTap(const GrammarGuardianScreen()),
            ),
            const SizedBox(height: 16),
             _buildGameCard(
              context,
              title: "Word Bridge",
              description: "Connect two unrelated concepts through a chain of words.",
              icon: Icons.hub,
              color: Colors.pink,
              onTap: () => _handleGameTap(const WordBridgeScreen()),
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              title: "Emoji Decoder",
              description: "Guess the famous idiom or phrase from emojis.",
              icon: Icons.emoji_objects_outlined,
              color: Colors.amber.shade800,
              onTap: () => _handleGameTap(const EmojiDecoderScreen()),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
