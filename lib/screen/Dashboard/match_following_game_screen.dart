import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/match_following_result_screen.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';


class MatchFollowingGameScreen extends StatefulWidget {
  final String exerciseId;
  final String title;
  final String subject;
  final List<Map<String, String>> pairsData;

  const MatchFollowingGameScreen({
    super.key,
    required this.exerciseId,
    required this.title,
    required this.subject,
    required this.pairsData,
  });

  @override
  State<MatchFollowingGameScreen> createState() => _MatchFollowingGameScreenState();
}

class _MatchFollowingGameScreenState extends State<MatchFollowingGameScreen> {
  final GlobalKey _stackKey = GlobalKey();

  late List<String> _leftItems;
  late List<String> _rightItems;

  // Track matched indices: key is left index, value is right index
  Map<int, int> _matches = {};

  // Currently selected left index
  int? _selectedLeftIndex;

  bool _isSubmitted = false;
  int _score = 0;

  late List<GlobalKey> _leftKeys;
  late List<GlobalKey> _rightKeys;

  @override
  void initState() {
    super.initState();
    _startNewGame();
    // Trigger redraw after first frame layout to compute initial coordinates for lines
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _startNewGame() {
    _leftItems = widget.pairsData.map((p) => p['left']!).toList();
    _rightItems = widget.pairsData.map((p) => p['right']!).toList();
    _rightItems.shuffle();

    _leftKeys = List.generate(_leftItems.length, (_) => GlobalKey());
    _rightKeys = List.generate(_rightItems.length, (_) => GlobalKey());

    _matches.clear();
    _selectedLeftIndex = null;
    _isSubmitted = false;
    _score = 0;
  }

  void _onResetPressed() {
    setState(_startNewGame);
    // The new GlobalKeys have no layout until the next frame, so the
    // connection painter needs a second pass to pick up card positions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  bool _isCorrectMatch(int leftIdx, int rightIdx) {
    final leftVal = _leftItems[leftIdx];
    final rightVal = _rightItems[rightIdx];
    return widget.pairsData.any((p) => p['left'] == leftVal && p['right'] == rightVal);
  }

  void _onLeftCardTap(int index) {
    if (_isSubmitted) return;
    setState(() {
      _selectedLeftIndex = index;
    });
  }

  void _onRightCardTap(int index) {
    if (_isSubmitted) return;
    if (_selectedLeftIndex == null) {
      // Prompt user to select left item first
      CustomToast.showInfo(context, _getTranslation(context, 'selectLeftFirst'));
      return;
    }

    setState(() {
      // Check if this right item is already matched with some other left item, if so remove that match
      _matches.removeWhere((key, value) => value == index);

      // Save the match
      _matches[_selectedLeftIndex!] = index;
      _selectedLeftIndex = null;
    });
  }

  void _clearMatch(int leftIndex) {
    if (_isSubmitted) return;
    setState(() {
      _matches.remove(leftIndex);
      if (_selectedLeftIndex == leftIndex) {
        _selectedLeftIndex = null;
      }
    });
  }

  void _submitMatches() {
    if (_matches.length < _leftItems.length) {
      CustomToast.showInfo(context, _getTranslation(context, 'matchAllPrompt'));
      return;
    }

    int tempScore = 0;
    _matches.forEach((leftIdx, rightIdx) {
      if (_isCorrectMatch(leftIdx, rightIdx)) {
        tempScore++;
      }
    });

    setState(() {
      _score = tempScore;
      _isSubmitted = true;
    });

    _saveHistory();
  }

  Future<void> _saveHistory() async {
    try {
      final List<Map<String, dynamic>> finalAnswers = [];
      _matches.forEach((leftIdx, rightIdx) {
        final leftVal = _leftItems[leftIdx];
        final rightVal = _rightItems[rightIdx];
        final isCorrect = _isCorrectMatch(leftIdx, rightIdx);
        
        // Find correct answer from pairsData
        final correctRightVal = widget.pairsData.firstWhere((p) => p['left'] == leftVal)['right'] ?? "";

        finalAnswers.add({
          "left": leftVal,
          "studentMatch": rightVal,
          "correctMatch": correctRightVal,
          "isCorrect": isCorrect,
        });
      });

      // Find any unmatched left items
      for (int i = 0; i < _leftItems.length; i++) {
        if (!_matches.containsKey(i)) {
          final leftVal = _leftItems[i];
          final correctRightVal = widget.pairsData.firstWhere((p) => p['left'] == leftVal)['right'] ?? "";
          finalAnswers.add({
             "left": leftVal,
             "studentMatch": "",
             "correctMatch": correctRightVal,
             "isCorrect": false,
          });
        }
      }

      await ApiService.submitMatchFollowingExamResult(
        examId: widget.exerciseId,
        title: widget.title,
        obtainedMarks: _score,
        totalMarks: _leftItems.length,
        accuracy: (_score / _leftItems.length) * 100,
        violationCount: 0,
        answers: finalAnswers,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MatchFollowingResultScreen(
              totalPairs: _leftItems.length,
              correctMatches: _score,
              averageAccuracy: (_score / _leftItems.length) * 100,
              subject: widget.subject,
              title: widget.title,
              unit: "", // Adjust if unit is available
              answers: finalAnswers,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving match following history: $e");
      if (mounted) {
        // Fallback to home if error?
        Navigator.pop(context);
      }
    }
  }

  // _showResultDialog is no longer used, we navigate to the result screen directly.
  void _showHowToPlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.help_outline_rounded, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _getTranslation(context, 'howToPlay'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInstructionRow(theme, "1", _getTranslation(context, 'rule1')),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", _getTranslation(context, 'rule2')),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", _getTranslation(context, 'rule3')),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "4", _getTranslation(context, 'rule4')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _getTranslation(context, 'letsPlay'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
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
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  String _getTranslation(BuildContext context, String key) {
    // only english language currenyly we are working on
    final locale = Localizations.localeOf(context).languageCode;
    const translations = {
      'en': {
        'columnA': 'Column A',
        'columnB': 'Column B',
        'submit': 'Submit Matches',
        'reset': 'Reset',
        'perfect': 'Perfect Score!',
        'goodJob': 'Good Job!',
        'keepTrying': 'Keep Practicing!',
        'score': 'Score',
        'accuracy': 'Accuracy',
        'retry': 'Play Again',
        'exit': 'Exit',
        'howToPlay': 'How to Play',
        'rule1': 'Tap any item in Column A (Left) to highlight it.',
        'rule2': 'Tap the corresponding match in Column B (Right) to connect them.',
        'rule3': 'A colorful connection line will link the matched pair.',
        'rule4': 'To cancel a match, tap the connected item and it will disconnect.',
        'letsPlay': 'Let\'s Play!',
        'selectLeftFirst': 'Please select an item from Column A first!',
        'matchAllPrompt': 'Please connect all pairs before submitting!',
      },
      'gu': {
        'columnA': 'α¬╡α¬┐α¬¡α¬╛α¬ù A',
        'columnB': 'α¬╡α¬┐α¬¡α¬╛α¬ù B',
        'submit': 'α¬╕α¬¼α¬«α¬┐α¬ƒ α¬òα¬░α½ï',
        'reset': 'α¬░α½Çα¬╕α½çα¬ƒ',
        'perfect': 'α¬ëα¬ñα½ìα¬ñα¬« α¬¬α¬░α¬┐α¬úα¬╛α¬«!',
        'goodJob': 'α¬ûα½éα¬¼ α¬╕α¬░α¬╕!',
        'keepTrying': 'α¬¬α½ìα¬░α¬»α¬╛α¬╕ α¬Üα¬╛α¬▓α½ü α¬░α¬╛α¬ûα½ï!',
        'score': 'α¬ùα½üα¬ú',
        'accuracy': 'α¬Üα½ïα¬òα¬╕α¬╛α¬ê',
        'retry': 'α¬½α¬░α½Ç α¬░α¬«α½ï',
        'exit': 'α¬¼α¬╣α¬╛α¬░ α¬¿α½Çα¬òα¬│α½ï',
        'howToPlay': 'α¬òα½çα¬╡α½Ç α¬░α½Çα¬ñα½ç α¬░α¬«α¬╡α½üα¬é',
        'rule1': 'α¬╡α¬┐α¬¡α¬╛α¬ù A (α¬íα¬╛α¬¼α½Ç α¬¼α¬╛α¬£α½ü) α¬¿α¬╛ α¬òα½ïα¬êα¬¬α¬ú α¬╢α¬¼α½ìα¬ª α¬¬α¬░ α¬ƒα½çα¬¬ α¬òα¬░α½ï.',
        'rule2': 'α¬ñα½çα¬¿α½ç α¬£α½ïα¬íα¬╡α¬╛ α¬«α¬╛α¬ƒα½ç α¬╡α¬┐α¬¡α¬╛α¬ù B (α¬£α¬«α¬úα½Ç α¬¼α¬╛α¬£α½ü) α¬¿α¬╛ α¬╕α¬╛α¬Üα¬╛ α¬╢α¬¼α½ìα¬ª α¬¬α¬░ α¬ƒα½çα¬¬ α¬òα¬░α½ï.',
        'rule3': 'α¬¼α¬éα¬¿α½çα¬¿α½Ç α¬╡α¬Üα½ìα¬Üα½ç α¬Åα¬ò α¬╕α½üα¬éα¬ªα¬░ α¬░α¬éα¬ùα½Çα¬¿ α¬▓α¬╛α¬êα¬¿ α¬£α½ïα¬íα¬╛α¬╢α½ç.',
        'rule4': 'α¬£α½ïα¬íα¬╛α¬ú α¬░α¬ª α¬òα¬░α¬╡α¬╛ α¬«α¬╛α¬ƒα½ç α¬£α½ïα¬íα¬╛α¬»α½çα¬▓α¬╛ α¬╢α¬¼α½ìα¬ª α¬¬α¬░ α¬½α¬░α½Ç α¬ƒα½çα¬¬ α¬òα¬░α½ï.',
        'letsPlay': 'α¬Üα¬╛α¬▓α½ï α¬░α¬«α½Çα¬Å!',
        'selectLeftFirst': 'α¬òα½âα¬¬α¬╛ α¬òα¬░α½Çα¬¿α½ç α¬¬α¬╣α½çα¬▓α¬╛ α¬╡α¬┐α¬¡α¬╛α¬ù A α¬«α¬╛α¬éα¬Ñα½Ç α¬Åα¬ò α¬╢α¬¼α½ìα¬ª α¬¬α¬╕α¬éα¬ª α¬òα¬░α½ï!',
        'matchAllPrompt': 'α¬òα½âα¬¬α¬╛ α¬òα¬░α½Çα¬¿α½ç α¬╕α¬¼α¬«α¬┐α¬ƒ α¬òα¬░α¬ñα¬╛ α¬¬α¬╣α½çα¬▓α¬╛ α¬¼α¬ºα¬╛ α¬£α½ïα¬íα¬òα¬╛ α¬£α½ïα¬íα½ï!',
      },
      'hi': {
        'columnA': 'αñ╕αÑìαññαñéαñ¡ A',
        'columnB': 'αñ╕αÑìαññαñéαñ¡ B',
        'submit': 'αñ£αñ«αñ╛ αñòαñ░αÑçαñé',
        'reset': 'αñ░αñ┐αñ╕αÑçαñƒ',
        'perfect': 'αñëαññαÑìαñòαÑâαñ╖αÑìαñƒ αñ╕αÑìαñòαÑïαñ░!',
        'goodJob': 'αñàαñÜαÑìαñ¢αñ╛ αñ¬αÑìαñ░αñ»αñ╛αñ╕!',
        'keepTrying': 'αñàαñ¡αÑìαñ»αñ╛αñ╕ αñòαñ░αññαÑç αñ░αñ╣αÑçαñé!',
        'score': 'αñàαñéαñò',
        'accuracy': 'αñ╕αñƒαÑÇαñòαññαñ╛',
        'retry': 'αñ¬αÑüαñ¿αñâ αñûαÑçαñ▓αÑçαñé',
        'exit': 'αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ▓αÑçαñé',
        'howToPlay': 'αñòαÑêαñ╕αÑç αñûαÑçαñ▓αÑçαñé',
        'rule1': 'αñ╕αÑìαññαñéαñ¡ A (αñ¼αñ╛αñÅαñé) αñ«αÑçαñé αñòαñ┐αñ╕αÑÇ αñ¡αÑÇ αñåαñçαñƒαñ« αñ¬αñ░ αñƒαÑêαñ¬ αñòαñ░αÑçαñéαÑñ',
        'rule2': 'αñëαñ¿αÑìαñ╣αÑçαñé αñ£αÑïαñíαñ╝αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ╕αÑìαññαñéαñ¡ B (αñªαñ╛αñÅαñé) αñ«αÑçαñé αñ╕αñéαñ¼αñéαñºαñ┐αññ αñåαñçαñƒαñ« αñ¬αñ░ αñƒαÑêαñ¬ αñòαñ░αÑçαñéαÑñ',
        'rule3': 'αñÅαñò αñ░αñéαñùαÑÇαñ¿ αñ░αÑçαñûαñ╛ αñªαÑïαñ¿αÑïαñé αñòαÑï αñ£αÑïαñíαñ╝ αñªαÑçαñùαÑÇαÑñ',
        'rule4': 'αñòαñ¿αÑçαñòαÑìαñ╢αñ¿ αñ╣αñƒαñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ, αñ£αÑüαñíαñ╝αÑç αñ╣αÑüαñÅ αñåαñçαñƒαñ« αñ¬αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñƒαÑêαñ¬ αñòαñ░αÑçαñéαÑñ',
        'letsPlay': 'αñÜαñ▓αÑï αñûαÑçαñ▓αÑçαñé!',
        'selectLeftFirst': 'αñòαÑâαñ¬αñ»αñ╛ αñ¬αñ╣αñ▓αÑç αñ╕αÑìαññαñéαñ¡ A αñ╕αÑç αñÅαñò αñåαñçαñƒαñ« αñÜαÑüαñ¿αÑçαñé!',
        'matchAllPrompt': 'αñòαÑâαñ¬αñ»αñ╛ αñ£αñ«αñ╛ αñòαñ░αñ¿αÑç αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╕αñ¡αÑÇ αñ£αÑïαñíαñ╝αÑç αñ«αñ┐αñ▓αñ╛αñÅαñü!',
      },
      'mr': {
        'columnA': 'αñùαñƒ A',
        'columnB': 'αñùαñƒ B',
        'submit': 'αñ╕αñ¼αñ«αñ┐αñƒ αñòαñ░αñ╛',
        'reset': 'αñ░αñ┐αñ╕αÑçαñƒ',
        'perfect': 'αñëαññαÑìαñòαÑâαñ╖αÑìαñƒ αñùαÑüαñú!',
        'goodJob': 'αñ╢αñ╛αñ¼αÑìαñ¼αñ╛αñ╕!',
        'keepTrying': 'αñ╕αñ░αñ╛αñ╡ αñòαñ░αññ αñ░αñ╛αñ╣αñ╛!',
        'score': 'αñùαÑüαñú',
        'accuracy': 'αñàαñÜαÑéαñòαññαñ╛',
        'retry': 'αñ¬αÑüαñ¿αÑìαñ╣αñ╛ αñûαÑçαñ│αñ╛',
        'exit': 'αñ¼αñ╛αñ╣αÑçαñ░ αñ¬αñíαñ╛',
        'howToPlay': 'αñòαñ╕αÑç αñûαÑçαñ│αñ╛αñ»αñÜαÑç',
        'rule1': 'αñùαñƒ A (αñíαñ╛αñ╡αÑÇαñòαñíαÑÇαñ▓) αñ«αñºαÑÇαñ▓ αñòαÑïαñúαññαÑìαñ»αñ╛αñ╣αÑÇ αñÿαñƒαñòαñ╛αñ╡αñ░ αñƒαÑàαñ¬ αñòαñ░αñ╛.',
        'rule2': 'αñ£αÑïαñíαñúαÑìαñ»αñ╛αñ╕αñ╛αñáαÑÇ αñùαñƒ B (αñëαñ£αñ╡αÑÇαñòαñíαÑÇαñ▓) αñ«αñºαÑÇαñ▓ αñ╕αñéαñ¼αñéαñºαñ┐αññ αñÿαñƒαñòαñ╛αñ╡αñ░ αñƒαÑàαñ¬ αñòαñ░αñ╛.',
        'rule3': 'αñªαÑïαñ¿αÑìαñ╣αÑÇαñéαñÜαÑìαñ»αñ╛ αñ«αñºαÑìαñ»αÑç αñÅαñò αñ░αñéαñùαÑÇαññ αñ░αÑçαñ╖αñ╛ αñ£αÑïαñíαñ▓αÑÇ αñ£αñ╛αñêαñ▓.',
        'rule4': 'αñ£αÑïαñíαñúαÑÇ αñ░αñªαÑìαñª αñòαñ░αñúαÑìαñ»αñ╛αñ╕αñ╛αñáαÑÇ αñ£αÑïαñíαñ▓αÑçαñ▓αÑìαñ»αñ╛ αñÿαñƒαñòαñ╛αñ╡αñ░ αñ¬αÑüαñ¿αÑìαñ╣αñ╛ αñƒαÑàαñ¬ αñòαñ░αñ╛.',
        'letsPlay': 'αñÜαñ▓αñ╛ αñûαÑçαñ│αÑéαñ»αñ╛!',
        'selectLeftFirst': 'αñòαÑâαñ¬αñ»αñ╛ αñåαñºαÑÇ αñùαñƒ A αñ«αñºαÑÇαñ▓ αñÿαñƒαñò αñ¿αñ┐αñ╡αñíαñ╛!',
        'matchAllPrompt': 'αñòαÑâαñ¬αñ»αñ╛ αñ╕αñ¼αñ«αñ┐αñƒ αñòαñ░αñúαÑìαñ»αñ╛αñ¬αÑéαñ░αÑìαñ╡αÑÇ αñ╕αñ░αÑìαñ╡ αñ£αÑïαñíαÑìαñ»αñ╛ αñ£αÑüαñ│αñ╡αñ╛!',
      },
      'ta': {
        'columnA': 'α«¿α»åα«ƒα»üα«╡α«░α«┐α«Üα»ê A',
        'columnB': 'α«¿α»åα«ƒα»üα«╡α«░α«┐α«Üα»ê B',
        'submit': 'α«Üα««α«░α»ìα«¬α»ìα«¬α«┐α«òα»ìα«òα«╡α»üα««α»ì',
        'reset': 'α««α»Çα«ƒα»ìα«ƒα««α»ê',
        'perfect': 'α««α»üα«┤α»ü α««α«ñα«┐α«¬α»ìα«¬α»åα«úα»ì!',
        'goodJob': 'α«¿α«⌐α»ìα«▒α»ü!',
        'keepTrying': 'α««α»üα«»α«▒α»ìα«Üα«┐ α«Üα»åα«»α»ìα«ò!',
        'score': 'α««α«ñα«┐α«¬α»ìα«¬α»åα«úα»ì',
        'accuracy': 'α«ñα»üα«▓α»ìα«▓α«┐α«»α««α»ì',
        'retry': 'α««α»Çα«úα»ìα«ƒα»üα««α»ì α«╡α«┐α«│α»êα«»α«╛α«ƒα»ü',
        'exit': 'α«╡α»åα«│α«┐α«»α»çα«▒α»ü',
        'howToPlay': 'α«╡α«┐α«│α»êα«»α«╛α«ƒα»üα«╡α«ñα»ü α«Äα«¬α»ìα«¬α«ƒα«┐',
        'rule1': 'α«¿α»åα«ƒα»üα«╡α«░α«┐α«Üα»ê A α«çα«▓α»ì α«ëα«│α»ìα«│ α«Åα«ñα»çα«⌐α»üα««α»ì α«Æα«░α»ü α«Üα»èα«▓α»ìα«▓α»êα«ñα»ì α«ñα«ƒα»ìα«ƒα«╡α»üα««α»ì.',
        'rule2': 'α«¿α»åα«ƒα»üα«╡α«░α«┐α«Üα»ê B α«çα«▓α»ì α«ëα«│α»ìα«│ α«àα«ñα«▒α»ìα«òα»üα«¬α»ì α«¬α»èα«░α»üα«ñα»ìα«ñα««α«╛α«⌐ α«Üα»èα«▓α»ìα«▓α»êα«ñα»ì α«ñα«ƒα»ìα«ƒα«╡α»üα««α»ì.',
        'rule3': 'α«Æα«░α»ü α«╡α«úα»ìα«úα«òα»ì α«òα»ïα«ƒα»ü α«çα«░α«úα»ìα«ƒα»êα«»α»üα««α»ì α«çα«úα»êα«òα»ìα«òα»üα««α»ì.',
        'rule4': 'α«çα«úα»êα«¬α»ìα«¬α»ê α«¿α»Çα«òα»ìα«ò, α«çα«úα»êα«òα»ìα«òα«¬α»ìα«¬α«ƒα»ìα«ƒ α«Üα»èα«▓α»ìα«▓α»ê α««α»Çα«úα»ìα«ƒα»üα««α»ì α«ñα«ƒα»ìα«ƒα«╡α»üα««α»ì.',
        'letsPlay': 'α«ñα»èα«ƒα«Öα»ìα«òα»üα«╡α»ïα««α»ì!',
        'selectLeftFirst': 'α««α»üα«ñα«▓α«┐α«▓α»ì α«¿α»åα«ƒα»üα«╡α«░α«┐α«Üα»ê A α«çα«▓α«┐α«░α»üα«¿α»ìα«ñα»ü α«Æα«░α»ü α«Üα»èα«▓α»ìα«▓α»êα«ñα»ì α«ñα»çα«░α»ìα«¿α»ìα«ñα»åα«ƒα»üα«òα»ìα«òα«╡α»üα««α»ì!',
        'matchAllPrompt': 'α«Üα««α«░α»ìα«¬α»ìα«¬α«┐α«¬α»ìα«¬α«ñα«▒α»ìα«òα»ü α««α»üα«⌐α»ì α«àα«⌐α»êα«ñα»ìα«ñα»ü α«£α»ïα«ƒα«┐α«òα«│α»êα«»α»üα««α»ì α«çα«úα»êα«òα»ìα«òα«╡α»üα««α»ì!',
      }
    };
    final langMap = translations[locale] ?? translations['en']!;
    return langMap[key] ?? key;
  }

  Widget _buildLeftCard(BuildContext context, ThemeData theme, bool isDark,
      Color primary, int index) {
    final text = _leftItems[index];
    final isSelected = _selectedLeftIndex == index;
    final isMatched = _matches.containsKey(index);
    final matchedRightIdx = _matches[index];

    Color cardColor = theme.cardColor;
    Color borderCol = isDark ? Colors.white10 : Colors.grey.shade200;
    double borderW = 1.5;

    if (isSelected) {
      borderCol = primary;
      borderW = 2.5;
    } else if (isMatched) {
      if (_isSubmitted) {
        final correct = _isCorrectMatch(index, matchedRightIdx!);
        borderCol = correct ? Colors.green : Colors.red;
        cardColor = correct
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08);
        borderW = 2.0;
      } else {
        borderCol = primary.withOpacity(0.5);
      }
    }

    return GestureDetector(
      key: _leftKeys[index],
      onTap: () => _onLeftCardTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: borderW),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected || isMatched
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? primary
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            if (isMatched && !_isSubmitted)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _clearMatch(index),
              )
            else if (_isSubmitted && isMatched)
              Icon(
                _isCorrectMatch(index, matchedRightIdx!)
                    ? Icons.check_circle
                    : Icons.error,
                color: _isCorrectMatch(index, matchedRightIdx)
                    ? Colors.green
                    : Colors.red,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightCard(BuildContext context, ThemeData theme, bool isDark,
      Color primary, int index) {
    final text = _rightItems[index];
    final isMatched = _matches.containsValue(index);

    // Find which left index matches this right index (if any)
    int? leftIndexMatch;
    _matches.forEach((key, val) {
      if (val == index) leftIndexMatch = key;
    });

    Color cardColor = theme.cardColor;
    Color borderCol = isDark ? Colors.white10 : Colors.grey.shade200;
    double borderW = 1.5;

    if (isMatched) {
      if (_isSubmitted && leftIndexMatch != null) {
        final correct = _isCorrectMatch(leftIndexMatch!, index);
        borderCol = correct ? Colors.green : Colors.red;
        cardColor = correct
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08);
        borderW = 2.0;
      } else {
        borderCol = primary.withOpacity(0.5);
      }
    }

    return GestureDetector(
      key: _rightKeys[index],
      onTap: () => _onRightCardTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: borderW),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontWeight: isMatched ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final RenderBox? stackRenderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _onResetPressed,
            child: Text(
              _getTranslation(context, 'reset'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Headings Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTranslation(context, 'columnA'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    _getTranslation(context, 'columnB'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            // Matching Area inside Stack (scrollable so all pairs are reachable)
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  key: _stackKey,
                  children: [
                  // Custom Paint overlay for connection lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ConnectionPainter(
                        connections: _matches,
                        leftKeys: _leftKeys,
                        rightKeys: _rightKeys,
                        ancestorBox: stackRenderBox,
                        isSubmitted: _isSubmitted,
                        pairsData: widget.pairsData,
                        leftItems: _leftItems,
                        rightItems: _rightItems,
                        context: context,
                      ),
                    ),
                  ),
                  // Lists of items side by side
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column A (Left)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                _leftItems.length,
                                (index) => _buildLeftCard(
                                    context, theme, isDark, primary, index),
                              ),
                            ),
                          ),
                        ),
                        // Visual Spacer for lines
                        const SizedBox(width: 60),
                        // Column B (Right)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                _rightItems.length,
                                (index) => _buildRightCard(
                                    context, theme, isDark, primary, index),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ),
            // Submission Button Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitted ? _startNewGame : _submitMatches,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSubmitted ? Colors.grey.shade700 : primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isSubmitted
                            ? _getTranslation(context, 'retry')
                            : _getTranslation(context, 'submit'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final Map<int, int> connections;
  final List<GlobalKey> leftKeys;
  final List<GlobalKey> rightKeys;
  final RenderBox? ancestorBox;
  final bool isSubmitted;
  final List<Map<String, String>> pairsData;
  final List<String> leftItems;
  final List<String> rightItems;
  final BuildContext context;

  ConnectionPainter({
    required this.connections,
    required this.leftKeys,
    required this.rightKeys,
    required this.ancestorBox,
    required this.isSubmitted,
    required this.pairsData,
    required this.leftItems,
    required this.rightItems,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ancestorBox == null) return;

    final colors = [
      Colors.blue.shade600,
      Colors.purple.shade600,
      Colors.orange.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
    ];

    connections.forEach((leftIdx, rightIdx) {
      if (leftIdx >= leftKeys.length || rightIdx >= rightKeys.length) return;

      final leftContext = leftKeys[leftIdx].currentContext;
      final rightContext = rightKeys[rightIdx].currentContext;

      if (leftContext != null && rightContext != null) {
        final leftBox = leftContext.findRenderObject() as RenderBox?;
        final rightBox = rightContext.findRenderObject() as RenderBox?;

        if (leftBox != null && rightBox != null) {
          final leftOffset = leftBox.localToGlobal(
            Offset(leftBox.size.width, leftBox.size.height / 2),
            ancestor: ancestorBox,
          );
          final rightOffset = rightBox.localToGlobal(
            Offset(0, rightBox.size.height / 2),
            ancestor: ancestorBox,
          );

          Color lineColor = colors[leftIdx % colors.length];

          if (isSubmitted) {
            // Check correctness
            final leftVal = leftItems[leftIdx];
            final rightVal = rightItems[rightIdx];
            final correct = pairsData.any((p) => p['left'] == leftVal && p['right'] == rightVal);
            lineColor = correct ? Colors.green : Colors.red;
          }

          final paint = Paint()
            ..color = lineColor.withOpacity(0.85)
            ..strokeWidth = 3.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

          // Draw a beautiful curved bezier line
          final path = Path();
          path.moveTo(leftOffset.dx, leftOffset.dy);

          // Control points create a smooth S-curve horizontally
          final controlPoint1 = Offset(leftOffset.dx + 40, leftOffset.dy);
          final controlPoint2 = Offset(rightOffset.dx - 40, rightOffset.dy);
          path.cubicTo(
            controlPoint1.dx, controlPoint1.dy,
            controlPoint2.dx, controlPoint2.dy,
            rightOffset.dx, rightOffset.dy,
          );

          // Draw a subtle wider line shadow for glow effect
          canvas.drawPath(
            path,
            Paint()
              ..color = lineColor.withOpacity(0.18)
              ..strokeWidth = 7.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round,
          );

          canvas.drawPath(path, paint);

          // Draw circular connection dots at the anchor points
          final dotPaint = Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill;
          canvas.drawCircle(leftOffset, 5, dotPaint);
          canvas.drawCircle(rightOffset, 5, dotPaint);
        }
      }
    });
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return true; // Keep lines synced on layout/selection updates
  }
}

// Custom Confetti Particle Model
class ConfettiParticle {
  double x;
  double y;
  double speedY;
  double speedX;
  double angle;
  double rotateSpeed;
  Color color;
  double size;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.angle,
    required this.rotateSpeed,
    required this.color,
    required this.size,
  });
}

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.y += p.speedY;
            p.x += p.speedX;
            p.angle += p.rotateSpeed;
          }
        });
      });

    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.yellow.shade400,
      Colors.pink.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
    ];

    // Seed particle cloud
    for (int i = 0; i < 70; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble() * 360,
        y: -_random.nextDouble() * 200,
        speedY: 2.0 + _random.nextDouble() * 4.0,
        speedX: -1.5 + _random.nextDouble() * 3.0,
        angle: _random.nextDouble() * pi,
        rotateSpeed: -0.05 + _random.nextDouble() * 0.1,
        color: colors[_random.nextInt(colors.length)],
        size: 5.0 + _random.nextDouble() * 6.0,
      ));
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ConfettiPainter(particles: _particles),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);
      
      // Draw rectangular confetti bits
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return true;
  }
}
