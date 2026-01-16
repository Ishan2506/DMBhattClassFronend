import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DMAIScreen extends StatefulWidget {
  const DMAIScreen({super.key});

  @override
  State<DMAIScreen> createState() => _DMAIScreenState();
}

class _DMAIScreenState extends State<DMAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // This list is local. It resets to empty every time the screen is opened.
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  late AuthenticationCubit _authenticationCubit;
  bool _showQuickActions = true;

  // Updated Mock Database with your specific naming style
  final List<Map<String, String>> _videoDatabase = [
    {
      "title": "std 10th English unit 1",
      "description": "Chapter 1 explanation for 10th English medium.",
      "url": "https://www.youtube.com/@dmbhatteducationchannel/search?query=10th+english+unit+1",
      "std": "10th"
    },
    {
      "title": "std 10th Gujarati unit 1",
      "description": "Chapter 1 explanation for 10th Gujarati medium.",
      "url": "https://www.youtube.com/@dmbhatteducationchannel/search?query=10th+gujarati+unit+1",
      "std": "10th"
    },
    {
      "title": "std 9th Maths unit 1",
      "description": "Number systems detailed explanation for class 9.",
      "url": "https://www.youtube.com/@dmbhatteducationchannel/search?query=9th+maths+unit+1",
      "std": "9th"
    },
    {
      "title": "std 12th Physics unit 1",
      "description": "Electrostatics part 1 for class 12 Science.",
      "url": "https://www.youtube.com/@dmbhatteducationchannel/search?query=12th+physics+unit+1",
      "std": "12th Sci"
    },
  ];

  @override
  void initState() {
    super.initState();
    _authenticationCubit = BlocProvider.of<AuthenticationCubit>(context);
    
    // Clear any potential leftover data (though being in initState, it starts empty anyway)
    _messages.clear();
    
    // Start the fresh session greeting
    _initializeChat();
  }

  void _initializeChat() {
    final userStd = _authenticationCubit.state.formState.studentStandard;
    
    _addBotMessage("Hello! I am your DM AI Assistant. I don't save our chat history, so every session is a fresh start.");
    
    if (userStd.isNotEmpty) {
      _addBotMessage("I see you are in $userStd. Here are your current units:");
    }
  }

  // --- BUILD QUICK ACTIONS CHIPS ---
  Widget _buildQuickActions() {
    final userStd = _authenticationCubit.state.formState.studentStandard;
    
    // Get videos matching the student's current standard
    final List<String> suggestions = _videoDatabase
        .where((v) => v['std'] == userStd)
        .map((v) => v['title']!)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestions[index],
                style: GoogleFonts.poppins(
                  fontSize: 12, 
                  color: const Color(0xFF4C53A5),
                  fontWeight: FontWeight.w500
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF4C53A5), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _handleSubmitted(suggestions[index]),
            ),
          );
        },
      ),
    );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _addUserMessage(text);
    _messageController.clear();
    
    setState(() {
      _isTyping = true;
      _showQuickActions = false; // Hide chips after selection to clean UI
    });

    // Simulated AI response delay
    await Future.delayed(const Duration(seconds: 1));

    final query = text.toLowerCase();
    final results = _videoDatabase.where((video) {
      return video['title']!.toLowerCase().contains(query);
    }).toList();

    setState(() => _isTyping = false);

    if (results.isNotEmpty) {
      _addBotMessage("I found these videos for you:");
      for (var video in results) {
        _addVideoMessage(video);
      }
    } else {
      _addBotMessage("I couldn't find a direct link for '$text'. Try searching the full channel below:");
      _addVideoMessage({
        "title": "Search DM Bhatt Education",
        "description": "Search for '$text' on YouTube",
        "url": "https://www.youtube.com/@dmbhatteducationchannel/search?query=${Uri.encodeComponent(text)}",
        "std": "General"
      });
    }
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add({"sender": "user", "type": "text", "content": text}));
    _scrollToBottom();
  }

  void _addBotMessage(String text) {
    setState(() => _messages.add({"sender": "bot", "type": "text", "content": text}));
    _scrollToBottom();
  }

  void _addVideoMessage(Map<String, String> video) {
    setState(() => _messages.add({"sender": "bot", "type": "video", "content": video}));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Chat area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, top: 8),
                      child: Text("Typing...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  );
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Bottom controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Actions Toggle
                InkWell(
                  onTap: () => setState(() => _showQuickActions = !_showQuickActions),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("View quick actions",
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF4C53A5), 
                                fontWeight: FontWeight.w600, 
                                fontSize: 13)),
                        Icon(_showQuickActions ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: const Color(0xFF4C53A5), size: 18),
                      ],
                    ),
                  ),
                ),
                
                // Show standard-based chips
                if (_showQuickActions) _buildQuickActions(),

                // Text Input Field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: "Type a message...",
                                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  onSubmitted: _handleSubmitted,
                                ),
                              ),
                              const Icon(Icons.mic, color: Colors.grey),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _handleSubmitted(_messageController.text),
                        child: const Icon(Icons.send, color: Color(0xFF4C53A5), size: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final isVideo = message['type'] == 'video';

    if (isVideo) {
      final video = message['content'] as Map<String, String>;
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: const Color(0xFFF5F5F5),
            child: ListTile(
              onTap: () => _launchUrl(video['url']!),
              leading: const Icon(Icons.play_circle_fill, color: Colors.red, size: 36),
              title: Text(video['title']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(video['description']!, style: GoogleFonts.poppins(fontSize: 11)),
              trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF4C53A5) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          message['content'],
          style: GoogleFonts.poppins(
            color: isUser ? Colors.white : Colors.black87, 
            fontSize: 14,
            height: 1.4
          ),
        ),
      ),
    );
  }
}