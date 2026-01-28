// lib/network/ai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class TuitionAIService {
  final String _geminiKey = 'AIzaSyAGh3ga2KcJBK-8dZLjO-39wgAdI2i7L9E';
  final String _youtubeKey = 'AIzaSyBxCUknZpAeSAzBCtUcYAkHUp8lnToSM0I';
  final String _channelHandle = '@dmbhatteducationchannel';
  String? _channelId;

  late final GenerativeModel _model;

  TuitionAIService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _geminiKey,
      // ✅ FIXED: Use Content.system() for system instruction
      generationConfig: GenerationConfig(
        // Optional: Control response format
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<String> processStudentQuery(String query) async {
    try {
      final classification = await _classifyQuery(query);
      
      if (classification['type'] == 'offtopic') {
        return "❌ Sorry! Only Std 10-12 study questions and videos supported.";
      }

      if (classification['type'] == 'video') {
        _channelId ??= await _getChannelId();
        final videoLink = await _searchYouTubeVideo(
          classification['keywords'], 
          _channelId!
        );
        return videoLink;
      }

      return classification['answer'] ?? "Study answer unavailable.";
      
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return "⚠️ Service temporarily unavailable. Please try again.";
    }
  }

  Future<Map<String, dynamic>> _classifyQuery(String query) async {
    // ✅ CORRECT SYNTAX: Content.text()
    final content = [
      Content.text('''
      Analyze this student query and respond with VALID JSON only:
      
      Query: "$query"
      
      Return exactly this JSON format:
      {
        "type": "video" (if wants video/lecture/chapter), 
        "type": "study" (if asking study question), 
        "type": "offtopic" (movies/sports/news),
        "keywords": "3-5 YouTube search keywords for tuition videos",
        "answer": "direct study answer only if type=study, otherwise null"
      }
      
      Study topics only: Std 10-12 Commerce/Science/Arts subjects.
      '''), 
    ];
    
    final response = await _model.generateContent(content);
    final jsonStr = response.text!.trim();
    
    try {
      return jsonDecode(jsonStr);
    } catch (e) {
      // Fallback: Treat as study question
      return {
        'type': 'study', 
        'keywords': query,
        'answer': response.text ?? 'No answer generated'
      };
    }
  }

  Future<String> _getChannelId() async {
    if (_channelId != null) return _channelId!;
    
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/channels?forHandle=$_channelHandle&key=$_youtubeKey&part=id'
    );
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['items'] != null && data['items'].isNotEmpty) {
        _channelId = data['items'][0]['id'];
        return _channelId!;
      }
    }
    throw Exception('Channel @dmbhatteducationchannel not found');
  }

  Future<String> _searchYouTubeVideo(String keywords, String channelId) async {
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?'
      'part=snippet&q=${Uri.encodeComponent(keywords)}&'
      'channelId=$channelId&maxResults=1&type=video&key=$_youtubeKey'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['items'] != null && data['items'].isNotEmpty) {
        final videoId = data['items'][0]['id']['videoId'];
        return "📺 **Found your video!**\nhttps://www.youtube.com/watch?v=$videoId";
      }
    }
    
    return "🔍 No video found for '$keywords' in tuition channel.";
  }
}
