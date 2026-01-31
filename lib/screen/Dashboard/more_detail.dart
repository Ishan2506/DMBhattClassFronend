import 'package:dm_bhatt_tutions/screen/Dashboard/student_product_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/settings_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/leaderboard_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/about_us_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/events_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _shareApp() {
    Share.share('Check out D. M. Bhatt Tuition Classes App! Download now: https://play.google.com/store/apps/details?id=com.dmbhatt.tutions');
  }

  void _showRateUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _RateUsDialog(),
    );
  }

  void _showFollowUsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Follow Us On",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialIcon(
                  context, 
                  icon: FontAwesomeIcons.facebook, 
                  color: const Color(0xFF1877F2), 
                  url: "https://www.facebook.com/dmbhatttutionclasses",
                  label: "Facebook"
                ),
                _buildSocialIcon(
                  context, 
                  icon: FontAwesomeIcons.instagram, 
                  color: const Color(0xFFE4405F), 
                  url: "https://www.instagram.com/dmbhatttutions",
                  label: "Instagram"
                ),
                _buildSocialIcon(
                  context, 
                  icon: FontAwesomeIcons.youtube, 
                  color: const Color(0xFFFF0000), 
                  url: "https://www.youtube.com/@dmbhatteducationchannel",
                  label: "YouTube"
                ),
                _buildSocialIcon(
                  context, 
                  icon: FontAwesomeIcons.whatsapp, 
                  color: const Color(0xFF25D366), 
                  url: "https://wa.me/919876543210",
                  label: "WhatsApp"
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _MoreScreenItem(
              title: "Events",
              value: "",
              icon: Icons.event,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                );
              },
            ),
             _MoreScreenItem(
              title: "About Us",
              value: "",
              icon: Icons.info_outline,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                );
              },
            ),

             // My Area Section
            _MoreScreenItem(
              title: "My Area",
              value: "",
              icon: Icons.person_pin,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const _MyAreaScreen()),
                );
              },
            ),

            // History Section
            _MoreScreenItem(
              title: "History",
              value: "",
              icon: Icons.history,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const _HistoryMenuScreen()),
                );
              },
            ),

            _MoreScreenItem(
              title: "Settings",
              value: "",
              icon: Icons.settings,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            
            // Share App
            _MoreScreenItem(
              title: "Share App",
              value: "",
              icon: Icons.share,
              onTap: _shareApp,
            ),

            // Rate Us
            _MoreScreenItem(
              title: "Rate Us",
              value: "",
              icon: Icons.star_rate_rounded, // Star Icon
              onTap: () => _showRateUsDialog(context),
            ),

             // Follow Us
            _MoreScreenItem(
              title: "Follow Us",
              value: "",
              icon: Icons.rss_feed_rounded, // or Icons.public
              onTap: () => _showFollowUsSheet(context),
            ),

            const SizedBox(height: 40),
            ],
          ),
       ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, {required IconData icon, required Color color, required String url, required String label}) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RateUsDialog extends StatefulWidget {
  @override
  State<_RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<_RateUsDialog> {
  int _selectedRating = -1;
  final TextEditingController _feedbackController = TextEditingController();

  final List<Map<String, dynamic>> _emojis = [
    {"icon": "😡", "label": "Terrible", "score": 1},
    {"icon": "🙁", "label": "Bad", "score": 2},
    {"icon": "😐", "label": "Okay", "score": 3},
    {"icon": "🙂", "label": "Good", "score": 4},
    {"icon": "😍", "label": "Great", "score": 5},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Using a custom styled dialog structure
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom Header
          Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 20),
             decoration: BoxDecoration(
               gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1565C0), // Deep Blue
                    const Color(0xFF42A5F5), // Lighter Blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
               ),
               borderRadius: const BorderRadius.only(
                 topLeft: Radius.circular(20),
                 topRight: Radius.circular(20),
               ),
             ),
             child: Column(
               children: [
                 const Icon(Icons.star_rounded, color: Colors.white, size: 48),
                 const SizedBox(height: 8),
                 Text(
                   "Rate Your Experience",
                   style: GoogleFonts.poppins(
                     fontWeight: FontWeight.bold, 
                     fontSize: 20,
                     color: Colors.white,
                   ),
                 ),
               ],
             ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                 Text(
                  "How do you feel about the app?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 24),
                
                // Emojis Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _emojis.map((e) {
                    final isSelected = _selectedRating == e['score'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = e['score'];
                        });
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Text(
                              e['icon'],
                              style: const TextStyle(fontSize: 32),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                // Selected Label Indicator
                if (_selectedRating != -1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _emojis[_selectedRating - 1]['label'],
                      style: GoogleFonts.poppins(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: colorScheme.primary
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                
                // Feedback Field
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Write your feedback here (optional)...",
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedRating != -1) {
                            CustomToast.showSuccess(context, "Thank you for your feedback!");
                            Navigator.pop(context);
                          } else {
                             CustomToast.showError(context, "Please select a rating.");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text("Submit", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyAreaScreen extends StatelessWidget {
  const _MyAreaScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Area",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
               _MoreScreenItem(
                title: "Leaderboard",
                value: "",
                icon: Icons.leaderboard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryMenuScreen extends StatelessWidget {
  const _HistoryMenuScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "History",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
               _MoreScreenItem(
                title: "Exam History",
                value: "",
                icon: Icons.history_edu,
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentExamHistoryScreen()),
                  );
                },
              ),
               _MoreScreenItem(
                title: "Product History",
                value: "",
                icon: Icons.shopping_bag,
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentProductHistoryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreScreenItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreScreenItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer, // Dynamic Card Color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface, // Dynamic Text
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
                Text(
                value,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant, // Dynamic Text
                    fontWeight: FontWeight.w500,
                ),
                ),
                const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
