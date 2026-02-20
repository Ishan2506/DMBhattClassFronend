import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentUserId;
  String? userStandard;
  String? std;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      // Token managed internally


      // If std or userId is missing, fetch profile data
      if (std == null || userId == null) {
        try {
          final profileResponse = await ApiService.getProfile();
          if (profileResponse.statusCode == 200) {
            final profileData = jsonDecode(profileResponse.body);
            final user = profileData['user'];
            final profile = profileData['profile'];
            
            // Save userId and std for future use
            if (user != null && user['_id'] != null) {
              userId = user['_id'];
              await prefs.setString('userId', userId!);
            }
            if (profile != null && profile['std'] != null) {
              std = profile['std'];
              await prefs.setString('std', std!);
            }
          }
        } catch (e) {
          setState(() {
            errorMessage = 'Failed to load profile data';
            isLoading = false;
          });
          return;
        }
      }

      // Check again after fetching
      if (std == null) {
        setState(() {
          errorMessage = 'Please login again';
          isLoading = false;
        });
        return;
      }

      currentUserId = userId;
      userStandard = std;

      final response = await ApiService.getLeaderboard(
        std: std!,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            leaderboardData = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load leaderboard';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load leaderboard';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Leaderboard - Standard $userStandard",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const CustomLoader()
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaderboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : leaderboardData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.leaderboard_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No students in this standard yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Top 3 Container
                        if (leaderboardData.length >= 3)
                          Container(
                            padding: const EdgeInsets.only(
                              bottom: 24,
                              left: 16,
                              right: 16,
                              top: 20,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // 2nd Place
                                _buildTopRanker(
                                  context,
                                  leaderboardData[1],
                                  2,
                                  80,
                                  Colors.grey.shade300,
                                ),
                                // 1st Place (Center, larger)
                                _buildTopRanker(
                                  context,
                                  leaderboardData[0],
                                  1,
                                  100,
                                  Colors.amber,
                                ),
                                // 3rd Place
                                _buildTopRanker(
                                  context,
                                  leaderboardData[2],
                                  3,
                                  80,
                                  Colors.brown.shade300,
                                ),
                              ],
                            ),
                          ),

                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadLeaderboard,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: leaderboardData.length >= 3
                                  ? leaderboardData.length - 3
                                  : leaderboardData.length,
                              itemBuilder: (context, index) {
                                final item = leaderboardData.length >= 3
                                    ? leaderboardData[index + 3]
                                    : leaderboardData[index];
                                final isUser = item['_id'] == currentUserId;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.2)
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isUser
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.3),
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "${item['rank']}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        radius: 20,
                                        child: Text(
                                          (item['firstName'] ?? 'U')[0]
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'
                                              .trim(),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.stars,
                                              size: 16,
                                              color: Colors.amber.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${item['totalRewardPoints'] ?? 0}",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.amber.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      ],
                    ),
    );
  }

  Widget _buildTopRanker(
    BuildContext context,
    Map<String, dynamic> data,
    int rank,
    double size,
    Color color,
  ) {
    final firstName = data['firstName'] ?? 'Unknown';
    final points = data['totalRewardPoints'] ?? 0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: Colors.white,
                child: Text(
                  firstName[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            if (rank == 1)
              const Positioned(
                top: 0,
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 36,
                ),
              ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$rank",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(
          firstName.split(' ')[0], // First Name
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          "$points pts",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
