import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  final Function(String)? onOptionSelected;

  const ChatBubble({
    super.key, 
    required this.message,
    this.onOptionSelected,
  });

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);

    // ✅ Use external application modeR
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final text = message.text;

    // ✅ detect URLs
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlRegex.firstMatch(text);

    final bubbleColor = isUser ? scheme.primary : scheme.surfaceContainer;
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: match != null && !isUser
                ? InkWell(
                    onTap: () => _openLink(match.group(0)!),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.replaceAll(match.group(0)!, '').trim(),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          match.group(0)!,
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(color: textColor),
                  ),
          ),
            if (message.options != null && message.options!.isNotEmpty && !isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.options!.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: ActionChip(
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: scheme.primary, 
                            width: 1.5
                          ),
                        ),
                        label: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700, // Bold text
                            color: scheme.primary,
                          ),
                        ),
                        onPressed: () {
                          if (onOptionSelected != null) {
                            onOptionSelected!(option);
                          }
                        },
                        backgroundColor: scheme.surfaceContainer,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 🎥 VIDEO LIST
          if (message.videos != null && message.videos!.isNotEmpty)
            Container(
              height: 160,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.videos!.length,
                itemBuilder: (context, index) {
                  final video = message.videos![index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _openLink(video['url']!),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              video['thumbnail']!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 100,
                                color: scheme.surfaceContainerHighest,
                                child: const Icon(Icons.video_library),
                              ),
                            ),
                          ),
                          // Title
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              video['title']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
