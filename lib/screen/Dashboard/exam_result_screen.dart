import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamResultScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> selectedAnswers;

  const ExamResultScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    // Reward Logic: 5 points if full marks
    final int rewardPoints = (correctAnswers == totalQuestions) ? 5 : 0;
    final bool hasReward = rewardPoints > 0;
    
    // Theme Colors
    final gradientColors = [Colors.blue.shade900, Colors.blue.shade700];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Softer background
      appBar: const CustomAppBar(
        title: "Exam Result",
        automaticallyImplyLeading: false, // Prevent going back to exam
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: P.all16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Score Card - The "Wow" element
              Container(
                padding: P.all24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24), // More rounded
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (correctAnswers > totalQuestions / 2)
                      const Text("🎉", style: TextStyle(fontSize: 40)),
                    Text(
                      correctAnswers > totalQuestions / 2 ? "Excellent Job!" : "Keep Practicing!",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasReward) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "+$rewardPoints Reward Points Earned",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$correctAnswers",
                          style: GoogleFonts.poppins(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 4),
                          child: Text(
                            "/ $totalQuestions",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Your Score",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue.shade100,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              blankVerticalSpace24,

              // 2. Stats Grid - Clean Cards
              Row(
                children: [
                  Expanded(child: _buildStatCard("Correct", "$correctAnswers", Colors.green.shade500, Icons.check_circle_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Wrong", "$wrongAnswers", Colors.red.shade400, Icons.cancel_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Skipped", "$skippedAnswers", Colors.orange.shade400, Icons.help_outline)),
                ],
              ),

              blankVerticalSpace32,

              // 3. Exam Summary Header
              Row(
                children: [
                  Container(
                    width: 4, 
                    height: 24, 
                    decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Exam Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              blankVerticalSpace16,

              // 4. Questions List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final userAns = selectedAnswers[index];
                  final correctAns = question['correctAnswer'];
                  final isCorrect = userAns == correctAns;
                  final isSkipped = userAns == null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green.withOpacity(0.1) : (isSkipped ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isCorrect ? Colors.green : (isSkipped ? Colors.orange : Colors.red),
                                    child: Icon(
                                      isCorrect ? Icons.check : (isSkipped ? Icons.priority_high : Icons.close),
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Question ${index + 1}",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  "1 Mark",
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question['question'],
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500, 
                                  color: Colors.black87
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Answers Section
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isSkipped)
                                      _buildAnswerRow("Your Answer", userAns!, isCorrect ? Colors.green : Colors.red),
                                    
                                    if (!isCorrect) ...[
                                      if (!isSkipped) const SizedBox(height: 8),
                                      _buildAnswerRow("Correct Answer", correctAns, Colors.green),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              blankVerticalSpace24,

              // 5. Download Button & Home
              CustomFilledButton(
                label: "Download Question Paper",
                icon: Icons.download_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Downloading PDF...")),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LandingScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  "Back to Dashboard",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              blankVerticalSpace24,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerRow(String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
