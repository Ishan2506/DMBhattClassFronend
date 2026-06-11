import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class TrueFalseGameScreen extends StatefulWidget {
  final String exerciseId;
  final String title;
  final String subject;
  final List<Map<String, dynamic>> questionsData;

  const TrueFalseGameScreen({
    super.key,
    required this.exerciseId,
    required this.title,
    required this.subject,
    required this.questionsData,
  });

  @override
  State<TrueFalseGameScreen> createState() => _TrueFalseGameScreenState();
}

class _TrueFalseGameScreenState extends State<TrueFalseGameScreen> {
  // Track selected answers: key is question index, value is boolean (true = True, false = False)
  final Map<int, bool> _answers = {};

  bool _isSubmitted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _answers.clear();
      _isSubmitted = false;
      _score = 0;
    });
  }

  void _selectAnswer(int index, bool val) {
    if (_isSubmitted) return;
    setState(() {
      _answers[index] = val;
    });
  }

  void _submitAnswers() {
    if (_answers.length < widget.questionsData.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation(context, 'selectOptionPrompt')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int tempScore = 0;
    for (int i = 0; i < widget.questionsData.length; i++) {
      final correctAnswer = widget.questionsData[i]['answer'] as bool;
      if (_answers[i] == correctAnswer) {
        tempScore++;
      }
    }

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
      final historyList = prefs.getStringList('true_false_history') ?? [];
      final newItem = {
        'id': widget.exerciseId,
        'title': widget.title,
        'subject': widget.subject,
        'score': _score,
        'total': widget.questionsData.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
      historyList.insert(0, jsonEncode(newItem));
      await prefs.setStringList('true_false_history', historyList);
    } catch (e) {
      debugPrint("Error saving true false history: $e");
    }
  }

  void _showResultDialog() {
    final theme = Theme.of(context);
    final isPerfect = _score == widget.questionsData.length;

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
                    : (_score >= widget.questionsData.length / 2
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
                    children: List.generate(widget.questionsData.length, (index) {
                      return Icon(
                        index < _score ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${_getTranslation(context, 'score')}: $_score / ${widget.questionsData.length}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(_score / widget.questionsData.length * 100).toInt()}% ${_getTranslation(context, 'accuracy')}",
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
        'submit': 'Submit Answers',
        'reset': 'Reset',
        'perfect': 'Perfect Score!',
        'goodJob': 'Good Job!',
        'keepTrying': 'Keep Practicing!',
        'score': 'Score',
        'accuracy': 'Accuracy',
        'retry': 'Play Again',
        'exit': 'Exit',
        'howToPlay': 'How to Play',
        'rule1': 'Read each statement carefully.',
        'rule2': 'Select TRUE if the statement is correct, or FALSE if it is incorrect.',
        'rule3': 'You must answer all statements before submitting.',
        'rule4': 'After submitting, review the explanation for each statement.',
        'letsPlay': 'Let\'s Play!',
        'selectOptionPrompt': 'Please answer all questions before submitting!',
        'trueText': 'TRUE',
        'falseText': 'FALSE',
        'explanation': 'Explanation',
      },
      'gu': {
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
        'rule1': 'દરેક વિધાન ધ્યાનથી વાંચો.',
        'rule2': 'જો વિધાન સાચું હોય તો સાચું (TRUE) પસંદ કરો, અથવા ખોટું હોય તો ખોટું (FALSE) પસંદ કરો.',
        'rule3': 'સબમિટ કરતા પહેલા તમારે બધા પ્રશ્નોના ઉત્તર આપવા પડશે.',
        'rule4': 'સબમિટ કર્યા પછી, દરેક વિધાન માટેની સમજૂતી તપાસો.',
        'letsPlay': 'ચાલો રમીએ!',
        'selectOptionPrompt': 'કૃપા કરીને સબમિટ કરતા પહેલા બધા પ્રશ્નોના ઉત્તર આપો!',
        'trueText': 'ખરું',
        'falseText': 'ખોટું',
        'explanation': 'સમજૂતી',
      },
      'hi': {
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
        'rule1': 'प्रत्येक कथन को ध्यान से पढ़ें।',
        'rule2': 'यदि कथन सही है तो सही (TRUE) चुनें, और यदि गलत है तो गलत (FALSE) चुनें।',
        'rule3': 'जमा करने से पहले आपको सभी कथनों का उत्तर देना होगा।',
        'rule4': 'जमा करने के बाद, प्रत्येक कथन के लिए स्पष्टीकरण की समीक्षा करें।',
        'letsPlay': 'चलो खेलें!',
        'selectOptionPrompt': 'कृपया जमा करने से पहले सभी प्रश्नों के उत्तर दें!',
        'trueText': 'सही',
        'falseText': 'गलत',
        'explanation': 'स्पष्टीकरण',
      },
      'mr': {
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
        'rule1': 'प्रत्येक विधान काळजीपूर्वक वाचा.',
        'rule2': 'विधान बरोबर असल्यास बरोबर (TRUE) निवडा, चूक असल्यास चूक (FALSE) निवडा.',
        'rule3': 'सबमिट करण्यापूर्वी तुम्हाला सर्व प्रश्नांची उत्तरे द्यावी लागतील.',
        'rule4': 'सबमिट केल्यानंतर, प्रत्येक विधानाच्या स्पष्टीकरणाचे पुनरावलोकन करा.',
        'letsPlay': 'चला खेळूया!',
        'selectOptionPrompt': 'कृपया सबमिट करण्यापूर्वी सर्व प्रश्नांची उत्तरे द्या!',
        'trueText': 'बरोबर',
        'falseText': 'चूक',
        'explanation': 'स्पष्टीकरण',
      },
      'ta': {
        'submit': 'சமர்ப்பிக்கவும்',
        'reset': 'மீட்டமை',
        'perfect': 'முழு மதிப்பெண்!',
        'goodJob': 'நன்று!',
        'keepTrying': 'முயற்சி செய்க!',
        'score': 'மதிப்பெண்',
        'accuracy': 'துல்லியம்',
        'retry': 'மீண்டும் ठेवा',
        'exit': 'வெளியேறு',
        'howToPlay': 'விளையாடுவது எப்படி',
        'rule1': 'ஒவ்வொரு கூற்றையும் கவனமாகப் படிக்கவும்.',
        'rule2': 'கூற்று சரியாக இருந்தால் சரி (TRUE) என்றும், தவறாக இருந்தால் தவறு (FALSE) என்றும் தேர்ந்தெடுக்கவும்.',
        'rule3': 'சமர்ப்பிப்பதற்கு முன் நீங்கள் அனைத்து வினாக்களுக்கும் பதிலளிக்க வேண்டும்.',
        'rule4': 'சமர்ப்பித்த பிறகு, ஒவ்வொரு கூற்றிற்கான விளக்கத்தையும் சரிபார்க்கவும்.',
        'letsPlay': 'தொடங்குவோம்!',
        'selectOptionPrompt': 'சமர்ப்பிப்பதற்கு முன் அனைத்து வினாக்களுக்கும் பதிலளிக்கவும்!',
        'trueText': 'சரி',
        'falseText': 'தவறு',
        'explanation': 'விளக்கம்',
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
            // Statement list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: widget.questionsData.length,
                itemBuilder: (context, index) {
                  final qData = widget.questionsData[index];
                  final statement = qData['statement'] as String;
                  final correctAnswer = qData['answer'] as bool;
                  final explanation = qData['explanation'] as String;
                  final userSel = _answers[index];

                  Color cardBorderCol = isDark ? Colors.white10 : Colors.grey.shade200;
                  Color cardColor = theme.cardColor;

                  if (_isSubmitted && userSel != null) {
                    final correct = userSel == correctAnswer;
                    cardBorderCol = correct ? Colors.green : Colors.red;
                    cardColor = correct ? Colors.green.withOpacity(0.04) : Colors.red.withOpacity(0.04);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorderCol, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Index and Result icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Statement ${index + 1}",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (_isSubmitted && userSel != null) ...[
                              Icon(
                                userSel == correctAnswer ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: userSel == correctAnswer ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Statement text
                        Text(
                          statement,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // TRUE and FALSE options side-by-side
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionButton(
                                context: context,
                                text: _getTranslation(context, 'trueText'),
                                isSelected: userSel == true,
                                isCorrectOption: correctAnswer == true,
                                activeColor: Colors.green,
                                onTap: () => _selectAnswer(index, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildOptionButton(
                                context: context,
                                text: _getTranslation(context, 'falseText'),
                                isSelected: userSel == false,
                                isCorrectOption: correctAnswer == false,
                                activeColor: Colors.red,
                                onTap: () => _selectAnswer(index, false),
                              ),
                            ),
                          ],
                        ),
                        // Explanation block
                        if (_isSubmitted) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTranslation(context, 'explanation'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  explanation,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Submit Button Area
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
                      onPressed: _isSubmitted ? _startNewGame : _submitAnswers,
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

  Widget _buildOptionButton({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required bool isCorrectOption,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgCol = isDark ? const Color(0xFF1E284A) : Colors.grey.shade100;
    Color borderCol = isDark ? Colors.white10 : Colors.grey.shade200;
    Color textCol = isDark ? Colors.white70 : Colors.grey.shade700;

    if (isSelected) {
      bgCol = activeColor.withOpacity(0.15);
      borderCol = activeColor;
      textCol = activeColor;
    }

    if (_isSubmitted) {
      if (isCorrectOption) {
        // Highlight correct option in green
        bgCol = Colors.green.withOpacity(0.2);
        borderCol = Colors.green;
        textCol = Colors.green;
      } else if (isSelected) {
        // User selected this and it was wrong
        bgCol = Colors.red.withOpacity(0.2);
        borderCol = Colors.red;
        textCol = Colors.red;
      } else {
        // Not selected and wrong
        bgCol = isDark ? const Color(0xFF1E284A) : Colors.grey.shade100;
        borderCol = isDark ? Colors.white10 : Colors.grey.shade200;
        textCol = isDark ? Colors.white30 : Colors.grey.shade400;
      }
    }

    return GestureDetector(
      onTap: _isSubmitted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: 1.5),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected || (_isSubmitted && isCorrectOption) ? FontWeight.bold : FontWeight.w600,
            color: textCol,
          ),
        ),
      ),
    );
  }
}

// Confetti particle models & overlay
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
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return true;
  }
}
