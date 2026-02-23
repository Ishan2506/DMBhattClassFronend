import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';

class DMAIScreen extends StatefulWidget {
  const DMAIScreen({super.key});

  @override
  State<DMAIScreen> createState() => _DMAIScreenState();
}

class _DMAIScreenState extends State<DMAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  
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
    _initTts();
    
    // Clear any potential leftover data (though being in initState, it starts empty anyway)
    _messages.clear();
    
    // Start the fresh session greeting
    _initializeChat();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.1); // Slightly higher pitch for female-like voice
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    final userStd = _authenticationCubit.state.formState.studentStandard;
    
    const welcomeMsg = "Hello! I am your AI Learning Assistant. I don't save our chat history, so every session is a fresh start.";
    _addBotMessage(welcomeMsg);
    
    if (userStd.isNotEmpty) {
      _addBotMessage("I see you are in $userStd. Here are your current units:");
    }
  }

  // --- BUILD QUICK ACTIONS CHIPS ---
  Widget _buildQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;
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
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500
                ),
              ),
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.primary, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _handleSubmitted(suggestions[index]);
                _speak("Searching for ${suggestions[index]}");
              },
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
        "title": "Search Education Channel",
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
    _speak(text); 
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Slightly off-white background
      
      body: Column(
        children: [
          // AI Avatar / Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    backgroundImage: const AssetImage(imgLoaderBot), // Using bot image as specified "AI"
                  ),
                ),
                const SizedBox(height: 8),
                
              ],
            ),
          ),

          // Chat area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8),
                      child: Row(
                        children: [
                           const CircleAvatar(
                            radius: 12,
                            backgroundImage: AssetImage(imgLoaderBot),
                          ),
                          const SizedBox(width: 8),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(20),
                             ),
                            child: Text("Thinking...", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                          ),
                        ],
                      ),
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
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.1))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ]
            ),
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Actions Toggle
                InkWell(
                  onTap: () => setState(() => _showQuickActions = !_showQuickActions),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.tips_and_updates, size: 16, color: Colors.amber.shade700),
                         const SizedBox(width: 6),
                        Text("Suggested Topics",
                            style: GoogleFonts.poppins(
                                color: colorScheme.primary, 
                                fontWeight: FontWeight.w600, 
                                fontSize: 13)),
                        const Spacer(),
                        Icon(_showQuickActions ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: colorScheme.primary.withOpacity(0.5), size: 18),
                      ],
                    ),
                  ),
                ),
                
                // Show standard-based chips
                if (_showQuickActions) _buildQuickActions(),

                // Text Input Field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: TextStyle(color: colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    hintText: "Type your question here...",
                                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onSubmitted: _handleSubmitted,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.mic, color: colorScheme.primary),
                                onPressed: () {
                                  // Mic functionality (could be added later)
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary, 
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: IconButton(
                          onPressed: () => _handleSubmitted(_messageController.text),
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message['sender'] == 'user';
    final isVideo = message['type'] == 'video';
    
    // Using simple blue theme for user, white/grey for bot
    final userBubbleColor = colorScheme.primary;
    final botBubbleColor = Colors.white;
    const userTextColor = Colors.white;
    final botTextColor = Colors.grey.shade800;

    if (isVideo) {
      final video = message['content'] as Map<String, String>;
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          margin: const EdgeInsets.only(bottom: 16, left: 40), // Indent for bot avatar alignment
          child: GestureDetector(
            onTap: () => _launchUrl(video['url']!),
            child: Container(
               decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120, // Placeholder for video thumbnail if available, or just a colored container
                    width: double.infinity,
                    color: Colors.blue.shade50,
                    child: Center(
                       child: Icon(Icons.play_circle_fill_rounded, color: Colors.red.shade400, size: 50),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(video['title']!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(video['description']!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Text Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(imgLoaderBot), // Bot Avatar
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : botBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
                boxShadow: [
                   if (!isUser) BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Text(
                message['content'],
                style: GoogleFonts.poppins(
                  color: isUser ? userTextColor : botTextColor, 
                  fontSize: 14,
                  height: 1.5
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
