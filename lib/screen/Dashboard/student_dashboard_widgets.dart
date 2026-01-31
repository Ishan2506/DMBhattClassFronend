import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AchieverModel {
  final String name;
  final String marks;
  final String subject;
  final String rank;
  final Color color;

  AchieverModel({
    required this.name,
    required this.marks,
    required this.subject,
    required this.rank,
    required this.color,
  });
}

class StudentAchieverSlider extends StatefulWidget {
  const StudentAchieverSlider({super.key});

  @override
  State<StudentAchieverSlider> createState() => _StudentAchieverSliderState();
}

class _StudentAchieverSliderState extends State<StudentAchieverSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Mock Data based on the user's image
  final List<AchieverModel> _achievers = [
    AchieverModel(name: "Hanshika M Dave", marks: "98/100", subject: "English", rank: "1st", color: Colors.blue.shade800),
    AchieverModel(name: "Ansh K Shah", marks: "97/100", subject: "English", rank: "2nd", color: Colors.red.shade800),
    AchieverModel(name: "Nency V Shah", marks: "96/100", subject: "English", rank: "3rd", color: Colors.teal.shade800),
    AchieverModel(name: "Dhruv P Chauhan", marks: "96/100", subject: "English", rank: "3rd", color: Colors.orange.shade800),
    AchieverModel(name: "Palak G Diyodra", marks: "94/100", subject: "English", rank: "4th", color: Colors.purple.shade800),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _achievers.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.01),
          child: Row(
            children: [
               Container(
                height: screenHeight * 0.025,
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Top Rankers",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color, // Adapted to theme
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: screenHeight * 0.18, // Reduced height (was 0.22)
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _achievers.length,
            itemBuilder: (context, index) {
              final achiever = _achievers[index];
              return _buildAchieverCard(context, achiever);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _achievers.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchieverCard(BuildContext context, AchieverModel achiever) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
      ),
      child: Stack(
        children: [
          // Background Decoration
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: screenWidth * 0.1, // Reduced decoration radius
              backgroundColor: achiever.color.withOpacity(0.1),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.015), // Reduced vertical padding
            child: Row(
              children: [
                // Avatar Placeholder
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: achiever.color, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: screenWidth * 0.08, // Reduced avatar radius
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: Icon(Icons.person, size: screenWidth * 0.08, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: achiever.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${achiever.subject} • ${achiever.rank}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: screenWidth * 0.022, // Slightly reduced font size
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Text(
                        achiever.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: achiever.marks,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.05, // Reduced font size
                                fontWeight: FontWeight.bold,
                                color: achiever.color,
                              ),
                            ),
                            TextSpan(
                              text: " Marks",
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.028, // Slightly reduced font size
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
          ),
        ],
      ),
    );
  }
}

class YouTubeChannelAd extends StatelessWidget {
  const YouTubeChannelAd({super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.youtube.com/@DMBhattClasses'); // Replace with actual URL if known
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchURL,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.red,
                    size: screenWidth * 0.08,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Watch & Learn!",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Subscribe to our Official YouTube Channel",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

