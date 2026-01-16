import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StudentVideoScreen extends StatefulWidget {
  const StudentVideoScreen({super.key});

  @override
  State<StudentVideoScreen> createState() => _StudentVideoScreenState();
}

class _StudentVideoScreenState extends State<StudentVideoScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isWebViewSupported = false;
  
  // Base channel URL
  final String _baseChannelUrl = 'https://www.youtube.com/@dmbhatteducationchannel';
  
  // Current active URL
  String _currentUrl = 'https://www.youtube.com/@dmbhatteducationchannel';
  String _selectedSubject = "All";

  // Subject List with specific search queries
  final List<Map<String, dynamic>> _subjects = [
    {"name": "All", "query": "", "color": Colors.red},
    {"name": "English", "query": "Std 10 English", "color": Colors.blue},
    {"name": "Gujarati", "query": "Std 10 Gujarati", "color": Colors.orange},
    {"name": "Maths", "query": "Std 10 Maths", "color": Colors.green},
    {"name": "Science", "query": "Std 10 Science", "color": Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _isWebViewSupported = true;
      _initController();
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  // Logic to filter YouTube videos by subject
  void _onSubjectTap(Map<String, dynamic> subject) {
    setState(() {
      _selectedSubject = subject['name'];
      if (subject['name'] == "All") {
        _currentUrl = _baseChannelUrl;
      } else {
        // This creates a URL that searches within that specific channel
        _currentUrl = "$_baseChannelUrl/search?query=${Uri.encodeComponent(subject['query'])}";
      }
    });

    if (_controller != null) {
      _controller!.loadRequest(Uri.parse(_currentUrl));
    } else {
      _launchURL(_currentUrl);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("DM Bhatt Education", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. SUBJECT CIRCLES (Like YouTube Topics)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final sub = _subjects[index];
                bool isSelected = _selectedSubject == sub['name'];
                
                return GestureDetector(
                  onTap: () => _onSubjectTap(sub),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected ? sub['color'] : Colors.grey.shade200,
                          child: Text(
                            sub['name'][0], // Show first letter
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          sub['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? sub['color'] : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 2. VIDEO WEBVIEW AREA
          Expanded(
            child: Stack(
              children: [
                if (_isWebViewSupported && _controller != null)
                  WebViewWidget(controller: _controller!)
                else
                  _buildFallbackUI(),
                if (_isLoading && _isWebViewSupported)
                  const Center(child: CircularProgressIndicator(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library_outlined, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            "Viewing: $_selectedSubject",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "WebView is for Mobile.\nPlease open the channel in your browser.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _launchURL(_currentUrl),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Open in YouTube App", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}