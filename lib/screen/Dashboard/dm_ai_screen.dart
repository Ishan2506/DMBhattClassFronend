// import 'package:dm_bhatt_tutions/model/chat_message.dart';
// import 'package:dm_bhatt_tutions/network/ai_service.dart';
// import 'package:dm_bhatt_tutions/widget/chat_bubble.dart';
// import 'package:flutter/material.dart';

// class DMAIChatScreen extends StatefulWidget {
//   const DMAIChatScreen({super.key});

//   @override
//   State<DMAIChatScreen> createState() => _DMAIChatScreenState();
// }

// class _DMAIChatScreenState extends State<DMAIChatScreen> {
//   final _controller = TextEditingController();
//   final _scrollController = ScrollController();
//   final _aiService = TuitionAIService();

//   final List<ChatMessage> _messages = [];

//   String? _standard;
//   String? _subject;
//   String? _chapter;

//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _addBot("👋 Hello friend! I'm your DMAI Teacher");
//     _addBot("Please tell me your class (Std 8–12)");
//   }
//   void _startFreshConversation() {
//     setState(() {
//       _messages.clear();
//       _standard = null;
//       _subject = null;
//       _chapter = null;
//       _loading = false;
//     });

//     _addBot("👋 Hello friend! I'm your DMAI Teacher");
//     _addBot("Please tell me your class (Std 8–12)");
//   }

//   void _addBot(String text) {
//     setState(() {
//       _messages.add(ChatMessage(text: text, isUser: false));
//     });
//   }

//   void _addUser(String text) {
//     setState(() {
//       _messages.add(ChatMessage(text: text, isUser: true));
//     });
//   }

//   Future<void> _handleSubmit() async {
//     final input = _controller.text.trim();
//     if (input.isEmpty) return;

//     _controller.clear();
//     _addUser(input);

//     if (_standard == null) {
//       _standard = input;
//       _addBot("Great 👍 Now tell me your subject");
//       return;
//     }

//     if (_subject == null) {
//       _subject = input;
//       _addBot("Nice! Now tell me the chapter");
//       return;
//     }

//     _chapter = input;

//     setState(() => _loading = true);
//     _addBot("Thinking... 🔍");

//     final result = await _aiService.fetchLectureVideo(
//       standard: _standard!,
//       subject: _subject!,
//       chapter: _chapter!,
//     );

//     setState(() => _loading = false);
//     _addBot(result);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16),
//               itemCount: _messages.length,
//               itemBuilder: (_, i) =>
//                   ChatBubble(message: _messages[i]),
//             ),
//           ),

//           if (_loading)
//             const Padding(
//               padding: EdgeInsets.all(8),
//               child: CircularProgressIndicator(),
//             ),

//           // Padding(
//           //   padding: const EdgeInsets.all(12),
//           //   child: Row(
//           //     children: [
//           //       Expanded(
//           //         child: TextField(
//           //           controller: _controller,
//           //           decoration: const InputDecoration(
//           //             hintText: "Type here...",
//           //             border: OutlineInputBorder(),
//           //           ),
//           //         ),
//           //       ),
//           //       const SizedBox(width: 8),
//           //       IconButton(
//           //         icon: const Icon(Icons.send),
//           //         onPressed: _handleSubmit,
//           //       ),
//           //     ],
//           //   ),
//           // )
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     style: TextStyle(
//                       color: Theme.of(context).textTheme.bodyLarge!.color,
//                     ),
//                     cursorColor: Theme.of(context).colorScheme.primary,
//                     decoration: InputDecoration(
//                       hintText: "Type your answer...",
//                       hintStyle: TextStyle(
//                         color: Theme.of(context).hintColor,
//                       ),
//                       filled: true,
//                       fillColor: Theme.of(context).cardColor,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 IconButton(
//                   icon: Icon(
//                     Icons.send,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   onPressed: _handleSubmit,
//                 ),
//               ],
//             ),
//           ),

//         ],
//       ),
//     );
//   }
// }

import 'package:dm_bhatt_tutions/model/chat_message.dart';
import 'package:dm_bhatt_tutions/network/ai_service.dart';
import 'package:dm_bhatt_tutions/widget/chat_bubble.dart';
import 'package:flutter/material.dart';

class DMAIChatScreen extends StatefulWidget {
  const DMAIChatScreen({super.key});

  @override
  State<DMAIChatScreen> createState() => _DMAIChatScreenState();
}

class _DMAIChatScreenState extends State<DMAIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = TuitionAIService();

  final List<ChatMessage> _messages = [];

  String? _standard;
  String? _subject;
  String? _chapter;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startFreshConversation();
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

    _addBot("👋 Hello friend! I'm your DMAI Teacher");
    _addBot("Please tell me your class (Std 8–12)");
  }

  void _addBot(String text) {
    _messages.add(ChatMessage(text: text, isUser: false));
    _scrollToBottom();
    setState(() {});
  }

  void _addUser(String text) {
    _messages.add(ChatMessage(text: text, isUser: true));
    _scrollToBottom();
    setState(() {});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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

  // Future<void> _handleSubmit() async {
  //   final input = _controller.text.trim();
  //   if (input.isEmpty) return;

  //   _controller.clear();
  //   _addUser(input);

  //   // STEP 1: CLASS
  //   if (_standard == null) {
  //     if (!_isValidStandard(input)) {
  //       _addBot(
  //           "❌ Please tell me a valid class like Std 8, 9, 10, 11 or 12.");
  //       return;
  //     }
  //     _standard = input;
  //     _addBot("Great 👍 Now tell me your subject");
  //     return;
  //   }

  //   // STEP 2: SUBJECT
  //   if (_subject == null) {
  //     _subject = input;
  //     _addBot("Nice! Now tell me the chapter name");
  //     return;
  //   }

  //   // STEP 3: CHAPTER
  //   _chapter = input;

  //   setState(() => _loading = true);
  //   _addBot("Thinking... 🔍");

  //   try {
  //     final result = await _aiService.fetchLectureVideo(
  //       standard: _standard!,
  //       subject: _subject!,
  //       chapter: _chapter!,
  //     );

  //     _addBot(result);
  //   } catch (e) {
  //     _addBot("⚠️ Sorry, I couldn’t find a video for this chapter.");
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }
  Future<void> _handleSubmit() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    _controller.clear();
    _addUser(input);

    // STEP 1: CLASS
    if (_standard == null) {
      if (!_isValidStandard(input)) {
        _addBot(
            "❌ Please tell me a valid class like Std 8, 9, 10, 11 or 12.");
        return;
      }
      _standard = input;
      _addBot("Great 👍 Now tell me your subject");
      return;
    }

    // STEP 2: SUBJECT
    if (_subject == null) {
      if (!_isValidSubject(input)) {
        _addBot(
            "❌ Subject name looks invalid. Example: Science, Maths, Commerce");
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
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Restart",
            onPressed: _startFreshConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) =>
                  ChatBubble(message: _messages[i]),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color,
                    ),
                    decoration: InputDecoration(
                      hintText: "Type here...",
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
