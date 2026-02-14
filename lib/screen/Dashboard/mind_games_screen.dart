import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
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
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class MindGamesScreen extends StatefulWidget {
  const MindGamesScreen({super.key});

  @override
  State<MindGamesScreen> createState() => _MindGamesScreenState();
}

class _MindGamesScreenState extends State<MindGamesScreen> {
  final MindGameService _gameService = MindGameService();
  bool _isGuest = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    setState(() => _isLoading = true);
    await _gameService.init();
    _isGuest = await GuestUtils.isGuest();
    if (mounted) setState(() => _isLoading = false); // Refresh UI
  }

  void _handleGameTap(Widget gameScreen, {bool isFree = false}) {
    if (_isGuest && !isFree) {
      GuestUtils.showGuestRestrictionDialog(
        context,
        message: "Only one game is accessible in guest mode. Register to unlock all games!"
      );
      return;
    }
    if (_gameService.canPlay()) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => gameScreen)
      ).then((_) {
        // Refresh when they come back (to update remaining time display)
        setState(() {});
      });
    } else {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.dailyLimitReached),
          content: Text(l10n.limitQuotaMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;
     final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.mindGames,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildGameCard(
                  context,
                  title: l10n.memoryMatch,
                  description: l10n.memoryMatchDesc,
                  isFree: true,
                  icon: Icons.grid_view_rounded,
                  color: Colors.blue,
                  onTap: () => _handleGameTap(const MemoryMatchGameScreen(), isFree: true),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.speedMath,
                  description: l10n.speedMathDesc,
                  icon: Icons.calculate_outlined,
                  color: Colors.red,
                  onTap: () => _handleGameTap(const MathQuizScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.wordScramble,
                  description: l10n.wordScrambleDesc,
                  icon: Icons.text_fields_rounded,
                  color: Colors.deepPurple,
                  onTap: () => _handleGameTap(const WordScrambleScreen()),
                ),
                const SizedBox(height: 16),
                 _buildGameCard(
                  context,
                  title: l10n.oddOneOut,
                  description: l10n.oddOneOutDesc,
                  icon: Icons.filter_list_off,
                  color: Colors.brown,
                  onTap: () => _handleGameTap(const OddOneOutScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.codeBreaker,
                  description: l10n.codeBreakerDesc,
                  icon: Icons.lock_open_rounded,
                  color: Colors.grey.shade800,
                  onTap: () => _handleGameTap(const CodeBreakerScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.factOrFiction,
                  description: l10n.factOrFictionDesc,
                  icon: Icons.thumbs_up_down_rounded,
                  color: Colors.deepPurpleAccent,
                  onTap: () => _handleGameTap(const FactOrFictionScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.sentenceBuilder,
                  description: l10n.sentenceBuilderDesc,
                  icon: Icons.segment_rounded,
                  color: Colors.orange,
                  onTap: () => _handleGameTap(const SentenceBuilderScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.grammarGuardian,
                  description: l10n.grammarGuardianDesc,
                  icon: Icons.spellcheck,
                  color: Colors.teal,
                  onTap: () => _handleGameTap(const GrammarGuardianScreen()),
                ),
                const SizedBox(height: 16),
                 _buildGameCard(
                  context,
                  title: l10n.wordBridge,
                  description: l10n.wordBridgeDesc,
                  icon: Icons.hub,
                  color: Colors.pink,
                  onTap: () => _handleGameTap(const WordBridgeScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.emojiDecoder,
                  description: l10n.emojiDecoderDesc,
                  icon: Icons.emoji_objects_outlined,
                  color: Colors.amber.shade800,
                  onTap: () => _handleGameTap(const EmojiDecoderScreen()),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CustomLoader()),
        ],
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFree = false,
  }) {
    final theme = Theme.of(context);
    final isLocked = _isGuest && !isFree;
    final isDark = theme.brightness == Brightness.dark;
    
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
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
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
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios, 
              color: isLocked ? Colors.orange : theme.dividerColor, 
              size: 16
            ),
          ],
        ),
      ),
    );
  }
}
