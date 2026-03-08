import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/upgrade_plan_screen.dart';
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
import 'package:dm_bhatt_tutions/screen/Dashboard/games/math_riddles_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/number_series_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/magic_square_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/algebra_balancer_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/spot_the_difference_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/flag_explorer_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/logic_gates_quest_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/stroop_effect_challenge_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/syllable_scramble_screen.dart';



import 'package:dm_bhatt_tutions/screen/Dashboard/games/spelling_master_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/synonym_antonym_screen.dart';

import 'package:dm_bhatt_tutions/screen/Dashboard/games/language_translator_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/subject_word_search_screen.dart';

import 'package:dm_bhatt_tutions/screen/Dashboard/games/grammar_sorter_screen.dart';

import 'package:dm_bhatt_tutions/screen/Dashboard/games/capital_city_quest_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/proverb_completer_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/direction_sense_screen.dart';

import 'package:dm_bhatt_tutions/screen/Dashboard/games/gk_quiz_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/games/sequence_memory_screen.dart';



import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';


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
  bool _isPaid = false;
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
    
    if (!_isGuest) {
      try {
        final profileResponse = await ApiService.getProfile(forceRefresh: true);
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          _isPaid = profileData['user']?['isPaid'] ?? false;
        }
      } catch (e) {
        debugPrint('Error fetching profile for MindGames: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false); // Refresh UI
  }

  void _handleGameTap(Widget gameScreen, {bool isFree = false}) {
    if (isFree) {
       Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => gameScreen)
      ).then((_) {
        setState(() {});
      });
      return;
    }

    if (_isGuest) {
      GuestUtils.showGuestRestrictionDialog(
        context,
        message: "Only one game is accessible in guest mode. Register to unlock all games!"
      );
      return;
    }

    if (!_isPaid) {
      _showUpgradeDialog();
      return;
    }

    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => gameScreen)
    ).then((_) {
      // Refresh when they come back
      setState(() {});
    });
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Premium Feature",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Unlocking all educational games requires a premium plan. Upgrade now to enjoy unlimited access!",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Upgrade Now", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.mindGames,
        centerTitle: true,
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
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.mathRiddles,
                  description: l10n.mathRiddlesDesc,
                  icon: Icons.psychology_alt_rounded,
                  color: Colors.teal,
                  onTap: () => _handleGameTap(const MathRiddlesScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.numberSeries,
                  description: l10n.numberSeriesDesc,
                  icon: Icons.linear_scale_rounded,
                  color: Colors.green,
                  onTap: () => _handleGameTap(const NumberSeriesScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.magicSquare,
                  description: l10n.magicSquareDesc,
                  icon: Icons.grid_3x3_rounded,
                  color: Colors.amber.shade600,
                  onTap: () => _handleGameTap(const MagicSquareScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.algebraBalancer,
                  description: l10n.algebraBalancerDesc,
                  icon: Icons.balance_rounded,
                  color: Colors.blue.shade600,
                  onTap: () => _handleGameTap(const AlgebraBalancerScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.spotTheDifference,
                  description: l10n.spotTheDifferenceDesc,
                  icon: Icons.search_rounded,
                  color: Colors.pinkAccent,
                  onTap: () => _handleGameTap(const SpotTheDifferenceScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.flagExplorer,
                  description: l10n.flagExplorerDesc,
                  icon: Icons.flag_circle,
                  color: Colors.deepOrange,
                  onTap: () => _handleGameTap(const FlagExplorerScreen()),
                ),
                const SizedBox(height: 16),


                _buildGameCard(
                  context,
                  title: l10n.spellingMaster,
                  description: l10n.spellingMasterDesc,
                  icon: Icons.spellcheck_rounded,
                  color: Colors.indigo,
                  onTap: () => _handleGameTap(const SpellingMasterScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.synonymAntonym,
                  description: l10n.synonymAntonymDesc,
                  icon: Icons.compare_arrows_rounded,
                  color: Colors.teal.shade700,
                  onTap: () => _handleGameTap(const SynonymAntonymScreen()),
                ),
                const SizedBox(height: 16),


                _buildGameCard(
                  context,
                  title: l10n.languageTranslator,
                  description: l10n.languageTranslatorDesc,
                  icon: Icons.g_translate_rounded,
                  color: Colors.blueAccent,
                  onTap: () => _handleGameTap(const LanguageTranslatorScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.subjectWordSearch,
                  description: l10n.subjectWordSearchDesc,
                  icon: Icons.find_in_page_rounded,
                  color: Colors.orange.shade700,
                  onTap: () => _handleGameTap(const SubjectWordSearchScreen()),
                ),
                const SizedBox(height: 16),


                _buildGameCard(
                  context,
                  title: l10n.grammarSorter,
                  description: l10n.grammarSorterDesc,
                  icon: Icons.sort_by_alpha_rounded,
                  color: Colors.green.shade600,
                  onTap: () => _handleGameTap(const GrammarSorterScreen()),
                ),
                const SizedBox(height: 16),


                _buildGameCard(
                  context,
                  title: l10n.capitalCityQuest,
                  description: l10n.capitalCityQuestDesc,
                  icon: Icons.location_city_rounded,
                  color: Colors.redAccent.shade400,
                  onTap: () => _handleGameTap(const CapitalCityQuestScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.proverbCompleter,
                  description: l10n.proverbCompleterDesc,
                  icon: Icons.format_quote_rounded,
                  color: Colors.deepPurple,
                  onTap: () => _handleGameTap(const ProverbCompleterScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.directionSense,
                  description: l10n.directionSenseDesc,
                  icon: Icons.explore_rounded,
                  color: Colors.blue.shade800,
                  onTap: () => _handleGameTap(const DirectionSenseScreen()),
                ),
                const SizedBox(height: 16),


                _buildGameCard(
                  context,
                  title: l10n.gkQuiz,
                  description: l10n.gkQuizDesc,
                  icon: Icons.quiz_rounded,
                  color: Colors.amber.shade700,
                  onTap: () => _handleGameTap(const GKQuizScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.sequenceMemory,
                  description: l10n.sequenceMemoryDesc,
                  icon: Icons.memory_rounded,
                  color: Colors.teal.shade500,
                  onTap: () => _handleGameTap(const SequenceMemoryScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.syllableScramble,
                  description: l10n.syllableScrambleDesc,
                  icon: Icons.text_snippet_rounded,
                  color: Colors.amberAccent.shade700,
                  onTap: () => _handleGameTap(const SyllableScrambleScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.logicGatesQuest,
                  description: l10n.logicGatesQuestDesc,
                  icon: Icons.settings_input_component_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => _handleGameTap(const LogicGatesQuestScreen()),
                ),
                const SizedBox(height: 16),
                _buildGameCard(
                  context,
                  title: l10n.stroopEffectChallenge,
                  description: l10n.stroopEffectChallengeDesc,
                  icon: Icons.palette_rounded,
                  color: Colors.greenAccent.shade700,
                  onTap: () => _handleGameTap(const StroopEffectChallengeScreen()),
                ),              ],
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
    final isLocked = (_isGuest || !_isPaid) && !isFree;
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
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
