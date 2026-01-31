import 'package:dm_bhatt_tutions/network/ai_service.dart';
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

    try {
      final response = await _aiService.processStudentQuery(query);
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg.text == "Let me think... 🤔");
          _messages.add(ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg.text == "Let me think... 🤔");
          _messages.add(ChatMessage(
            text: "Oops! I ran into a little problem: ${e.toString()}",
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
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
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
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
                  _buildTestButton("❓ How to study?"),
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/dmai_helper_lady.png'),
              backgroundColor: Colors.white,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isUser 
                    ? Color(0xFF5C6BC0) 
                    : (isDark ? Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isUser ? Radius.circular(20) : Radius.circular(5),
                  bottomRight: isUser ? Radius.circular(5) : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser 
                      ? Colors.white 
                      : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (isUser) ...[
             SizedBox(width: 8),
             CircleAvatar(
               radius: 16,
               backgroundColor: Colors.transparent, // Transparent to let image show fully if needed
               backgroundImage: AssetImage('assets/images/user_placeholder.png'),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24), // Extra padding at bottom for iOS home bar etc
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

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
