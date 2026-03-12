import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class GameObjectivesScreen extends StatelessWidget {
  const GameObjectivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Game Objectives",
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCategorySection(
            context,
            title: "Mathematics",
            icon: Icons.calculate_rounded,
            color: Colors.red,
            games: [
              _GameInfo(name: l10n.speedMath, desc: l10n.speedMathDesc, example: "E.g., 5 + 7 = ? Solve as quickly as possible."),
              _GameInfo(name: l10n.mathRiddles, desc: l10n.mathRiddlesDesc, example: "E.g., I am an odd number. Take away a letter and I become even. What number am I? (Seven)"),
              _GameInfo(name: l10n.numberSeries, desc: l10n.numberSeriesDesc, example: "E.g., 2, 4, 8, 16, ? Find the next sequence (32)."),
              _GameInfo(name: l10n.magicSquare, desc: l10n.magicSquareDesc, example: "E.g., Fill a 3x3 grid such that every row, column, and diagonal adds up to 15."),
              _GameInfo(name: l10n.algebraBalancer, desc: l10n.algebraBalancerDesc, example: "E.g., 2x + 5 = 15. Find the value of x (x = 5)."),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            context,
            title: "Language & Vocabulary",
            icon: Icons.menu_book_rounded,
            color: Colors.blue,
            games: [
              _GameInfo(name: l10n.wordScramble, desc: l10n.wordScrambleDesc, example: "E.g., 'ELGNSIH' -> 'ENGLISH'"),
              _GameInfo(name: l10n.sentenceBuilder, desc: l10n.sentenceBuilderDesc, example: "E.g., Arrange 'apple / eating / an / am / I' into 'I am eating an apple.'"),
              _GameInfo(name: l10n.grammarGuardian, desc: l10n.grammarGuardianDesc, example: "E.g., Choose the correct verb: 'He (go/goes) to school.' (goes)"),
              _GameInfo(name: l10n.wordBridge, desc: l10n.wordBridgeDesc, example: "E.g., Connect related words or form compound words like 'Sun' + 'Flower' = 'Sunflower'."),
              _GameInfo(name: l10n.spellingMaster, desc: l10n.spellingMasterDesc, example: "E.g., Find the correctly spelled word out of 'Acommodate', 'Accommodate', 'Accomodate'."),
              _GameInfo(name: l10n.synonymAntonym, desc: l10n.synonymAntonymDesc, example: "E.g., Choose the synonym of 'Happy' (Joyful) or antonym of 'Hot' (Cold)."),
              _GameInfo(name: l10n.languageTranslator, desc: l10n.languageTranslatorDesc, example: "E.g., Translate 'Apple' to French ('Pomme')."),
              _GameInfo(name: l10n.subjectWordSearch, desc: l10n.subjectWordSearchDesc, example: "E.g., Find mathematical terms hidden in a letter grid."),
              _GameInfo(name: l10n.grammarSorter, desc: l10n.grammarSorterDesc, example: "E.g., Categorize words into Nouns, Verbs, and Adjectives."),
              _GameInfo(name: l10n.proverbCompleter, desc: l10n.proverbCompleterDesc, example: "E.g., 'A stitch in time saves ___.' (nine)"),
              _GameInfo(name: l10n.syllableScramble, desc: l10n.syllableScrambleDesc, example: "E.g., Arrange syllables 'ta', 'po', 'to' into 'potato'."),
              _GameInfo(name: "Word Chain", desc: "Create a connected chain of words where the last letter of one word becomes the first letter of the next.", example: "E.g., APPLE -> ELEPHANT -> TIGER"),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            context,
            title: "Memory & Cognitive",
            icon: Icons.psychology_rounded,
            color: Colors.purple,
            games: [
              _GameInfo(name: l10n.memoryMatch, desc: l10n.memoryMatchDesc, example: "E.g., Flip cards to find matching pairs of images or concepts."),
              _GameInfo(name: l10n.spotTheDifference, desc: l10n.spotTheDifferenceDesc, example: "E.g., Compare two similar images and tap on the subtle differences."),
              _GameInfo(name: l10n.sequenceMemory, desc: l10n.sequenceMemoryDesc, example: "E.g., Memorize a pattern of flashing lights and repeat it."),
              _GameInfo(name: l10n.stroopEffectChallenge, desc: l10n.stroopEffectChallengeDesc, example: "E.g., The word 'RED' is written in blue color. Tap 'Blue', not 'Red'."),
              _GameInfo(name: "Sorting Sweep", desc: "Tap ascending numeric values as fast as possible.", example: "E.g., Tap 5, then 8, then 12 before the time runs out."),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            context,
            title: "Logic & Reasoning",
            icon: Icons.extension_rounded,
            color: Colors.orange,
            games: [
              _GameInfo(name: l10n.oddOneOut, desc: l10n.oddOneOutDesc, example: "E.g., Choose the odd one from 'Apple, Banana, Carrot, Orange' (Carrot - it's a vegetable)."),
              _GameInfo(name: l10n.codeBreaker, desc: l10n.codeBreakerDesc, example: "E.g., Guess a 4-digit secret code based on Mastermind hints."),
              _GameInfo(name: l10n.emojiDecoder, desc: l10n.emojiDecoderDesc, example: "E.g., Decode '🦇👨' to guess the movie 'Batman'."),
              _GameInfo(name: l10n.directionSense, desc: l10n.directionSenseDesc, example: "E.g., If you walk north, turn right, then turn right again, which direction are you facing? (South)"),
              _GameInfo(name: l10n.logicGatesQuest, desc: l10n.logicGatesQuestDesc, example: "E.g., If input A is 1 and input B is 0 for an AND gate, what is the output? (0)"),
              _GameInfo(name: "Path Finder", desc: "Draw continuous lines to connect matching colored dots without crossing paths.", example: "E.g., Connect Red to Red and Blue to Blue without overlapping their lines."),
              _GameInfo(name: "Color Flood", desc: "Strategically flood the board with a single color in limited moves.", example: "E.g., Change the top-left color to absorb adjacent connected tiles of the same color."),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategorySection(
            context,
            title: "Geography & General Knowledge",
            icon: Icons.public_rounded,
            color: Colors.teal,
            games: [
              _GameInfo(name: l10n.factOrFiction, desc: l10n.factOrFictionDesc, example: "E.g., 'The Great Wall of China is visible from space.' (Fiction)"),
              _GameInfo(name: l10n.flagExplorer, desc: l10n.flagExplorerDesc, example: "E.g., Identify the country for a given flag (e.g., 🇯🇵 -> Japan)."),
              _GameInfo(name: l10n.capitalCityQuest, desc: l10n.capitalCityQuestDesc, example: "E.g., What is the capital of Australia? (Canberra)."),
              _GameInfo(name: l10n.gkQuiz, desc: l10n.gkQuizDesc, example: "E.g., Who painted the Mona Lisa? (Leonardo da Vinci)."),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, {required String title, required IconData icon, required MaterialColor color, required List<_GameInfo> games}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            collapsedBackgroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            children: [
              Container(
                color: theme.dividerColor.withValues(alpha: 0.02),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            game.desc,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb, size: 18, color: Colors.amber.shade600),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    game.example,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameInfo {
  final String name;
  final String desc;
  final String example;

  _GameInfo({required this.name, required this.desc, required this.example});
}
