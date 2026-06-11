import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';


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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation(context, 'selectLeftFirst')),
          duration: const Duration(seconds: 1),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation(context, 'matchAllPrompt')),
          backgroundColor: Colors.orange,
        ),
      );
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
    _showResultDialog();
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('match_following_history') ?? [];
      final newItem = {
        'id': widget.exerciseId,
        'title': widget.title,
        'subject': widget.subject,
        'score': _score,
        'total': _leftItems.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
      historyList.insert(0, jsonEncode(newItem));
      await prefs.setStringList('match_following_history', historyList);
    } catch (e) {
      debugPrint("Error saving match following history: $e");
    }
  }

  void _showResultDialog() {
    final theme = Theme.of(context);
    final isPerfect = _score == _leftItems.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isPerfect
                    ? _getTranslation(context, 'perfect')
                    : (_score >= _leftItems.length / 2
                        ? _getTranslation(context, 'goodJob')
                        : _getTranslation(context, 'keepTrying')),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // Star Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_leftItems.length, (index) {
                      return Icon(
                        index < _score ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${_getTranslation(context, 'score')}: $_score / ${_leftItems.length}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(_score / _leftItems.length * 100).toInt()}% ${_getTranslation(context, 'accuracy')}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to selection screen
                  },
                  child: Text(
                    _getTranslation(context, 'exit'),
                    style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startNewGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _getTranslation(context, 'retry'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (isPerfect)
              const IgnorePointer(
                child: ConfettiOverlay(),
              ),
          ],
        );
      },
    );
  }

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
        'columnA': 'વિભાગ A',
        'columnB': 'વિભાગ B',
        'submit': 'સબમિટ કરો',
        'reset': 'રીસેટ',
        'perfect': 'ઉત્તમ પરિણામ!',
        'goodJob': 'ખૂબ સરસ!',
        'keepTrying': 'પ્રયાસ ચાલુ રાખો!',
        'score': 'ગુણ',
        'accuracy': 'ચોકસાઈ',
        'retry': 'ફરી રમો',
        'exit': 'બહાર નીકળો',
        'howToPlay': 'કેવી રીતે રમવું',
        'rule1': 'વિભાગ A (ડાબી બાજુ) ના કોઈપણ શબ્દ પર ટેપ કરો.',
        'rule2': 'તેને જોડવા માટે વિભાગ B (જમણી બાજુ) ના સાચા શબ્દ પર ટેપ કરો.',
        'rule3': 'બંનેની વચ્ચે એક સુંદર રંગીન લાઈન જોડાશે.',
        'rule4': 'જોડાણ રદ કરવા માટે જોડાયેલા શબ્દ પર ફરી ટેપ કરો.',
        'letsPlay': 'ચાલો રમીએ!',
        'selectLeftFirst': 'કૃપા કરીને પહેલા વિભાગ A માંથી એક શબ્દ પસંદ કરો!',
        'matchAllPrompt': 'કૃપા કરીને સબમિટ કરતા પહેલા બધા જોડકા જોડો!',
      },
      'hi': {
        'columnA': 'स्तंभ A',
        'columnB': 'स्तंभ B',
        'submit': 'जमा करें',
        'reset': 'रिसेट',
        'perfect': 'उत्कृष्ट स्कोर!',
        'goodJob': 'अच्छा प्रयास!',
        'keepTrying': 'अभ्यास करते रहें!',
        'score': 'अंक',
        'accuracy': 'सटीकता',
        'retry': 'पुनः खेलें',
        'exit': 'बाहर निकलें',
        'howToPlay': 'कैसे खेलें',
        'rule1': 'स्तंभ A (बाएं) में किसी भी आइटम पर टैप करें।',
        'rule2': 'उन्हें जोड़ने के लिए स्तंभ B (दाएं) में संबंधित आइटम पर टैप करें।',
        'rule3': 'एक रंगीन रेखा दोनों को जोड़ देगी।',
        'rule4': 'कनेक्शन हटाने के लिए, जुड़े हुए आइटम पर फिर से टैप करें।',
        'letsPlay': 'चलो खेलें!',
        'selectLeftFirst': 'कृपया पहले स्तंभ A से एक आइटम चुनें!',
        'matchAllPrompt': 'कृपया जमा करने से पहले सभी जोड़े मिलाएँ!',
      },
      'mr': {
        'columnA': 'गट A',
        'columnB': 'गट B',
        'submit': 'सबमिट करा',
        'reset': 'रिसेट',
        'perfect': 'उत्कृष्ट गुण!',
        'goodJob': 'शाब्बास!',
        'keepTrying': 'सराव करत राहा!',
        'score': 'गुण',
        'accuracy': 'अचूकता',
        'retry': 'पुन्हा खेळा',
        'exit': 'बाहेर पडा',
        'howToPlay': 'कसे खेळायचे',
        'rule1': 'गट A (डावीकडील) मधील कोणत्याही घटकावर टॅप करा.',
        'rule2': 'जोडण्यासाठी गट B (उजवीकडील) मधील संबंधित घटकावर टॅप करा.',
        'rule3': 'दोन्हींच्या मध्ये एक रंगीत रेषा जोडली जाईल.',
        'rule4': 'जोडणी रद्द करण्यासाठी जोडलेल्या घटकावर पुन्हा टॅप करा.',
        'letsPlay': 'चला खेळूया!',
        'selectLeftFirst': 'कृपया आधी गट A मधील घटक निवडा!',
        'matchAllPrompt': 'कृपया सबमिट करण्यापूर्वी सर्व जोड्या जुळवा!',
      },
      'ta': {
        'columnA': 'நெடுவரிசை A',
        'columnB': 'நெடுவரிசை B',
        'submit': 'சமர்ப்பிக்கவும்',
        'reset': 'மீட்டமை',
        'perfect': 'முழு மதிப்பெண்!',
        'goodJob': 'நன்று!',
        'keepTrying': 'முயற்சி செய்க!',
        'score': 'மதிப்பெண்',
        'accuracy': 'துல்லியம்',
        'retry': 'மீண்டும் விளையாடு',
        'exit': 'வெளியேறு',
        'howToPlay': 'விளையாடுவது எப்படி',
        'rule1': 'நெடுவரிசை A இல் உள்ள ஏதேனும் ஒரு சொல்லைத் தட்டவும்.',
        'rule2': 'நெடுவரிசை B இல் உள்ள அதற்குப் பொருத்தமான சொல்லைத் தட்டவும்.',
        'rule3': 'ஒரு வண்ணக் கோடு இரண்டையும் இணைக்கும்.',
        'rule4': 'இணைப்பை நீக்க, இணைக்கப்பட்ட சொல்லை மீண்டும் தட்டவும்.',
        'letsPlay': 'தொடங்குவோம்!',
        'selectLeftFirst': 'முதலில் நெடுவரிசை A இலிருந்து ஒரு சொல்லைத் தேர்ந்தெடுக்கவும்!',
        'matchAllPrompt': 'சமர்ப்பிப்பதற்கு முன் அனைத்து ஜோடிகளையும் இணைக்கவும்!',
      }
    };
    final langMap = translations[locale] ?? translations['en']!;
    return langMap[key] ?? key;
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
            onPressed: _startNewGame,
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
            // Matching Area inside Stack
            Expanded(
              child: Stack(
                key: _stackKey,
                fit: StackFit.expand,
                children: [
                  // Custom Paint overlay for connection lines
                  CustomPaint(
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
                  // Lists of items side by side
                  Row(
                    children: [
                      // Column A (Left)
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _leftItems.length,
                          itemBuilder: (context, index) {
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
                          },
                        ),
                      ),
                      // Visual Spacer for lines
                      const SizedBox(width: 60),
                      // Column B (Right)
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rightItems.length,
                          itemBuilder: (context, index) {
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
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
