import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, dynamic>> leaderboardData = [
      {'name': 'Aarav Patel', 'points': 1250, 'rank': 1},
      {'name': 'Priya Sharma', 'points': 1180, 'rank': 2},
      {'name': 'Rohan Mehta', 'points': 1150, 'rank': 3},
      {'name': 'Devarsh Shah', 'points': 1050, 'rank': 4}, // User
      {'name': 'Sita Verma', 'points': 980, 'rank': 5},
      {'name': 'Vikram Singh', 'points': 950, 'rank': 6},
      {'name': 'Neha Gupta', 'points': 920, 'rank': 7},
      {'name': 'Arjun Kumar', 'points': 890, 'rank': 8},
      {'name': 'Sneha Reddy', 'points': 850, 'rank': 9},
      {'name': 'Rahul Joshi', 'points': 800, 'rank': 10},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text("Leaderboard", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
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
      body: Column(
        children: [
          // Top 3 Container
          Container(
             padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 20),
             decoration: BoxDecoration(
               gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
               borderRadius: const BorderRadius.only(
                 bottomLeft: Radius.circular(30),
                 bottomRight: Radius.circular(30),
               )
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 // 2nd Place
                 _buildTopRanker(leaderboardData[1], 2, 80, Colors.grey.shade300),
                 // 1st Place (Center, larger)
                 _buildTopRanker(leaderboardData[0], 1, 100, Colors.amber),
                 // 3rd Place
                 _buildTopRanker(leaderboardData[2], 3, 80, Colors.brown.shade300),
               ],
             ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboardData.length - 3,
              itemBuilder: (context, index) {
                final item = leaderboardData[index + 3]; // Start from 4th
                final isUser = item['name'] == 'Devarsh Shah'; // Highlight User

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isUser ? Border.all(color: Colors.blue.shade200) : null,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
                    ]
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${item['rank']}",
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.grey.shade600
                        ),
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 20,
                        child: Text(
                          item['name'][0],
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['name'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.stars, size: 16, color: Colors.amber.shade700),
                             const SizedBox(width: 4),
                             Text(
                               "${item['points']}",
                               style: GoogleFonts.poppins(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 13,
                                 color: Colors.amber.shade800
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
          )
        ],
      ),
    );
  }

  Widget _buildTopRanker(Map<String, dynamic> data, int rank, double size, Color color) {
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
                     BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
               child: CircleAvatar(
                 radius: size / 2,
                 backgroundColor: Colors.white,
                 child: Text(
                    data['name'][0],
                    style: GoogleFonts.poppins(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                 ),
               ),
             ),
             if (rank == 1)
               const Positioned(
                 top: 0,
                 child: Icon(Icons.workspace_premium, color: Colors.amber, size: 36),
               ),
              Positioned(
                 bottom: 0,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                   decoration: BoxDecoration(
                     color: color,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Text(
                     "$rank",
                     style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                   ),
                 ),
               )
           ],
         ),
         const SizedBox(height: 8),
         Text(
           data['name'].split(' ')[0], // First Name
           style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
         ),
         Text(
           "${data['points']} pts",
           style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
         ),
      ],
    );
  }
}
