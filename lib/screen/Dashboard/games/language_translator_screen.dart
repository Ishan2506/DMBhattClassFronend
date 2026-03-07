import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/mind_game_service.dart';

class LanguageTranslatorScreen extends StatefulWidget {
  const LanguageTranslatorScreen({super.key});

  @override
  State<LanguageTranslatorScreen> createState() => _LanguageTranslatorScreenState();
}

class TranslationWord {
  final String english;
  final String hindi;
  final String gujarati;

  TranslationWord(this.english, this.hindi, this.gujarati);
}

class _LanguageTranslatorScreenState extends State<LanguageTranslatorScreen> {
  final MindGameService _gameService = MindGameService();
  final Random _random = Random();
  
  int _score = 0;
  int _currentIndex = 0;
  
  // 0: English -> Hindi, 1: English -> Gujarati, 2: Hindi -> English, etc.
  int _questionType = 0;
  List<String> _currentOptions = [];
  String _questionText = "";
  String _correctAnswer = "";
  String _targetLanguage = "";

  final List<TranslationWord> _allWords = [
    TranslationWord("Book", "किताब (Kitab)", "પુસ્તક (Pustak)"),
    TranslationWord("Water", "पानी (Pani)", "પાણી (Pani)"),
    TranslationWord("School", "विद्यालय (Vidyalaya)", "શાળા (Shala)"),
    TranslationWord("Teacher", "शिक्षक (Shikshak)", "શિક્ષક (Shikshak)"),
    TranslationWord("Student", "छात्र (Chhatra)", "વિદ્યાર્થી (Vidyarthi)"),
    TranslationWord("Friend", "दोस्त (Dost)", "મિત્ર (Mitra)"),
    TranslationWord("Food", "खाना (Khana)", "ખોરાક (Khorak)"),
    TranslationWord("House", "घर (Ghar)", "ઘર (Ghar)"),
    TranslationWord("Time", "समय (Samay)", "સમય (Samay)"),
    TranslationWord("Money", "पैसा (Paisa)", "પૈસા (Paisa)"),
    TranslationWord("Work", "काम (Kaam)", "કામ (Kaam)"),
    TranslationWord("Love", "प्यार (Pyaar)", "પ્રેમ (Prem)"),
    TranslationWord("Happy", "खुश (Khush)", "ખુશ (Khush)"),
    TranslationWord("Beautiful", "सुंदर (Sundar)", "સુંદર (Sundar)"),
    TranslationWord("Family", "परिवार (Parivar)", "પરિવાર (Parivar)"),
  ];

  late List<TranslationWord> _sessionWords;

  @override
  void initState() {
    super.initState();
    _gameService.startSession(context);
    _startSession();
  }

  void _startSession() {
    _sessionWords = List.from(_allWords)..shuffle();
    _score = 0;
    _currentIndex = 0;
    _loadQuestion();
  }

  void _loadQuestion() {
    if (_currentIndex >= _sessionWords.length) {
      _showWinDialog();
      return;
    }

    final currentWord = _sessionWords[_currentIndex];
    _questionType = _random.nextInt(4);

    switch (_questionType) {
      case 0: // English to Hindi
        _questionText = currentWord.english;
        _correctAnswer = currentWord.hindi;
        _targetLanguage = "Hindi";
        break;
      case 1: // English to Gujarati
        _questionText = currentWord.english;
        _correctAnswer = currentWord.gujarati;
        _targetLanguage = "Gujarati";
        break;
      case 2: // Hindi to English
        _questionText = currentWord.hindi;
        _correctAnswer = currentWord.english;
        _targetLanguage = "English";
        break;
      case 3: // Gujarati to English
        _questionText = currentWord.gujarati;
        _correctAnswer = currentWord.english;
        _targetLanguage = "English";
        break;
    }

    // Generate wrong options
    final _wrongOptionsPool = _allWords.where((w) => w.english != currentWord.english).toList()..shuffle();
    _currentOptions = [_correctAnswer];
    
    for (int i = 0; i < 3; i++) {
        switch (_questionType) {
          case 0: _currentOptions.add(_wrongOptionsPool[i].hindi); break;
          case 1: _currentOptions.add(_wrongOptionsPool[i].gujarati); break;
          case 2: _currentOptions.add(_wrongOptionsPool[i].english); break;
          case 3: _currentOptions.add(_wrongOptionsPool[i].english); break;
        }
    }
    _currentOptions.shuffle();
  }

  @override
  void dispose() {
    _gameService.stopSession();
    super.dispose();
  }

  void _checkAnswer(String selectedTranslation) {
    if (selectedTranslation == _correctAnswer) {
      setState(() {
        _score += 10;
        _currentIndex++;
        _loadQuestion();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correct translation!"),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incorrect! The correct answer was $_correctAnswer."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _currentIndex++;
        _loadQuestion();
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Translation Complete!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "You scored $_score out of ${_sessionWords.length * 10} points.",
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _startSession());
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit game
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
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
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.videogame_asset, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "How to Play",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInstructionRow(theme, "1", "A word will be shown on the screen."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "2", "Look at the target language requested (e.g., Translate to Hindi)."),
              const SizedBox(height: 12),
              _buildInstructionRow(theme, "3", "Select the correct translated word from the options provided."),
              const SizedBox(height: 24),
              // Example Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.tertiary.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Example Idea",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Translate 'Book' to Gujarati",
                      style: GoogleFonts.poppins(fontSize: 14, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "પુસ્તક (Pustak)",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                  elevation: 2,
                ),
                child: Text("Let's Play!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
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
            color: theme.colorScheme.secondary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _sessionWords.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Language Translator",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowToPlay,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Score Board
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Word ${_currentIndex + 1}/${_sessionWords.length}",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Score: $_score",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              Text(
                "Translate to $_targetLanguage",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
              ),
              
              const SizedBox(height: 24),
              
              // Word Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Text(
                  _questionText,
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const Spacer(),
              
              // Options Column
              Column(
                children: _currentOptions.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton(
                      onPressed: () => _checkAnswer(option),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        backgroundColor: theme.cardColor,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                        ),
                      ),
                      child: Text(
                        option,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
