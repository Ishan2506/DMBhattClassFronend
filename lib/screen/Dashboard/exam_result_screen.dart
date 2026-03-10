import 'dart:typed_data';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExamResultScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> selectedAnswers;
  final String? subject;
  final String? unit;

  const ExamResultScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.questions,
    required this.selectedAnswers,
    this.subject,
    this.unit,
  });

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    
    // Load custom font if needed, or use standard fonts
    // For simplicity using standard fonts first, can upgrade to custom if needed
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: fontBold,
          ),
          buildForeground: (context) {
            return pw.Center(
              child: pw.Transform.rotate(
                angle: -0.5,
                child: pw.Text(
                  "DMBhatt",
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 100,
                    color: PdfColors.grey200,
                  ),
                ),
              ),
            );
          },
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Result Summary", style: pw.TextStyle(font: fontBold, fontSize: 24)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "${unit ?? 'Unit Test'} , ${subject ?? 'Subject'}",
                        style: pw.TextStyle(font: font, fontSize: 16, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("DMBhatt Tuitions", style: pw.TextStyle(font: fontBold, fontSize: 14)),
                      pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}", style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Score Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStat("Total", "$totalQuestions", fontBold),
                  _buildPdfStat("Correct", "$correctAnswers", fontBold, color: PdfColors.green),
                  _buildPdfStat("Wrong", "$wrongAnswers", fontBold, color: PdfColors.red),
                  _buildPdfStat("Skipped", "$skippedAnswers", fontBold, color: PdfColors.orange),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Questions
            ...List.generate(questions.length, (index) {
              final question = questions[index];
              final userAns = selectedAnswers[index];
              final optionsRaw = question['optionsRaw'] as List? ?? [];
              final correctKey = question['correctAnswerKey'] ?? question['correctAnswer'];
              
              String resolvedCorrectText = "";
              try {
                final correctOption = optionsRaw.firstWhere((o) => o['key'] == correctKey);
                resolvedCorrectText = correctOption['text']?.toString() ?? "";
              } catch (e) {
                resolvedCorrectText = question['correctAnswer']?.toString() ?? "";
              }

              final isCorrect = userAns?.trim().toLowerCase() == resolvedCorrectText.trim().toLowerCase();
              final isSkipped = userAns == null || userAns.trim().isEmpty;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                     pw.Text(
                       "Q${index + 1}: ${question['question'] ?? ''}",
                       style: pw.TextStyle(font: fontBold, fontSize: 12),
                     ),
                     pw.SizedBox(height: 4),
                     pw.Text(
                       "Your Answer: ${userAns ?? 'Skipped'}",
                       style: pw.TextStyle(
                         font: font, 
                         fontSize: 10,
                         color: isCorrect ? PdfColors.green : (isSkipped ? PdfColors.orange : PdfColors.red),
                       ),
                     ),
                     if (!isCorrect)
                       pw.Text(
                         "Correct Answer: $resolvedCorrectText",
                         style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.green),
                       ),
                     pw.Divider(color: PdfColors.grey200),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'DMBhatt_Result_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
  
  pw.Widget _buildPdfStat(String label, String value, pw.Font font, {PdfColor color = PdfColors.black}) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 18, color: color)),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reward Logic: 1 reward point for every 10 marks
    final int rewardPoints = correctAnswers ~/ 10;
    final bool hasReward = rewardPoints > 0;
    
    // Theme Colors
    final theme = Theme.of(context);
    final gradientColors = [
      theme.colorScheme.primary,
      theme.colorScheme.primary.withOpacity(0.8),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Softer background
      appBar: CustomAppBar(
        title: "Exam Result",
        automaticallyImplyLeading: false, // Prevent going back to exam
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const LandingScreen()),
                (route) => false,
              );
            },
          ),
        ],
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
                      color: theme.colorScheme.primary.withOpacity(0.3),
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
                          color: theme.colorScheme.onPrimary.withOpacity(0.2),
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
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
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
                  Expanded(child: _buildStatCard(context, "Correct", "$correctAnswers", Colors.green.shade500, Icons.check_circle_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, "Wrong", "$wrongAnswers", Colors.red.shade400, Icons.cancel_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, "Skipped", "$skippedAnswers", Colors.orange.shade400, Icons.help_outline)),
                ],
              ),

              blankVerticalSpace32,

              // 3. Exam Summary Header
              Row(
                children: [
                  Container(
                    width: 4, 
                    height: 24, 
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Exam Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
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
                  final optionsRaw = question['optionsRaw'] as List? ?? [];
                  final correctKey = question['correctAnswerKey'] ?? question['correctAnswer'];

                  String resolvedCorrectText = "";
                  try {
                    final correctOption = optionsRaw.firstWhere((o) => o['key'] == correctKey);
                    resolvedCorrectText = correctOption['text']?.toString() ?? "";
                  } catch (e) {
                    resolvedCorrectText = question['correctAnswer']?.toString() ?? "";
                  }

                  final isCorrect = userAns?.trim().toLowerCase() == resolvedCorrectText.trim().toLowerCase();
                  final isSkipped = userAns == null || userAns.trim().isEmpty;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
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
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                                ),
                                child: Text(
                                  "1 Mark",
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
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
                                question['question'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500, 
                                  color: theme.colorScheme.onSurface
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Answers Section
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isSkipped)
                                      _buildAnswerRow(context, "Your Answer", userAns!, isCorrect ? Colors.green : Colors.red),
                                    
                                    if (!isCorrect) ...[
                                      if (!isSkipped) const SizedBox(height: 8),
                                      _buildAnswerRow(context, "Correct Answer", resolvedCorrectText, Colors.green),
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
                  _generatePdf(context);
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
                    color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildAnswerRow(BuildContext context, String label, String text, Color color) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildStatCard(BuildContext context, String title, String count, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
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
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
