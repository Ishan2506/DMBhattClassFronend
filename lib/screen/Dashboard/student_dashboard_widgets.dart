import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/explore_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/leaderboard_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mind_games_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mind_map_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickAccessCategories extends StatelessWidget {
  const QuickAccessCategories({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {
      "title": "Material",
      "icon": Icons.import_contacts_rounded,
      "color": Color(0xFF4A90E2),
      "screen": ExploreScreen(),
    },
    {
      "title": "Mind Games",
      "icon": Icons.extension_rounded,
      "color": Color(0xFF50E3C2),
      "screen": MindGamesScreen(),
    },
    {
      "title": "Mind Maps",
      "icon": Icons.hub_rounded,
      "color": Color(0xFFBD10E0),
      "screen": MindMapSelectionScreen(),
    },
    {
      "title": "Leaderboard",
      "icon": Icons.leaderboard_rounded,
      "color": Color(0xFFF5A623),
      "screen": LeaderboardScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories.map((cat) => _buildCategoryItem(context, cat)).toList(),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Map<String, dynamic> cat) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate a dynamic size based on screen width to ensure 4 icons fit comfortably
    final double iconSize = screenWidth * 0.16; // Approx 60-70px on most phones
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => cat['screen']),
        );
      },
      child: SizedBox(
        width: screenWidth * 0.22, // Ensure equal spacing for 4 items
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: iconSize,
              width: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    cat['color'],
                    cat['color'].withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cat['color'].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(-2, -2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: Icon(
                cat['icon'],
                color: Colors.white,
                size: iconSize * 0.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat['title'],
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}



class YouTubeChannelAd extends StatelessWidget {
  const YouTubeChannelAd({super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.youtube.com/@DMBhattSir'); // Replace with actual URL if known
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
