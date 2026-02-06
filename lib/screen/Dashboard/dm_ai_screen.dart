import 'package:dm_bhatt_tutions/model/chat_message.dart';
import 'package:dm_bhatt_tutions/network/ai_service.dart';
import 'package:dm_bhatt_tutions/widget/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:google_fonts/google_fonts.dart';


class DMAIChatScreen extends StatefulWidget {
  const DMAIChatScreen({super.key});

  @override
  State<DMAIChatScreen> createState() => _DMAIChatScreenState();
}

class _DMAIChatScreenState extends State<DMAIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = TuitionAIService();
  final FlutterTts _flutterTts = FlutterTts();


  final List<ChatMessage> _messages = [];

  String? _standard;
  String? _subject;
  String? _chapter;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _startFreshConversation();
  }

   Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.1); // Higher pitch for female voice preference
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔁 RESET CHAT
  void _startFreshConversation() {
    setState(() {
      _messages.clear();
      _standard = null;
      _subject = null;
      _chapter = null;
      _loading = false;
    });
  }

  void _addBot(String text, {List<String>? options}) {
    _messages.add(ChatMessage(text: text, isUser: false, options: options));
    _scrollToBottom();
    _speak(text);
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
    if (input.length < 3 || input.length > 25) return false;
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

    // STEP 1: CLASS
    if (_standard == null) {
      if (!_isValidStandard(input)) {
        _addBot(
            "❌ Please tell me a valid class like Std 8, 9, 10, 11 or 12.",
            options: ['Std 8', 'Std 9', 'Std 10', 'Std 11', 'Std 12']);
        return;
      }
      _standard = input;
      _addBot("Great 👍 Now tell me your subject", options: [
        'Maths',
        'Science',
        'English',
        'Social Science',
        'Gujarati',
        'Account',
        'Stats',
        'Physics',
        'Chemistry',
        'Biology'
      ]);
      return;
    }

    // STEP 2: SUBJECT
    if (_subject == null) {
      if (!_isValidSubject(input)) {
        _addBot(
            "❌ Subject name looks invalid. Example: Science, Maths, Commerce",
            options: [
              'Maths',
              'Science',
              'English',
              'Social Science',
              'Gujarati',
              'Account',
              'Stats',
              'Physics',
              'Chemistry',
              'Biology'
            ]);
        return;
      }
      _subject = input;
      _addBot("Nice! Now tell me the chapter name");
      return;
    }

    // STEP 3: CHAPTER
    if (_chapter == null) {
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
      final result = await _aiService.fetchLectureVideo(
        standard: _standard!,
        subject: _subject!,
        chapter: _chapter!,
      );
      _addBot(result);
    } catch (e) {
      _addBot("⚠️ Sorry, I couldn’t find a video for this chapter.");
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
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
                                color: Colors.blue.shade100, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: const AssetImage(imgLoaderBot),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Hello Friend! I'm your DMAI Teacher",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          "Ask me anything about your studies",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
                   Text("Searching video...", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.1))),
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                    onPressed: _startFreshConversation,
                    tooltip: "Reset Chat",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                     // border: Border.all(color: Colors.grey.shade300),
                    ),
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
                                color: Colors.grey.shade400, fontSize: 14
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
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B5B98), // Matching deep blue
                    boxShadow: [
                      BoxShadow(
                        // color: const Color(0xFF3B5B98).withOpacity(0.3),
                        // blurRadius: 8,
                        // offset: const Offset(0, 4),
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
