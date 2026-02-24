import 'package:dm_bhatt_tutions/network/ai_service.dart';
import 'package:dm_bhatt_tutions/widget/chat_bubble.dart';
import 'package:dm_bhatt_tutions/model/chat_message.dart';
import 'package:flutter/material.dart';

class AIChatScreen extends StatefulWidget {
  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TuitionAIService _aiService = TuitionAIService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "👋 Hello friend! I'm your DMAI Teacher. I'm here to make learning fun and easy! Ask me things like:\n\n"
          "• 'Show me a video for Std 11 Account Ch 2'\n"
          "• 'Explain depreciation to me simply'\n"
          "• 'Help me with Balance Sheet format'",
      isUser: false,
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _isLoading) return;

    // Add user message
    _messages.add(ChatMessage(text: query, isUser: true));
    _controller.clear();
    _scrollToBottom();

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(text: "Let me think... 🤔", isUser: false));
    });
    _scrollToBottom();

    if (query.toLowerCase().contains('contact professor') || query.toLowerCase().contains('teacher number')) {
      setState(() {
        _isLoading = false;
        _messages.removeWhere((msg) => msg.text == "Let me think... 🤔");
        _messages.add(ChatMessage(text: "Sure! Here are the contact details for our professors. You can chat with them directly on WhatsApp:", isUser: false));
        _messages.add(ChatMessage(text: "English Professor", isUser: false, contact: {"name": "Prof. English", "number": "98251 89540"}));
        _messages.add(ChatMessage(text: "Science Professor", isUser: false, contact: {"name": "Prof. Science", "number": "90332 39340"}));
        _messages.add(ChatMessage(text: "Maths Professor", isUser: false, contact: {"name": "Prof. Maths", "number": "78783 21090"}));
        _messages.add(ChatMessage(text: "How else can I help you?", isUser: false));
      });
      _scrollToBottom();
      return;
    }

    // Existing AI logic (mocked)
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg.text == "Let me think... 🤔");
          
          String responseText = "I'm still learning about your specific query! For now, I can help you find videos for your subjects.";
          Map<String, String>? subjectContact;

          if (query.toLowerCase().contains('math')) {
            subjectContact = {"name": "Prof. Maths", "number": "78783 21090"};
          } else if (query.toLowerCase().contains('science') || query.toLowerCase().contains('physics') || query.toLowerCase().contains('chemistry')) {
            subjectContact = {"name": "Prof. Science", "number": "90332 39340"};
          } else if (query.toLowerCase().contains('english')) {
            subjectContact = {"name": "Prof. English", "number": "98251 89540"};
          }

          _messages.add(ChatMessage(text: responseText, isUser: false));
          
          if (subjectContact != null) {
            _messages.add(ChatMessage(
              text: "If you have more doubts in this subject, you can contact our professor:",
              isUser: false,
              contact: subjectContact
            ));
          }
          
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _sendTestQuery(String testQuery) {
    _controller.text = testQuery;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      // AppBar removed as requested
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) => ChatBubble(
                message: _messages[index],
                onOptionSelected: (option) {
                  _controller.text = option;
                  _sendMessage();
                },
              ),
            ),
          ),
          
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                   CircleAvatar(
                     radius: 16,
                     backgroundImage: AssetImage('assets/images/dmai_helper_lady.png'),
                     backgroundColor: Colors.white,
                   ),
                   SizedBox(width: 10),
                   Container(
                     padding: EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         SizedBox(
                           width: 16,
                           height: 16,
                           child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5C6BC0)),
                         ),
                         SizedBox(width: 10),
                         Text("Thinking...", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                       ],
                     ),
                   )
                ],
              ),
            ),

          // Suggestions Area & Refresh Button
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            color: Colors.transparent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   // Refresh Button moved here
                   Padding(
                     padding: EdgeInsets.only(right: 8),
                     child: IconButton(
                       icon: Icon(Icons.refresh_rounded, color: Color(0xFF5C6BC0)),
                       onPressed: () {
                          setState(() => _messages.clear());
                          _addWelcomeMessage();
                       },
                       tooltip: "Restart Chat",
                       style: IconButton.styleFrom(
                         backgroundColor: Colors.white,
                         padding: EdgeInsets.all(8),
                       ),
                     ),
                   ),
                  _buildTestButton("📺 Std 11 Account Ch2"),
                  _buildTestButton("📝 Balance sheet"),
                ],
              ),
            ),
          ),

          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildTestButton(String testQuery) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => _sendTestQuery(testQuery.replaceAll(RegExp(r'[^\w\s\d]'), '').trim()), // Clean query for button action if needed, or send as is
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF5C6BC0),
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          side: BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
        ),
        child: Text(testQuery, style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildInputField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), 
            blurRadius: 10, 
            offset: Offset(0, -5)
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Ask me anything...",
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                filled: true,
                fillColor: isDark ? Color(0xFF2C2C2C) : Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          SizedBox(width: 12),
          Material(
            color: Color(0xFF5C6BC0),
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                child: _isLoading 
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
