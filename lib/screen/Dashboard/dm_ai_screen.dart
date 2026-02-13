import 'dart:convert';
import 'package:dm_bhatt_tutions/model/chat_message.dart';
import 'package:dm_bhatt_tutions/network/ai_service.dart';
import 'package:dm_bhatt_tutions/widget/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';


class DMAIChatScreen extends StatefulWidget {
  const DMAIChatScreen({super.key});

  @override
  State<DMAIChatScreen> createState() => _DMAIChatScreenState();
}

class _DMAIChatScreenState extends State<DMAIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = TuitionAIService();
  // final FlutterTts _flutterTts = FlutterTts();


  final List<ChatMessage> _messages = [];

  String? _standard;
  String? _stream;
  String? _subject;
  String? _chapter;
  
  String? _savedStandard;
  String? _savedStream;

  bool _loading = false;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    // _initTts();
    _fetchStudentName();
    _startFreshConversation();
  }

  Future<void> _fetchStudentName() async {
    try {
      // Token managed internally
      final response = await ApiService.getProfile();
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _studentName = data['user']['firstName'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching name: $e");
    }
  }

  //  Future<void> _initTts() async {
  //   await _flutterTts.setLanguage("en-IN");
  //   await _flutterTts.setPitch(1.1); // Higher pitch for female voice preference
  //   await _flutterTts.setSpeechRate(0.5);
  // }

  // Future<void> _speak(String text) async {
  //   await _flutterTts.speak(text);
  // }

  @override
  void dispose() {
    // _flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔁 FULL RESET (Clear chat)
  void _startFreshConversation() {
    setState(() {
      _messages.clear();
      _resetQuery();
    });
  }

  // 🔄 PARTIAL RESET (Keep chat, reset flow)
  void _resetQuery() {
    setState(() {
      _standard = null;
      _subject = null;
      _chapter = null;
      _loading = false;
    });
  }

  void _addBot(String text, {List<String>? options, List<Map<String, String>>? videos}) {
    _messages.add(ChatMessage(
      text: text, 
      isUser: false, 
      options: options,
      videos: videos
    ));
    _scrollToBottom();
    // _speak(text);
    setState(() {});
  }

  void _addUser(String text) {
    _messages.add(ChatMessage(text: text, isUser: true));
    _scrollToBottom();
    setState(() {});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isValidStandard(String input) {
    return RegExp(r'^(std\s*)?(8|9|10|11|12)$',
            caseSensitive: false)
        .hasMatch(input.trim());
  }

  bool _looksLikeQuestion(String input) {
    return RegExp(r'^(what|why|how|who|when|where)\b',
            caseSensitive: false)
        .hasMatch(input.trim()) ||
        input.contains('?');
  }

  bool _isValidSubject(String input) {
    if (_looksLikeQuestion(input)) return false;
    if (input.length < 2 || input.length > 25) return false;
    return true;
  }

  bool _isValidChapter(String input) {
    if (_looksLikeQuestion(input)) return false;
    if (input.length < 3 || input.length > 50) return false;
    return true;
  }

  Future<void> _handleSubmit() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    _controller.clear();
    _addUser(input);

    // STEP 0: GREETING
    final lowerInput = input.toLowerCase();
    if (lowerInput.startsWith('hi') || lowerInput.startsWith('hello') || lowerInput.startsWith('hey')) {
      final name = _studentName ?? "Student";
      _addBot("Hi $name! 👋 I'm here to help with your studies. Which class are you in?",
          options: ['Std 8', 'Std 9', 'Std 10', 'Std 11', 'Std 12']);
      _resetQuery(); // Ensure we start fresh
      return;
    }

    // STEP 1: CLASS
    if (_standard == null) {
      if (!_isValidStandard(input)) {
        _addBot(
            "❌ Please tell me a valid class like Std 8, 9, 10, 11 or 12.",
            options: ['Std 8', 'Std 9', 'Std 10', 'Std 11', 'Std 12']);
        return;
      }
      _standard = input;
      
      final stdNum = int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), ''));
      if (stdNum != null && stdNum >= 11) {
        _addBot("Which stream are you in?", options: ['Science', 'Commerce']);
      } else {
        _addBot("Great 👍 Now tell me your subject", options: [
          'Maths',
          'Science',
          'English',
          'Social Science',
          'Gujarati',
        ]);
      }
      return;
    }

    // STEP 1.5: STREAM (Conditional for 11 & 12)
    final stdNum = int.tryParse(_standard!.replaceAll(RegExp(r'[^0-9]'), ''));
    if (stdNum != null && stdNum >= 11 && _stream == null) {
      if (input.toLowerCase() == 'science' || input.toLowerCase() == 'commerce') {
        _stream = input;
        if (input.toLowerCase() == 'science') {
          _addBot("Select your Science subject", options: [
            'Physics',
            'Chemistry',
            'Mathematics',
            'English',
            'Biology',
            'Computer',
            'Physical Education'
          ]);
        } else {
          _addBot("Select your Commerce subject", options: [
            'Account',
            'BA',
            'Eco',
            'English',
            'State'
          ]);
        }
      } else {
        _addBot("❌ Please select a valid stream", options: ['Science', 'Commerce']);
      }
      return;
    }

    // STEP 2: SUBJECT
    if (_subject == null) {
      if (!_isValidSubject(input)) {
        List<String> options = [];
        if (stdNum != null && stdNum >= 11) {
          if (_stream?.toLowerCase() == 'science') {
            options = ['Physics', 'Chemistry', 'Mathematics', 'English', 'Biology', 'Computer', 'Physical Education'];
          } else {
            options = ['Account', 'BA', 'Eco', 'English', 'State'];
          }
        } else {
          options = ['Maths', 'Science', 'English', 'Social Science', 'Gujarati'];
        }

        _addBot(
            "❌ Subject name looks invalid. Please select from the options below:",
            options: options);
        return;
      }
      _subject = input;
      _addBot("Nice! Now tell me the chapter name (Chapter 1, Chapter 2, etc.)");
      return;
    }

    // STEP 3: CHAPTER
    if (_chapter == null) {
      // 🚨 STRICT VALIDATION: If only digits, reject it
      if (RegExp(r'^\d+$').hasMatch(input)) {
         _addBot("❌ Please enter valid format like 'Chapter $input' or topic name.");
         return; 
      }

      if (!_isValidChapter(input)) {
        _addBot(
            "❌ Chapter name looks invalid. Example: Chapter 3, Geometry");
        return;
      }
      _chapter = input;
      _addBot("Thinking... 🔍");
    }

    // STEP 4: CALL AI SERVICE
    setState(() => _loading = true);
    try {
      final videos = await _aiService.fetchLectureVideo(
        standard: _standard!,
        subject: _subject!,
        chapter: _chapter!,
      );

      if (videos.isNotEmpty) {
        _addBot(
          "📺 Found ${videos.length} videos for you! Tap to watch:",
          videos: videos,
        );
        
        // ✅ AUTO RESET FLOW FOR NEXT QUESTION
        _resetQuery();
        _addBot(
            "🎓 Ready for next question! Which class?", 
            options: ['Std 8', 'Std 9', 'Std 10', 'Std 11', 'Std 12']
        );

      } else {
        _addBot("⚠️ Sorry, I couldn’t find a video for this chapter.");
        _resetQuery(); // Reset to let them try again
        _addBot("Please try another topic or class.", options: ['Std 8', 'Std 9', 'Std 10', 'Std 11', 'Std 12']);
      }
    } catch (e) {
      _addBot("⚠️ Something went wrong. Please try again.");
      _resetQuery();
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      
      body: Column(
        children: [


          Expanded(
            child: Stack(
              children: [
                if (_messages.isNotEmpty)
                  Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.asset(imgLoaderBot, width: 250),
                    ),
                  ),
                _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: colorScheme.primary.withOpacity(0.1),
                            backgroundImage: const AssetImage(imgLoaderBot),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Hello Friend! I'm your DMAI Teacher",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          "Ask me anything about your studies",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => ChatBubble(
                      message: _messages[i],
                      onOptionSelected: (option) {
                        _controller.text = option;
                        _handleSubmit();
                      },
                    ),
                  ),
              ],
            ),
          ),

          if (_loading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const CircularProgressIndicator(strokeWidth: 2),
                   const SizedBox(width: 8),
                   Text("Searching video...", style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.primary)),
                ],
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ]
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurfaceVariant),
                    onPressed: _startFreshConversation,
                    tooltip: "Reset Chat",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          cursorColor: Theme.of(context).colorScheme.primary,
                          decoration: InputDecoration(
                            hintText: "Type your answer...",
                            hintStyle: GoogleFonts.poppins(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 14
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _handleSubmit(),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(right: 8.0),
                      //   child: IconButton(
                      //     icon: const Icon(Icons.mic, color: Colors.blue),
                      //     onPressed: () {
                      //         // Mic action placeholder
                      //     },
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary, // Matching deep blue
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: IconButton(
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
