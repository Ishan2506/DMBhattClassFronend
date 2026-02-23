import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/matching_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';

class OneLinerExamScreen extends StatefulWidget {
  const OneLinerExamScreen({super.key});

  @override
  State<OneLinerExamScreen> createState() => _OneLinerExamScreenState();
}

class _OneLinerExamScreenState extends State<OneLinerExamScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();
  double _confidence = 1.0;

  int _currentQuestionIndex = 0;
  final Map<int, String> _spokenAnswers = {};
  
  // Static question and answer list with multilingual Support and Synonyms
  final List<Map<String, dynamic>> _questions = [
    {
      "question": {
        "en": "What is matter?",
        "gu": "દ્રવ્ય એટલે શું?"
      },
      "answer": {
        "en": "Matter is anything that has mass and occupies space.",
        "gu": "દ્રવ્ય એ એવી વસ્તુ છે જે દળ ધરાવે છે અને જગ્યા રોકે છે."
      }
    },
    {
      "question": {
        "en": "What are the three states of matter?",
        "gu": "દ્રવ્યની ત્રણ અવસ્થાઓ કઈ છે?"
      },
      "answer": {
        "en": "The three states of matter are solid, liquid and gas.",
        "gu": "દ્રવ્યની ત્રણ અવસ્થાઓ ઘન, પ્રવાહી અને વાયુ છે."
      }
    },
    {
      "question": {
        "en": "What is diffusion?",
        "gu": "પ્રસરણ એટલે શું?"
      },
      "answer": {
        "en": "Diffusion is the intermixing of particles of two substances due to their random motion.",
        "gu": "પ્રસરણ એટલે બે પદાર્થોના કણોની તેમની યાદચ્છિક ગતિને કારણે એકબીજામાં ભળી જવાની પ્રક્રિયા."
      }
    },
    {
      "question": {
        "en": "Why are gases highly compressible?",
        "gu": "વાયુઓ શા માટે વધુ દબનીય હોય છે?"
      },
      "answer": {
        "en": "Gases are highly compressible because the particles have large spaces between them.",
        "gu": "વાયુઓ વધુ દબનીય હોય છે કારણ કે કણો વચ્ચે મોટી જગ્યાઓ હોય છે."
      }
    },
    {
      "question": {
        "en": "What is sublimation?",
        "gu": "ઉર્ધ્વપાતન એટલે શું?"
      },
      "answer": {
        "en": "Sublimation is the direct change of a solid into gas without passing through the liquid state.",
        "gu": "ઉર્ધ્વપાતન એટલે ઘન પદાર્થનું પ્રવાહી અવસ્થામાં આવ્યા વિના સીધું વાયુમાં રૂપાંતર થવાની પ્રક્રિયા."
      }
    }
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _checkPermission();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      await Permission.microphone.request();
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        final locale = context.read<ThemeCubit>().state.locale.languageCode;
        _speech.listen(
          localeId: locale == 'gu' ? 'gu_IN' : 'en_US',
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _spokenAnswers[_currentQuestionIndex] = _textController.text;
      }
    }
  }

  void _nextQuestion() {
    if (_textController.text.isNotEmpty) {
      _spokenAnswers[_currentQuestionIndex] = _textController.text;
    }
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _textController.text = _spokenAnswers[_currentQuestionIndex] ?? "";
        _isListening = false;
      });
      _speech.stop();
    } else {
      _showResult();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _textController.text = _spokenAnswers[_currentQuestionIndex] ?? "";
        _isListening = false;
      });
      _speech.stop();
    }
  }

  String _getQuestion() {
    final lang = context.read<ThemeCubit>().state.locale.languageCode;
    return _questions[_currentQuestionIndex]['question'][lang] ?? _questions[_currentQuestionIndex]['question']['en'];
  }

  String _getAnswer(int index) {
    final lang = context.read<ThemeCubit>().state.locale.languageCode;
    return _questions[index]['answer'][lang] ?? _questions[index]['answer']['en'];
  }

  void _showResult() {
    int score = 0;
    double totalPartialScore = 0.0;
    for (int i = 0; i < _questions.length; i++) {
      final matchScore = MatchingUtils.getMatchScore(_spokenAnswers[i] ?? "", _getAnswer(i));
      totalPartialScore += matchScore;
      if (matchScore >= 0.7) {
        score++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Exam Completed"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Score: $score / ${_questions.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Average Accuracy: ${(totalPartialScore / _questions.length * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
              const SizedBox(height: 16),
              const Text("Detailed Review:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final matchScore = MatchingUtils.getMatchScore(_spokenAnswers[index] ?? "", _getAnswer(index));
                    final isCorrect = matchScore >= 0.7;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Q${index + 1}: ${_questions[index]['question']['en']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("Answer: ${_getAnswer(index)}", style: const TextStyle(color: Colors.blue, fontSize: 12)),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black, fontSize: 12),
                              children: [
                                const TextSpan(text: "You said: ", style: TextStyle(fontStyle: FontStyle.italic)),
                                TextSpan(
                                  text: _spokenAnswers[index] ?? "N/A",
                                  style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: " (${(matchScore * 100).toStringAsFixed(0)}% match)",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back from exam
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lang = context.select((ThemeCubit c) => c.state.locale.languageCode);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: lang == 'gu' ? "એક લીટી પરીક્ષા" : "One-Liner Exam",
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: colorScheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'gu' ? "પ્રશ્ન ${_currentQuestionIndex + 1} માંથી ${_questions.length}" : "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Question Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Text(
                  _getQuestion(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              
              // Editing Field (TextFormField)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isListening ? Colors.red.shade300 : Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 3,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: lang == 'gu' ? "માઇક્રોફોન ટેપ કરો અને બોલો, અથવા અહીં ટાઇપ કરો..." : "Tap microphone and speak, or type here...",
                    hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                     _spokenAnswers[_currentQuestionIndex] = val;
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              // Microphone Button
              Center(
                child: GestureDetector(
                  onTap: _listen,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : colorScheme.primary).withOpacity(0.4),
                          blurRadius: _isListening ? 30 : 20,
                          spreadRadius: _isListening ? 10 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    lang == 'gu' ? "સાંભળી રહ્યા છીએ..." : "Listening...",
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 40),
              
              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    TextButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      label: Text(lang == 'gu' ? "પાછળ" : "Previous"),
                    )
                  else
                    const Spacer(),
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentQuestionIndex == _questions.length - 1 
                          ? (lang == 'gu' ? "પૂર્ણ" : "Finish") 
                          : (lang == 'gu' ? "આગળ" : "Next")),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
