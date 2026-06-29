import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/pdf_preview_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExamResultScreen extends StatefulWidget {
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

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  bool _isLoading = false;

  Future<Uint8List> _generatePdfBytes() async {
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
        ),
        build: (pw.Context context) {
          final String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
          final double accuracy = widget.totalQuestions > 0 ? (widget.correctAnswers / widget.totalQuestions) * 100 : 0;

          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Padhaku", style: pw.TextStyle(font: fontBold, fontSize: 18)),
                  pw.Text("Date: $formattedDate", style: pw.TextStyle(font: font)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(widget.unit ?? 'Unit Test', style: pw.TextStyle(font: fontBold, fontSize: 24)),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    "Marks Obtained: ${widget.correctAnswers}/${widget.totalQuestions}",
                    style: pw.TextStyle(font: font, fontSize: 16),
                  ),
                  pw.Text(
                    "Accuracy: ${accuracy.toStringAsFixed(1)}%",
                    style: pw.TextStyle(font: font, fontSize: 14, color: accuracy >= 70 ? PdfColors.green : PdfColors.orange),
                  ),
                ],
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text("Questions:", style: pw.TextStyle(font: fontBold, fontSize: 18)),
            pw.SizedBox(height: 10),
            ...List.generate(widget.questions.length, (index) {
              final question = widget.questions[index];
              final userAns = widget.selectedAnswers[index];
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
              final yourAnswer = isSkipped ? 'Skipped' : userAns;

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _buildResultItem(index + 1, question['question']?.toString() ?? '', yourAnswer, resolvedCorrectText, isCorrect, isSkipped, font, fontBold),
              );
            }),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  Future<void> _previewPdf() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await _generatePdfBytes();
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            product: {
              'name': '${widget.unit ?? 'Unit Test'} - ${widget.subject ?? 'Question Paper'}',
            },
            isFullAccess: true,
            pdfBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating preview: $e')),
        );
      }
    }
  }
  
  pw.Widget _buildResultItem(int number, String question, String yourAnswer, String correctAnswer, bool isCorrect, bool isSkipped, pw.Font font, pw.Font fontBold) {
    final PdfColor statusColor = isCorrect ? PdfColors.green : (isSkipped ? PdfColors.orange : PdfColors.red);
    final String statusText = isCorrect ? "CORRECT" : (isSkipped ? "SKIPPED" : "WRONG");
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$number. ", style: pw.TextStyle(font: fontBold)),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(question, style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text("Your Answer: $yourAnswer ", style: pw.TextStyle(font: font, fontSize: 10, color: statusColor)),
                    if (!isCorrect)
                      pw.Text("(Correct: $correctAnswer)", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.green)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            statusText,
            style: pw.TextStyle(font: fontBold, color: statusColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reward Logic: 1 reward point for every 10 marks
    final int rewardPoints = widget.correctAnswers ~/ 10;
    final bool hasReward = rewardPoints > 0;
    
    // Theme Colors
    final theme = Theme.of(context);
    final gradientColors = [
      theme.colorScheme.primary,
      theme.colorScheme.primary.withOpacity(0.8),
    ];

    return Stack(
      children: [
        Scaffold(
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
                    if (widget.correctAnswers > widget.totalQuestions / 2)
                      const Text("🎉", style: TextStyle(fontSize: 40)),
                    Text(
                      widget.correctAnswers > widget.totalQuestions / 2 ? "Excellent Job!" : "Keep Practicing!",
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
                          "${widget.correctAnswers}",
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
                            "/ ${widget.totalQuestions}",
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
                  Expanded(child: _buildStatCard(context, "Correct", "${widget.correctAnswers}", Colors.green.shade500, Icons.check_circle_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, "Wrong", "${widget.wrongAnswers}", Colors.red.shade400, Icons.cancel_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, "Skipped", "${widget.skippedAnswers}", Colors.orange.shade400, Icons.help_outline)),
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
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  final userAns = widget.selectedAnswers[index];
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
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isSkipped)
                                      _buildAnswerRow(context, "Your Answer", userAns, isCorrect ? Colors.green : Colors.red),
                                    
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

              // 5. Preview Button & Home
              CustomFilledButton(
                label: "Preview Question Paper",
                icon: Icons.visibility_rounded,
                onPressed: _previewPdf,
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
        ),
        if (_isLoading)
          const CustomLoader(),
      ],
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
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
